tmp=/tmp/sendphp
rm -fr $tmp
mkdir $tmp
cp $(find -name 'epi*.deb') $tmp/
rsync -rav $tmp/ epiconcept_build@files.epiconcept.fr:/space/applisdata/php/
rm -r $tmp

ssh -t $USER@files.epiconcept.fr sudo -u www-data bash -c 'cd /space/www/apps/apt; ./prep.sh update'
