#!/bin/bash

function sanity-test()
{
    cat "$GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/${remotereponame[$j]}/${recipeCreate[$x]}/${recipeCreate[$x]}.sh"
    if [[ -f "$GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/${remotereponame[$j]}/${recipeCreate[$x]}/${recipeCreate[$x]}.sh" ]];then        
        pushd "$GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/${remotereponame[$j]}/${recipeCreate[$x]}";
        ls ;
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
                sed -i "s/<\/table>/<tr><td>${provider[$j]}<\/td><td>${recipeCreate[$x]}<\/td><td>${value[i]}<\/td><td  class="success">PASS<\/td><\/tr><\/table>/" $GOPATH/$FILENAME
            else
                echo "${recipeCreate[$x]}":"Failed"
                r=$((r+1))
                sed -i "s/<\/table>/<tr><td>${provider[$j]}<\/td><td>${recipeCreate[$x]}<\/td><td>${value[i]}<\/td><td  class="error">FAIL<\/td><\/tr><\/table>/" $GOPATH/$FILENAME
            fi
            p=$((p+1));
            echo $p;
        done
        popd
        p=$((p+1))
    else
        echo "Sanity file does not exist"
        sed -i "s/<\/table>/<tr><td>${provider[$j]}<\/td><td>${recipeCreate[$x]}<\/td><td>NA<\/td><td>NA<\/td><\/tr><\/table>/" $GOPATH/$FILENAME
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
HTML="<!DOCTYPE html><html><head><style>table{font-family: arial, sans-serif;border-collapse: collapse;margin:auto;}td,th{border: 1px solid #dddddd;text-align: left;padding: 8px;}th{background: #003399;text-align:center; color:#fff;}body{padding-right: 15px;
      padding-left: 15px;margin-right: auto;margin-left: auto;}label{font-weight:bold;}.test-report h2{color : #003399;}.summary,.test-report{text-align:center;}.success{background-color:#79d279;}.error{background-color:#ff3300;}</style></head><body>
<section class="summary"><h2>Summary</h2><p>Number of test cases passed : <label></label></p><p>Number of test cases failed : <label><p>Total test cases : <label></label></p></section><section class="test-report"><h2>Test Report</h2><table><tr><th>Provider</th><th>Recipe</th><th>Testcase</th><th>Status</th></tr>
</table>
</html>"
echo $HTML >> $FILENAME

name="${TRAVIS_REPO_SLUG}" ;
namefolder=${name:14} ;
if [ -n "${TRAVIS_TAG}" ]; then
    destFolder="$namefolder-${TRAVIS_TAG}"
elif [ -z "${TRAVIS_TAG}" ]; then
    destFolder="$namefolder-${TRAVIS_BUILD_NUMBER}"
fi

array_length=$(cat $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/recipe_registry.json | jq '.recipe_repos | length') ;
echo "Found $array_length recipe providers." ;
count=();
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
            remotereponame[$j]="$provider_url";
            echo "${remotereponame[$j]}";
        fi
        recipeCreated=$(cat $GOPATH/recipes-[$j]);
        recipesToBeTested;
        echo "iiiiiiiiiiiiiiiiiiiii"
        echo gateway array is "${recipeCreate[@]}";
        echo "jjjjjjjjjjjjjjjjjjjjjjjj";
        for (( x=0; x<"${#recipeCreate[@]}"; x++ ))
        do
            sanity-test;
        done   
    done

sed -i s/"passed : <label>"/"passed : <label>$q"/g $GOPATH/$FILENAME
sed -i s/"failed : <label>"/"failed : <label>$r"/g $GOPATH/$FILENAME
sed -i s/"Total test cases : <label>"/"Total test cases : <label>$p"/g $GOPATH/$FILENAME

#cp $GOPATH/$FILENAME $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/latest
cp $GOPATH/$FILENAME $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/$destFolder     