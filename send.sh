tmp=/tmp/sendphp
rm -fr $tmp
mkdir $tmp
cp $(find -name 'epi*.deb') $tmp/
rsync -rav $tmp/ files.epiconcept.fr:/space/applisdata/php/
rm -r $tmp
