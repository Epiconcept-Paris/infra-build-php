# infra-build-php

Fournil à paquets PHP spécifiques à Epiconcept pour les versions suivantes de Debian Linux:
* 8 `jessie`
* 9 `stretch`
* 10 `buster`
* 11 `bullseye`
* 12 `bookworm`

Sont gérées :
* Les versions 5.2, 5.6, 7.1, 7.4, 8.1, 8.2 de PHP (au 1er août 2024),
  parfois pas sur toutes les versions de Debian Linux
* deux types de *build*s des paquets : développement (avec tests et mise au point) et production
* la mise à jour d'un dépot APT avec les paquets de production
* la fabrication automatique des *build*s à parution des nouvelles *release*s des versions Majeur.mineur de PHP connues


## Table des matières
* [Installation](#setup)
* [Arborescence des fichiers](#arbo)
* [Build et tests d'une nouvelle release](#bld)
* [Le script `bake`](#bakes)
* [Mise au point](#map)
* [Test de multiples versions](#multv)
* [Versions de développement et de production](#devprod)
* [Builds automatiques](#autob)
* [Les scripts auxiliaires (`bin/`)](#bins)
* [Ajout d'une version de PHP](#phpadd)
* [Ajout d'une version de Debian](#debadd)
* [Compilations d'extensions](#ecomp)
* [Containers `docker` auxiliaires](#xdock)
* [Notes](#hnote)


## <a name="setup">Installation

Le fonctionnement du fournil nécessite :
* `docker-ce` fonctionnel
  Il peut avoir été installé depuis le dépôt APT de `docker` :
  ```console
  $ cat /etc/apt/sources.list.d/docker.list
  deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian bullseye stable
  ```
* `curl` installé (`sudo apt install curl`)
* un compte utilisateur-système de développement (par exemple `dev`) avec accès sudo à `root`
* un compte utilisateur-système `php` 
* les droits pour `dev` d'exécuter des commandes comme `php` :
  ```console
  dev:~$ sudo cat /etc/sudoers/dev-php
  # Allow 'dev' to run without password any command as 'php'
  dev ALL = (php) NOPASSWD: ALL

  dev:~$ sudo -iu php
  php:~$ id
  uid=1004(php) gid=1004(php) groups=1004(php),27(sudo),33(www-data),998(docker),1002(dev)
  php:~$ exit
  dev:~$
  ```
* d'avoir exécuté en tant qu'utilisateur `dev` :
  ```console
  dev:~$ cd <répertoire parent du dépôt 'git'> # par exemple `cd projects`
  dev:~/projects$ git clone "https://github.com/Epiconcept-Paris/infra-build-php.git"
  dev:~/projects$ cd
  dev:~$ sudo -iu php
  php:~$ cd work # (par exemple)
  php:~/work$ git clone /home/dev/projects/infra-build-php
  php:~/work$ cd
  php:~$ ln -s work/infra-build-php php-prod	# lien symbolique utilisé par update.sh
  php:~$ mkdir php-debs	# Répertoire collatéral à php-prod, requis par le script savedist.sh
  ```
* le droit pour `php` d'exécuter la commande `bin/defroute` :
  ```console
  dev:~$ sudo cat /etc/sudoers/dev-php
  # Allow 'php' to run bin/defroute without password
  php ALL = (root) NOPASSWD: /home/php/php-prod/bin/defroute

  ```


## <a name="bld">Build et tests d'une nouvelle *release*

Ils se font en exécutant le script `bake` situé dans le répertoire principal (au même niveau que les répertoires `debian`, `php`, `tools` et `multi`) :
```console
./bake [ <version-Debian> ] [ <version-PHP> ... ]
```
builde et teste la version _\<version-PHP>_ pour _\<version-Debian>_.  

_\<version-PHP>_ est de la forme :
* _Maj_**.**_Min_ ou
* _Maj_**.**_Min_**.**_Rel_ ou
* _Maj_**.**_Min_**.**_Rel_**-**_Bld_ (voir ci-dessous pour le numéro de *build* _Bld_)
Par défaut, `bake` prend en compte toutes les versions _Maj_**.**_Min_ gérées pour _\<version-Debian>_. Actuellement, _Maj_ = 5, 7 ou 8, le fournil étant prévu pour l'instant jusqu'à _Maj_ = 9 inclus.

_\<version-Debian>_ est sous la forme numérique _n_, par défaut toutes les versions gérées.

On désigne ci-après par *release* la combinaison _Maj_**.**_Min_**.**_Rel_, qui est fournie par le [projet PHP](https://www.php.net).  
On désigne ci-après par *build* le résultat du fonctionnement du script `bake`, c'est à dire le jeu de paquets Debian produits, aussi bien que le déroulement lui-même des processus de build et de tests dans les container `docker` correspondants.  
Normalement, le terme *version* est réservé à la combinaison _Maj_**.**_Min_ (le terme *version-majeure* désignant quant à lui _Maj_ isolément), mais il peut arriver que l'on désigne une *release* ou un *build* du terme de *version*.  

Le projet `docker` comporte une phase de `build` des containers, phase qu'il ne faut pas confondre avec les *build* des  versions PHP : après qu'un container ait été construit lors de la phase `build` de `docker`, c'est au cours du fonctionnement de ce container (dans la phase `run`) qu'un *build*  PHP sera produit.

Le *build* (fabrication des paquets Debian) se déroule dans un container `docker` « de build » et les *tests* (de ces paquets Debian) dans un deuxième container `docker` de « tests ».
Les *tests* consistent à installer les paquets PHP (y compris intégrés à un serveur Web `Apache` pour ceux qui le nécessitent) et à demander l'exécution de la fonction `phpinfo()`.
NOTE: la phase de *build* comprend elle même un jeu de tests extensifs des fonctions de PHP (activés par un `make test` dans le script `php/run/build`) qu'il ne faut pas confondre avec les simple tests d'installation de fonctionnement réalisés dans le container de *tests*.

#### Exemples d'utilisation de `bake` :
```console
./bake 8 5.2.17
```
builde et teste la *release* 5.2.17 pour Debian jessie.

```console
./bake 7.4
```
builde et teste la dernière *release* disponible de PHP 7.4 pour toutes les _\<version-Debian>_ gérées.
```console
./bake mk
```
builde et teste toutes les dernières *release*s disponibles de PHP (ainsi que les cibles spéciales `tools` et `multi`, voir ci-dessous) pour toutes les _\<version-Debian>_ gérées. Pour chaque build, le script de pilotage `bake` appelle les scripts `php/bake`, `tools/bake`, ou `multi/bake`.

Les packages résultants sont produits dans le répertoire `debian/<version-Debian>/dist/<release-PHP>-<BUILD_NUM>`, qui est partagé avec le container `docker` (voir [Arborescence des fichiers](#arbo)).  
Les logs du build et des tests sont dans le répertoire `debian/<version-Debian>/dist/<release-PHP>-<BUILD_NUM>/.logs`.

Le nom des packages produits comporte, on l'a vu, un *numéro de build* après la _\<release-PHP>_. Ce numéro de build est contenu dans le fichier `php/<version-majeure-PHP>/<release-PHP>/BUILD_NUM`, qui peut être facilement modifié en passant un build complet à `bake`:
```console
./bake 7.4.33-2
```
ou en modifiant le fichier `BUILD_NUM` directement.  
`bake` signale une différence inattendue (autre qu'un incrément de 1) entre le contenu de `php/<version-majeure-PHP>/<release-PHP>/BUILD_NUM` à son lancement et la nouveau numéro de build passé dans l'argument.

## <a name="bakes">Le script `bake`
Le script bake admet un nombre quelconque d'arguments:
- des cibles : des _\<version-PHP>_ ou les cibles spéciales `tools` ou `multi`. Comme indiqué ci-dessus, les _\<version-PHP>_ sont admises sous trois formes :
  * _Maj_**.**_Min_ (*version*),
  * _Maj_**.**_Min_**.**_Rel_ (*release*) ou
  * _Maj_**.**_Min_**.**_Rel_**-**_Bld_ (*build*),
  par exemple : `7.4`, `7.4.9` ou `7.4.9-2`.

  Pour la forme _Maj_**.**_Min_, `bake` recherche la dernière *release* connue (sur Internet, ou en local si pas d'accès réseau).
  La forme _Maj_**.**_Min_**.**_Rel_**-**_Bld_ permet de préciser un numéro de build à créer (ce qui permet de changer aisément le numéro de build d'une *release* PHP) ou à supprimer (pour limiter la suppression à ce build précis)
- un mode : `mk` ou `rm`, par défaut `mk` si le mode n'est pas spécifié avant la première cible
- un filtre : une _\<version-Debian>_ spécifique (sous forme numérique), par défaut aucune version spécifique, c'est à dire toutes les versions de Debian gérées pour la *version* de PHP choisie.
  Le filtre spécial `-` est également reconnu, pour revenir à la valeur par défaut (toutes les versions) après avoir précédemment sélectionné une ou plusieurs version(s) spécifique(s).

Un mode ou un filtre restent actifs sur le reste de la ligne de commande jusqu'au prochain mode ou filtre (respectivement). Ainsi :
```console
./bake 8 5.2 - 5.6 9 7.0 - 7.1 7.4
```
lance s'il y a lieu (`mk` par défaut) le build des versions 5.2, 5.6, 7.1 et 7.4 pour `jessie`(8) et des versions 5.6, 7.0, 7.1 et 7.4 pour `stretch`(9). Autre exemple :
```console
./bake rm 7.4.8 mk 7.4
```
supprime tous les *build*s 7.4.8-\* (de toutes les _\<version-Debian>_) et lance le *build* de la dernière version 7.4 pour toutes les _\<version-Debian>_.

La cible spéciale `tools` gère le build ou la suppression des packages du répertoire `tools/` en appelant le script `tools/bake`

La cible spéciale `multi` gère le build, la suppression ou la reconfiguration de l'image `docker` de tests multiples (voir ci-dessous). Elle demande en arguments les _\<version-PHP>_ à utiliser (sous leurs 3 formes admises, voir ci-dessus), dont le build sera lancé si nécessaire.

Enfin, `bake` admet également des arguments uniques spéciaux :
```console
./bake ls
```
affiche la liste des distributions (build) PHP existantes.
```console
./bake ver
```
affiche les listes :
* des dernières *release*s de PHP connues (sur Internet ou en local) et
* des versions de Debian Linux gérées.
```console
./bake latest
```
affiche seulement la liste des dernières *release*s de PHP coonues.
```console
./bake fetch
```
est apparenté à `./bake latest` ci-dessus : le code-source des dernières *release*s parues de PHP est téléchargé, mais aucun build n'est lancé.

```console
./bake help
```
affiche l'aide résumée de `bake`.


## <a name="map">Mise au point

Elle se fait en créant un fichier `.norun` (vide) dans le répertoire principal (où se trouve le répertoire `debian`) : `>.norun` ou `touch .norun`\
Les scripts affichent alors les commandes `docker` à lancer au lieu de démarrer les containers. Un container `docker` une fois démarré, la  commande bash à lancer pour le build ou les tests est affichée au lieu d'être exécutée.

Il est possible de sauter le "make test" du build PHP en créant de même un fichier (vide) `php/.notest`.

Enfin, on peut également créer un fichier `.debug` (vide), qui :
* active des traces supplémentaires dans le container de *build* et
* crée des logs (et sauvegardes de fichiers) supplémentaires dans le répertoire `debian/<version-Debian>/dist/<release-PHP>-<BUILD_NUM>/.debug`
* place l'arborescence de /usr/src/php du container dans `debian/<version-Debian>/dist/<release-PHP>-<BUILD_NUM>/.debug/php`


## <a name="multv">Test de multiples versions

### Préparation (build) d'une image `docker`

Une fois qu'au moins deux versions de PHP (>= 5.6) ont été compilées, différant par leur versions Majeure et mineure, il est possible de préparer un container `docker` (de version Debian >= 9 (`stretch`) pour les tester simultanément avec PHP FPM :
```console
./bake [ <version-Debian> ] multi <version-PHP> [ <version-PHP> ...]
```
_\<version-Debian>_ est sous la forme numérique _n_, par défaut toutes les versions depuis `stretch` (Debian 9) jusqu'à la plus récente gérée (pour l'instant, la version 12 `bookworm`).

_\<version-PHP>_ est sous une des trois formes :
* _Maj_**.**_Min_,
* _Maj_**.**_Min_**.**_Rel_ ou
*  _Maj_**.**_Min_**.**_Rel_**-**_Bld_
où _Bld_ est le numéro du build de la version PHP, qui sera lancé s'il n'existe pas.

Exemple :
```console
./bake 10 multi 5.6.38-2 7.1.22 7.4
```
Le script `multi/bake`, appelé par `./bake` crée si nécessaire le répertoire `debian/<version-Debian>/multi` (partagé avec le container `docker`) avec 3 sous répertoires :
* `pkgs` qui contient les packages Debian `-cli` et `-fpm` (et `-mysql` s'il existe) de chaque _\<version-PHP>_
* `www` qui contient le `DocumentRoot` commun aux différentes _\<version-PHP>_ et qui est partagé avec le host comme un volume `docker` séparé. Coté host, le répertoire peut être un lien symbolique.
* `logs` qui contiendra les logs de build de l'image `epi-multi-php:<version-Debian>` (dans notre exemple `epi-multi-php:buster`) et éventuellement les logs de run du container correspondant.

Puis le script `multi/bake` builde si nécessaire l'image `docker` et affiche la commande pour lancer le container en mode background, sauf pour la mise au point (`.norun`, voir ci-dessous) pour laquelle la commande affichée lancera le container en mode interactif.
Si la variable d'environnement `MultiRun` est assignée (par exemple : `MultiRun=y`), le lancement en mode background se fera automatiquement, pour la version la plus récente de Debian si plusieurs versions de `multi` sont buildées.

### Exécution (run) du container

Lorsque le container est lancé, depuis le script principal `/opt/multi/start` du container, les packages de `pkgs` sont installés et un `VirtualHost`est automatiquement configuré pour chacune des _\<distrib-PHP>_ de ces packages.
Puis `apache2` est lancé, dans notre exemple sur le port 80 pour 3 `VirtualHost` : `php56.epiconcept.tld`, `php71.epiconcept.tld` et `php72.epiconcept.tld`, qu'il faudra déclarer dans un DNS ou dans le fichier `hosts` du client de test.  
Il est possible de changer le domaine par défaut `epiconcept.tld` de l'image `docker` en exportant avant le build la variable d'environnement `MultiDomain` ou en modifiant avant le run la variable `Domain=` du fichier `srvconf` (au même niveau que le répertoire `pkgs`).
De même, il est également possible de modifier le port TCP par défaut (`80`) en exportant la variable d'environnement `MultiPort` ou en modifiant la variable `Port=` du fichier `srvconf`.
Exemple:
```console
export MultiDomain=voozanoo.net Multiport=81 MultiRun=y
```

Les `VirtualHost` sont créés à partir d'un fichier template `siteconf.in` (au même niveau que les 3 répertoire `pkgs`, `logs` et `www`).
Dans ce fichier template, les macros `%Maj%` et `%Min%` seront automatiquement remplacées respectivement par les numéros de version majeure et mineure de chaque _\<distrib-PHP>_ placée dans `pkgs`.
Et les macros `%Port%` et `%Domain%` seront automatiquement remplacées par les valeurs de `Port=` et `Domain=` du fichier `srvconf`, qui prend en compte au build les valeurs éventuelles des variables d'environnement `MultiPort=` et `MultiDomain=`.
Si le fichier `srvconf` n'existe pas, il sera créé au build et modifiable par la suite avant chaque `run`
De même, si le fichier template `siteconf.in` n'existe pas, une version par défaut sera créée, modifiable par la suite.

### Exécution autonome du container de versions multiples

Il faut noter que l'image `docker` (`epi-multi-php:buster` dans notre exemple) est indépendante des _\<distrib-PHP>_ testées et de son propre système de build : le script `start` du container déduit les _\<distrib-PHP>_ et par suite les `VirtualHost`, du nom des packages `.deb` dans le répertoire `pkgs`. Pour cette raison, l'image n'est pas recréée à chaque lancement de `multi/bake`, il faut la supprimer explicitement, dans notre exemple par `./bake rm multi`.

Pour utiliser l'image `docker` (`epi-multi-php:buster` dans notre exemple) séparément de son système de build, il faut lui fournir un répertoire partagé (par exemple `fpm`) de structure :
```
fpm
├── pkgs/
│   ├── epi-php-…_amd64.deb
│   └── epi-php-…_amd64.deb
├── srvconf
├── logs/
└── go
```
dans laquelle seuls `pkgs` (et son contenu) et `srvconf` ont des noms imposés.
Les packages `epi-php-…_amd64.deb` de `pkgs` indiquent les _\<distrib-PHP>_ choisies.
Le sous-répertoire `logs` peut être absent et sera créé au besoin.
Le fichier `srvconf` contient par exemple :
```
Port='81'
Domain='epiconcept.tld'
IpSite='http://ipaddr.free.fr'
```
La variable IpSite, requise, est l'URL (externe sur Internet !) d'une page PHP contenant:
``` php
<?php
$Ip = $_SERVER['REMOTE_ADDR'];
$Hn = gethostbyaddr($Ip);
echo "$Ip\n$Hn\n";

```
qui renvoie par `curl -sSL $IpSite` deux lignes de texte:
```
<adresse-IP>
<reverse-lookup-hostname>
```
Le script `go` est une copie de `debian/10/multi/run`.

Si l'on suppose alors une arborescence web quelconque :
```
path
└── to
    └── web
        └── site
            ├── …
            └── index.php
```
la commande
```console
fpm/go path/to/web/site
```
lance l'image docker `epi-multi-php:buster` dans un container qui active Apache/FPM avec toutes les versions PHP définies par les paquets dans `fpm/pkgs`.

Enfin, le script `multi/bake`, comme le script `php/bake`, reconnait dans le répertoire principal le fichier `.norun` pour permettre la mise au point.


### Déploiement sur un serveur pour tests de FPM

Pour déployer sur un serveur un container `docker` de test FPM, il faut :

* sauvegarder l'image `docker` de `multi` pour la bonne version de Debian
  Par exemple, pour une `stretch` :
  ```console
  docker save epi-multi-php:stretch | bzip2 >epi-multi-php_stretch.tbz
  ```
* sauvegarder le répertoire `pkgs`, le script `run` et le fichier `srvconf` de `debian/9/multi` :
  ```console
  tar cjCf debian/9/multi fpm-deb9.tbz pkgs srvconf run
  ```
* installer si nécessaire `docker-ce` sur le serveur cible

* restaurer l'image docker :
  ```console
  bunzip2 < epi-multi-php_stretch.tbz | docker load
  ```
* restaurer le répertoire `pkgs` et autres, par exemple dans /opt/fpm
  ```console
  mkdir /opt/fpm
  tar xCf /opt/fpm fpm-deb9.tbz
  ```
* modifier selon les besoins le contenu de `pkgs` (suppression) et `srvconf` (modification)

* lancer le script `run` sur le `DocumentRoot` de son choix, par exemple `/var/www/html` :
  ```console
  /opt/fpm/run /var/www/html
  ```
  C'est prêt ! Bon tests :-)


## <a name="devprod"> Versions de développement et de production

Depuis juillet 2022, les script bake ont été augmentés pour utiliser des images `docker` différentes selon l'environnement dans lequel a été cloné ce dépot `git` :

* avec l'identité de l'utilisateur-système spécial `php` pour la génération des paquets Debian de `production`
* avec l'identité d'un autre utilisateur-système quelconque pour la génération de paquets dits de `développement`

Les paquets Debian générés sont identiques, mais leur génération utilise des containers `docker` dont les images portent des noms différents :
* `epi-build-php`, `epi-tests-php`, `epi-tools` et `epi-multi-php` pour l'utilisateur-système `php`
* `dev-build-php`, `dev-tests-php`, `dev-tools` et `dev-multi-php` pour un autre utilisateur-système

Cette séparation permet de développer un nouveau *build* pour une *release* donnée `<Maj>.<min>.<rel>` de PHP sans affecter le code source ni les images `docker` de la version de production.

Le dépôt `git` de l'utilisateur-système développeur a pour origine le dépôt `github` [infra-build-php](https://github.com/Epiconcept-Paris/infra-build-php), alors que le dépôt `git` de l'utilisateur `php` a pour origine le répertoire local du dépôt `git` de l'utilisateur développeur.  
En conséquence, il est inutile (et même déconseillé) de faire des modifications dans le dépot `git` de l'utilisateur-système `php` car il n'est pas possible de faire ensuite un `git push`.  
En effet, `git` ne permet des `git push` que vers des dépôts `à nu` (`bare`), c'est à dire qui ne soient PAS associés à un répertoire de travail. C'est le cas des dépôts sur `github`.
Les modification au dépôt `git` de ce fichier `README.md` doivent donc être faites uniquement dans la dépôt local de l'utilisateur-système développeur (`dev` dans nos exemples).


## <a name="autob"> Builds automatiques

Elle se fait avec le script `update.php` lancé par cron avec par exemple cette `crontab` (`/etc/cron.d/phpbuild`):
```
MAILTO='c.girard@epiconcept.fr'
MAILFROM='cty1@epiconcept.fr'

20 1 * * * dev infra-build-php/update.sh | mail -Es "$(hostname) PHP build(s) of new version(s)" -a "From: $MAILFROM" $MAILTO

```
Le script `update.php` fonctionne en deux instances, la première appelant la seconde.

La première instance (sous l'identité de l'utilisateur-système développeur (ici `dev`) effectue les taches suivantes:
* obtention de la liste des *release*s PHP plus récentes que celles de notre dépôt `git`
* les fichiers `BUILD_NUM` de ces *release*s plus récentes sont ajoutées au dépôt par un `git commit`
* *build* de chacune de ces *releases* et ajout dans une liste de production si le *build* s'effectue avec succès
* si la liste de production n'est pas vide, appeler la deuxième instance avec l'identité de l'utilisateur-système `php` en lui passant les éléments de la liste en arguments
* la deuxième instance retourne les *releases* qui lui ont été passées, avec indication de leur succès ou échec
* (envoyées en fait en pré-production) est ajouté au dépôt `git`de l'utilisateur-système développeur

La deuxième instance (sous l'identité de l'utilisateur-système `php`) effectue les taches suivantes:
* *build* de chacune des releases en retenant leur status de fin (succès ou échec)
* Lancement du script savedist.sh qui va automatiquement détecter les nouveaux packages Debian générés et les sauver dans le répertoire `../php-debs` collatéral au répertoire `php-prod` (voir [Installation](#setup))

## <a name="bins"> Les scripts auxiliaires (`bin/`)

### `aptsrv` Démarrage et arrêt d'un serveur de dépôt APT local
Ce script a été conçu pour pouvoir continuer à faire des *build*s pour Debian 8 (`jessie`) bien que les clés GPG standard dans cette version de Debian aient expiré en 2023.  
Il utilise le module `http.server` de `python3` pour gérer un dépôt APT local (ici `debian/8/repo`) à partir des fichiers `repo-*.txz` se trouvant dans la répertoire de la version Debian (ici `debian/8`).  
Le script est automatiquement lancé et arrêté par `bake` et ne dépend en principe pas de la version Debian.

### `defroute` Ajout et supprime la route réseau de sortie
Ce script est utilisé par le script `send.sh` pour ouvrir et fermer la route réseau ($GwIP dans `bin/defroute`) pour l'envoi des fichiers au serveur APT externe ($Srv dans le script `send.sh,` qui utilise `rsync` et `ssh`)

### `run` Script de filtre SSH sur le serveur Web de dépôt apt
Ce script est destiné à être installé sur le serveur APT externe pour filtrer les commandes reçues par `rsync` ou `ssh`.
Son installation est expliquée en détail dans le commentaire du script.

### `phpcache` Gestion des fichiers de `php/` ignorés par `git`
Ce script permet de lister, vérifier l'intégrité, sauver et supprimer les fichiers sources des *release*s  et des extensions de PHP qui ont été utilisées dans les *build*s, afin de pouvoir en disposer hors-ligne au besoin.
```console
bin/phpcache
bin/phpcache ls
bin/phpcache chk
bin/phpcache save cache00.tbz
bin/phpcache rm
```

### `chkdebs` Verification d'une version PHP pour une version Debian
Ce script vérifie tous les paquets Debian se trouvant dans `debian/*/dists/*/` et confirme leur bonne reconnaissance par la commande `file` comme `Debian binary package ...` en les affichant en vert sur un terminal (les erreurs étant affichées en rouge).


## <a name="phpadd"> Ajout d'une version de PHP

Ce travail est difficile à automatiser et ne l'a pas été.
Il varie évidemment selon qu'il s'agit d'une nouvelle version-majeure de PHP (par exemple PHP 8) ou d'une nouvelle version mineure (par exemple la 8.2 après la 8.1).
A titre d'exemple, voici les fichiers impactés par l'ajout (commit 09edf266) de la version majeure PHP 8 (pour PHP 8.1.5):
```
debian/8/Dockervars.sh
debian/9/Dockervars.sh
debian/9/mkre
debian/10/Dockervars.sh
debian/10/mkre
debian/11/Dockervars.sh
debian/11/mkre
php/8/Dockervars.sh
php/8/8.1.5/BUILD_NUM
php/8/files
php/8/hooks/apcu.sh
php/8/hooks/apcu_bc.sh
php/8/hooks/mcrypt.sh
php/8/hooks/oauth.sh
php/8/hooks/ssh2.sh
php/pkgs/00-cli/top/DEBIAN/control
php/pkgs/02-mod/install
php/pkgs/04-phpdbg/top/DEBIAN/control
php/run/build
php/bake

```

Il faut au minimum:
* créer un répertoire `php/<version-majeure>` et y placer `Dockervars.sh`, les répertoires `files` et `hooks` et un premier fichier `BUILD_NUM`
* mettre à jour les fichiers `debian/*/mkre` pour prendre en compte la nouvelle version
* mettre à jour les fichiers `debian/*/Dockevars*.sh pour ajouter éventuellement des nouvelles librairies
* prendre en compte ces nouvelles librairies dans le nouveau `php/<version-majeure>/Dockervars.sh`
* mettre à jour `php/run/build` pour ajouter la nouvelle version dans `$SupVer`
* mettre à jour les fichiers `top/DEBIAN/control` et éventuellement les fichiers `install` dans le répertoire `php/pkgs/`


## <a name="debadd"> Ajout d'une version de Debian

Ce travail est encore plus incertain que l'ajout d'une version majeure de PHP.
Toutefois, lors de l'ajout de Debian 12, seuls un petit nombre de fichiers ont été ajoutés ou modifiés :

```
debian/12/Dockervars.sh
debian/12/mkre
debian/12/name
php/run/bin/icu-config
README.md
```


## <a name="ecomp"> Compilations d'extensions

Elle se fait en lançant le script `dev/debrun` :

```console
$ dev/debrun bookworm
Building the 'extdev:bookworm' image...
Running the 'extdev-bookworm' container
Run:
    setup <Maj>.<min>   # to install epi-php packages for PHP version <Maj>.<min>
    ext <ext-tag>       # to compile and install a PECL PHP extension
```



## <a name="xdock"> Containers `docker` auxiliaires

### `ubuntu` Tests des paquets Debian 11 sur Ubuntu 20.04 LTS (focal)

### `docker` Essais de CGD avec Apache et FPM

### `tests` Container de tests des dépendances de paquets


## <a name="arbo">Arborescence des fichiers

<details>
<summary>Déplier / replier</summary>

```
.
├── bake*		# script principal
├── bin/		# Utilitaires
├── debian/		# Versions Debian
│   ├── 8/
│   │   └── dist/	# Répertoires de builds des paquets Debian 8
│   ├── 9/
│   │   └── dist/	# Répertoires de builds des paquets Debian 9
│   ├── 10/
│   │   └── dist/	# Répertoires de builds des paquets Debian 10
│   ├── 11/
│   │   └── dist/	# Répertoires de builds des paquets Debian 11
│   └── 12/
│       └── dist/	# Répertoires de builds des paquets Debian 12
│
├── php/		# Versions PHP, fichiers associés et spécifications des paquets
│   ├── lib/
│   ├── 5/		# Sources et fichiers spécifiques pour builds de PHP 5
│   │   ├── Dockervars.sh	# Ajout des fichiers spécifiques au container
│   │   ├── files/	# Fichiers communs à toutes les version de PHP 5
│   │   │   ├── 5.2/	# Fichiers spécifiques à PHP 5.2
│   │   │   └── 5.6/	# Fichiers spécifiques à PHP 5.6
│   │   └── hooks/	# Extensions à run/build
│   │
│   ├── 7/		# Sources et fichiers spécifiques pour builds de PHP 7
│   │   ├── Dockervars.sh	# Ajout des fichiers spécifiques au container
│   │   ├── files/	# Fichiers communs à toutes les version de PHP 7
│   │   │   └── 7.4/	# Fichiers spécifiques à PHP 7.4
│   │   └── hooks/	# Extensions à run/build
│   │
│   ├── 8/		# Sources et fichiers spécifiques pour builds de PHP 8
│   │   ├── Dockervars.sh	# Ajout des fichiers spécifiques au container
│   │   ├── files/	# Fichiers communs à toutes les version de PHP 8
│   │   └── hooks/	# Extensions à run/build
│   │
│   ├── files/		# Fichiers communs aux verions
│   ├── hooks/		# Extensions à run/build et run/tests
│   ├── pkgs/		# Spécifications des paquets
│   ├── run/
│   │   ├── build*	# Script pilote du container de build
│   │   └── tests*	# Script pilote du container de tests
│   ├── Dockerfile-build.in	# Génération du container de build
│   ├── Dockerfile-tests.in	# Génération du container de tests
│   └── bake*			# Script de build des seuls paquets PHP
│
├── tools/		# Outils annexes, fichiers associés et spécification des paquets
│   ├── Dockerfile.in	# Genération du container de build
│   ├── pkgs/		# Spécifications des paquets
│   ├── run/
│   │   └── build*	# Script pilote du container de tests
│   └── bake*		# Script de build des outils
│
├── multi/		# Container gérant un serveur Apache avec FPM et de multiples versions de PHP
│   ├── Dockerfile.in	# Genération du container
│   ├── mkre		# Filtre des versions Debian pour lesquelles builder le container
│   ├── pkgs/		# Répertoire de collecte des paquets PHP
│   └── bake*		# Script de build du container après collecte des paquets PHP dans debian/*/dist
│
├── dev/		# Container de compilation d'extensions utilisant les paquets epi-dev
│   ├── Dockerfile.in	# Genération du container
│   ├── bin/		# Scripts d'install et de compilation d'extensions
│   ├── etc/		# Extensions connues
│   ├── log/		# Logs du container
│   └── debrun*		# Lancement du container
│
├── docker/		# Essais de CGD avec Apache et FPM
├── tests/		# Container de tests des dépendances de paquets
├── ubuntu/		# Tests des paquets Debian 11 sur Ubuntu 20.04 LTS (focal)
├── attic/		# Vieilleries
├── .debug		# Build en mode debug (conservant l'arbo /usr/src/php hors du container)
├── .gitignore		# Fichiers ignorés par git
├── missing.sh		# Ancien script de vérification des dernière versions
├── savedist.sh*	# Sauvegarde des paquets Debian de production
├── send.sh*		# Envoi à epi
├── update.sh*		# Builds automatiques lancés par cron
└── README.md		# Ce fichier

```
</details>

## <a name="hnote"> Notes

* voir s'il faut gérer le rotate/reopen des logs de PHP-FPM
* voir les FAILED tests des make test ?
* correction des warnings du make install de PEAR 1.10 ?
* voir si on peut optimiser la phase de build en fonction du nombre de cores CPU
* voir s'il faut builder pour autre chose que amd64 (arm par ex)
* déployer sur (https://github.com/Epiconcept-Paris/infra-packages-check)
