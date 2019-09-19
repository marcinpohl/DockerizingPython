#!/bin/bash

function docker_flatten() {
    [[ $# -ne 2 ]] && ( echo "Example usage: docker_flatten python:3.7-slim python:3.7-slim-flat"; exit 255 )

    local SRC="$1"  # Name or SHA of the source image
    local TGT="$2"  # Name and optional tag of the target image

    ID=$(docker run -d "$SRC" /bin/bash)
    ### the actual flattening is export + import
    docker export "$ID" | docker import - "$TGT"
    docker container stop "$ID"

    SRC_SIZE=$(docker inspect --format '{{.Size}}' "$SRC")
    TGT_SIZE=$(docker inspect --format '{{.Size}}' "$TGT")
    echo "" \
    | awk -v src="$SRC_SIZE" -v tgt="$TGT_SIZE" \
        '{printf "Flattened image is %3.1f%% of the old one.\n", 100*tgt/src}'
}

docker_flatten "$@"

