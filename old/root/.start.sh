#!/bin/bash
export GITMIRROOT
gitmir -f /gitmir/feederFile.json | tee /gitmir/gitmirlog
wait
httpd-foreground