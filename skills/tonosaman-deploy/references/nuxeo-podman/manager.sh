#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")" || exit 1
COMPOSE_CMD="podman-compose -f ./docker-compose.yaml"
VOLUMES_DIR="$HOME/podman-volumes/myapp"
IMAGE_NAME="myapp:local"
NUXEO_URL="http://localhost:28080/nuxeo"
NUXEO_ADMINISTRATOR_LOGIN="Administrator:change-me"
export VOLUMES_DIR

VOLUMES=(
    "$VOLUMES_DIR/nuxeo_data"
    "$VOLUMES_DIR/nuxeo_log"
    "$VOLUMES_DIR/nuxeo_ui"
    "$VOLUMES_DIR/kafka_data"
    "$VOLUMES_DIR/postgres_data"
    "$VOLUMES_DIR/opensearch_data1"
    "$VOLUMES_DIR/opensearch_data2"
)

create_volumes() {
    mkdir -p "${VOLUMES[@]}"
}

destroy_volumes() {
    sudo rm -rf "$VOLUMES_DIR"
}

confirm() {
    read -r -p "$1 [y/N] " answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

is_running() {
    $COMPOSE_CMD ps --status running -q 2>/dev/null | grep -q .
}

require_image() {
    if ! podman image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
        echo "=> ERROR: Image '$IMAGE_NAME' not found. Build it first with: ./manager.sh build"
        exit 1
    fi
}

require_node() {
    if ! command -v node &> /dev/null; then
        echo "=> ERROR: 'node' is required but not installed."
        exit 1
    fi
}

fix_nuxeo_ui_permissions() {
    echo "=> Waiting for nuxeo.war to be populated..."
    until podman exec myapp-nuxeo test -d /opt/nuxeo/server/nxserver/nuxeo.war/WEB-INF 2>/dev/null; do
        sleep 2
    done
    echo "=> Making nuxeo.war writable for host-side UI editing..."
    podman exec --user 0 myapp-nuxeo chmod -R a+w /opt/nuxeo/server/nxserver/nuxeo.war
}

ensure_local_conf() {
    if [ ! -f ./local.conf.d/90-local.conf ]; then
        mkdir -p ./local.conf.d
        cp ./local.conf.d/90-local.conf.example ./local.conf.d/90-local.conf
        echo "Created local.conf.d/90-local.conf from the example (gitignored, yours to edit)."
    fi
}

nuxeo_automation() {
    local operation="$1"
    local body='{"params":{}}'
    [ $# -ge 2 ] && body="$2"
    curl --fail -X POST -u "$NUXEO_ADMINISTRATOR_LOGIN" \
        "$NUXEO_URL/api/v1/automation/$operation" \
        -H 'Content-Type: application/json' \
        -d "$body"
    echo ""
}

seed_vocabularies() {
    echo "=> Importing vocabularies..."
    nuxeo_automation "MYAPP.ImportVocabulariesFromCSV"
}

seed_vocabularies_joins() {
    echo "=> Importing vocabulary joins..."
    nuxeo_automation "Directory.ImportMultiParentJoins"
}

seed_groups() {
    echo "=> Creating base groups..."
    nuxeo_automation "MYAPP.CreateGroups"
}

seed_plan_classement() {
    require_node
    echo "=> Initializing plan de classement..."
    node ../script/init_plan_classement.js
}

seed_templates() {
    require_node
    echo "=> Initializing templates..."
    node ../script/init_templates.js
}

seed_users() {
    require_node
    echo "=> Initializing users..."
    node ../script/init_users.js
}

hotreload() {
    echo "=> Hot-reloading Studio SNAPSHOT..."
    nuxeo_automation "Service.HotReloadStudioSnapshot" '{"input":{},"params":{},"context":{}}'
}

reindex() {
    echo "=> Triggering full OpenSearch reindex..."
    curl --fail -X POST -u "$NUXEO_ADMINISTRATOR_LOGIN" \
        "$NUXEO_URL/api/v1/management/search/reindex"
    echo ""
}

usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  build                                     Build the local Podman image using BASECORE image from Harbor"
    echo "  build --local                             Build using base:local as base image (no addon override)"
    echo "  build --local <addon> [<addon> ...]       Build specified BaseCore addons from local source, rest from Artifactory"
    echo "  start                                     Start the containers"
    echo "  stop                                      Stop the containers"
    echo "  restart                                   Restart the containers"
    echo "  register                                  Register the Nuxeo instance with Nuxeo Connect (run once after first start)"
    echo "  destroy                                   Stop containers and delete all data volumes"
    echo "  purge                                     Delete the '$IMAGE_NAME' container image"
    echo "  seed                                      Run all seed steps (vocabularies, groups, plan de classement, templates, users)"
    echo "  seed-vocabularies                         Import vocabularies from CSV"
    echo "  seed-vocabularies-joins                   Import multi-parent vocabulary joins"
    echo "  seed-groups                               Create base permission groups"
    echo "  seed-plan-de-classement                   Initialize plan de classement"
    echo "  seed-templates                            Initialize document templates"
    echo "  seed-users                                Initialize users"
    echo "  hotreload                                 Hot-reload the Studio SNAPSHOT"
    echo "  reindex                                   Trigger a full OpenSearch reindex"
    echo "  clean                                     Clean folders (pass extra paths as args)"
    echo ""
    echo "Examples:"
    echo "  ./manager.sh build"
    echo "  ./manager.sh build --local"
    echo "  ./manager.sh build --local myapp-trash-package"
    echo "  ./manager.sh build --local myapp-trash-package myapp-lifecycle-package"
    exit 1
}

case "${1:-}" in
    build)
        shift
        bash "$(dirname "$0")/scripts/build-local.sh" "$@"
        ;;
    start)
        ensure_local_conf
        require_image
        create_volumes
        $COMPOSE_CMD up -d
        fix_nuxeo_ui_permissions
        ;;
    stop)
        $COMPOSE_CMD down 2>/dev/null
        ;;
    destroy)
        if is_running; then
            echo "Services are still running."
        fi
        if confirm "This will stop all services and DELETE all data (volumes). Continue?"; then
            $COMPOSE_CMD down -v 2>/dev/null
            destroy_volumes
        else
            echo "Aborted."
        fi
        ;;
    restart)
        ensure_local_conf
        require_image
        $COMPOSE_CMD down 2>/dev/null
        create_volumes
        $COMPOSE_CMD up -d
        fix_nuxeo_ui_permissions
        ;;
    register)
        if ! is_running; then
            echo "=> ERROR: Nuxeo is not running. Start it first with: ./manager.sh start"
            exit 1
        fi
        echo "=> Registering Nuxeo instance with Nuxeo Connect..."
        echo "   You will be prompted for your Connect username, token, project, and description."
        podman exec -it myapp-nuxeo \
            /opt/nuxeo/server/bin/nuxeoctl register
        ;;
    purge)
        if is_running; then
            if confirm "Services are still running. Stop them first?"; then
                $COMPOSE_CMD down 2>/dev/null
            else
                echo "Aborted."
                exit 1
            fi
        fi
        if confirm "Remove image '$IMAGE_NAME'?"; then
            podman image rm "$IMAGE_NAME"
        else
            echo "Aborted."
        fi
        ;;
    seed)
        seed_vocabularies
        seed_vocabularies_joins
        seed_groups
        seed_plan_classement
        seed_templates
        seed_users
        ;;
    seed-vocabularies)      seed_vocabularies ;;
    seed-vocabularies-joins) seed_vocabularies_joins ;;
    seed-groups)            seed_groups ;;
    seed-plan-de-classement) seed_plan_classement ;;
    seed-templates)         seed_templates ;;
    seed-users)             seed_users ;;
    hotreload)              hotreload ;;
    reindex)                reindex ;;
    clean)
        require_node
        node ../script/init_plan_classement.js --clean "${@:2}"
        ;;
    *)
        usage
        ;;
esac
