BUILD PHP7.1
################

From https://svn.epiconcept.fr/outils_internes/ansible-deploy/specifique/php52_jessie/php52_jessie.yml

To change the **PHP** version, edit the link in ``files/build.sh`` where : ::

	if [ ! -f php.tar.bz2 ]; then 
	curl -SL "http://fr2.php.net/get/php-7.1.11.tar.bz2/from/this/mirror" -o php.tar.bz2 
	fi
