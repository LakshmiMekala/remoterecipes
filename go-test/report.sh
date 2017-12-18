#!/bin/bash

name="${TRAVIS_REPO_SLUG}" ;
namefolder=${name:14} ;
echo "$namefolder";

pushd $GOPATH/src/github.com/TIBCOSoftware/mashling ;
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

cp "$GOPATH/src/github.com/TIBCOSoftware/mashling/go-test-result.html" "$GOPATH/src/github.com/TIBCOSoftware/mashling/$destFolder/go-test-result.html"
rm -rf Godeps
rm gotest_stdout_file gotest_stderr_file go-test-result.html
popd ;

