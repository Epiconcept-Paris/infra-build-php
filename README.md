# infra-build-php
Usine à paquets PHP spécifiques Epiconcept sur Debian jessie/stretch

## Build et tests d'une nouvelle version

````
./mk.sh <version-PHP> [ <version-Debian> ]
````

version-PHP est sous la forme x.y.z, où x = [57]
version-Debian est sous la forme numérique n, par défaut la plus récente gérée

./mk.sh sans arguments affiche la liste des dernières versions disponibles de PHP et celle des versions gérées de Debian

Les packages résultants sont produits dans debian/<version-Debian>/dist (répertoire partagé avec le container docker)
Les logs du build et des tests sont dans debian/<version-Debian>/dist/.logs-<version-PHP>/

## Mise au point

Elle se fait en créant un fichier .norun (vide) dans le répertoire du script mk.sh
Le script affiche alors les commandes docker à lancer au lieu de les exécuter,
ainsi que les commandes bash à lancer pour le build et les tests

Il est possible de sauter le "make test" du build en créant de même un fichier php/.notest
