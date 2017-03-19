#!/usr/bin/python
import sys, os, argparse
from urllib.request import urlopen
from multiprocessing import Pool

def findgitrepo(domain):
    domain = domain.strip()
    
    try:
        # Try to download http://target.tld/.git/HEAD
        req = urlopen('http://' + domain + "/.git/HEAD")
        answer = req.read(200).decode()
        
        # Check if refs/heads is in the file
        if(not 'refs/heads' in answer):
            return
        
        # Write match to OUTPUTFILE
        fHandle = open(OUTPUTFILE,'a')
        fHandle.write(domain + "\n")
        fHandle.close()
        
        print("[*] Found: " + domain)
    
    except Exception as e:
        return 

if __name__ == '__main__':
    print("""
###########
# Finder is part of https://github.com/internetwache/GitTools
#
# Developed and maintained by @gehaxelt from @internetwache
#
# Use at your own risk. Usage might be illegal in certain circumstances. 
# Only for educational purposes!
###########
        """)
    # Parse arguments
    parser = argparse.ArgumentParser()
    parser.add_argument('-i', '--inputfile', default='domains.txt', help='input file')
    parser.add_argument('-o', '--outputfile', default='output.txt', help='output file')
    parser.add_argument('-t', '--threads', default=200, help='threads')
    args = parser.parse_args()

    DOMAINFILE=args.inputfile
    OUTPUTFILE=args.outputfile
    MAXPROCESSES=int(args.threads)

    print("Scanning...")
    pool = Pool(processes=MAXPROCESSES)
    domains = open(DOMAINFILE, "r").readlines()
    pool.map(findgitrepo, domains)
    print("Finished")