#!/bin/bash

pushd $GOPATH/src/github.com/TIBCOSoftware/mashling ;
go-test-html gotest_stdout_file gotest_stderr_file go-test-result.html
mkdir reports;
cd reports;
cp "$GOPATH/src/github.com/TIBCOSoftware/mashling/go-test-result.html" "$GOPATH/src/github.com/TIBCOSoftware/mashling/reports/go-test-result.html"
cd ..;
rm -rf Godeps
rm gotest_stdout_file gotest_stderr_file go-test-result.html
popd ;