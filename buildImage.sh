#!/bin/bash
#
# Builds image xgo-latest and base images with the given go version as the
# latest version. It also checks for mistakes made when adding new versions.
#
# Ensure that you have added the go-<version> directory under docker.
#
# Usage: buildLatestImage.sh <go version> [latest]
#
# e.g. buildLatestImage.sh 1.7.4

set -e

GO_VERSION=$1
SCRIPT=$(basename "$0")

if [ "$GO_VERSION" == "" ]; then
  echo Usage: "$SCRIPT" "<go version> [latest]"
  exit -1
fi

if ! [[ $GO_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo Version must be of the format \'A.B.C\' where \'A\', \'B\' and \'C\' are all positive integers.
    exit -1
fi

cd docker

VERSION_DIR=go-$GO_VERSION
DOCKERFILE="$VERSION_DIR"/Dockerfile

if [ ! -f "$DOCKERFILE" ]; then
    echo That version has no docker definition. Please add a Dockerfile to docker/"$VERSION_DIR" and try again.
    exit -1
fi

# Check that the Dockerfile is correctly configured for the version. Two things to check:
# a) For version A.B.C, ENV should be GO_VERSION ABC
if ! grep -Fq "GO_VERSION ${GO_VERSION//.}" "$DOCKERFILE"; then
    echo The ENV declaration in "$DOCKERFILE" is missing or points to the wrong version.
    echo Please update and try again.
    exit -1
fi
# b) The export ROOT_DIST line should target the correct go version
if ! grep -Fq "go${GO_VERSION}" "$DOCKERFILE"; then
    echo The export ROOT_DIST declaration in "$DOCKERFILE" is missing or points to the wrong version.
    echo Please update and try again.
    exit -1
fi

INITPWD=$PWD

cd base
docker build -t elasticlic/xgo-base .

cd ../"$VERSION_DIR"
docker build -t elasticlic/xgo-"$GO_VERSION" .
cd ..

if [ ! "$2" = "latest" ]; then
    cd "$INITPWD"
    exit 0
fi

# Check that the MED_LATEST Dockerfile exists
MED_LATEST=$(echo "$GO_VERSION" | cut -d '.' -f 1).$(echo "$GO_VERSION" | cut -d '.' -f 2).x
MED_LATEST_DIR=go-$MED_LATEST
if [ ! -f "$MED_LATEST_DIR"/Dockerfile ]; then
    echo docker/"$MED_LATEST_DIR" is missing or does not contain a Dockerfile. Please fix.
    exit -1
fi

# Check that the MED_LATEST Dockerfile points to the version we've specified.
cd "$MED_LATEST_DIR"
if ! grep -Fq "$GO_VERSION" Dockerfile; then
    echo The version in docker/"$MED_LATEST_DIR"/Dockerfile does not match the version you entered.
    echo Please update and try again.
    exit -1
fi

docker build -t elasticlic/xgo-"$MED_LATEST" .
cd ../go-latest

# Check that xgo-latest references MED_LATEST
if ! grep -Fq "$MED_LATEST" Dockerfile; then
    echo The version in docker/xgo-latest/Dockerfile is incorrect.
    echo It should reference image "$MED_LATEST_DIR".
    echo Please update and try again.
    exit -1
fi

docker build -t elasticlic/xgo-latest .

cd "$INITPWD"
