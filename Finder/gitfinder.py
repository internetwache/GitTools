#!/usr/bin/env python3

'''
Finder is part of https://github.com/internetwache/GitTools

Developed and maintained by @gehaxelt from @internetwache

Use at your own risk. Usage might be illegal in certain circumstances.
Only for educational purposes!
'''

import argparse
import signal
from functools import partial
from multiprocessing import Pool
from urllib.request import urlopen
from urllib.error import HTTPError, URLError
from datetime import datetime
import sys


def fSetErased1(vE1):
    global vErased1
    vErased1 = vE1


def fGetErased1():
    return vErased1


def fSetErased2(vE2):
    global vErased2
    vErased2 = vE2 


def fGetErased2():
    return vErased2


def init_worker():
    signal.signal(signal.SIGINT, signal.SIG_IGN)


#@retry(urllib.URLError, tries=4 , delay=1, backoff=1)
def findgitrepo(output_file, tldomain_filter, verbose_log, erase_logs, domains):
    sstime = datetime.now().strftime('%Y%m%d_%H:%M:%S - ')
    domain = domains.strip()

    if tldomain_filter != "all":
        if not domain.endswith(tldomain_filter):
            return

    if verbose_log  == "yes":
        if erase_logs == "yes" and fGetErased1() == "no":
            with open("verbose.log", 'w') as file_handle:
                 file_handle.write('@' + sstime + ' Checking: {}'.format(domain) + '\n')
            fSetErased1("yes")
        else: 
            with open("verbose.log", 'a') as file_handle:
                 file_handle.write('@' + sstime + ' Checking: {}'.format(domain) + '\n')

    try:
        # Try to download http://target.tld/.git/HEAD
        with urlopen(''.join(['http://', domain, '/.git/HEAD']), timeout=15) as response:
            answer = response.read(200).decode('utf-8', 'ignore')

    except HTTPError:
        return
    except URLError:
        return
    except ConnectionResetError:
        return
    except SystemExit:
        raise
    except KeyboardInterrupt:
        pass 

    print(' |_domain: ' + domain)
    # print(' |_answer: ' + answer)

    # Check if refs/heads is in the file
    if 'refs/heads' not in answer:
        erase_logs = "no" 
        return

    # Write match to output_file
    if erase_logs == "yes" and fGetErased2() == "no":
        with open(output_file, 'w') as file_handle:
            file_handle.write(''.join([domain, '\n']))
        fSetErased2("yes")
    else:
        with open(output_file, 'a') as file_handle:
            file_handle.write(''.join([domain, '\n']))

    print(''.join(['[*] Found: ', domain]) + '\n')


def read_file(filename):
    with open(filename) as file:
        return file.readlines()

def main():
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
    parser.add_argument('-d', '--tldomain', default='all', help='tld')
    parser.add_argument('-e', '--eraselogs', default='no', help='tld')
    parser.add_argument('-f', '--inputfile', default='', help='input file')
    parser.add_argument('-s', '--inputstring', default='', help='input string')
    parser.add_argument('-o', '--outputfile', default='output.txt', help='output file')
    parser.add_argument('-t', '--threads', default=200, help='threads')
    parser.add_argument('-v', '--verbose', default='no', help='verbose')
    args = parser.parse_args()

    domain_file = args.inputfile
    domain_string = args.inputstring
    global erase_logs
    erase_logs = args.eraselogs
    output_file = args.outputfile
    tldomain_filter = args.tldomain
    verbose_log = args.verbose

    fSetErased1("no")
    fSetErased2("no")

    try:
        max_processes = int(args.threads)
    except ValueError as err:
        sys.exit(err)
   

    domains = []

    if domain_file != "":
        try:
            domains = read_file(domain_file)
            # print (domains[-1].strip())
        except FileNotFoundError as err:
            sys.exit(err)


    print ('Domains: ')

    if domain_string.strip():
        domain_list = domain_string.split();
        domains = domains + domain_list

    print(*domains)

    fun = partial(findgitrepo, output_file, tldomain_filter, verbose_log, erase_logs)
    print("Scanning...")
    try: 
        with Pool(processes=max_processes, initializer=init_worker) as pool:
            pool.map(fun, domains)
    except KeyboardInterrupt:
        pool.terminate()
        pool.close()
        print('Program interrupted, bye!')
        exit(5)
    #finally:
    #    pool.close()
    #    pool.join()
    print("Finished")

if __name__ == '__main__':
    main()
