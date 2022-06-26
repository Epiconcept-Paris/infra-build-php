#!/bin/sh

tmp=/space/tmp/sendphp
user=epiconcept_build
server=files.epiconcept.fr
rm -fr $tmp
mkdir $tmp
#cp $(find -name 'epi*.deb' | grep -v '/dist/') $tmp/
for i in debian/*/dist/*/*.deb; do
	cp -p $i $tmp/
done
rsync -rltuv $tmp/ $user@$server:/space/applisdata/php/
rm -r $tmp

ssh -t $user@$server /usr/local/bin/apt_deploy.sh 
