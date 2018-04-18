# infra-build-php
usine à paquets PHP

## Infos pratique

* Build PHP 5.2 : https://svn.epiconcept.fr/outils_internes/ansible-deploy/specifique/php52_jessie/
* IP serveur AWS de build : 34.240.2.84 (compte "cdt")
* source pour le build PHP5.2, utilisateur "cdt", url Subversion : https://svn.epiconcept.fr/outils_internes/ansible-deploy/specifique/php52_jessie/ (le but n'est vraiment pas d'intégrer directement, mais de reprendre les éléments et de les intégrer)

## Cahier des charges

* phase 1
  * livrables attendus : processus documenté pour builder un paquet pour n'importe quelle version de PHP 7 (présente ou future)  pour Debian Jessie et Stretch
  * reprendre le script actuel
  * l'étendre pour permettre de builder une version quelconque (télécharger l'archive depuis php.net, builder, jouer les tests PHP via "make test" et en signaler les erreurs pour documentation, builder le paquet DEB)
  * le principe idéal serait de passer la version à builder, et de n'avoir en spécifique que les options du ./configure qui sont propres à une version
    * le script actuel de build est dans https://github.com/Epiconcept-Paris/infra-build-php/blob/master/docker/docker-entrypoint.sh
    * la doc d'utilisation est dans https://github.com/Epiconcept-Paris/infra-build-php/blob/master/docker/README.md
    * si on ajoute des extensions (mysql par exemple), il faut probablement avoir un script de mise en place qui vient compléter la récupération de l'archive contenant le code depuis php.net en récupérant des patchs et éléments de code
  * documenter les commandes de build, d'ajout d'une version, etc...
  * ajouter l'extension APC (nommée APCu probablement en fait) pour PHP7
  * intégrer la signature des paquets
  * analyse/résoudre/ignorer les warnings au make install de PHP7
  * Nettoyer les erreurs lintian (build du paquet DEB)
  * gérer l'incompatibilité de nos paquets epi-php* avec php5*/php7* fourni par les distros (on ne doit pas pouvoir les installer en même temps)
  * nous pourrons mettre à jour notre serveur de preprod PHP7, ce qui nous apportera une aide immédiatement
  
* phase 2
  * livrables attendus : intégration PHP 5.2 au process de la phase 1
  * il nécessite pour être buildé que deux patchs (fourni dans le svn) soient appliqués
  * ajouter l'extension APC pour PHP5.2
  
* phase 3
  * tester l'ajout de l'extension Mysql sur PHP7 (obsolète mais on risque d'en avoir besoin pour un code legacy, il existe des tutoriels en ligne sur le sujet)
  
