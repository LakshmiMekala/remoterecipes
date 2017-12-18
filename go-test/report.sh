#!/bin/bash

name="${TRAVIS_REPO_SLUG}" ;
namefolder=${name:14} ;
echo "$namefolder";

    if [ -n "${TRAVIS_TAG}" ]; then
        destFolder="$namefolder-${TRAVIS_TAG}"
    elif [ -z "${TRAVIS_TAG}" ]; then
        destFolder="$namefolder-${TRAVIS_BUILD_NUMBER}"
    fi

    if [ ! -d "$destFolder" ]; then
        mkdir "$destFolder";
    fi
    echo "Creating folder - $destFolder /"
    cd "$destFolder";

pushd $GOPATH/src/github.com/TIBCOSoftware/mashling ;

mkdir -p "$destFolder";
cd "$destFolder";
cp "$GOPATH/src/github.com/TIBCOSoftware/mashling/go-test-result.html" "$GOPATH/src/github.com/TIBCOSoftware/mashling/$destFolder/go-test-result.html" ;
echo "files in directory";
ls;
popd;