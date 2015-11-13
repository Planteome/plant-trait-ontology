#!/usr/bin/perl
while(<>) {
    if (m@ (\w+):(\d+)@) {
        print "http://purl.obolibrary.org/obo/$1_$2\n";
    }
}
