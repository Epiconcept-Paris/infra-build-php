# infra-build-php
usine à paquets PHP

## Cahier des charges

* phase 1
  * reprendre le script actuel
  * l'étendre pour permettre de builder une version quelconque (télécharger l'archive depuis php.net, builder, jouer les tests PHP, builder le paquet DEB)
  * documenter les commandes de build, d'ajout d'une version, etc...
  * ajouter l'extension APC pour PHP7
  * nous pourrons mettre à jour notre serveur de preprod PHP7, ce qui nous apportera une aide immédiatemen
* phase 2
  * intégrer PHP 5.2 dans le même processus
  * ajouter l'extension APC pour PHP5.2
  * au build, il faut préciser : /etc/php/php.ini / /etc/php/conf.d
* phase 3
  * tester l'ajout de l'extension Mysql sur PHP7(obsolète mais on risque d'en avoir besoin pour un code legacy, il existe des tutoriels)
  
