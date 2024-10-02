# infra-build-php

Fournil à paquets PHP spécifiques à Epiconcept pour les versions suivantes de Debian Linux :
* 8 `jessie`
* 9 `stretch`
* 10 `buster`
* 11 `bullseye`
* 12 `bookworm`

Sont gérées :
* Les versions 5.2, 5.6, 7.1, 7.4, 8.1, 8.2 de PHP (au 1er août 2024) mais,
  pour certaines versions de PHP, pas sur toutes les versions de Debian Linux
* l'ancienne extension `mysql` sur les versions 7 et 8 de PHP
* deux chaines simultanées de *build*s des paquets :
  - développement (avec tests et mise au point) et
  - production
* la mise à jour d'un dépot APT distant avec les paquets de production
* la fabrication automatique des *build*s de PHP à parution des nouvelles *release*s
  des versions Majeur.mineur de PHP connues


## <a name="toc"> Table des matières </a>
Dans [github](https://github.com/Epiconcept-Paris/infra-build-php), il est possible de passer facilement d'une section de ce document à une autre en utilisant le menu dont l'icone [**☰**] se trouve à droite de la barre juste au dessus de la zone de ce texte.

* [Installation](#setup)
* [Build et tests d'une nouvelle release](#bld)
* [Mise au point](#tune)
* [Test de multiples versions](#multv)
* [Versions de développement et de production](#devprod)
* [Builds automatiques](#update)
* [Les scripts auxiliaires (`bin/`)](#bins)
* [Ajout d'une version de PHP](#phpadd)
* [Ajout d'une version de Debian](#debadd)
* [Compilations d'extensions](#ecomp)
* [Containers `docker` auxiliaires](#xdock)
* [Arborescence des fichiers](#arbo)
* [Notes](#hnote)


## <a name="setup">Installation </a>

Le fonctionnement du fournil nécessite :
* `docker-ce` fonctionnel.  
  Il peut avoir été installé depuis le dépôt APT de `docker` :
  ```console
  $ cat /etc/apt/sources.list.d/docker.list
  deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
    https://download.docker.com/linux/debian bullseye stable
  ```
* `curl` installé (`sudo apt install curl`)
* un compte utilisateur-système de développement (par exemple `dev`) avec accès à `docker` et accès sudo à `root`
* un compte utilisateur-système `php` avec :
  * l'appartenance au groupe `docker` pour avoir le droit d'exécuter la commande `docker`
  * un répertoire SSH (`.ssh`) contenant au minimum la clé privée (par exemple `.ssh/id_rsa`) pour accéder au dépot APT distant des paquets produits et un fichier de configuration SSH (`.ssh/config`) sur le modèle suivant :
    ```
    Host apt
    	Hostname files.epiconcept.fr
    	User epiconcept_build
    ```
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
  php:~$ cd work	# (par exemple)
  php:~/work$ git clone /home/dev/projects/infra-build-php
  php:~/work$ cd
  php:~$ ln -s work/infra-build-php php-prod	# lien symbolique utilisé par update.sh
  php:~$ mkdir php-debs	# Répertoire collatéral à php-prod, requis par le script savedist.sh
  ```
* le droit pour `dev` et `php` d'exécuter la commande `defroute` avec `sudo` sans mot de passe :
  ```console
  dev:~$ sudo cat /etc/sudoers/defroute
  # Allow 'dev' and 'php' to run defroute without password
  dev,php ALL = (root) NOPASSWD: /usr/local/bin/defroute
  dev:~$ 
  ```
* d'avoir installé une `crontab` similaire à celle signalée à la section [Builds automatiques](#update) pour que le script `update.sh` soit exécuté.
* d'avoir créé un répertoire `/space/tmp` avec les permissions 1777, pour le script `send.sh`


## <a name="bld">Build et tests d'une nouvelle *release* </a>

Ils se font en exécutant le script `bake` situé dans le répertoire principal (au même niveau que les répertoires `debian`, `php`, `tools` et `multi`) :
```console
./bake [ <version-Debian> ] [ <version-PHP> ... ]
```
*build*e et teste la version _\<version-PHP>_ pour _\<version-Debian>_.  

_\<version-PHP>_ est de la forme :
* _Maj_**.**_Min_ ou
* _Maj_**.**_Min_**.**_Rel_ ou
* _Maj_**.**_Min_**.**_Rel_**-**_Bld_ (voir ci-dessous pour le numéro de *build* _Bld_)  
Par défaut, `bake` prend en compte toutes les versions _Maj_**.**_Min_ gérées pour _\<version-Debian>_. Actuellement, _Maj_ = 5, 7 ou 8, le fournil étant prévu pour l'instant jusqu'à _Maj_ = 9 inclus.

_\<version-Debian>_ est de la forme numérique _n_, par défaut toutes les versions gérées.

On désigne ci-après par *release* la combinaison _Maj_**.**_Min_**.**_Rel_, qui est fournie par le [projet PHP](https://www.php.net).  
On désigne ci-après par *build* le résultat du fonctionnement du script `bake`, c'est à dire le jeu de paquets Debian produits, aussi bien que le déroulement lui-même des processus de *build* et de *tests* dans les container `docker` correspondants.  
Normalement, le terme *version* est réservé à la combinaison _Maj_**.**_Min_ (le terme *version-majeure* désignant quant à lui _Maj_ isolément), mais il peut arriver que l'on désigne une *release* ou un *build* du terme de *version*.  

*ATTENTION* : Le projet `docker` comporte une phase de `build` des containers, phase qu'il ne faut pas confondre avec les *build* des  versions PHP : après qu'un container ait été construit lors de la phase de `build` de `docker`, c'est au cours du fonctionnement (la phase de `run`) de ce container qu'un *build*  PHP sera produit.

Le *build* (fabrication des paquets Debian) se déroule dans un container `docker` « de *build* » et les *tests* (de ces paquets Debian) dans un deuxième container `docker` « de *tests* ».
Les *tests* consistent à installer les paquets PHP (y compris intégrés à un serveur Web `Apache` pour ceux qui le nécessitent) et à demander l'exécution de la fonction `phpinfo()`.  
NOTE : la phase de *build* comprend elle même un jeu de tests extensifs des fonctions de PHP (activés par un `make test` dans le script `php/run/build`) qu'il ne faut pas confondre avec les simple tests d'installation de fonctionnement réalisés dans le container de *tests*.

### Exemples d'utilisation de `bake` :
```console
./bake 8 5.2.17
```
*build*e et teste la *release* 5.2.17 pour Debian `jessie`.

```console
./bake 7.4
```
*build*e et teste la dernière *release* disponible de PHP 7.4 pour toutes les _\<version-Debian>_ gérées.
```console
./bake mk
```
*build*e et teste toutes les dernières *release*s disponibles de PHP (ainsi que les cibles spéciales `tools` et `multi`, voir ci-dessous) pour toutes les _\<version-Debian>_ gérées.
Pour chaque *build*, le script de pilotage `bake` appelle les scripts `php/bake`, `tools/bake`, ou `multi/bake`.

Les paquets Debian résultants sont produits dans le répertoire de *build* `debian/<version-Debian>/dist/<release-PHP>-<BUILD_NUM>`, qui est partagé avec le container `docker` (voir [Arborescence des fichiers](#arbo)).  
Les logs du *build* et des *tests* sont dans le répertoire `debian/<version-Debian>/dist/<release-PHP>-<BUILD_NUM>/.logs`.

Le nom des paquets Debian produits comporte, on l'a vu, un numéro de *build* après la _\<release-PHP>_. Ce numéro de *build* est contenu dans le fichier `php/<version-majeure-PHP>/<release-PHP>/BUILD_NUM`, qui peut être facilement modifié en passant un *build* à `bake`:
```console
./bake 7.4.33-2
```
ou en modifiant le fichier `BUILD_NUM` directement.  
`bake` signale une différence inattendue (autre qu'un incrément de 1) entre le contenu de `php/<version-majeure-PHP>/<release-PHP>/BUILD_NUM` à son lancement et la nouveau numéro de *build* passé dans l'argument.

### Le script `bake`
Le script bake admet un nombre quelconque d'arguments :
- des cibles : des _\<version-PHP>_ ou les cibles spéciales `tools` ou `multi`. Comme indiqué ci-dessus, les _\<version-PHP>_ sont admises sous trois formes :
  * _Maj_**.**_Min_ (*version*),
  * _Maj_**.**_Min_**.**_Rel_ (*release*) ou
  * _Maj_**.**_Min_**.**_Rel_**-**_Bld_ (*build*),
  par exemple : `7.4`, `7.4.9` ou `7.4.9-2`.

  Pour la forme _Maj_**.**_Min_, `bake` recherche la dernière *release* connue (sur Internet, ou en local si pas d'accès réseau).
  La forme _Maj_**.**_Min_**.**_Rel_**-**_Bld_ permet de préciser un numéro de *build* à créer (ce qui permet de changer aisément le numéro de *build* d'une *release* PHP) ou à supprimer (pour limiter la suppression à ce *build* précis)
- un mode : `mk` ou `rm`, par défaut `mk` si le mode n'est pas spécifié avant la première cible
- un filtre : une _\<version-Debian>_ spécifique (sous forme numérique), par défaut aucune version spécifique, c'est à dire toutes les versions de Debian gérées pour la *version* de PHP choisie.
  Le filtre spécial `-` est également reconnu, pour revenir à la valeur par défaut (toutes les versions) après avoir précédemment sélectionné une ou plusieurs version(s) spécifique(s).

Un mode ou un filtre restent actifs sur le reste de la ligne de commande jusqu'au prochain mode ou filtre (respectivement). Ainsi :
```console
./bake 8 5.2 - 5.6 9 7.0 - 7.1 7.4
```
lance s'il y a lieu (`mk` par défaut) le *build* des versions 5.2, 5.6, 7.1 et 7.4 pour `jessie`(8) et des versions 5.6, 7.0, 7.1 et 7.4 pour `stretch`(9). Autre exemple :
```console
./bake rm 7.4.8 mk 7.4
```
supprime tous les *build*s 7.4.8-\* (de toutes les _\<version-Debian>_) et lance le *build* de la dernière version 7.4 pour toutes les _\<version-Debian>_.

La cible spéciale `tools` gère le *build* ou la suppression des paquets Debian du répertoire `tools/` en appelant le script `tools/bake`

La cible spéciale `multi` gère le `build`, la suppression ou la reconfiguration de l'image `docker` de tests multiples (voir ci-dessous). Elle demande en arguments les _\<version-PHP>_ à utiliser (sous leurs 3 formes admises, voir ci-dessus), dont le *build* sera lancé si nécessaire.

Enfin, `bake` admet également des arguments uniques spéciaux :

```console
$ ./bake ls
```
affiche la liste des *build*s PHP existants dans ce dépôt `git`.  
Sur un terminal, chaque *build* est colorié en vert si tous les paquets semblent valides, en rouge sinon.


```console
$ ./bake ver
```
affiche les listes :
* des dernières *release*s de PHP connues (sur Internet ou en local) et
* des versions de Debian Linux gérées.


```console
$ ./bake latest
```
affiche seulement la liste des dernières *release*s de PHP coonues.


```console
$ ./bake fetch
```
est apparenté à `./bake latest` ci-dessus : le code-source des dernières *release*s parues de PHP est téléchargé, mais aucun *build* n'est lancé.


```console
./bake help
```
affiche l'aide résumée de `bake`.


## <a name="tune">Mise au point d'un *build* </a>

Elle se fait en créant un fichier `.norun` (vide) dans le répertoire principal (où se trouve le répertoire `debian`) : `>.norun` ou `touch .norun`  
Les scripts affichent alors la commande `docker run` à lancer, au lieu de démarrer le container.
Le container `docker` une fois démarré avec cette commande, la commande `bash` à lancer pour le *build* ou les *tests* est affichée au lieu d'être exécutée.  
Une fois qu'elle a été exécutée, on peut ainsi travailler dans le container à la mise au point.
S'il y a certains éléments à 'sortir' du container pour les réintégrer à ce dépôt `git`, on peut les copier dans le répertoire de *build* qui est partagé avec l'option `-v` de `docker run` après le `:` de l'argument de l'option, soit pour PHP le répertoire `/opt/php-mk/dist` interne au container.

Il est possible de sauter le "make test" du *build* PHP en créant de même un fichier (vide) `php/.notest`.

Enfin, on peut également créer dans le répertoire principal un fichier `.debug` (vide), qui :
* active des traces supplémentaires dans le container de *build* et
* crée des logs (et sauvegardes de fichiers) supplémentaires dans le répertoire  
  `debian/<version-Debian>/dist/<release-PHP>-<BUILD_NUM>/.debug`
* place l'arborescence de /usr/src/php du container dans  
  `debian/<version-Debian>/dist/<release-PHP>-<BUILD_NUM>/.debug/php`,  
  ce qui permet de pouvoir y accéder par la suite en dehors du container, et même de relancer le container ultérieurement pour pouvoir continuer la mise au point sans avoir à relancer entièrement le *build*


## <a name="multv">Test de multiples versions </a>

### Préparation (`build`) d'une image `docker`

Après qu'au moins deux versions de PHP (de *version* >= 5.6) ont été compilées, différant par leur versions Majeure et mineure, il est possible de préparer un container `docker` (de version Debian >= 9 `stretch`) pour les tester simultanément avec PHP FPM :

```console
./bake [ <version-Debian> ] multi <version-PHP> [ <version-PHP> ...]
```
_\<version-Debian>_ est sous la forme numérique _n_, par défaut toutes les versions depuis `stretch` (Debian 9) jusqu'à la plus récente gérée (pour l'instant, la version 12 `bookworm`).

_\<version-PHP>_ est sous une des trois formes :
* _Maj_**.**_Min_,
* _Maj_**.**_Min_**.**_Rel_ ou
*  _Maj_**.**_Min_**.**_Rel_**-**_Bld_
où _Bld_ est le numéro du *build* de la version PHP, qui sera lancé s'il n'existe pas.

Exemple :
```console
./bake 10 multi 5.6.38-2 7.1.22 7.4
```
Le script `multi/bake`, appelé par `./bake` crée si nécessaire le répertoire `debian/<version-Debian>/multi` (partagé avec le container `docker`) avec 3 sous répertoires :
* `pkgs` qui contient les paquets Debian `-cli` et `-fpm` (et `-mysql` s'il existe) de chaque _\<version-PHP>_
* `www` qui contient le `DocumentRoot` commun aux différentes _\<version-PHP>_ et qui est partagé avec le host comme un volume `docker` séparé. Coté host, le répertoire peut être un lien symbolique.
* `logs` qui contiendra les logs de build de l'image `epi-multi-php:<version-Debian>` (dans notre exemple `epi-multi-php:buster`) et éventuellement les logs de run du container correspondant.

Puis le script `multi/bake` `build`e si nécessaire l'image `docker` et affiche la commande pour lancer le container en mode background, sauf pour la mise au point (`.norun`, voir ci-dessous) pour laquelle la commande affichée lancera le container en mode interactif.
Si la variable d'environnement `MultiRun` est assignée (par exemple : `MultiRun=y`), le lancement en mode background se fera automatiquement lors du `bake`, pour la version la plus récente de Debian si plusieurs versions de `multi` sont buildées.

### Exécution (run) du container

Lorsque le container est lancé, depuis le script principal `/opt/multi/start` du container, les paquets Debian de `pkgs` sont installés et un `VirtualHost`est automatiquement configuré pour chacune des _\<version-PHP>_ de ces paquets.
Puis `apache2` est lancé, dans notre exemple sur le port 80 pour 3 `VirtualHost` : `php56.epiconcept.tld`, `php71.epiconcept.tld` et `php74.epiconcept.tld`, qu'il faudra déclarer dans un DNS ou dans le fichier `hosts` du client de test.  
Il est possible de changer le domaine par défaut `epiconcept.tld` de l'image `docker` en exportant avant le `build` la variable d'environnement `MultiDomain` ou en modifiant avant le run la variable `Domain=` du fichier `srvconf` (au même niveau que le répertoire `pkgs`).
De même, il est également possible de modifier le port TCP par défaut (`80`) en exportant la variable d'environnement `MultiPort` ou en modifiant la variable `Port=` du fichier `srvconf`.
Exemple :
```console
export MultiDomain=voozanoo.net Multiport=81 MultiRun=y
```

Les `VirtualHost` sont créés à partir d'un fichier template `siteconf.in` (au même niveau que les 3 répertoire `pkgs`, `logs` et `www`).
Dans ce fichier template, les macros `%Maj%` et `%Min%` seront automatiquement remplacées respectivement par les numéros de version majeure et mineure de chaque _\<build-PHP>_ placée dans `pkgs`.
Et les macros `%Port%` et `%Domain%` seront automatiquement remplacées par les valeurs de `Port=` et `Domain=` du fichier `srvconf`, qui prend en compte au `build` les valeurs éventuelles des variables d'environnement `MultiPort=` et `MultiDomain=`.
Si le fichier `srvconf` n'existe pas, il sera créé au `build` et modifiable par la suite avant chaque `run`
De même, si le fichier template `siteconf.in` n'existe pas, une version par défaut sera créée, modifiable par la suite.

### Exécution autonome du container de versions multiples

Il faut noter que l'image `docker` (`epi-multi-php:buster` dans notre exemple) est indépendante des _\<distrib-PHP>_ testées et de son propre système de `build` : le script `start` du container déduit les _\<distrib-PHP>_ et par suite les `VirtualHost`, du nom des paquets `.deb` dans le répertoire `pkgs`. Pour cette raison, l'image n'est pas recréée à chaque lancement de `multi/bake`, il faut la supprimer explicitement, dans notre exemple par `./bake rm multi`.

Pour utiliser l'image `docker` (`epi-multi-php:buster` dans notre exemple) séparément de son système de `build`, il faut lui fournir un répertoire partagé (par exemple `fpm`) de structure :
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
Les paquets `epi-php-…_amd64.deb` de `pkgs` indiquent les _\<distrib-PHP>_ choisies.
Le sous-répertoire `logs` peut être absent et sera créé au besoin.
Le fichier `srvconf` contient par exemple :
```
Port='81'
Domain='epiconcept.tld'
IpSite='http://ipaddr.free.fr'
```
La variable IpSite, requise, est l'URL (externe sur Internet !) d'une page PHP contenant :
``` php
<?php
$Ip = $_SERVER['REMOTE_ADDR'];
$Hn = gethostbyaddr($Ip);
echo "$Ip\n$Hn\n";

```
qui renvoie par `curl -sSL $IpSite` deux lignes de texte :
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


## <a name="devprod"> Versions de développement et de production </a>

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


## <a name="update"> Builds automatiques </a>

Elle se fait avec le script `update.php` lancé par cron, par exemple avec la `crontab` suivante (dans `/etc/cron.d/`, donc avec indication d'un utilisateur système (ici `dev`) :
```console
MAILTO='c.girard@epiconcept.fr'
MAILFROM='binbuild@epiconcept.fr'

15 0 * * * dev build-php/update.sh | mail -Es "$(hostname) PHP build(s) of new version(s)" -a "From: $MAILFROM" $MAILTO
```

La sortie standard (`stdout`) et la sortie d'erreur (`stderr`) de `update.sh` sont sauvées dans un fichier journal `update.log/<AAAA-MM-JJ>` (à la date du jour).
Mais dans le cas où des *build*s sont compilés, un rapport (de succès ou d'échec(s)) est envoyé sur la sortie standard initiale, c'est à dire dans l'exemple ci-dessous, par mail.

Le script `update.sh` fonctionne en deux instances, la première appelant la seconde.

La première instance (sous l'identité de l'utilisateur-système développeur, ici `dev`) effectue les tâches suivantes :
* obtenir la liste des *release*s PHP plus récentes que celles de notre dépôt `git`
* obtenir la liste de nouveaux *build*s non-`commit`és de *release*s existantes
* s'il n'y a pas de nouvelles *release*s ni de nouveaux *build*s, écrire simplement dans le journal la date et le nom de l'utilisateur, et sortir de `update.sh` sans mail
* sinon, ajouter au dépôt par un `git commit` les fichiers `BUILD_NUM` de ces *release*s ou *build*s plus récents
* *build*er chacune de ces *releases* ou nouveau(x) *build*(s) et l'ajouter dans une liste de production si le *build* s'effectue avec succès
* si la liste de production n'est pas vide, appeler la deuxième instance avec l'identité de l'utilisateur-système `php` en lui passant les éléments de la liste en arguments.
  La deuxième instance retourne les *releases* qui lui ont été passées, avec indication de leur succès ou échec
* envoyer par mail un rapport sur chaque *build* qui vient d'être produit pour les différentes versions Debian supportées par chaque *release*, ainsi que sur la sauvegarde locale et l'envoi au dépôt APT des paquets Debian des *build*s
* purger les éléments encombrants des éventuels *build*s trop anciens (image `docker` et éventuel répertoire `.debug/php`)

La deuxième instance (sous l'identité de l'utilisateur-système `php`) effectue les tâches suivantes :
* *build*er chacune des *release*s en retenant leur status de fin (succès ou échec)
* lancer le script `savedist.sh` qui va automatiquement détecter les nouveaux paquets Debian générés et les sauver dans le répertoire `../php-debs` collatéral au répertoire `php-prod` (voir [Installation](#setup)).  
  Ce répertoire `php-debs` est la référence (*master*) des paquets PHP (et associés) générés par ce dépôt `git`, référence qui sert de base à `rsync` dans le script `send.sh` ci-après
* lancer le script `send.sh` qui va envoyer au dépôt APT les nouveaux paquets Debian sauvegardés par la commande `savedist.sh` en synchronisant (`rsync`) tous les paquets Debian de `php-debs` avec le dépôt APT.
  Toute erreur dans le déroulement de ce processus est rapportée dans le mail envoyé par la `crontab` qui appelle le script `update.sh`.
  Il peut en effet arriver que le script `/usr/local/bin/apt_deploy.sh`, lancé sur 'apt' par SSH depuis `send.sh`, retourne le message `Job is already running`, précédant le signalement d'une erreur `(xc=1)`.
  Il faut dans ce cas patienter jusqu'à la prochaine exécution automatique du script sur `apt` du script.

Si un *build* de PHP a échoué, son répertoire de *build* contiendra un fichier témoin `.fail`.
Si le script `update.sh` ne trouve pas de nouvelle version PHP à *build*er, il signalera dans son rapport tous les *build* PHP dont le répertoire de *build* contient ce fichier `.fail`, jusqu'à ce que ce dernier soit supprimé.

## <a name="bins"> Les scripts auxiliaires (`bin/`) </a>

### `aptsrv`: Démarrage et arrêt d'un serveur de dépôt APT local
Ce script a été conçu pour pouvoir continuer à faire des *build*s pour Debian 8 (`jessie`) bien que les clés GPG standard dans cette version de Debian aient expiré en 2023.  
Il utilise le module `http.server` de `python3` pour gérer un dépôt APT local (ici `debian/8/repo`) à partir des fichiers `repo-*.txz` se trouvant dans la répertoire de la version Debian (ici `debian/8`).  
Le script est automatiquement lancé et arrêté par `bake` et ne dépend en principe pas de la version Debian.

### `defroute`: Ajout et supprime la route réseau de sortie
Ce script est utilisé par le script `send.sh` pour ouvrir et fermer la route réseau (`GwIP` dans `defroute`) pour l'envoi des fichiers au serveur APT externe (`Srv` dans le script `send.sh,` qui utilise `rsync` et `ssh`). Il **doit** être copié dans `/usr/local/bin` s'il n'y est pas déjà et le fichier crontab `defroute` doit étre similaire (aux adaptations locales près) à celui indiqué dans l'[Installation](#setup).

### `run`: Script de filtre SSH sur le serveur Web de dépôt apt
Ce script est destiné à être installé sur le serveur APT externe pour filtrer les commandes reçues par `rsync` ou `ssh`.
Son installation est expliquée en détail dans le commentaire du script.

### `phpcache`: Gestion des fichiers de `php/` ignorés par `git`
Ce script permet de lister, vérifier l'intégrité, sauver et supprimer les fichiers sources des *release*s  et des extensions de PHP qui ont été utilisées dans les *build*s, afin de pouvoir en disposer hors-ligne au besoin.
Commandes disponibles :
```console
bin/phpcache			# Affiche une aide résumée
bin/phpcache ls			# Liste des fichiers
bin/phpcache chk		# Vérifie l'intégrité des fichiers
bin/phpcache save cache00.tbz	# Sauvegarde les fichiers
bin/phpcache rm			# Supprime les fichiers
```

### `chkdebs`: Verification des *build*s des versions PHP pour chaque version Debian
Ce script vérifie tous les paquets Debian se trouvant dans `debian/*/dists/*/` et confirme leur bonne reconnaissance par la commande `file` comme `Debian binary package ...` en les affichant en vert sur un terminal (les erreurs étant affichées en rouge).


## <a name="phpadd"> Ajout d'une version de PHP </a>

Ce travail est difficile à automatiser et ne l'a pas été.
Il varie évidemment selon qu'il s'agit d'une nouvelle version-majeure de PHP (par exemple PHP 8) ou d'une nouvelle version-mineure (par exemple la 8.2 après la 8.1).  

### Ajout d'une version-majeure
Il part évidemment des fichiers similaires de la version-majeure précédente.
A titre d'exemple, voici les fichiers concernés par l'ajout (commit 09edf266) de la version-majeure PHP 8 (pour PHP 8.1.5) :
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

### Ajout d'une version-mineure
Le travail est en partie plus simple : en dehors du fichier `BUILD_NUM` de la nouvelle version, il n'y a en général que peu ou pas de fichiers à créer (un patch, par exemple).
A titre d'exemple, voici les fichiers concernés par l'ajout (commit 75223fe0) de la version-mineure PHP 8.2 (pour PHP 8.2.4) :
```
debian/9/mkre
debian/10/mkre
debian/11/mkre
php/8/hooks/mysql.sh
php/8/8.2.4/BUILD_NUM
php/run/build

```
Seul le fichier `php/8/8.2.4/BUILD_NUM` a été créé.

### Résumé des modifications

Indépendamment des difficultés rencontrées, il faut au minimum :
* créer un répertoire `php/<version-majeure>` et y placer `Dockervars.sh`, les répertoires `files` et `hooks` et un premier fichier `BUILD_NUM` dans le répertoire de la _\<version-PHP>_
* mettre à jour les fichiers `debian/*/mkre` pour prendre en compte la nouvelle version
* mettre à jour les fichiers `debian/*/Dockevars*.sh` pour ajouter éventuellement des nouvelles librairies
* prendre en compte ces nouvelles librairies dans le nouveau `php/<version-majeure>/Dockervars.sh`
* mettre à jour `php/run/build` pour ajouter la nouvelle version dans `SupVer=`
* mettre à jour `dev/bin/setup` pour ajouter éventuellement la nouvelle version dans `SupVer=`
* mettre à jour les fichiers `top/DEBIAN/control` et éventuellement les fichiers `install` dans le répertoire `php/pkgs/`


## <a name="debadd"> Ajout d'une version de Debian </a>

Ce travail est encore plus incertain que l'ajout d'une version majeure de PHP.
Ainsi, lors de l'ajout de Debian 12, les fichiers suivants ont été ajoutés ou modifiés :

```
debian/12/Dockervars.sh
debian/12/mkre
debian/12/name
php/5/files/5.6/openssl.patch
php/7/Dockervars.sh
php/7/files/openssl.patch
php/7/hooks/openssl.sh
php/pkgs/00-cli/top/usr/share/lintian/overrides/pkgname
php/pkgs/01-pear/top/usr/share/lintian/overrides/pkgname
php/pkgs/02-mod/top/usr/share/lintian/overrides/pkgname
php/pkgs/03-fpm/top/usr/share/lintian/overrides/pkgname
php/pkgs/04-phpdbg/top/usr/share/lintian/overrides/pkgname
php/run/bin/icu-config
php/run/build
tools/pkgs/00-tools-waitpid/src/waitpid.c
tools/pkgs/01-php-setup/top/usr/share/lintian/overrides/pkgname
savedist.sh
README.md
```

Indépendamment des difficultés rencontrées, il faut au minimum :
* créer le répertoire `debian/<version_Debian>`
* créer dans ce répertoire les fichiers `Dockervars.sh`, `mkre` et `name`. Il est possible de reprendre les fichiers de même nom de la version précédente de Debian en les adaptant
* mettre à jour ce fichier (`README.md`)
* mettre à jour s'il y a lieu les mentions de Debian dans les commentaires de divers fichiers

Pendant la mise au point de la prise en charge de cette nouvelle version, il est possible de désactiver la prise en compte de la version par `update.sh` en créant un fichier vide `.noupd` dans le répertoire de la version (par exemple : `debian/12/.noupd`).


## <a name="ecomp"> Compilations d'extensions (développement) </a>

Pour le cas ou des extensions supplémentaires de PHP seraient nécessaires, le répertoie `dev/` définit un container qui permet de les compiler pour certaines versions de PHP et à partir de Debian 11 `bullseye`.

### Lancement du container
Il se fait par le script `dev/debrun` avec en argument une version *texte* de Debian, par exemple :

```console
$ dev/debrun bookworm
Building the 'extdev:bookworm' image...
Running the 'extdev-bookworm' container
Run:
    setup <Maj>.<min>   # to install epi-php packages for PHP version <Maj>.<min>
    ext <ext-tag>       # to compile and install a PECL PHP extension
```
Le script `dev/debrun` `build`e une image `docker` de développement et lance directement un container `docker` interactif.

Comme l'indique l'aide initiale, il faut d'abord installer une version de PHP parmi celles gérées, soit pour l'instant 7.4 et 8.2 (définiées dans la variable `SupVer=` de `dev/bin/setup`), par exemple :

```console
root@88e944da6b42:/# setup 7.4
Adding Epiconcept's APT repository
Fetching Epiconcept's APT key
Installing epi-php development packages for PHP 7.4 (log to /var/log/extdev/install.out)
Ready to compile PHP extensions
root@88e944da6b42:/#
```

### Compilation d'une extension déjà configurée
Il est alors possible de compiler les extensions déjà configurées, que l'on peut examiner avec :
```console
root@88e944da6b42:/# ext
Usage: ext <PECL-extension>
Known extensions:
    imagick
    event
    ev
root@88e944da6b42:/#
```
(lors de la dernière mise à jour de ce fichier `README.md`)

Il suffit pour cela de lancer la commande `ext` suivie du noms de l'extension, par exemple :
```console
root@88e944da6b42:/# ext ev
Installing package(s) libev-dev (log to /var/log/extdev/install-deb12-7.4.out)
Compiling the ev PHP extension (log to /usr/local/etc/ext/ev/bookworm-7.4/compile.out)
Configuring the ev extension
Extension ev saved to 'etc/ext/ev/bookworm-7.4'
Checking the ev extension:
Additional .ini files parsed => /etc/php/7.4/conf.d/ev.ini,
ev
Installed packages, channel pecl.php.net:
=========================================
Package Version State
ev      1.1.5   stable
event   3.1.4   stable
imagick 3.7.0   stable
root@88e944da6b42:/#
```
Le résultat se trouve dans le même répertoire que le fichier `compile.out`, sous forme de deux fichiers `ev.so` et `ev.ini` qu'il faudra placer respectivement dans `/usr/lib/php/extensions` et dans `/etc/php/<version-PHP>/conf.d"`.  
Pour l'instant (1er août 2024), aucun paquet Debian n'est généré.

### Ajout d'une nouvelle extension
Comme pour les ajouts de version PHP ou de version Debian, le travail est évidemment variable, mais le point de départ est l'utilisation de la commande `pecl install` (disponible après avoir exécuté le script `setup`). Par exemple :
```console
root@88e944da6b42:/# pecl install decimal
...
configure: error: Please reinstall libmpdec
ERROR: `/tmp/pear/temp/decimal/configure --with-php-config=/usr/bin/php-config' failed
```
Il apparait que la compilation de l'extension `decimal` requiert la présence de la librairie `libmpdec`. Comme il s'agit d'une compilation, il faut chercher le paquet Debian de développement de cete librairie, soit `libmpdec-dev`.  
Malheureusement, pour une raison peu claire, ce paquet n'est plus disponible sur Debian `bookworm`, mais la difficulté n'est pas trop grande, car la version `bullseye` de `libmpdec` et de `libmpdec-dev` fonctionne :
```console
root@88e944da6b42:/# cd
root@88e944da6b42:~# curl -sSO "http://ftp.debian.org/debian/pool/main/m/mpdecimal/libmpdec3_2.5.1-1_amd64.deb"
root@88e944da6b42:~# curl -sSO "http://ftp.debian.org/debian/pool/main/m/mpdecimal/libmpdec-dev_2.5.1-1_amd64.deb"
root@88e944da6b42:~# dpkg -i libmpdec3_2.5.1-1_amd64.deb
Selecting previously unselected package libmpdec3:amd64.
(Reading database ... 16442 files and directories currently installed.)
Preparing to unpack libmpdec3_2.5.1-1_amd64.deb ...
Unpacking libmpdec3:amd64 (2.5.1-1) ...
Setting up libmpdec3:amd64 (2.5.1-1) ...
Processing triggers for libc-bin (2.36-9+deb12u8) ...
root@88e944da6b42:~# dpkg -i libmpdec-dev_2.5.1-1_amd64.deb
Selecting previously unselected package libmpdec-dev:amd64.
(Reading database ... 16450 files and directories currently installed.)
Preparing to unpack libmpdec-dev_2.5.1-1_amd64.deb ...
Unpacking libmpdec-dev:amd64 (2.5.1-1) ...
Setting up libmpdec-dev:amd64 (2.5.1-1) ...
root@88e944da6b42:~# pecl install decimal
...
Build process completed successfully
Installing '/usr/lib/php/extensions/decimal.so'
install ok: channel://pecl.php.net/decimal-1.5.0
configuration option "php_ini" is not set to php.ini location
You should add "extension=decimal.so" to php.ini
root@88e944da6b42:~# pecl list
Installed packages, channel pecl.php.net:
=========================================
Package Version State
decimal 1.5.0   stable
root@88e944da6b42:~# 
```

Ca compile ! Il n'y plus qu'à rajouter l'extension `decimal` au fichier /usr/local/etc/ext.conf :
```console
root@88e944da6b42:/# echo -e "decimal\t\tlibmpdec-dev" >>/usr/local/etc/ext.conf
root@88e944da6b42:/# 
```

## <a name="xdock"> Containers `docker` auxiliaires </a>

### `ubuntu/`: Tests des paquets Debian 11 sur Ubuntu 20.04 LTS (`focal`)
Ce container a été créé fin avril 2022 pour mettre au point l'installation de paquets PHP 7.4 d'Epiconcept sur une version 20.04 LTS (`focal`) d'Ubuntu.
Le fichier `ubuntu/README.txt` indique la procédure à suivre pour effectuer l'installation et tester les paquets `epi-php`.

### `docker/apachefpm/`: Essais de CGD avec Apache et PHP-FPM
Ce container résulte des essais sur FPM de CGD fin juillet 2020.

### `tests/`: Container de tests des dépendances de paquets
Ce container a servi de mise au point de tests sur la dépendance des paquets début octobre 2019.  
Il présente l'intérêt de montrer la mécanique minimale de la fabrication bas-niveau de paquets, directement à partir des fichiers avec la commande `dpkg-deb --build` et non à partir de leurs sources avec la commande `dpkg-buildpackage`.


## <a name="arbo"> Arborescence des fichiers </a>

<details open>
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
│       ├── name	# Nom de la version (ici: bookworm)
│       ├── mkre	# Expression régulière de filtre des version PHP
│       ├── dist/	# Répertoires de builds des paquets Debian 12
│       └── .noupd	# Optionnel: update.sh ne prendra pas en compte la version
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
│   ├── files/		# Fichiers communs aux versions
│   ├── hooks/		# Extensions à run/build et run/tests
│   ├── pkgs/		# Spécifications des paquets
│   │   ├── 00-cli/
│   │   │   ├── install*	# Installation du build dans top/ ci-dessous
│   │   │   └── top/
│   │   │       ├── DEBIAN/	# Fichiers liés au paquet et à son ajout / retrait
│   │   │       │   ├── control		# Metadate du paquet (dont dépendances)
│   │   │       │   ├── conffiles	# Fichiers de configuration du paquet
│   │   │       │   ├── postinst	# Actions après install
│   │   │       │   └── prerm		# Actions avant purge
│   │   │       ├── etc/		# Fichiers de configuration
│   │   │       │   └── ...
│   │   │       └── usr/		# Fichiers du paquet
│   │   │           ├── lib/
│   │   │           │   └── ...
│   │   │           └── share		# Fichiers requis par dpkg-deb
│   │   │               ├── doc
│   │   │               │   └── pkgname
│   │   │               │       ├── changelog
│   │   │               │       ├── changelog.Debian
│   │   │               │       └── copyright
│   │   │               └── lintian/overrides/pkgname
│   │   ├── 01-pear/
│   │   │   └── ...
│   │   ├── 02-mod/
│   │   │   └── ...
│   │   ├── 03-fpm/
│   │   │   └── ...
│   │   ├── 04-phpdbg/
│   │   │   └── ...
│   │   ├── 05-mysql/
│   │   │   └── ...
│   │   └── 06-dev/
│   │       └── ...
│   ├── run/
│   │   ├── build*	# Script pilote du container de build
│   │   └── tests*	# Script pilote du container de tests
│   ├── Dockerfile-build.in	# Génération du container de build
│   ├── Dockerfile-tests.in	# Génération du container de tests
│   ├── bake*			# Script de build des seuls paquets PHP
│   └── .notest			# Optionnel: ne pas effectuer au build les tests étendus de PHP
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
│   ├── etc/		# Extensions connues (`etc/ext/*`) et leur configuration (`etc/ext.conf`)
│   ├── log/		# Logs du container
│   └── debrun*		# Lancement du container après build si nécessaire
│
├── ubuntu/		# Container de tests des paquets Debian 11 sur Ubuntu 20.04 LTS (focal)
├── docker/apachefpm/	# Essais de CGD avec Apache et FPM
├── tests/mypkg/	# Container de tests des dépendances de paquets
├── attic/		# Vieilleries
├── update.log/		# Fichiers de log de l'exécution de update.sh (ci-dessous)
├── .gitignore		# Fichiers ignorés par git
├── .norun		# Optionnel: docker ne lance pas (run) les containers, mais affiche la commande
├── .debug		# Optionnel: build en mode debug (conservant l'arbo. php/ hors du container)
├── missing.sh		# Ancien script de vérification des dernières versions
├── savedist.sh*	# Sauvegarde des paquets Debian de production
├── send.sh*		# Envoi au dépôt APT d'Epiconcept
├── update.sh*		# Builds automatiques lancés par cron
└── README.md		# Ce fichier
```
</details>

## <a name="hnote"> Notes </a>

* voir s'il faut gérer le rotate/reopen des logs de PHP-FPM
* voir les FAILED tests des make test ?
* correction des warnings du make install de PEAR 1.10 ?
* voir si on peut optimiser la phase de `build` en fonction du nombre de cores CPU
* voir s'il faut *build*er pour autre chose que amd64 (arm par ex)
* déployer sur (https://github.com/Epiconcept-Paris/infra-packages-check)
