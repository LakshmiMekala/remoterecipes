#!/bin/bash

name="${TRAVIS_REPO_SLUG}" ;
namefolder=${name:14} ;

###Fetching argument values passed along with build file

for ARGUMENT in "$@"
do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)

    case "$KEY" in
            OPTIMIZE)
			OPTIMIZE=${VALUE} ;;
            *)
    esac
done

echo "OPTIMIZE = $OPTIMIZE"

####Adding AWS credentials to download latest recipes folder from S3

mkdir ${HOME}/.aws
cat > ${HOME}/.aws/credentials <<EOL
[default]
aws_access_key_id = ${SITE_KEY}
aws_secret_access_key = ${SITE_KEY_SECRET}
EOL

    pushd $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes
    #Fetching short commit id
    commitId=$(git diff --name-only HEAD~1) ;
    #Copying files changed in commit to info.log file
    echo $(git log -m -1 --name-status $commitId) >> $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/info.log ;
    recipeName=$(cat $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/info.log) ;
    echo $recipeName
    popd ;

###Deleting receipes removed from recipe_registry.json
function RecipesToBeDeleted()
{
    recipeDeleteLatest=()
                for z in "${recipesInLatest[@]}"; do
                    skip=
                    for l in "${Gateway[@]}"; do
                        [[ $z == $l ]] && { skip=1; break; }
                    done
                    [[ -n $skip ]] || recipeDeleteLatest+=("$z")
                done
                #declare -p recipeDeleteLatest
                for (( p=0; p<${#recipeDeleteLatest[@]}; p++ ))
                do
                if [[ -d $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder"/"${recipeDeleteLatest[$p]}" ]]; then
                    rm -rf $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder"/"${recipeDeleteLatest[$p]}" ;
                    echo deleting "${recipeDeleteLatest[$p]}"
                fi
                done
		#RecipesNewlyAdded ;
}

function RecipesNewlyAdded()
{
    recipeAdded=()
    echo Gateway arrays are "${recipeCreate[@]}";
    #echo recipes-in latest are "${recipesInLatest[@]}"
            for z in "${Gateway[@]}"; do
                skip=
                for l in "${recipesInLatest[@]}"; do
                    [[ $z == $l ]] && { skip=1; break; }
                done
                [[ -n $skip ]] || recipeAdded+=("$z")
            done
        echo #####################################################
		echo newly added recipe-in recipe_registry is "${recipeAdded[@]}" ;
        echo recipeCreate="${recipeCreate[@]}";
        echo recipeTOCreate="${recipeTOCreate[@]}"
        echo #####################################################
        ###"${recipeTOCreate[@]}"
        recipeTOCreate=$(echo "${recipeAdded[@]}" "${recipeCreate[@]}" "${recipeTOCreate[@]}"  | tr ' ' '\n' | sort -u | tr '\n' ' ') ;        
        IFS=\  read -a recipeCreate <<<"$recipeTOCreate" ;
        set | grep ^IFS= ;
        #separating array by line
        IFS=$' \t\n' ;
        #fetching Gateway
        set | grep ^recipeCreate=\\\|^recipeTOCreate= ;
            for (( x=0; x<${#recipeCreate[@]}; x++ ))
            do
                echo "${recipeCreate[$x]}" ;
            done
            echo newly added recipe is "${recipeCreate[@]}" ;           
}

##Function to copy recipes from S3 to Local for optimized build
function S3copytoLocal()
{
    aws s3 cp s3://test-bucket4569/master-builds/latest  $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder" --recursive
    pushd $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/$destFolder
    rm -rf recipeinfo.json recipe_registry.json
    recipesInLatest=(*)
    for ((i=0; i<${#recipesInLatest[@]}; i++));
    do
        echo "${recipesInLatest[$i]}";
        recipesInLatest[$i]=${recipesInLatest[$i]}
    done
    echo Recipes available-in latest folder : "${recipesInLatest[@]}" ;
    popd
}
###########################################################################

function create_dest_directory ()
{
    cd master-builds ;
    if [ -n "${TRAVIS_TAG}" ]; then
        destFolder="$namefolder-${TRAVIS_TAG}"
    elif [ -z "${TRAVIS_TAG}" ]; then
        destFolder="$namefolder-${TRAVIS_BUILD_NUMBER}"
    fi

    if [ ! -d "$destFolder" ]; then
        mkdir "$destFolder";
    fi
    echo "Creating folder - $destFolder /"
    cd "$destFolder";
}

function publish_gateway()
{
    publish=$(echo $publish | tr -d ',') ;
    publish=$(echo $publish | tr -d '"') ;
    echo $publish ;
    # removing string duplicates
    publish=$(echo "$publish" | xargs -n1 | sort -u | xargs) ;
    IFS=\  read -a Gateway <<<"$publish" ;
    set | grep ^IFS= ;
    #separating arrays ny line
    IFS=$' \t\n' ;
    #fetching Gateway
    set | grep ^Gateway=\\\|^publish= ;
}

function recipe_registry()
{
    array_length=$(cat $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/recipe_registry.json | jq '.recipe_repos | length') ;
    echo "Found $array_length recipe providers." ;
        for (( j = 0; j < $array_length; j++ ))
            do
                echo "value of j=$j" ;
                #eval provider and publish
                eval xpath_publish='.recipe_repos[$j].publish' ;
                publish_length=$(cat $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/recipe_registry.json | jq $xpath_publish' | length') ;
                echo "Found $publish_length recipes." ;
                if [[ "${GOOSystem[$k]}" = linux ]]; then
                    if [[ $OPTIMIZE = TRUE ]] ; then
                        for (( x=0; x<$publish_length; x++ ))
                        do
                            eval xpath_recipe='.recipe_repos[$j].publish[$x].recipe' ;
                            Gateway[$x]=$(cat $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/recipe_registry.json | jq $xpath_recipe) ;
                            Gateway[$x]=$(echo ${Gateway[$x]} | tr -d '"') ;
                        done
                        echo "${Gateway[@]}" ;
                        RecipesToBeDeleted ;
                    fi
                fi
                recipeCreate=()
                y=0;
                for (( x=0; x<$publish_length; x++ ))
                do
                    eval xpath_recipe='.recipe_repos[$j].publish[$x].recipe' ;
                    Gateway[$x]=$(cat $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/recipe_registry.json | jq $xpath_recipe) ;
                    Gateway[$x]=$(echo ${Gateway[$x]} | tr -d '"') ;
                    #recipeCreate[$y]=${Gateway[$x]} ;
                    recipeInfo ;
                    if [[ $OPTIMIZE = TRUE ]] ; then
                        if [[ $recipeName =~ ${Gateway[$x]}/${Gateway[$x]}.json ]] || [[ $recipeName =~ ${Gateway[$x]}/manifest ]];then
                            echo "${Gateway[$x]} found in current commit" ;
                            recipeCreate[$y]=${Gateway[$x]} ;
                            if [[ -d $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder"/"${recipeCreate[$y]}" ]] ; then
                                rm -rf $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder"/"${recipeCreate[$y]}";
                            fi
                            echo #################################
                            y=$y+1;
                            echo #################################
                        else
                            echo "${Gateway[$x]} not found in current commit ";
                        fi
                        #recipeInfo ;
                    else
                        echo "recipe needs to be created from full build"
                        recipeCreate[$y]=${Gateway[$x]} ;
                        y=$y+1;
                    fi                    
                done
                RecipesNewlyAdded ;
            done
            RecipesToBeCreated ;
}

function RecipesToBeCreated()
{
    echo gateway array is "${recipeCreate[@]}";
    echo length of gateway array is "${#recipeCreate[@]}";
    for (( y=0; y < "${#recipeCreate[@]}"; y++ ));
    do
    if [[ -f $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/recipes/${recipeCreate[$y]}/${recipeCreate[$y]}.json ]] || [[ -f $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/recipes/${recipeCreate[$y]}/manifest ]] ; then
        displayImage=$(cat $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/recipes/"${recipeCreate[$y]}"/"${recipeCreate[$y]}".json | jq '.gateway.display_image') ;
        displayImage=$(echo $displayImage | tr -d '"') ;
        echo "creating ${recipeCreate[$y]} gateway" ;
        cp -r $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/recipes/${recipeCreate[$y]}/manifest $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder"
        mashling create -f $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/recipes/"${recipeCreate[$y]}"/"${recipeCreate[$y]}".json "${recipeCreate[$y]}";
        rm -rf $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder"/manifest; 
        binarycheck ;
    fi
    done
}

function binarycheck()
{
    if [[ "${OS_NAME[$k]}" == "windows" ]] ; then
        fname="${recipeCreate[$y]}-${GOOSystem[$k]}-$GOARCH.exe" ;
        fnamelc="${fname,,}" ;
        if [[ -f $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder"/"${recipeCreate[$y]}"/bin/$fnamelc ]];then
            package_gateway ;
        else
            echo "${recipeCreate[$y]} binary not found"
            exit 1;
        fi
    else
        fname="${recipeCreate[$y]}-${GOOSystem[$k]}-$GOARCH" ;
        fnamelc="${fname,,}" ;
        if [[ -f $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder"/"${recipeCreate[$y]}"/bin/$fnamelc ]] ;then
            package_gateway ;
        else
            echo "${recipeCreate[$y]} binary not found"
            exit 1;
        fi
    fi
}

function package_gateway()
{
    # If directory exists proceed to next steps
    if [ -d "${recipeCreate[$y]}" ]; then
            cd "${recipeCreate[$y]}"  ;
            mv bin "${recipeCreate[$y]}-${OS_NAME[$k]}" ;
            mv  mashling.json "${recipeCreate[$y]}.mashling.json" ;
            cp -r "${recipeCreate[$y]}.mashling.json" "${recipeCreate[$y]}-${OS_NAME[$k]}" ;
            echo $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/recipes/"${recipeCreate[$y]}"/"$displayImage"
            if [[ -f $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/recipes/"${recipeCreate[$y]}"/"$displayImage" ]]; then
            cp -r $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/recipes/"${recipeCreate[$y]}"/$displayImage $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder"/"${recipeCreate[$y]}"
            fi
            echo "$displayImage";
            rm -r src vendor pkg ;
                # Changing directory to  binary containing folder
                cd "${recipeCreate[$y]}-${OS_NAME[$k]}";
                    if [ "${OS_NAME[$k]}" == windows ] ; then
                        fname="${recipeCreate[$y]}-${GOOSystem[$k]}-$GOARCH.exe" ;
                        echo "$fname" ;
                        fnamelc="${fname,,}" ;
                        echo "$fnamelc" ;
                        destfname="${recipeCreate[$y]}.exe" ;
                        echo "$destfname" ;
                        destfnamelc="${destfname,,}" ;
                        echo "$destfnamelc" ;
                        mv $fnamelc $destfnamelc ;
                    else
                        fname="${recipeCreate[$y]}-${GOOSystem[$k]}-$GOARCH" ;
                        echo "$fname" ;
                        fnamelc="${fname,,}" ;
                        echo "$fnamelc" ;
                        destfname="${recipeCreate[$y]}" ;
                        echo "$destfname" ;
                        destfnamelc="${destfname,,}" ;
                        echo "$destfnamelc" ;
                        mv $fnamelc $destfnamelc ;
                    fi
                    zip -r "${recipeCreate[$y]}-${OS_NAME[$k]}" *;
                    cp "${recipeCreate[$y]}-${OS_NAME[$k]}.zip" ../../"${recipeCreate[$y]}" ;
                cd .. ;
            rm -r "${recipeCreate[$y]}-${OS_NAME[$k]}" ;
        cd ..;
        # Copying gateway into latest folder
        # cp -r "${recipeCreate[$y]}" ../latest ;
        # Exit if directory not found
    else
        echo "failed to create ${recipeCreate[$y]} gateway"
        echo "directory ${recipeCreate[$y]}" not found
        exit 1
    fi
}

function recipeInfo()
{
    if [[ "${GOOSystem[$k]}" == windows ]]; then
    idvalue="${Gateway[$x]}" ;
    eval xpath_featured='.recipe_repos[$j].publish[$x].featured' ;
    featuredvalue=$(cat $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/recipe_registry.json | jq $xpath_featured) ;
    sourceURL=https://github.com/TIBCOSoftware/mashling-recipes/tree/master/recipes/${Gateway[$x]} ;
    echo "$sourceURL";
    JSONURL=/${Gateway[$x]}/${Gateway[$x]}.mashling.json ;
    IMAGEURL=/${Gateway[$x]}/$displayImage ;
    MACURL=/${Gateway[$x]}/${Gateway[$x]}-osx.zip ;
    LINUXURL=/${Gateway[$x]}/${Gateway[$x]}-linux.zip ;
    WINDOWSURL=/${Gateway[$x]}/${Gateway[$x]}-windows.zip ;

    jo -p id=$idvalue featured=$featuredvalue repository_url=$sourceURL json_url=$JSONURL image_url=$IMAGEURL binaries=[$(jo  platform=mac url=$MACURL),$(jo  platform=linux url=$LINUXURL),$(jo  platform=windows url=$WINDOWSURL)] >> $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/latest/temp/recipe1-[$x].json ;
    echo "alert json 3" ;
    jq -s '.[0] * .[1]' $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/recipes/"${Gateway[$x]}"/"${Gateway[$x]}".json $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/latest/temp/recipe1-[$x].json >> $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/latest/temp/recipe-[$x].json ;
    fi
}

    GOOSystem=({"linux","darwin","windows"});
    OS_NAME=({"linux","osx","windows"});
    # GOARCH=({"amd64","amd64","amd64"});
        # get length of an array
        Len="${#GOOSystem[@]}"
            for (( k=0; k < "${Len}"; k++ ));
            do
                export GOOS="${GOOSystem[$k]}" ;
                echo $GOOS ;
                export GOARCH=amd64 ;
                echo $GOARCH ;
                    if [[ ! -d $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/tmp ]]; then
                    mkdir -p $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/tmp
                    fi
                    cd $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes
                    create_dest_directory ;
                    if [[ "${GOOSystem[$k]}" == linux ]]; then
                        if [[ $OPTIMIZE == TRUE ]] ; then
                            S3copytoLocal;
                        fi
                    fi
                    recipe_registry ;
                    echo "#########Alert 15#####";
                    pushd $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder";
                    ls ;
                    cp -r $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder"/* $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/tmp ;
                    echo "#########Alert 16#####";
                    popd
                    rm -rf $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder"
                    echo "#########Alert 17#####";
            done

        mv $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/tmp $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder";
        cd $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes ;

        cp $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/recipe_registry.json $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder";
        cp $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/recipe_registry.json $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/latest;
        cp -r $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder"/* $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/latest;

        pushd $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/latest/temp ;
        echo "alert json 4" ;
        jq -s '.' recipe-*.json > recipeinfo.json
        echo "alert json 5" ;
        cp recipeinfo.json $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/latest
        cp recipeinfo.json $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder";
        echo "alert json 6" ;
        rm -rf $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/latest/temp ;
        popd ;


        # cd $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds
        # git add .
        # git commit -m "uploading builds" ;
        # # git push ;
