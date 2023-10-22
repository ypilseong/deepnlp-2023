#!/bin/bash
# add your custom commands here that should be executed when building the docker image
# arguments usage
USAGE="
$0 COMMAND [OPTIONS]

Arguments:
COMMAND                The operation to be performed. Must be one of: [start|run]

Options:
-m, --model MODEL_NAME          Specify a model name
-h, --help                      Display this help message.

Additional arguments can be provided after the Docker name, and they will be passed directly to the Docker Compose command.

Example:
$0 start
"

# declare arguments
MODEL_NAME="llama2"
ADDITIONAL_ARGS=""

set +u
# read arguments
# first argument is the command
COMMAND="$1"
shift

# parse options
while [[ $# -gt 0 ]]; do
    case "$1" in
    -m | --model)
        MODEL_NAME="$2"
        shift
        ;;
    --model=*)
        MODEL_NAME="${1#*=}"
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

if [ "${COMMAND}" == "start" ]; then
    echo "Start ollama container"
elif [ "${COMMAND}" == "run" ]; then
    echo "Run a model in ollama container"
else
    echo "Invalid command: $COMMAND" >&2
    echo "Usage: $0 $USAGE" >&2
    exit 1
fi
echo "---"

# load environment variables and print them
set -a
OLLAMA_ENV_FILE="ollama/ollama.env"
if [ -e "$OLLAMA_ENV_FILE" ]; then
    echo "Loading common environment variables from $OLLAMA_ENV_FILE"
    set -x # print commands and thier arguments
    # shellcheck disable=SC1091,SC1090
    source "$OLLAMA_ENV_FILE"
    set +x # disable printing of environment variables
fi
set +a

# prepare local workspace to be mounted
echo "Preparing local workspace directories"
[ ! -d "${OLLAMA_WORKSPACE_ROOT}" ] && mkdir -p "${OLLAMA_WORKSPACE_ROOT}"

# execute docker command
if [ "${COMMAND}" == "start" ]; then
    CMD="docker run -d --gpus '\"device=$OLLAMA_GPU_DEVICE_ID\"' -v $OLLAMA_WORKSPACE_ROOT:/root/.ollama -p $OLLAMA_SVC_PORT:11434 --name $OLLAMA_CONTAINER_NAME ollama/ollama"
elif [ "${COMMAND}" == "run" ]; then
    CMD="docker exec -it $OLLAMA_CONTAINER_NAME ollama run $MODEL_NAME"
fi
echo "Running command: ${CMD}"
eval "${CMD}"
