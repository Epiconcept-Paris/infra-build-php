# infra-build-php
Usine à paquets PHP spécifiques Epiconcept sur Debian jessie/stretch

## Build et tests d'une nouvelle version

````
./mk.sh <version-PHP> [ <version-Debian> ]
````
builde et teste la version _\<version-PHP>_ pour _\<version-Debian>_

_\<version-PHP>_ est sous la forme x.y.z, où x = [57] \
_\<version-Debian>_ est sous la forme numérique n, par défaut la plus récente gérée

````./mk.sh```` (sans arguments) affiche la liste des dernières versions disponibles de PHP et celle des versions gérées de Debian

Les packages résultants sont produits dans le répertoire ````debian/\<version-Debian>/dist/<version-PHP>-<BUILD_NUM>````, qui est partagé avec le container docker. \
Les logs du build et des tests sont dans le répertoire ````debian/<version-Debian>/dist/<version-PHP>-<BUILD_NUM>/.logs````

Le nom des packages produits comporte un numéro de build après la _\<version-PHP>_. Ce numéro de build est contenu dans le fichier ````php/<version-majeure-PHP>/<version-PHP>/BUILD_NUM````. Après un ````git commit```` de ce fichier, on peut provoquer un incrément automatique de la valeur de ce dernier ````git commit```` en supprimant le fichier avec un simple :\
````rm php/<version-majeure-PHP>/<version-PHP>/BUILD_NUM````\
On peut aussi bien sur incrémenter manuellement le contenu du fichier.


## Mise au point

Elle se fait en créant un fichier ````.norun```` (vide) dans le répertoire du script mk.sh : ````>.norun```` \
Le script affiche alors les commandes docker à lancer au lieu de les exécuter,
ainsi que les commandes bash à lancer pour le build et les tests

Il est possible de sauter le "make test" du build en créant de même un fichier ````php/.notest````.

Enfin, on peut également créer un fichier ````.debug```` (vide), qui active des traces supplémentaires dans le container de build

## Notes

* Serveur AWS de build : cdt@34.243.220.28
* voir si on peut optimiser la phase de build en fonction du nombre de cores CPU
* voir s'il faut builder pour autre chose que amd64 (arm par ex)
* déployer sur prephp7a1 et tester
* déployer sur (https://github.com/Epiconcept-Paris/infra-packages-check)
