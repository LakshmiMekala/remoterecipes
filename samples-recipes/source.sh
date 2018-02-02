#!/bin/bash

#Create recipes and run sanity tests

    chmod ugo+x ./local.sh ./local-sanity.sh
    ./local-recipes.sh
    ./local-sanity.sh