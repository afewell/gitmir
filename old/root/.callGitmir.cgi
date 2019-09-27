#!/usr/bin/perl
print "Content-type: text/html\n\n";
print "Hello, World.";
exec "gitmir -f /gitmir/feederFile.json";
