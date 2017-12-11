#!/bin/bash

# mkdir ${HOME}/.aws

# cat > ${HOME}/.aws/credentials <<EOL
# [default]
# aws_access_key_id = ${SITE_KEY}
# aws_secret_access_key = ${SITE_KEY_SECRET}
# EOL

echo "test123"
    if [ "$TRAVIS_PULL_REQUEST" = "false" ] ; then    
        echo "cleaning S3 folder"
        aws s3 rm s3://test-bucket4569/master-builds/latest --recursive
    fi

