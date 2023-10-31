#!/bin/bash
# add your custom commands here that should be executed when building the docker image
# arguments usage
USAGE="
$0 COMMAND [OPTIONS]

Arguments:
COMMAND                The operation to be performed. Must be one of: [build|config|login|up|down|run]

Options:
-p, --pname PROJECT_NAME        Specify a project name for the container instance.
-r, --run RUN_COMMAND           Specify a command to run when using the 'run' command. Default: bash
-h, --help                      Display this help message.

Additional arguments can be provided after the Docker name, and they will be passed directly to the Docker Compose command.

Example:
$0 build -v base
"

# declare arguments
PROJECT_NAME="admin"
COMMAND="build"
RUN_COMMAND="bash"
ADDITIONAL_ARGS=""

set +u
# read arguments
# first argument is the command
COMMAND="$1"
shift

# parse options
while [[ $# -gt 0 ]]; do
    case "$1" in
    -p | --pname)
        PROJECT_NAME="$2"
        shift
        ;;
    --pname=*)
        PROJECT_NAME="${1#*=}"
        ;;
    -r | --run)
        RUN_COMMAND="$2"
        shift
        ;;
    --run=*)
        RUN_COMMAND="${1#*=}"
        ;;
    -h | --help)
        echo "Usage: $0 $USAGE" >&2
        exit 0
        ;;
    -h*)
        echo "Usage: $0 $USAGE" >&2
        exit 0
        ;;
    *)
        ADDITIONAL_ARGS="$ADDITIONAL_ARGS $1"
        ;;
    esac
    shift
done
# check if remaining arguments exist
if [[ -n "$ADDITIONAL_ARGS" ]]; then
    echo "Additional arguments: $ADDITIONAL_ARGS" >&2
fi
set -u

if [ "${COMMAND}" == "build" ]; then
    echo "Building docker image for the project: ${PROJECT_NAME}"
elif [ "${COMMAND}" == "config" ]; then
    echo "Printing docker config for the project: ${PROJECT_NAME}"
elif [ "${COMMAND}" == "up" ]; then
    echo "Starting docker container for the project: ${PROJECT_NAME}"
elif [ "${COMMAND}" == "down" ]; then
    echo "Stopping docker container for the project: ${PROJECT_NAME}"
elif [ "${COMMAND}" == "run" ]; then
    echo "Running docker container for the project: ${PROJECT_NAME}"
elif [ "${COMMAND}" == "login" ]; then
    echo "Logging into docker registry for the project: ${PROJECT_NAME}"
else
    echo "Invalid command: $COMMAND" >&2
    echo "Usage: $0 $USAGE" >&2
    exit 1
fi
echo "---"

DOCKER_PROJECT_NAME="${PROJECT_NAME}"
DOCKER_PROJECT_SERVICE_NAME="app"
DOCKER_PROJECT_COMPOSE_FILE="llmsvc/${PROJECT_NAME}/docker-compose.yaml"

# load environment variables and print them
set -a
# load secert environment variables from .env.secret
DOCKER_SECRET_ENV_FILENAME=${DOCKER_SECRET_ENV_FILENAME:-".env.secret"}
if [ -e "${DOCKER_SECRET_ENV_FILENAME}" ]; then
    echo "Loading secret environment variables from ${DOCKER_SECRET_ENV_FILENAME}"
    set -x # print commands and thier arguments
    # shellcheck disable=SC1091,SC1090
    source "${DOCKER_SECRET_ENV_FILENAME}"
    set +x # disable printing of environment variables
fi
# load global environment variables from .env.docker
DOCKERFILES_SHARE_DIR=${DOCKERFILES_SHARE_DIR:-"$HOME/.local/share/dockerfiles"}
DOCKER_GLOBAL_ENV_FILENAME=${DOCKER_GLOBAL_ENV_FILENAME:-".env.docker"}
DOCKER_GLOBAL_ENV_FILE=${DOCKER_GLOBAL_ENV_FILE:-"${DOCKERFILES_SHARE_DIR}/${DOCKER_GLOBAL_ENV_FILENAME}"}
if [ ! -e "${DOCKER_GLOBAL_ENV_FILENAME}" ] && [ -e "${DOCKER_GLOBAL_ENV_FILE}" ]; then
    echo "Symlinking ${DOCKER_GLOBAL_ENV_FILE} to ${DOCKER_GLOBAL_ENV_FILENAME}"
    ln -s "${DOCKER_GLOBAL_ENV_FILE}" "${DOCKER_GLOBAL_ENV_FILENAME}"
fi
if [ -e "${DOCKER_GLOBAL_ENV_FILENAME}" ]; then
    echo "Loading global environment variables from ${DOCKER_GLOBAL_ENV_FILENAME}"
    set -x # print commands and thier arguments
    # shellcheck disable=SC1091,SC1090
    source "${DOCKER_GLOBAL_ENV_FILENAME}"
    set +x # disable printing of environment variables
fi
DOCKER_COMMON_ENV_FILENAME="llmsvc/docker.common.env"
if [ -e "${DOCKER_COMMON_ENV_FILENAME}" ]; then
    echo "Loading common environment variables from ${DOCKER_COMMON_ENV_FILENAME}"
    set -x # print commands and thier arguments
    # shellcheck disable=SC1091,SC1090
    source "${DOCKER_COMMON_ENV_FILENAME}"
    set +x # disable printing of environment variables
fi
DOCKER_PROJECT_ENV_FILENAME="llmsvc/${PROJECT_NAME}/docker.env"
if [ -e "${DOCKER_PROJECT_ENV_FILENAME}" ]; then
    echo "Loading environment variables from ${DOCKER_PROJECT_ENV_FILENAME}"
    set -x # print commands and thier arguments
    # shellcheck disable=SC1091,SC1090
    source "${DOCKER_PROJECT_ENV_FILENAME}"
    set +x # disable printing of environment variables
fi
set +a

# prepare docker network
if [[ -n "${CONTAINER_NETWORK_NAME}" ]] && ! docker network ls | grep -q "${CONTAINER_NETWORK_NAME}"; then
    echo "Creating network ${CONTAINER_NETWORK_NAME}"
    docker network create "${CONTAINER_NETWORK_NAME}"
else
    echo "Network ${CONTAINER_NETWORK_NAME} already exists."
fi

# prepare local workspace to be mounted
# echo "Preparing local workspace directories"
# [ ! -d "${HOST_WORKSPACE_ROOT}" ] && mkdir -p "${HOST_WORKSPACE_ROOT}"
# [ ! -d "${HOST_HF_HOME}" ] && mkdir -p "${HOST_HF_HOME}"

# run docker-compose
if [ "${COMMAND}" == "login" ]; then
    echo "GITHUB_CR_PAT: $GITHUB_CR_PAT"
    CMD="docker login ghcr.io -u $GITHUB_USERNAME"
elif [ "${COMMAND}" == "run" ]; then
    CMD="docker compose --project-directory . -f ${DOCKER_PROJECT_COMPOSE_FILE} run ${DOCKER_PROJECT_SERVICE_NAME} ${RUN_COMMAND} ${ADDITIONAL_ARGS}"
else
    CMD="docker-compose --project-directory . -f ${DOCKER_PROJECT_COMPOSE_FILE} -p ${DOCKER_PROJECT_NAME} ${COMMAND} ${ADDITIONAL_ARGS}"
fi
echo "Running command: ${CMD}"
eval "${CMD}"
