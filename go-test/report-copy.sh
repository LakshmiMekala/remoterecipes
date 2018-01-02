#!/bin/bash

name="${TRAVIS_REPO_SLUG}" ;
namefolder=${name:14} ;

mkdir ${HOME}/.aws
cat > ${HOME}/.aws/credentials <<EOL
[default]
aws_access_key_id = ${SITE_KEY}
aws_secret_access_key = ${SITE_KEY_SECRET}
EOL

function create_dest_directory ()
{
    cd reports ;
    if [ -n "${TRAVIS_TAG}" ]; then
        destFolder="$namefolder-${TRAVIS_TAG}"
    elif [ -z "${TRAVIS_TAG}" ]; then
        destFolder="$namefolder-${TRAVIS_BUILD_NUMBER}"
    fi

    if [ ! -d "$destFolder" ]; then
        mkdir "$destFolder" "latest";
    fi
    echo "Creating folder - $destFolder /"
    cd "$destFolder";
}

pushd $GOPATH/src/github.com/TIBCOSoftware/mashling ;
go-test-html gotest_stdout_file gotest_stderr_file go-test-result.html

mkdir -p reports;
create_dest_directory ;

ls;

cp "$GOPATH/src/github.com/TIBCOSoftware/mashling/go-test-result.html" "$GOPATH/src/github.com/TIBCOSoftware/mashling/reports/$destFolder"
cp "$GOPATH/src/github.com/TIBCOSoftware/mashling/go-test-result.html" "$GOPATH/src/github.com/TIBCOSoftware/mashling/reports/latest"

aws s3 cp "$GOPATH/src/github.com/TIBCOSoftware/mashling/reports" "s3://$AWS_BUCKET/LakshmiMekala/remoterecipes/go-tests" --recursive

popd ;





