#!/bin/sh

dist=../php-debs
tmp=/space/tmp/sendphp
user=epiconcept_build
server=files.epiconcept.fr
test -d $dist || { echo "$0: cannot find '$dist'" >&2; exit 1; }
rm -fr $tmp
mkdir $tmp
for i in $dist/*/*/*.deb; do
	cp -p $i $tmp/
done
rsync -rltuv $tmp/ $user@$server:/space/applisdata/php/
rm -r $tmp

ssh -t $user@$server /usr/local/bin/apt_deploy.sh 
