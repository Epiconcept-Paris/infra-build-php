#!/bin/sh
#
#   Make all packages in pkgs/
#
Dir=`dirname $0`
Ver=$1
cd $Dir/pkgs
test -f .norun && echo "Only showing package commands as pkgs/.norun is present"
for pkg in *
do
    cmd="$Dir/pkgs/$pkg/mkpkg $Ver"
    test -f .norun && echo "$cmd" || $cmd
done
