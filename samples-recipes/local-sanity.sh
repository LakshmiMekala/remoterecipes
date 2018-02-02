#!/bin/bash

function sanity-test()
{
    if [[ -f "$GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/${remotereponame[$j]}/${recipeCreate[$x]}/${recipeCreate[$x]}.sh" ]];then        
        pushd "$GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/${remotereponame[$j]}/${recipeCreate[$x]}";
        source ./${recipeCreate[$x]}.sh
        value=($(get_test_cases))
        sleep 1
        echo ${#value[@]}
        echo test=${value[0]}
        
        for ((i=0;i < ${#value[@]};i++))
        do
            #source ./${recipeCreate[$x]}.sh
            #${value[i]}
            value1=$(${value[i]})            
            echo value1=$value1
            sleep 10
            if [[ $value1 == *"PASS"* ]];  then
                echo "${recipeCreate[$x]}":"Passed"
                echo ${value[i]}
                q=$((q+1))
                sed -i "s/<\/tr> <\/table>/<tr><td>${provider[$j]}<\/td><td>${recipeCreate[$x]}<\/td><td>${value[i]}<\/td><td  class="success">PASS<\/td><\/tr><\/tr> <\/table>/g" $GOPATH/$FILENAME
            else
                echo "${recipeCreate[$x]}":"Failed"
                r=$((r+1))
                sed -i "s/<\/tr> <\/table>/<tr><td>${provider[$j]}<\/td><td>${recipeCreate[$x]}<\/td><td>${value[i]}<\/td><td  class="error">FAIL<\/td><\/tr><\/tr> <\/table>/g" $GOPATH/$FILENAME
            fi
            p=$((p+1));
        done
        popd
    else
        echo "Sanity file does not exist"
        sed -i "s/<\/tr> <\/table>/<tr><td>${provider[$j]}<\/td><td>${recipeCreate[$x]}<\/td><td>NA<\/td><td>NA<\/td><\/tr><\/tr> <\/table>/g" $GOPATH/$FILENAME
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
FILENAME="SanityReport.html"
HTML="<!DOCTYPE html>
<html><head><style>table {font-family: arial, sans-serif;border-collapse: collapse;margin: auto;}td,th {border: 1px solid #dddddd;text-align: left;padding: 8px;}th {background: #003399;text-align: center;color: #fff;}body {padding-right: 15px;padding-left: 15px;margin-right: auto;margin-left: auto;}label {font-weight: bold;}.test-report h1 {color: #003399;}.summary,.test-report {text-align: center;}.success {background-color: #79d279;}.error {background-color: #ff3300;}.summary-tbl {font-weight: bold;}.summary-tbl td {border: none;}</style></head><body>    <section class=test-report><h1>Recipes Sanity Report</h1></section><section class=summary><h2>Summary</h2><table class="summary-tbl"><tr><td>Number of test cases passed </td> <td> </td></tr><tr><td>Number of test cases failed </td> <td> </td></tr><td>Total test cases</td><td></td></tr></tr></table></section><section class=test-report><h2>Detailed report</h2><table><tr><th>Provider</th><th>Recipe</th><th> Testcase </th><th>Status</th><tr></tr> </table></html>"

echo $HTML >> $FILENAME

common::detect() {
    local BUILD_CICD="LOCAL" # default CICD
    if [[ ( -n "${TRAVIS}" ) && ( "${TRAVIS}" == "true" ) ]]; then
      BUILD_CICD="TRAVIS"
    # elif [ -n "${TEAMCITY_VERSION}" ]; then
      # BUILD_CICD="TEAMCITY"
    fi
    echo "${BUILD_CICD}"
}

common::envvars() {
  local BUILD_CICD=$(common::detect)
  case "${BUILD_CICD}" in
      LOCAL)
        cd $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes        
        cd master-builds;               
        destFolder="recipes";
        if [ ! -d "$destFolder" ]; then
        mkdir "$destFolder";
        fi
        echo "Creating folder - $destFolder /"
        cd "$destFolder";
      ;;
      TRAVIS)
            name="${TRAVIS_REPO_SLUG}" ;
            namefolder=${name:14} ;
            if [ -n "${TRAVIS_TAG}" ]; then
                destFolder="$namefolder-${TRAVIS_TAG}"
            elif [ -z "${TRAVIS_TAG}" ]; then
                destFolder="$namefolder-${TRAVIS_BUILD_NUMBER}"
            fi
      ;;
 esac     
}


common::envvars;
array_length=$(cat $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/recipe_registry.json | jq '.recipe_repos | length') ;
echo "Found $array_length recipe providers." ;
    p=0;
    q=0;
    r=0;
for (( j = 0; j < $array_length; j++ ))
    do            
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
            if [ -n "$provider_url" ]; then
                remotereponame[$j]=recipes
                echo "==========${remotereponame[$j]}============"
            fi
        fi
        recipeCreated=$(cat $GOPATH/recipes-[$j]);
        recipesToBeTested;
        echo gateway array is "${recipeCreate[@]}";
        for (( x=0; x<"${#recipeCreate[@]}"; x++ ))
        do
            sanity-test;
        done   
    done

sed -i s/"passed <\/td> <td>"/"passed <\/td> <td>$q"/g $GOPATH/$FILENAME
sed -i s/"failed <\/td> <td>"/"failed <\/td> <td>$r"/g $GOPATH/$FILENAME
sed -i s/"cases<\/td><td>"/"cases<\/td><td>$p"/g $GOPATH/$FILENAME

#cp $GOPATH/$FILENAME $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/latest
cp $GOPATH/$FILENAME $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/$destFolder     