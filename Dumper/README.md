GitDumper
=================
This is a tool for downloading .git repositories from webservers which do not have directory listing enabled. 

# Requirements
- git
- curl
- bash
- sed

# Usage

```
bash gitdumper.sh http://target.tld/.git/ dest-dir
```

Note: This tool has no 100% guaranty to completely recover the .git repository. Especially if the repository has been compressed into ```pack```-files, it may fail.
