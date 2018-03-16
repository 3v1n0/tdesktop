#!/bin/bash

set -xe

TRAVIS_BUILD_STEP="$1"

if [ -z "$TRAVIS_BUILD_STEP" ]; then
  echo "No travis build step defined"
  exit 1
fi

REPO="$PWD"
THIS_PATH=$(dirname $0)
UPSTREAM="$REPO/upstream"
CACHE="$HOME/travisCacheDir"

DOCKER_IMAGE="ubuntu:xenial"
DOCKER_BUILDER_NAME='builder'

function docker_exec() {
  docker exec -i $DOCKER_BUILDER_NAME $*
}

if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
  if [ "$SNAP_PRIME_ON_PULL_REQUEST" != "true" ]; then
    echo '$SNAP_PRIME_ON_PULL_REQUEST is not set to true, thus we skip this now'
    exit 0
  fi
fi

if [ "$TRAVIS_BUILD_STEP" == "before_install" ]; then
  if [ -n "$ARCH" ]; then DOCKER_IMAGE="$ARCH/$DOCKER_IMAGE"; fi
    docker run --name $DOCKER_BUILDER_NAME -e LANG=C.UTF-8 -e TERM \
     -v $PWD:$PWD -w $UPSTREAM -td $DOCKER_IMAGE
elif [ "$TRAVIS_BUILD_STEP" == "install" ]; then
  docker_exec apt-get update -q
  docker_exec apt-get install -y snapcraft
elif [ "$TRAVIS_BUILD_STEP" == "script" ]; then
  build_type="Debug"
  snapcraft_yaml="$UPSTREAM/snap/snapcraft.yaml"

  sed "s,CMAKE_BUILD_TYPE=.*,CMAKE_BUILD_TYPE=$build_type,g;
       s,build-type:.*,build-type: '$build_type',g" \
      -i "$snapcraft_yaml"

  docker_exec snapcraft prime
fi
