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

###Fetching recipes from latest folder
function recipesFromLatest()
{
    pushd $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/$destFolder
    rm -rf recipeinfo.json recipe_registry.json
    recipesInLatest=("${provider[$j]}"/*)
    for ((i=0; i<${#recipesInLatest[@]}; i++));
    do
        recipesInLatest[$i]=$(echo ${recipesInLatest[$i]} | rev | cut -d '/' -f 1 | rev);
        recipesInLatest[$i]=$(echo ${recipesInLatest[$i]} | cut -f1 -d '.');
        echo "${recipesInLatest[$i]}";
        recipesInLatest[$i]=${recipesInLatest[$i]}
    done    
    echo Recipes available-in latest folder : "${recipesInLatest[@]}" ;
    popd
}



###Deleting receipes removed from recipe_registry.json
function RecipesToBeDeleted()
{
    recipesFromLatest ;
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
                if [[ -d $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder"/"${provider[$j]}"/"${recipeDeleteLatest[$p]}" ]]; then
                    rm -rf $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder"/"${provider[$j]}"/"${recipeDeleteLatest[$p]}" ;
                    echo deleting "${recipeDeleteLatest[$p]}";
                fi
                done
		#RecipesNewlyAdded ;
}

function RecipesNewlyAdded()
{
    #recipesFromLatest ;
    #eval recipeAdded=recipe[$j]Added
    recipeAdded=()
    echo Gateway arrays are "${recipeCreate[@]}";
    echo ======registry is "${Gateway[@]}"======;
    echo ======latest is "${recipesInLatest[@]}"=======;
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
        echo "recipeCreate=${recipeCreate[@]}";
        echo "recipeTOCreate=${recipeTOCreate[@]}";
        echo #####################################################
        ###"${recipeTOCreate[@]}"
        recipeTOCreate=$(echo "${recipeAdded[@]}" "${recipeCreate[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ') ;        
        IFS=\  read -a recipeCreate <<<"$recipeTOCreate" ;
        set | grep ^IFS= ;
        #separating array by line
        IFS=$' \t\n' ;
        #fetching Gateway
        set | grep ^recipeCreate=\\\|^recipeTOCreate= ;
            for (( x=0; x<${#recipeCreate[@]}; x++ ))
            do
                echo "${recipeCreate[$x]}" ;
                echo value of j is $j and value of x is $x;
                #remotereponame[$j_$x]="${recipeCreate[$x]}";
                echo ++++++++++${remotereponame[$j_$x]}++++++++++++++
            done
            echo FInal list of recipes to be built "${recipeCreate[@]}" ;
            unset recipeAdded;
            #echo after reseting recipeadded is "${recipeAdded[@]}" ;
            unset recipeTOCreate;
            #echo after reseting recipetocreate is "${recipeTOCreate[@]}" ;
            #RecipesToBeCreated ;
}

##Function to copy recipes from S3 to Local for optimized build
function S3copytoLocal()
{
    aws s3 cp s3://test-bucket4569/master-builds/latest  $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder" --recursive    
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
                unset Gateway ;
                echo *******${Gateway[@]}***************
                echo "value of j=$j" ;
                #eval provider and publish
                eval xpath_publish='.recipe_repos[$j].publish' ;
                publish_length=$(cat $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/recipe_registry.json | jq $xpath_publish' | length') ;
                echo "Found $publish_length recipes." ;
                eval xpath_url='.recipe_repos[$j].url' ;
                url=$(cat $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/recipe_registry.json | jq $xpath_url) ;
                provider_url=$(echo $url | tr -d '"') ;
                eval xpath_provider='.recipe_repos[$j].provider' ;
                provider=$(cat $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/recipe_registry.json | jq $xpath_provider) ;
                provider[$j]=$(echo $provider | tr -d '"') ;
                echo provider is "${provider[$j]}";
                #remote_recipes;  
                if [[ "$GOOS" == linux ]]; then
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
                        pushd $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes ;
                        git clone $path_url "${remotereponame[$j]}" ;
                        popd ;
                    else
                        remotereponame[$j]="$provider_url";
                    fi
                    if [[ $OPTIMIZE = TRUE ]] ; then
                        for (( x=0; x<$publish_length; x++ ))
                        do
                            eval xpath_recipe='.recipe_repos[$j].publish[$x].recipe' ;
                            Gateway[$x]=$(cat $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/recipe_registry.json | jq $xpath_recipe) ;
                            Gateway[$x]=$(echo ${Gateway[$x]} | tr -d '"') ;
                            echo %%%%%%%%%%"${Gateway[$x]}"%%%%%%%%%%%%%
                        done
                        echo "${Gateway[@]}" ;
                        RecipesToBeDeleted ;
                    fi
                fi
                recipeCreate=()
                recipearray=()
                y=0;
                echo "$publish_length" ;
                for (( x=0; x<$publish_length; x++ ))
                do
                    eval xpath_recipe='.recipe_repos[$j].publish[$x].recipe' ;
                    Gateway[$x]=$(cat $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/recipe_registry.json | jq $xpath_recipe) ;
                    Gateway[$x]=$(echo ${Gateway[$x]} | tr -d '"') ;
                    echo "----------${Gateway[$x]}----------------"
                    #recipeCreate[$y]=${Gateway[$x]} ;
                    recipeInfo ;
                    if [[ $OPTIMIZE = TRUE ]] ; then
                        if [[ $recipeName =~ ${Gateway[$x]}/${Gateway[$x]}.json ]] || [[ $recipeName =~ ${Gateway[$x]}/manifest ]];then
                            # echo "${Gateway[$x]} found in current commit" ;
                            recipeCreate[$y]=${Gateway[$x]} ;
                            if [[ -d $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder"/"${recipeCreate[$y]}" ]] ; then
                                rm -rf $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder"/"${recipeCreate[$y]}";
                            fi
                        else
                            echo "${Gateway[$x]} not found in current commit ";
                        fi
                        #recipeInfo ;
                    else
                        # echo "recipe needs to be created from full build"
                        recipeCreate[$y]=${Gateway[$x]} ;
                        y=$y+1;
                    fi                    
                done
                for (( x=0; x<$publish_length; x++ ))
                do
                    eval xpath_recipe='.recipe_repos[$j].publish[$x].recipe' ;
                    Gateway[$x]=$(cat $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/recipe_registry.json | jq $xpath_recipe) ;
                    Gateway[$x]=$(echo ${Gateway[$x]} | tr -d '"') ;
                    echo "----------${Gateway[$x]}----------------"
                done    
                echo "list of gws available in registry is ${Gateway[@]}";
                RecipesNewlyAdded ;
            done
            #RecipesToBeCreated ;
            #echo ${recipearray[@]};
}

function RecipesToBeCreated()
{
    echo gateway array is "${recipeCreate[@]}";
    echo length of gateway array is "${#recipeCreate[@]}";
    #for (( j = 0; j < $array_length; j++ ))
    #do
        mkdir -p "${provider[$j]}";
        echo "${provider[$j]}" ; 
        cd "${provider[$j]}" ;
        for (( y=0; y < "${#recipeCreate[@]}"; y++ ));    
        do
            #recipeCreate[$y]="${recipearray[$j_$y]}";
            echo "${recipeCreate[$y]}";
            if [[ -f $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/"${remotereponame[$j]}"/${recipeCreate[$y]}/${recipeCreate[$y]}.json ]] || [[ -f $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/"${remotereponame[$j]}"/${recipeCreate[$y]}/manifest ]] ; then
                displayImage=$(cat $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/"${remotereponame[$j]}"/"${recipeCreate[$y]}"/"${recipeCreate[$y]}".json | jq '.gateway.display_image') ;
                displayImage=$(echo $displayImage | tr -d '"') ;
                echo "creating ${recipeCreate[$y]} gateway" ;
                cp -r $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/"${remotereponame[$j]}"/${recipeCreate[$y]}/manifest $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder"/"${provider[$j]}"
                mashling create -f $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/"${remotereponame[$j]}"/"${recipeCreate[$y]}"/"${recipeCreate[$y]}".json "${recipeCreate[$y]}";
                rm -rf $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder"/"${provider[$j]}"/manifest;
                echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
            fi
            binarycheck ;
        done
        cd ..;
   # done
}

function binarycheck()
{
    if [[  "$GOOS" == "linux" ]] ; then        
        fname="${recipeCreate[$y]}-$GOOS-$GOARCH" ;
        fnamelc="${fname,,}" ;
        echo $fnamelc ;
        if [[ -f $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder"/"${provider[$j]}"/"${recipeCreate[$y]}"/bin/$fnamelc ]] ;then
            echo "binary file found" ;
            package_gateway;
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
            cd "${recipeCreate[$y]}";
            cat mashling.json >> "${recipeCreate[$y]}.mashling.json" ;
            GOOSystem=("linux" "darwin" "windows");
            OS_NAME=("linux" "osx" "windows");  
            echo "entered into ${recipeCreate[$y]} folder"
            Len="${#GOOSystem[@]}"
            for (( k=0; k < "${Len}"; k++ ));
            do
                export GOOS="${GOOSystem[$k]}" ;
                echo GOOS=$GOOS ;
                export GOARCH=amd64 ;
                echo GOARCH=$GOARCH ;
                echo "hitting mashling build";
                mashling build ;        
                mv bin "${recipeCreate[$y]}-${OS_NAME[$k]}" ;            
                #mv mashling.json "${recipeCreate[$y]}.mashling.json" ;
                cp -r "${recipeCreate[$y]}.mashling.json" "${recipeCreate[$y]}-${OS_NAME[$k]}" ;
                #mv "${recipeCreate[$y]}.mashling.json" mashling.json ;
                echo $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/${remotereponame[$j]}/"${recipeCreate[$y]}"/"$displayImage"
                if [[ -f $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/${remotereponame[$j]}/"${recipeCreate[$y]}"/"$displayImage" ]]; then
                cp -r $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/${remotereponame[$j]}/"${recipeCreate[$y]}"/$displayImage $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder"/"${provider[$j]}"/"${recipeCreate[$y]}"
                fi
                echo "$displayImage";
                #rm -r src vendor pkg ;
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
                # Copying gateway into latest folder
                # cp -r "${recipeCreate[$y]}" ../latest ;
                # Exit if directory not found
            done            
            rm -r src vendor pkg mashling.json ;            
            cd ..;
            export GOOS=linux ;
    else
        echo "failed to create ${recipeCreate[$y]} gateway"
        echo "directory ${recipeCreate[$y]}" not found
        exit 1
    fi
}

function recipeInfo()
{
    #if [[ "${GOOSystem[$k]}" == windows ]]; then
    idvalue="${Gateway[$x]}" ;
    eval xpath_featured='.recipe_repos[$j].publish[$x].featured' ;
    featuredvalue=$(cat $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/recipe_registry.json | jq $xpath_featured) ;
    echo "$provider_url";
    if [[ "${remotereponame[$j]}" == recipes ]] ; then
        sourceURL=https://github.com/TIBCOSoftware/mashling-recipes/tree/master/recipes/"${Gateway[$x]}" ;
        echo "$sourceURL";
    else
        if [[ $provider_url == *[.git] ]]; then	
        echo provider_url=${provider_url::-4}
        fi
        sourceURL=$provider_url/tree/master/"${Gateway[$x]}" ;
        echo "$sourceURL";
    fi     
    # sourceURL=https://github.com/TIBCOSoftware/mashling-recipes/tree/master/recipes/${Gateway[$x]} ;
    # echo "$sourceURL";
    JSONURL="${provider[$j]}"/${Gateway[$x]}/${Gateway[$x]}.mashling.json ;
    IMAGEURL="${provider[$j]}"/${Gateway[$x]}/$displayImage ;
    MACURL="${provider[$j]}"/${Gateway[$x]}/${Gateway[$x]}-osx.zip ;
    LINUXURL="${provider[$j]}"/${Gateway[$x]}/${Gateway[$x]}-linux.zip ;
    WINDOWSURL="${provider[$j]}"/${Gateway[$x]}/${Gateway[$x]}-windows.zip ;
    echo #############################
    echo JSONURL="$JSONURL";
    echo IMAGEURL="$IMAGEURL";
    echo MACURL="$MACURL";
    echo LINUXURL="$LINUXURL";
    echo WINDOWSURL="$WINDOWSURL";
    jo -p id=$idvalue featured=$featuredvalue repository_url=$sourceURL json_url=$JSONURL image_url=$IMAGEURL binaries=[$(jo  platform=mac url=$MACURL),$(jo  platform=linux url=$LINUXURL),$(jo  platform=windows url=$WINDOWSURL)] >> $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/latest/temp/A"${provider[$j]}-[$x]".json ;
    echo "alert json 3" ;
    jq -s '.[0] * .[1]' $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/${remotereponame[$j]}/"${Gateway[$x]}"/"${Gateway[$x]}".json $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/latest/temp/A"${provider[$j]}-[$x]".json >> $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/latest/temp/"${provider[$j]}-[$x]".json ;
    #fi
    echo ############################
}

    export GOOS=linux ;
    echo $GOOS ;
    export GOARCH=amd64 ;
    echo $GOARCH ;
    cd $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes
    array_length=$(cat $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/recipe_registry.json | jq '.recipe_repos | length') ;
    create_dest_directory ;
    if [[ "$GOOS" == linux ]]; then
        if [[ $OPTIMIZE == TRUE ]] ; then
            S3copytoLocal;
        fi
    fi
    recipe_registry ;



        cp $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/recipe_registry.json $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder";
        cp $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/recipe_registry.json $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/latest;    
        cp -r $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder"/* $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/latest;
        pushd $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/latest/temp ;
        echo "alert json 4" ;
        ls;
        #cat TIBCOSoftware_Engineering-[0].json;
        #cat TIBCOSoftware_Services-[0].json;
        echo "alert json 5" ;
        for (( j = 0; j < $array_length; j++ ))
        do
            echo provider is "${provider[$j]}"; 
        done
        for (( j = 0; j < $array_length; j++ ))
        do
            #cat "${provider[$j]}-*.json";
            echo value of j= $j and value for provider is ${provider[$j]};
            echo "${provider[$j]}-*.json";
            echo value of j= $j and value for provider is ${provider[$j]};
            eval provider="${provider[$j]}";
            jq -s '.' $provider-*.json > recipe-[$j].json
            echo "alert json 11" ;
            #cat recipe-[$j].json ;
            #echo "alert json 12" ;
        done
        echo "alert json 9" ;
        ls
        echo "alert json 11" ;
        jq -s '.' recipe-*.json > recipeinfo.json
        echo "alert json 6" ;
        cat recipeinfo.json;
        echo "alert json 7" ;
        cp recipeinfo.json $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/latest
        cp recipeinfo.json $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder";
        echo "alert json 8" ;
        rm -rf $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/latest/temp ;
        popd ;


        # cd $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds
        # git add .
        # git commit -m "uploading builds" ;
        # # git push ;
###############################################################################
    # GOOSystem=({"linux","darwin","windows"});
    # OS_NAME=({"linux","osx","windows"});
    # # GOARCH=({"amd64","amd64","amd64"});
    #     # get length of an array
    #     Len="${#GOOSystem[@]}"
    #         for (( k=0; k < "${Len}"; k++ ));
    #         do
    #             export GOOS="${GOOSystem[$k]}" ;
    #             echo $GOOS ;
    #             export GOARCH=amd64 ;
    #             echo $GOARCH ;
    #                 if [[ ! -d $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/tmp ]]; then
    #                 mkdir -p $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/tmp
    #                 fi
    #                 cd $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes
    #                 create_dest_directory ;
    #                 if [[ "${GOOSystem[$k]}" == linux ]]; then
    #                     if [[ $OPTIMIZE == TRUE ]] ; then
    #                         S3copytoLocal;
    #                     fi
    #                 fi
    #                 recipe_registry ;
    #                 echo "#########Alert 15#####";
    #                 pushd $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder";
    #                 ls ;
    #                 cp -r $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder"/* $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/tmp ;
    #                 echo "#########Alert 16#####";
    #                 popd
    #                 rm -rf $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder"
    #                 echo "#########Alert 17#####";
    #         done

    #     mv $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/tmp $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder";
    #     cd $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes ;

    #     cp $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/recipe_registry.json $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder";
    #     cp $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/recipe_registry.json $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/latest;
    #     cp -r $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder"/* $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/latest;
###############################################################################################################