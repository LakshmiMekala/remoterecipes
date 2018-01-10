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
cp $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/latest/ $GOPATH/sanity;

array_length=$(cat $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/recipe_registry.json | jq '.recipe_repos | length') ;
echo "Found $array_length recipe providers." ;
    for (( j = 0; j < $array_length; j++ ))
    do
        recipeCreated=$(cat $GOPATH/recipes-[$j]);
        recipesToBeTested;
        echo "iiiiiiiiiiiiiiiiiiiii"
        echo gateway array is "${recipeCreate[@]}";
        echo "jjjjjjjjjjjjjjjjjjjjjjjj";        
        eval xpath_url='.recipe_repos[$j].url' ;
        url=$(cat $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/recipe_registry.json | jq $xpath_url) ;
        provider_url=$(echo $url | tr -d '"') ;
        eval xpath_provider='.recipe_repos[$j].provider' ;
        provider=$(cat $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/recipe_registry.json | jq $xpath_provider) ;
        provider[$j]=$(echo $provider | tr -d '"') ;
        provider[$j]=$(echo "${provider[$j]}" | sed -e 's/ /-/g') ;
        echo provider is "${provider[$j]}";
        regex='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'              
        #checking if url contains http or not
        if [[ "$provider_url" =~ $regex ]] ; then
            path_url=$provider_url ;
            if [[ ! $provider_url == *[.git] ]] ; then
                path_url=$path_url.git ;    
            fi
            remotereponame[$j]=$(echo $path_url | rev | cut -d '/' -f 1 | rev);
            remotereponame[$j]=$(echo ${remotereponame[$j]} | cut -f1 -d '.');
            echo "${remotereponame[$j]}";
        else
            remotereponame[$j]="$provider_url";
        fi
    done