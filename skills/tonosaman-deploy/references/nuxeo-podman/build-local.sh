#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")" || exit 1
PROJECT_ROOT="../.."

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
# Usage:
#   build-local.sh                              → default build (Artifactory for all BaseCore)
#   build-local.sh --local                      → use base:local Podman image (no addon override)
#   build-local.sh --local myapp-trash-package    → build those BaseCore addons locally, rest from Artifactory
#   build-local.sh --local myapp-trash-package myapp-lifecycle-package ...
# ---------------------------------------------------------------------------

BASECORE_IMAGE_ARG=""
LOCAL_ADDONS=()   # list of BaseCore artifact names to build locally

case "${1:-}" in
    "")
        ;;
    --local)
        BASECORE_IMAGE_ARG="--build-arg BASECORE_IMAGE=base:local"
        shift
        # Any remaining args are addon names to build locally
        LOCAL_ADDONS=("$@")
        ;;
    *)
        echo "❌ ERROR: Unknown argument '${1}'. Usage: manager.sh build [--local [addon-name ...]]"
        exit 1
        ;;
esac

# ---------------------------------------------------------------------------
# Prerequisites
# ---------------------------------------------------------------------------

for cmd in mvn yq curl podman; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "❌ ERROR: '$cmd' is required but not installed."
    exit 1
  fi
done

required_vars=(
  DEPOSIT_TOKEN
  HARBOR_USER
  HARBOR_TOKEN
)

for var in "${required_vars[@]}"; do
  if [ -z "${!var:-}" ]; then
    echo "❌ ERROR: $var is not set. Add it to your ~/.bashrc"
    exit 1
  fi
done

