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

Les packages résultants sont produits dans ````debian/\<version-Debian>/dist```` (répertoire partagé avec le container docker) \
Les logs du build et des tests sont dans ````debian/<version-Debian>/dist/.logs-<version-PHP>/````

Le nom des packages produits comporte un numéro de build après la _\<version-PHP>_.
Ce numéro de build, contenu dans ````php/<version-majeure-PHP>/<version-PHP>/BUILD_NUM```` est incrémenté automatiquement au premier ````./mk.sh ...```` suivant son dernier commit,
mais ce commit doit être fait manuellement, ce qui vaut validation du build portant ce numéro. \
Il ne faut donc **pas** commiter un BUILD_NUM avant d'avoir validé les packages pour la production.

Dans le cas **anormal** ou il serait nécessaire de refaire un build d'un certain numéro, on peut procéder ainsi:
* supprimer le BUILD_NUM en cours avec un ````git rm --cached php/<version-majeure-PHP>/<version-PHP>/BUILD_NUM````
* creer le BUILD_NUM désiré
* lancer le build/tests
* rétablir le BUILD_NUM avec un ````git reset HEAD php/<version-majeure-PHP>/<version-PHP>/BUILD_NUM````

## Mise au point

Elle se fait en créant un fichier ````.norun```` (vide) dans le répertoire du script mk.sh : ````>.norun```` \
Le script affiche alors les commandes docker à lancer au lieu de les exécuter,
ainsi que les commandes bash à lancer pour le build et les tests

Il est possible de sauter le "make test" du build en créant de même un fichier ````php/.notest````.
