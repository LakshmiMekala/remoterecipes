#!/bin/bash

#Create recipes and run sanity tests

    chmod ugo+x ./local.sh ./local-sanity.sh
    ./local.sh || travis_terminate 1
    ./local-sanity.sh