#!/bin/bash
export GITMIRROOT
gitmir -f /root/feederFile.json | tee /root/gitmirlog
wait
httpd-foreground
