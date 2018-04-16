# infra-build-php
usine à paquets PHP

## Infos pratique

* Build PHP 5.2 : https://svn.epiconcept.fr/outils_internes/ansible-deploy/specifique/php52_jessie/
* IP serveur AWS de build : 34.240.2.84 (compte "cdt")
* source pour le build PHP5.2, utilisateur "cdt", url Subversion : https://svn.epiconcept.fr/outils_internes/ansible-deploy/specifique/php52_jessie/ (le but n'est vraiment pas d'intégrer directement, mais de reprendre les éléments et de les intégrer)

## Cahier des charges

???
* fichier Yaml 

* phase 1
  * reprendre le script actuel
  * l'étendre pour permettre de builder une version quelconque (télécharger l'archive depuis php.net, builder, jouer les tests PHP, builder le paquet DEB)
  * le principe idéal serait de passer la version à builder, et de n'avoir en spécifique 
    * le script actuel de build est dans https://github.com/Epiconcept-Paris/infra-build-php/blob/master/docker/docker-entrypoint.sh
    * la doc d'utilisation est dans https://github.com/Epiconcept-Paris/infra-build-php/blob/master/docker/README.md
  * documenter les commandes de build, d'ajout d'une version, etc...
  * ajouter l'extension APC pour PHP7
  * intégrer la signature des paquets
  * nous pourrons mettre à jour notre serveur de preprod PHP7, ce qui nous apportera une aide immédiatement
* phase 2
  * intégrer PHP 5.2 dans le même processus
  * ajouter l'extension APC pour PHP5.2
* phase 3
  * tester l'ajout de l'extension Mysql sur PHP7(obsolète mais on risque d'en avoir besoin pour un code legacy, il existe des tutoriels)
  
