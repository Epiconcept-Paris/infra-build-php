# infra-build-php
usine à paquets PHP

## Infos pratique

* Build PHP 5.2 : https://svn.epiconcept.fr/outils_internes/ansible-deploy/specifique/php52_jessie/

## Cahier des charges

* phase 1
  * reprendre le script actuel
  * l'étendre pour permettre de builder une version quelconque (télécharger l'archive depuis php.net, builder, jouer les tests PHP, builder le paquet DEB)
  * fichier Yaml 
  * documenter les commandes de build, d'ajout d'une version, etc...
  * ajouter l'extension APC pour PHP7
  * intégrer la signature des paquets
  * nous pourrons mettre à jour notre serveur de preprod PHP7, ce qui nous apportera une aide immédiatement
* phase 2
  * intégrer PHP 5.2 dans le même processus
  * ajouter l'extension APC pour PHP5.2
  * au build, il faut préciser : /etc/php/php.ini / /etc/php/conf.d
* phase 3
  * tester l'ajout de l'extension Mysql sur PHP7(obsolète mais on risque d'en avoir besoin pour un code legacy, il existe des tutoriels)
  
