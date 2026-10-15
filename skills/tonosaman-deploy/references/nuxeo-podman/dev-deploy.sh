#!/usr/bin/env bash
# Fast dev-deploy for local Nuxeo development.
# Builds the target module, copies its JARs into the running nuxeo container,
# and restarts only Nuxeo — Kafka, Postgres, OpenSearch stay up.
#
# Usage (from anywhere in the project tree):
#   ./myapp_nuxeo_podman/dev-deploy.sh                                    # builds all myapp addons
#   ./myapp_nuxeo_podman/dev-deploy.sh myapp-addon/myapp-extsync-sync    # one module subtree
#   ./myapp_nuxeo_podman/dev-deploy.sh --gradle                           # build with Gradle instead
#
# --gradle swaps only the compile step. Maven remains the default and is untouched, because
# using Gradle is a personal preference and nobody should have to adopt it to deploy locally.
# Dependency staging below stays on Maven either way: it is the step that knows which
# third-party jars the server is missing, and there is no reason to have two answers to that.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

NUXEO_CONTAINER="nuxeo"
NUXEO_BUNDLES="/opt/nuxeo/server/nxserver/bundles"
NUXEO_LIB="/opt/nuxeo/server/nxserver/lib"
USE_GRADLE=false
TARGET_MODULE="myapp-addon"
for arg in "$@"; do
    case "$arg" in
        --gradle) USE_GRADLE=true ;;
        -*)       echo "[dev-deploy] ERROR: unknown option: $arg" ; exit 1 ;;
        *)        TARGET_MODULE="$arg" ;;
    esac
done

# Staged outside any target/ directory on purpose — see the find below.
DEPS_STAGE="$PROJECT_ROOT/.dev-deploy-deps"

if [[ ! -d "$PROJECT_ROOT/$TARGET_MODULE" ]]; then
    echo "[dev-deploy] ERROR: module not found: $PROJECT_ROOT/$TARGET_MODULE"
    exit 1
fi

if [[ "$USE_GRADLE" == true ]]; then
    # Gradle has no notion of the directory subtree this script takes, so it builds every module;
    # the subtree filter is applied when the JARs are collected. Incremental builds make the
    # difference negligible. myapp-package is not a Gradle module — it is not deployed either.
    echo "[dev-deploy] Building all modules with Gradle (subtree filter applies to $TARGET_MODULE) ..."
    (cd "$PROJECT_ROOT" && ./gradlew jar)
    BUILD_OUTPUT_GLOB="*/build/libs/*.jar"
else
    echo "[dev-deploy] Building $TARGET_MODULE ..."
    (cd "$PROJECT_ROOT/$TARGET_MODULE" && mvn package -DskipTests --settings "$PROJECT_ROOT/settings.xml")
    BUILD_OUTPUT_GLOB="*/target/*.jar"
fi

echo "[dev-deploy] Collecting JARs ..."
# Only our own build output belongs in bundles/. Third-party dependencies are staged in
# DEPS_STAGE below and go to lib/ — they must never be swept up by this find, or Nuxeo's own
# xerces/jackson end up duplicated in bundles/ and the server dies on a classloader clash.
mapfile -t JARS < <(find "$PROJECT_ROOT/$TARGET_MODULE" -path "$BUILD_OUTPUT_GLOB" \
    ! -path "$DEPS_STAGE/*" \
    ! -name "*-tests.jar" \
    ! -name "*-sources.jar" \
    ! -name "*-javadoc.jar")

if [[ ${#JARS[@]} -eq 0 ]]; then
    echo "[dev-deploy] ERROR: no JARs found after build — did the build succeed?"
    exit 1
fi

echo "[dev-deploy] Copying ${#JARS[@]} JAR(s) to $NUXEO_CONTAINER:$NUXEO_BUNDLES/"
for jar in "${JARS[@]}"; do
    echo "    $(basename "$jar")"
    podman cp "$jar" "$NUXEO_CONTAINER:$NUXEO_BUNDLES/"
done

# Third-party libraries the addon needs that the Nuxeo distribution does not ship.
# Without them a dev-deployed bundle throws NoClassDefFoundError at runtime, and in a
# *synchronous* listener that Error is not caught by Nuxeo's event service — it aborts the
# user operation that fired the event (a trash, a delete), which looks like a broken app.
#
# This list is explicit on purpose. Auto-detecting "already provided" from the dependency
# tree cannot be made safe: Tomcat ships unversioned jars (jasper-el.jar, el-api.jar) that
# no version-stripping heuristic matches against their Maven names
# (tomcat-jasper-el-10.1.57.jar), and pushing a second copy of a library the server already
# has breaks Nuxeo's classloader — a duplicate xerces takes SchemaManager down and Tomcat
# then refuses to start the /nuxeo context at all.
#
# Getting this list wrong fails in the safe direction: a missing entry is a loud
# NoClassDefFoundError naming the class. Add an entry when the addon takes a new dependency.
EXTRA_LIBS=(vavr vavr-match)

echo "[dev-deploy] Collecting third-party dependencies ..."
rm -rf "$DEPS_STAGE"
# myapp-package has to be kept out of this reactor. It depends on the sibling com.example artifacts,
# which nothing in this workflow installs into ~/.m2 — neither `mvn package` nor Gradle — so
# resolving them reaches the remote repos and 401s, failing the whole run. It contributes no
# third-party library anyway: its only output is the marketplace zip.
DEPS_REACTOR_FILTER=()
if [[ -d "$PROJECT_ROOT/$TARGET_MODULE/myapp-package" ]]; then
    DEPS_REACTOR_FILTER=(-pl '!myapp-package')
fi
(cd "$PROJECT_ROOT/$TARGET_MODULE" && mvn -q dependency:copy-dependencies \
    ${DEPS_REACTOR_FILTER[@]+"${DEPS_REACTOR_FILTER[@]}"} \
    -DincludeScope=runtime \
    -DexcludeGroupIds=org.nuxeo,com.example \
    -DoutputDirectory="$DEPS_STAGE" \
    --settings "$PROJECT_ROOT/settings.xml")

for name in "${EXTRA_LIBS[@]}"; do
    mapfile -t matches < <(find "$DEPS_STAGE" -maxdepth 1 -name "$name-[0-9]*.jar" 2>/dev/null)
    if [[ ${#matches[@]} -eq 0 ]]; then
        echo "[dev-deploy] WARNING: '$name' is in EXTRA_LIBS but was not resolved — skipping."
        continue
    fi
    for dep in "${matches[@]}"; do
        echo "    lib/ $(basename "$dep")"
        podman cp "$dep" "$NUXEO_CONTAINER:$NUXEO_LIB/"
    done
done

LOG4J2_SRC="$PROJECT_ROOT/myapp_nuxeo_docker/configs/log4j2-myapp.xml"
LOG4J2_DST="$NUXEO_CONTAINER:/opt/nuxeo/server/lib/log4j2-myapp.xml"
if [[ -f "$LOG4J2_SRC" ]]; then
    echo "[dev-deploy] Applying log4j2-myapp.xml ..."
    podman cp "$LOG4J2_SRC" "$LOG4J2_DST"
fi

echo "[dev-deploy] Restarting Nuxeo (Kafka/Postgres/OpenSearch stay up) ..."
podman restart "$NUXEO_CONTAINER"

echo ""
echo "[dev-deploy] Nuxeo is restarting. Tail logs:"
echo "    tail -f $PROJECT_ROOT/myapp_nuxeo_podman/volumes/nuxeo_log/server.log"