# When local addon builds are requested, BASECORE_ADDONS_PATH is required
if [[ ${#LOCAL_ADDONS[@]} -gt 0 ]]; then
  if [ -z "${BASECORE_ADDONS_PATH:-}" ]; then
    echo "ERROR: BASECORE_ADDONS_PATH is not set. Add it to your ~/.bashrc"
    echo "   Example: export BASECORE_ADDONS_PATH=\"/mnt/c/projects/myapp_addons\""
    exit 1
  fi
  if [ ! -d "$BASECORE_ADDONS_PATH" ]; then
    echo "ERROR: BASECORE_ADDONS_PATH directory not found: $BASECORE_ADDONS_PATH"
    exit 1
  fi
fi

echo "🔑 Environment variables ✅"

# ---------------------------------------------------------------------------
# Downloads cleanup
# ---------------------------------------------------------------------------

echo "🗑️  Cleaning downloads/"
rm -rf "$PROJECT_ROOT/downloads/"*

ARTIFACTORY_URL="https://artifactory.example.com:443"
SOCLE_ARTIFACTORY_REPO_RELEASE="base-nuxeo-maven-release"
SOCLE_ARTIFACTORY_REPO_SNAPSHOT="base-nuxeo-maven-snapshot"
ARTIFACTS_FILE="$PROJECT_ROOT/addons_artifacts.yml"
NEXUS_URL="https://nexus.example.com/repository"
NEXUS_REPOSITORY="nuxeo-studio"
GROUP_ID="nuxeo-studio"

# ---------------------------------------------------------------------------
# MYAPP Maven build
# ---------------------------------------------------------------------------

echo "🏗️ Building MYAPP Maven artifacts"
mkdir -p "$PROJECT_ROOT/downloads/myapp"
(cd "$PROJECT_ROOT" && mvn clean verify -T1C -Dmaven.repo.local="$HOME"/.m2/repository --settings ./settings.xml -Drepo.token="$DEPOSIT_TOKEN")
find "$PROJECT_ROOT" -type f -name '*package*' -path '*-package/target/*' -exec cp --verbose -t "$PROJECT_ROOT/downloads/myapp/" {} +

# ---------------------------------------------------------------------------
# BaseCore packages — local override or Artifactory download
# ---------------------------------------------------------------------------

echo "📦 Resolving BaseCore packages"
mkdir -p "$PROJECT_ROOT/downloads/basecore"
ARTIFACT_COUNT=$(yq -r 'explode(.) | .basecore | length // 0' "$ARTIFACTS_FILE")

if [[ "$ARTIFACT_COUNT" -eq 0 ]]; then
  echo "   No BaseCore packages found, skipping"
else
  yq -r 'explode(.) | .basecore[] | "\(.name) \(.version) \(.extension)"' "$ARTIFACTS_FILE" |
  while read -r ARTIFACT_NAME ARTIFACT_VERSION ARTIFACT_EXTENSION; do
    ARTIFACT_FILE="${ARTIFACT_NAME}-${ARTIFACT_VERSION}.${ARTIFACT_EXTENSION}"
    OUT="$PROJECT_ROOT/downloads/basecore/${ARTIFACT_FILE}"

    # Check if this addon was requested as a local build
    IS_LOCAL=false
    for ADDON in "${LOCAL_ADDONS[@]+"${LOCAL_ADDONS[@]}"}"; do
      [[ "$ADDON" == "$ARTIFACT_NAME" ]] && IS_LOCAL=true && break
    done

    if [[ "$IS_LOCAL" == true ]]; then
      MODULE_DIR="${ARTIFACT_NAME%-package}"
      MODULE_PATH="$BASECORE_ADDONS_PATH/$MODULE_DIR"
      PACKAGE_TARGET="$MODULE_PATH/$ARTIFACT_NAME/target"

      if [ ! -d "$MODULE_PATH" ]; then
        echo "   ❌ $ARTIFACT_NAME → module directory not found: $MODULE_PATH"
        exit 1
      fi

      echo "   🔨 Building $ARTIFACT_NAME locally..."
      (cd "$MODULE_PATH" && mvn clean verify -T1C -Dmaven.repo.local="$HOME"/.m2/repository --settings "$BASECORE_ADDONS_PATH/settings.xml" -Drepo.token="$DEPOSIT_TOKEN")

      BUILT_ZIP=$(find "$PACKAGE_TARGET" -maxdepth 1 -name "${ARTIFACT_NAME}-*.zip" 2>/dev/null | head -1)
      if [ -z "$BUILT_ZIP" ]; then
        echo "   ❌ $ARTIFACT_NAME → built zip not found in $PACKAGE_TARGET"
        exit 1
      fi

      printf "   -> %-75s" "$ARTIFACT_FILE"
      cp "$BUILT_ZIP" "$OUT"
      echo "⚡ [LOCAL BUILD: $(basename "$BUILT_ZIP")]"
    else
      if [[ "$ARTIFACT_VERSION" == *-SNAPSHOT ]]; then
        REPO="$SOCLE_ARTIFACTORY_REPO_SNAPSHOT"
      else
        REPO="$SOCLE_ARTIFACTORY_REPO_RELEASE"
      fi
      ARTIFACT_URL="${ARTIFACTORY_URL}/artifactory/${REPO}/com/myapp/${ARTIFACT_NAME}/${ARTIFACT_VERSION}/${ARTIFACT_FILE}"
      printf "   -> %-75s" "$ARTIFACT_FILE"
      curl --fail -s -H "Authorization: Bearer $DEPOSIT_TOKEN" --output "$OUT" "$ARTIFACT_URL"
      echo "✅ [Artifactory]"
    fi
  done
fi

# ---------------------------------------------------------------------------
# Studio package
# ---------------------------------------------------------------------------

echo "🎨 Downloading Studio package"
mkdir -p "$PROJECT_ROOT/downloads/studio"
yq -r 'explode(.) | .studio[] | "\(.name) \(.version) \(.extension)"' "$ARTIFACTS_FILE" |
while read -r ARTIFACT_NAME ARTIFACT_VERSION ARTIFACT_EXTENSION; do
  ARTIFACT_URL="${NEXUS_URL}/${NEXUS_REPOSITORY}/${GROUP_ID}/${ARTIFACT_NAME}/${ARTIFACT_VERSION}/${ARTIFACT_NAME}-${ARTIFACT_VERSION}.${ARTIFACT_EXTENSION}"
  OUT="$PROJECT_ROOT/downloads/studio/${ARTIFACT_NAME}-${ARTIFACT_VERSION}.${ARTIFACT_EXTENSION}"
  printf "   -> %-75s" "${ARTIFACT_NAME}-${ARTIFACT_VERSION}.${ARTIFACT_EXTENSION}"
  curl --fail -s --output "$OUT" "$ARTIFACT_URL"
  echo "✅"
done

# ---------------------------------------------------------------------------
# Marketplace packages
# ---------------------------------------------------------------------------

echo "🛒 Downloading Marketplace packages"
mkdir -p "$PROJECT_ROOT/downloads/marketplace"
ARTIFACT_COUNT=$(yq -r 'explode(.) | .marketplace | length // 0' "$ARTIFACTS_FILE")
if [[ "$ARTIFACT_COUNT" -eq 0 ]]; then
  echo "   No Marketplace packages found, skipping"
else
  yq -r 'explode(.) | .marketplace[] | "\(.name) \(.version) \(.extension)"' "$ARTIFACTS_FILE" |
  while read -r ARTIFACT_NAME ARTIFACT_VERSION ARTIFACT_EXTENSION; do
    ARTIFACT_FILE="${ARTIFACT_NAME}-${ARTIFACT_VERSION}.${ARTIFACT_EXTENSION}"
    ARTIFACT_URL="${ARTIFACTORY_URL}/artifactory/packages.nuxeo.com-private-maven-remote/org/nuxeo/packages/${ARTIFACT_NAME}/${ARTIFACT_VERSION}/${ARTIFACT_FILE}"
    OUT="$PROJECT_ROOT/downloads/marketplace/${ARTIFACT_FILE}"
    printf "   -> %-75s" "$ARTIFACT_FILE"
    curl --fail -s -H "Authorization: Bearer $DEPOSIT_TOKEN" --output "$OUT" "$ARTIFACT_URL"
    echo "✅"
  done
fi

# ---------------------------------------------------------------------------
# Podman image build
# ---------------------------------------------------------------------------

if [ -z "$BASECORE_IMAGE_ARG" ]; then
  echo "🔐 Logging in to Harbor"
  echo "$HARBOR_TOKEN" | podman login -u "$HARBOR_USER" --password-stdin registry.example.com
else
  echo "🔐 Harbor login skipped (using local BaseCore image)"
fi

echo "🦭 Building Podman image (myapp:local)"
podman build --target=aprod -t myapp:local -f "$PROJECT_ROOT/myapp_nuxeo_docker/docker_images/Dockerfile" "$PROJECT_ROOT" --no-cache --build-arg HTTP_PROXY="${HTTP_PROXY:-}" $BASECORE_IMAGE_ARG
