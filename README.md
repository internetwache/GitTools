# GitTools

This repository contains three small python/bash scripts used for the Git research. [Read about it here](http://en.internetwache.org/dont-publicly-expose-git-or-how-we-downloaded-your-websites-sourcecode-an-analysis-of-alexas-1m-28-07-2015/)

## Finder

You can use this tool to find websites with their .git repository available to the public

### Usage

This python script identifies websites with publicly accessible ```.git``` repositories.
It checks if the ```.git/HEAD``` file contains ```refs/heads```.

```
./gitfinder.py -h
usage: gitfinder.py [-h] [-i INPUTFILE] [-o OUTPUTFILE] [-t THREADS]

optional arguments:
  -h, --help            show this help message and exit
  -i INPUTFILE, --inputfile INPUTFILE
                        input file
  -o OUTPUTFILE, --outputfile OUTPUTFILE
                        output file
  -t THREADS, --threads THREADS
                        threads
```

The input file should contain the targets one per line.
The script will output discovered domains in the form of ```[*] Found: DOMAIN``` to stdout.


## Dumper

This tool can be used to download as much as possible from the found .git repository from webservers which do not have directory listing enabled.

### Usage

```
./gitdumper.sh -h

[*] USAGE: http://target.tld/.git/ dest-dir [--git-dir=otherdir]
		--git-dir=otherdir		Change the git folder name. Default: .git

```

Note: This tool has no 100% guaranty to completely recover the .git repository. Especially if the repository has been compressed into ```pack```-files, it may fail.


## Extractor

A small bash script to extract commits and their content from a broken repository.

This script tries to recover incomplete git repositories:

- Iterate through all commit-objects of a repository
- Try to restore the contents of the commit
- Commits are *not* sorted by date

### Usage

```
./extractor.sh /tmp/mygitrepo /tmp/mygitrepodump
```
where
- ```/tmp/mygitrepo``` contains a ```.git``` directory
- ```/tmp/mygitrepodump``` is the destination directory

This can be used in combination with the ```Git Dumper``` in case the downloaded repository is incomplete.


## Demo

Here's a small demo of the **Dumper** tool:

[![asciicast](https://asciinema.org/a/24072.png)](https://asciinema.org/a/24072)


## Requirements
* git
* python
* curl
* bash
* sed

# License

All tools are licensed using the MIT license. See LICENSE.md
