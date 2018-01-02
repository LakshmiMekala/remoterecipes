#!/bin/bash

REPONAME="${TRAVIS_REPO_SLUG}" ;
REPOFOLDER=${REPONAME:14} ;

mkdir ${HOME}/.aws
cat > ${HOME}/.aws/credentials <<EOL
[default]
aws_access_key_id = ${SITE_KEY}
aws_secret_access_key = ${SITE_KEY_SECRET}
EOL

if [ "$TRAVIS_PULL_REQUEST" = "false" ] ; then    
    echo "cleaning S3 folder"
    aws s3 rm s3://$AWS_BUCKET/LakshmiMekala/remoterecipes/go-tests/latest --recursive
fi

function create_dest_directory ()
{
    cd reports ;
    if [ -n "${TRAVIS_TAG}" ]; then
        DESTFOLDER="$REPOFOLDER-${TRAVIS_TAG}"
    elif [ -z "${TRAVIS_TAG}" ]; then
        DESTFOLDER="$REPOFOLDER-${TRAVIS_BUILD_NUMBER}"
    fi

    if [ ! -d "$DESTFOLDER" ]; then
        mkdir "$DESTFOLDER" "latest";
    fi
    echo "Creating folder - $DESTFOLDER /"
    cd "$DESTFOLDER";
}

pushd $GOPATH/src/github.com/TIBCOSoftware/mashling ;
go-test-html gotest_stdout_file gotest_stderr_file go-test-result.html;
mkdir -p reports;
create_dest_directory ;
cp "$GOPATH/src/github.com/TIBCOSoftware/mashling/go-test-result.html" "$GOPATH/src/github.com/TIBCOSoftware/mashling/reports/$DESTFOLDER"
cp "$GOPATH/src/github.com/TIBCOSoftware/mashling/go-test-result.html" "$GOPATH/src/github.com/TIBCOSoftware/mashling/reports/latest"
aws s3 cp "$GOPATH/src/github.com/TIBCOSoftware/mashling/reports" "s3://$AWS_BUCKET/LakshmiMekala/remoterecipes/go-tests" --recursive
popd ;





