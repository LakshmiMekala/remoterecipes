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
}

function RecipesNewlyAdded()
{
    recipeAdded=()
		for z in "${Gateway[@]}"; do
			skip=
			for l in "${recipesInLatest[@]}"; do
				[[ $z == $l ]] && { skip=1; break; }
			done
			[[ -n $skip ]] || recipeAdded+=("$z")
		done
		echo newly added recipe-in recipe_registry is "${recipeAdded[@]}" ;
        echo "+++++++++++++++++++++++++++${recipeCreate[@]}+++++++++++++++++++++++++++"
        recipeTOCreate=$(echo "${recipeAdded[@]}" "${recipeCreate[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ') ;        
        IFS=\  read -a recipeCreate <<<"$recipeTOCreate" ;
        set | grep ^IFS= ;
        #separating array by line
        IFS=$' \t\n' ;
        #fetching Gateway
        set | grep ^recipeCreate=\\\|^recipeTOCreate= ;
            for (( x=0; x<${#recipeCreate[@]}; x++ ))
            do
                echo "${recipeCreate[$x]}";
            done
            unset recipeAdded;
            unset recipeTOCreate;
            echo "${recipeCreate[@]}" > $GOPATH/recipes-[$j]; 
            RecipesToBeCreated ;
}

##Function to copy recipes from S3 to Local for optimized build
function S3copytoLocal()
{
    aws s3 cp s3://${AWS_BUCKET}/master-builds/latest  $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder" --recursive    
}


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
            provider[$j]=$(echo "${provider[$j]}" | sed -e 's/ /-/g') ;
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
					if [ -n "$provider_url" ]; then
                        remotereponame[$j]=recipes
                        echo "==========${remotereponame[$j]}============"
                    fi
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
			y=0;
			echo "$publish_length" ;
			for (( x=0; x<$publish_length; x++ ))
			do
				eval xpath_recipe='.recipe_repos[$j].publish[$x].recipe' ;
				Gateway[$x]=$(cat $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/recipe_registry.json | jq $xpath_recipe) ;
				Gateway[$x]=$(echo ${Gateway[$x]} | tr -d '"') ;
				recipeInfo ;
                z=$z+1
				if [[ $OPTIMIZE = TRUE ]] ; then
					if [[ "${remotereponame[$j]}" == recipes ]] ; then
						if [[ $recipeName =~ ${Gateway[$x]}/${Gateway[$x]}.json ]] || [[ $recipeName =~ ${Gateway[$x]}/manifest ]];then
							recipeCreate[$y]=${Gateway[$x]} ;
							if [[ -d $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder"/"${provider[$j]}"/"${Gateway[$x]}" ]] ; then
								rm -rf $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder"/"${provider[$j]}"/"${Gateway[$x]}";
                                echo "deleting recipeCreate[$y]-----------${Gateway[$x]}"    
                            fi
						else
							echo "${Gateway[$x]} not found in current commit ";
						fi
                        y=$y+1;
					fi
				else
					echo "recipe needs to be created from full build"
					recipeCreate[$y]=${Gateway[$x]} ;
					y=$y+1;
				fi                    
			done
			for (( x=0; x<$publish_length; x++ ))
			do
				eval xpath_recipe='.recipe_repos[$j].publish[$x].recipe' ;
				Gateway[$x]=$(cat $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/recipe_registry.json | jq $xpath_recipe) ;
				Gateway[$x]=$(echo ${Gateway[$x]} | tr -d '"') ;
			done    
			echo "list of gws available in registry is ${Gateway[@]}";
            echo gateway array is "${recipeCreate[@]}";
			RecipesNewlyAdded ;
		done
}

function RecipesToBeCreated()
{
    echo gateway array is "${recipeCreate[@]}";
    echo length of gateway array is "${#recipeCreate[@]}";
	mkdir -p "${provider[$j]}";
	echo "${provider[$j]}" ; 
	cd "${provider[$j]}" ;
	for (( y=0; y < "${#recipeCreate[@]}"; y++ ));    
	do
		echo "${recipeCreate[$y]}";
		if [[ -f $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/"${remotereponame[$j]}"/${recipeCreate[$y]}/${recipeCreate[$y]}.json ]] || [[ -f $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/"${remotereponame[$j]}"/${recipeCreate[$y]}/manifest ]] ; then
			displayImage=$(cat $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/"${remotereponame[$j]}"/"${recipeCreate[$y]}"/"${recipeCreate[$y]}".json | jq '.gateway.display_image') ;
			displayImage=$(echo $displayImage | tr -d '"') ;
			echo "creating ${recipeCreate[$y]} gateway" ;
			cp -r $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/"${remotereponame[$j]}"/${recipeCreate[$y]}/manifest $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder"/"${provider[$j]}"
			mashling create -f $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/"${remotereponame[$j]}"/"${recipeCreate[$y]}"/"${recipeCreate[$y]}".json "${recipeCreate[$y]}";
			rm -rf $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder"/"${provider[$j]}"/manifest;
		fi
		binarycheck ;
	done
	cd ..;   
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
                cp -r "${recipeCreate[$y]}.mashling.json" "${recipeCreate[$y]}-${OS_NAME[$k]}" ;
                echo $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/${remotereponame[$j]}/"${recipeCreate[$y]}"/"$displayImage"
                if [[ -f $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/${remotereponame[$j]}/"${recipeCreate[$y]}"/"$displayImage" ]]; then
                cp -r $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/${remotereponame[$j]}/"${recipeCreate[$y]}"/$displayImage $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder"/"${provider[$j]}"/"${recipeCreate[$y]}"
                fi
                echo "$displayImage";
                cd "${recipeCreate[$y]}-${OS_NAME[$k]}";
                if [ "${OS_NAME[$k]}" == windows ] ; then
                    fname="${recipeCreate[$y]}-${GOOSystem[$k]}-$GOARCH.exe" ;
                    fnamelc="${fname,,}" ;
                    destfname="${recipeCreate[$y]}.exe" ;
                    destfnamelc="${destfname,,}" ;
                    echo "$destfnamelc" ;
                    mv $fnamelc $destfnamelc ;
                else
                    fname="${recipeCreate[$y]}-${GOOSystem[$k]}-$GOARCH" ;
                    fnamelc="${fname,,}" ;
                    destfname="${recipeCreate[$y]}" ;
                    destfnamelc="${destfname,,}" ;
                    echo "$destfnamelc" ;
                    mv $fnamelc $destfnamelc ;
                fi
                if [[ $GOOS == linux ]];then
                    cp $destfnamelc "$GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/${remotereponame[$j]}/${recipeCreate[$y]}";
                fi
                zip -r "${recipeCreate[$y]}-${OS_NAME[$k]}" *;
                cp "${recipeCreate[$y]}-${OS_NAME[$k]}.zip" ../../"${recipeCreate[$y]}" ;
                cd .. ;
                rm -r "${recipeCreate[$y]}-${OS_NAME[$k]}" ;
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
    PROVIDERURL="${provider[$j]}"
    JSONURL="${provider[$j]}"/${Gateway[$x]}/${Gateway[$x]}.mashling.json ;
    IMAGEURL="${provider[$j]}"/${Gateway[$x]}/$displayImage ;
    MACURL="${provider[$j]}"/${Gateway[$x]}/${Gateway[$x]}-osx.zip ;
    LINUXURL="${provider[$j]}"/${Gateway[$x]}/${Gateway[$x]}-linux.zip ;
    WINDOWSURL="${provider[$j]}"/${Gateway[$x]}/${Gateway[$x]}-windows.zip ;
	
    jo -p id=$idvalue featured=$featuredvalue repository_url=$sourceURL json_url=$JSONURL image_url=$IMAGEURL binaries=[$(jo  platform=mac url=$MACURL),$(jo  platform=linux url=$LINUXURL),$(jo  platform=windows url=$WINDOWSURL)] provider=$PROVIDERURL >> $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/latest/temp/A"${provider[$j]}-[$x]".json ;
    jq -s '.[0] * .[1]' $GOPATH/src/github.com/TIBCOSoftware/mashling-recipes/${remotereponame[$j]}/"${Gateway[$x]}"/"${Gateway[$x]}".json $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/latest/temp/A"${provider[$j]}-[$x]".json >> $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/latest/temp/"recipe-[$z]".json ;    
}

z=0
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
echo "alert json 5" ;
jq -s '.' recipe-*.json > recipeinfo.json
echo ==========================================
cat recipeinfo.json
echo ==========================================
cp recipeinfo.json $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/latest
cp recipeinfo.json $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/"$destFolder";
rm -rf $GOPATH/src/github.com/TIBCOSoftware/recip1/samples-recipes/master-builds/latest/temp ;
popd ;