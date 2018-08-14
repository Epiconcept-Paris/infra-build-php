# infra-build-php
Usine à paquets PHP spécifiques Epiconcept sur Debian jessie/stretch

## Build et tests d'une nouvelle version

````
./mk.sh <version-PHP> [ <version-Debian> ]
````
builde et teste la version _\<version-PHP>_ pour _\<version-Debian>_

_\<version-PHP>_ est sous la forme _Maj_**.**_Min_**.**_Rel_, où _Maj_ = 5 ou 7 \
_\<version-Debian>_ est sous la forme numérique _n_, par défaut la plus récente gérée. Exemple :
````
./mk.sh 5.2.17 8
````
builde et teste la version 5.2.17 sous Debian jessie

````./mk.sh```` (sans arguments) affiche la liste des dernières versions disponibles de PHP et celle des versions gérées de Debian

Les packages résultants sont produits dans le répertoire ````debian/<version-Debian>/dist/<version-PHP>-<BUILD_NUM>````, qui est partagé avec le container docker. \
Les logs du build et des tests sont dans le répertoire ````debian/<version-Debian>/dist/<version-PHP>-<BUILD_NUM>/.logs````

Le nom des packages produits comporte un numéro de build après la _\<version-PHP>_. Ce numéro de build est contenu dans le fichier ````php/<version-majeure-PHP>/<version-PHP>/BUILD_NUM````. Après un ````git commit```` de ce fichier, on peut provoquer un incrément automatique de la valeur de ce dernier ````git commit```` en supprimant le fichier avec un simple :\
````rm php/<version-majeure-PHP>/<version-PHP>/BUILD_NUM````\
On peut aussi bien sur incrémenter manuellement le contenu du fichier.


## Mise au point

Elle se fait en créant un fichier ````.norun```` (vide) dans le répertoire du script mk.sh : ````>.norun```` ou ````touch .norun````\
Le script affiche alors les commandes docker à lancer au lieu de les exécuter,
ainsi que les commandes bash à lancer pour le build et les tests

Il est possible de sauter le "make test" du build en créant de même un fichier (vide) ````php/.notest````.

Enfin, on peut également créer un fichier ````.debug```` (vide), qui active des traces supplémentaires dans le container de build et des logs (et sauvegardes de fichiers) supplémentaires dans le répertoire ````debian/<version-Debian>/dist/<version-PHP>-<BUILD_NUM>/.debug````

## Test de multiples versions
Une fois qu'au moins deux versions de PHP ont été compilées, différant par leur versions Majeure et mineure, il est possible de les tester simultanément avec PHP FPM dans un container de test :
````
./multi.sh <distrib-PHP> [ <distrib-PHP> ...] [ <version-Debian> ]
````

_\<distrib-PHP>_ est sous la forme _Maj_**.**_Min_**.**_Rel_**-**_Bld_, où _Bld_ est le numéro de build de la version PHP.\
_\<version-Debian>_ est sous la forme numérique _n_, par défaut la plus récente gérée (pour l'instant, la version 9 [stretch] est la seule). Exemple :
````
./multi.sh 5.6.37-2 7.1.20-2 7.2.9-1
````
Le script ````multi.sh```` crée si nécessaire le répertoire ````debian/<version-Debian>/multi```` (partagé avec le container docker) avec 3 sous répertoires :
* ````pkgs```` qui contient les packages Debian -cli et -fpm (et -mysql s'il existe) de chaque _\<distrib-PHP>_
* ````www```` qui contient les ````DocumentRoot```` de test pour chaque version PHP, par défaut sous la forme ````php<version-majeure><version-mineure>````, dans notre exemple ````php56````, ````php71```` et ````php72````
* ````logs```` qui contient les logs de build de l'image ````epi-multi-php:<version-Debian>```` (dans notre exemple ````epi-multi-php:stretch````) et de run du container ````epi_multi_php````

Puis le script ````multi.sh```` builde si nécessaire l'image docker et lance le container en mode background (sauf pour la mise au point). Depuis le script principal  ````/opt/multi/start```` du container, les packages de ````pkgs```` sont installés et un ````VirtualHost````est automatiquement configuré pour chacune des _\<distrib-PHP>_ de ces packages. Puis ````apache2```` est lancé sur le port 80, dans notre exemple pour 3 ````VirtualHost```` : ````php56.epiconcept.tld````,````php71.epiconcept.tld```` et ````php72.epiconcept.tld````, qu'il faudra déclarer dans le fichier ````hosts```` du client de test.

Il est possible de modifier le hostname fictif ````php%M%m.epiconcept.tld```` en définissant avant le ````docker run```` la variable d'environnement ````HOSTFMT````, dans laquelle les variables ````%M```` et ````%m```` seront automatiquement remplacées respectivement par les numéros de version majeure et mineure de chaque _\<distrib-PHP>_. Le script ````start```` utilisera automatiquement comme ````DocumentRoot```` des ````VirtualHost```` des sous-répertoires de ````www```` nommés comme la partie gauche finale du hostname, éventuellement modifiée par ````HOSTFMT````.

Il faut noter que l'image docker (````epi-multi-php:stretch```` dans notre example) est indépendante des _\<distrib-PHP>_ testées et de son propre système de build : le script ````start```` du container déduit les _\<distrib-PHP>_ et par suite les ````VirtualHost````, du nom des packages ````.deb```` dans le répertoire ````pkgs````. Pour cette raison, l'image n'est pas recréée à chaque lancement de ````./multi.sh````, il faut la supprimer explicitement, dans notre exemple par ````docker rmi epi-multi-php:stretch````.

Pour utiliser l'image docker (````epi-multi-php:stretch```` toujours dans notre example) séparément de son système de build, il faut lui fournir un répertoire partagé de structure analogue à celle de ````debian/<version-Debian>/multi````, dans lequel les packages ````.deb```` de ````pkgs```` indiquent les _\<distrib-PHP>_ choisies et les sous-répertoires de ````www```` correspondent bien aux hostnames éventuellement modifiés par ````HOSTFMT````. Le sous-répertoire ````logs```` peut être vide mais doit être présent. Il suffit alors à un user ayand créé un répertoire ````$HOME/essai```` correctement peuplé de la façon décrite ci-dessus de lancer la commande (encore dans notre exemple) :
````
docker run -d -e HOSTFMT -p 80:80 -v ~/essai:/opt/multi/work --name epi_multi_php --rm epi-multi-php:stretch
````
\
Enfin, le script ````multi.sh````, comme le script ````mk.sh````, reconnait dans son répertoire le fichier ````.norun```` pour permettre la mise au point.

## Notes

* Serveur AWS de build : cdt@34.243.220.28
* voir s'il faut gérer le rotate/reopen des logs de PHP-FPM
* voir les FAILED tests des make test ?
* correction des warnings du make install de PEAR 1.10 ?
* voir si on peut optimiser la phase de build en fonction du nombre de cores CPU
* voir s'il faut builder pour autre chose que amd64 (arm par ex)
* déployer sur prephp7a1 et tester
* déployer sur (https://github.com/Epiconcept-Paris/infra-packages-check)
