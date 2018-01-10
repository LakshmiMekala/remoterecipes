#!/bin/bash

function sanity-test()
{
    if [[ -f "$GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/${remotereponame[$j]}/${Gateway[$x]}/${Gateway[$x]}.sh" ]];then
        cd ${remotereponame[$j]}/${Gateway[$x]};
        chmod 777 "${Gateway[$x]}-linux".zip ;
		unzip -o "${Gateway[$x]}-linux".zip ;
        cd "${Gateway[$x]}";
        ./"${Gateway[$x]}" & ./"$GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/recipes/${Gateway[$x]}/${Gateway[$x]}.sh";
        cd ../..
    else
        STATUS= "NA"
    fi
}

function recipesToBeTested()
{
    IFS=\  read -a recipeCreate <<<"$recipeCreated" ;
    set | grep ^IFS= ;
    # separating arrays ny line
    IFS=$' \t\n' ;
    # fetching Gateway
    set | grep ^recipeCreate=\\\|^recipeCreated= ;  
}


cd $GOPATH
mkdir -p sanity;
cd sanity;
cp $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/$destFolder/$provider_url $GOPATH/sanity;

array_length=$(cat $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/recipe_registry.json | jq '.recipe_repos | length') ;
echo "Found $array_length recipe providers." ;
    for (( j = 0; j < $array_length; j++ ))
    do
    recipeCreated=$(cat $GOPATH/recipes-[$j]);
    recipesToBeTested;
    echo "iiiiiiiiiiiiiiiiiiiii"
    echo gateway array is "${recipeCreate[@]}";
    echo "jjjjjjjjjjjjjjjjjjjjjjjj"
    done





# array_length=$(cat $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/recipe_registry.json | jq '.recipe_repos | length') ;
# echo "Found $array_length recipe providers." ;
#     for (( j = 0; j < $array_length; j++ ))
#     do
#         unset Gateway ;
#         eval xpath_publish='.recipe_repos[$j].publish' ;
#         publish_length=$(cat $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/recipe_registry.json | jq $xpath_publish' | length') ;
#         echo "Found $publish_length recipes." ;
#         eval xpath_url='.recipe_repos[$j].url' ;
#         url=$(cat $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/recipe_registry.json | jq $xpath_url) ;
#         provider_url=$(echo $url | tr -d '"') ;
#         for (( x=0; x<$publish_length; x++ ))
#         do
#             eval xpath_recipe='.recipe_repos[$j].publish[$x].recipe' ;
#             Gateway[$x]=$(cat $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/recipe_registry.json | jq $xpath_recipe) ;
#             Gateway[$x]=$(echo ${Gateway[$x]} | tr -d '"') ;
#         done
#         echo "${Gateway[@]}" ;
#         # if [[ $provider_url == recipes ]]; then
#         #     sanity-test ;
#         # fi
#     done
    


