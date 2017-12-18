#!/bin/bash

name="${TRAVIS_REPO_SLUG}" ;
namefolder=${name:14} ;

destFolder="$namefolder-${TRAVIS_TAG}"

pushd $GOPATH/src/github.com/TIBCOSoftware/mashling ;

mkdir -p "$destFolder";
cd "$destFolder";
cp "$GOPATH/src/github.com/TIBCOSoftware/mashling/go-test-result.html" "$GOPATH/src/github.com/TIBCOSoftware/mashling/$destFolder/go-test-result.html" ;
echo "files in directory";
ls;
popd;