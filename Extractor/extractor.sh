#!/bin/bash
#$1 : Folder containing .git directory to scan
#$2 : Folder to put files to

if [ $# -ne 2 ]; then
	echo "USAGE: extractor.sh GIT-DIR DEST-DIR";
	exit 1;
fi

if [ ! -d "$1/.git" ]; then
	echo "There's no .git folder";
	exit 1;
fi

if [ ! -d "$2" ]; then
	echo "Destination folder does not exist";
    echo "Creating..."
    mkdir "$2"
fi

function traverse_tree() {
	local tree=$1
	local path=$2
	
    #Read blobs/tree information from root tree
	git ls-tree $tree |
	while read leaf; do
		type=$(echo $leaf | awk -F' ' '{print $2}') #grep -oP "^\d+\s+\K\w{4}");
		hash=$(echo $leaf | awk -F' ' '{print $3}') #grep -oP "^\d+\s+\w{4}\s+\K\w{40}");
		name=$(echo $leaf | awk '{$1=$2=$3=""; print substr($0,4)}') #grep -oP "^\d+\s+\w{4}\s+\w{40}\s+\K.*");
		
        # Get the blob data
		git cat-file -e $hash;
		#Ignore invalid git objects (e.g. ones that are missing)
		if [ $? -ne 0 ]; then
			continue;
		fi	
		
		if [ "$type" = "blob" ]; then
			echo "Found file: $path/$name"
			git cat-file -p $hash > "$path/$name"
		else
			echo "Found folder: $path/$name"
			mkdir -p "$path/$name";
			#Recursively traverse sub trees
			traverse_tree $hash "$path/$name";
		fi
		
	done;
}

function traverse_commit() {
	local base=$1
	local commit=$2
	local count=$3
	
    #Create folder for commit data
	echo "Found commit: $commit";
	path="$base/$count-$commit"
	mkdir -p $path;
    #Add meta information
	git cat-file -p "$commit" > "$path/commit-meta.txt"
    #Try to extract contents of root tree
	traverse_tree $commit $path
}

#Current directory as we'll switch into others and need to restore it.
OLDDIR=$(pwd)
TARGETDIR=$2
COMMITCOUNT=0;

#If we don't have an absolute path, add the prepend the CWD
if [ "${TARGETDIR:0:1}" != "/" ]; then
	TARGETDIR="$OLDDIR/$2"
fi

cd $1

#Extract all object hashes
find ".git/objects" -type f | 
	sed -e "s/\///g" |
	sed -e "s/\.gitobjects//g" |
	while read object; do
	
	type=$(git cat-file -t $object)
	
    # Only analyse commit objects
	if [ "$type" = "commit" ]; then
		CURDIR=$(pwd)
		traverse_commit "$TARGETDIR" $object $COMMITCOUNT
		cd $CURDIR
		
		COMMITCOUNT=$((COMMITCOUNT+1))
	fi
	
	done;

cd $OLDDIR;

echo "Finished";
