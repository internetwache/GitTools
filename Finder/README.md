# GitFinder

This python script identifies websites with publicly accessible `.git` repositories.
It checks if the `.git/HEAD` file contains `refs/heads`.

# Setup

```
> pip3 install -r requirements.txt
```

# Usage

```
> python3 gitfinder.py -h
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
The script will output discovered domains in the form of `[*] Found: DOMAIN` to stdout.
