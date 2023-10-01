# infra-build-php
Fournil à paquets PHP spécifiques Epiconcept sur Debian 8 à 12 (jessie/stretch/buster/bullseye/bookworm)

## Installation

* nécessite : `docker` fonctionnel
* `sudo apt install curl`

## Build et tests d'une nouvelle version

Ils se font en exécutant le script `bake` situé dans le répertoire principal (au même niveau que les répertoires `debian`, `php`, `tools` et `multi`) :
```
./bake [ <version-Debian> ] [ <version-PHP> ... ]
```
builde et teste la version _\<version-PHP>_ pour _\<version-Debian>_

_\<version-PHP>_ est sous la forme _Maj_**.**_Min_, _Maj_**.**_Min_**.**_Rel_, ou _Maj_**.**_Min_**.**_Rel_**-**_Bld_ (voir ci-dessous pour le numéro de build _Bld_), par défaut toutes les dernières versions _Maj_**.**_Min_ gérées pour _\<version-Debian>_. Actuellement, _Maj_ = 5 ou 7, le fournil étant prévu jusqu'à _Maj_ = 9.

_\<version-Debian>_ est sous la forme numérique _n_, par défaut toutes les versions gérées.

#### Exemples :
```
./bake 8 5.2.17
```
builde et teste la version 5.2.17 pour Debian jessie.

```
./bake 7.2
```
builde et teste la dernière version disponible de PHP 7.2 pour toutes les _\<version-Debian>_ gérées.
```
./bake mk
```
builde et teste toutes les dernières versions disponibles de PHP (ainsi que les cibles spéciales `tools` et `multi`, voir ci-dessous) pour toutes les _\<version-Debian>_ gérées. Pour chaque build, le script de pilotage `bake` appelle le script `php/bake`, `tools/bake`, ou `multi/bake`.

Les packages résultants sont produits dans le répertoire `debian/<version-Debian>/dist/<version-PHP>-<BUILD_NUM>`, qui est partagé avec le container `docker`. \
Les logs du build et des tests sont dans le répertoire `debian/<version-Debian>/dist/<version-PHP>-<BUILD_NUM>/.logs`

Le nom des packages produits comporte un numéro de build après la _\<version-PHP>_. Ce numéro de build est contenu dans le fichier `php/<version-majeure-PHP>/<version-PHP>/BUILD_NUM`, qui peut être facilement modifié en passant un build complet à `bake`:
```
./bake 7.2.9-2
```
`bake` signale une différence inattendue (autre qu'un incrément de 1) entre le contenu de `php/<version-majeure-PHP>/<version-PHP>/BUILD_NUM` à son lancement et la nouveau numéro de build passé dans l'argument.

## Le script `bake`
Le script bake admet un nombre quelconque d'arguments:
- des cibles : des _\<version-PHP>_ ou les cibles spéciales `tools` ou `multi`. Les _\<version-PHP>_ sont admises sous trois formes : _Maj_**.**_Min_, _Maj_**.**_Min_**.**_Rel_, ou _Maj_**.**_Min_**.**_Rel_**-**_Bld_, par exemple : `7.2`, `7.2.9` ou `7.2.9-2`. Pour la forme _Maj_**.**_Min_, `bake` recherche la dernière release connue (sur Internet ou en local). La forme _Maj_**.**_Min_**.**_Rel_**-**_Bld_ permet de préciser un numéro de build à créer (ce qui permet de changer aisément le numéro de build d'une release PHP) ou à supprimer (pour limiter la suppression à ce build précis)
- un mode : `mk` ou `rm`, par défaut `mk` si le mode n'est pas spécifié avant la première cible
- un filtre : une _\<version-Debian>_ spécifique (sous forme numérique), par défaut aucune version spécifique, c'est à dire toutes les versions gérées. Le filtre spécial `-` est également reconnu, pour revenir à la valeur par défaut (toutes les versions) après avoir précédemment sélectionné une ou plusieurs version(s) spécifique(s).

Un mode ou un filtre restent actifs sur le reste de la ligne de commande jusqu'au prochain mode ou filtre (respectivement). Ainsi :
```
./bake 8 5.2 - 5.6 9 7.0 - 7.1 7.2
```
lance s'il y a lieu (`mk` par défaut) le build des versions 5.2, 5.6, 7.1 et 7.2 pour `jessie`(8) et des versions 5.6, 7.0, 7.1 et 7.2 pour `stretch`(9). Autre exemple :
```
./bake rm 7.2.8 mk 7.2
```
supprime les distributions 7.2.8-\* (de toutes les _\<version-Debian>_) et lance le build de la dernière version 7.2 pour toutes les _\<version-Debian>_.

La cible spéciale `tools` gère le build ou la suppression des packages du répertoire `tools/` en appelant le script `tools/bake`

La cible spéciale `multi` gère le build, la suppression ou la reconfiguration de l'image `docker` de tests multiples (voir ci-dessous). Elle demande en arguments les _\<version-PHP>_ à utiliser (sous leurs 3 formes admises, voir ci-dessus), dont le build sera lancé si nécessaire.

Enfin, `bake` admet également des arguments uniques spéciaux :
```
./bake ls
```
affiche la liste des distributions (build) PHP existantes.
```
./bake ver
```
affiche les listes des dernières versions de PHP connues (sur Internet ou en local) et des versions de Debian Linux gérées.
```
./bake latest
```
affiche seulement la liste des dernières versions PHP coonues.
```
./bake help
```
affiche l'aide résumée de `bake`.



## Mise au point

Elle se fait en créant un fichier `.norun` (vide) dans le répertoire principal (où se trouve le répertoire `debian`) : `>.norun` ou `touch .norun`\
Les scripts affichent alors les commandes `docker` à lancer au lieu de démarrer les containers. Un container `docker` une fois démarré, la  commande bash à lancer pour le build ou les tests est affichée au lieu d'être exécutée.

Il est possible de sauter le "make test" du build PHP en créant de même un fichier (vide) `php/.notest`.

Enfin, on peut également créer un fichier `.debug` (vide), qui active des traces supplémentaires dans le container de build et des logs (et sauvegardes de fichiers) supplémentaires dans le répertoire `debian/<version-Debian>/dist/<version-PHP>-<BUILD_NUM>/.debug`

## Test de multiples versions

### Préparation (build) d'une image `docker`

Une fois qu'au moins deux versions de PHP (>= 5.6) ont été compilées, différant par leur versions Majeure et mineure, il est possible de préparer un container `docker` pour les tester simultanément avec PHP FPM :
```
./bake [ <version-Debian> ] multi <version-PHP> [ <version-PHP> ...]
```
_\<version-Debian>_ est sous la forme numérique _n_, par défaut toutes les versions depuis `stretch` (Debian 9) jusqu'à la plus récente gérée (pour l'instant, la version 12 `bookworm`).

_\<version-PHP>_ est sous une des trois formes _Maj_**.**_Min_, _Maj_**.**_Min_**.**_Rel_ ou  _Maj_**.**_Min_**.**_Rel_**-**_Bld_, où _Bld_ est le numéro du build de la version PHP, qui sera lancé s'il n'existe pas.\
Exemple :
```
./bake 10 multi 5.6.38-2 7.1.22 7.2
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
```
export MultiDomain=voozanoo.net Multiport=81 MultiRun=y
```

Les `VirtualHost` sont créés à partir d'un fichier template `siteconf.in` (au même niveau que les 3 répertoire `pkgs`, `logs` et `www`).
Dans ce fichier template, les macros `%Maj%` et `%Min%` seront automatiquement remplacées respectivement par les numéros de version majeure et mineure de chaque _\<distrib-PHP>_ placée dans `pkgs`.
Et les macros `%Port%` et `%Domain%` seront automatiquement remplacées par les valeurs de `Port=` et `Domain=` du fichier `srvconf`, qui prend en compte au build les valeurs éventuelles des variables d'environnement `MultiPort=` et `MultiDomain=`.
Si le fichier `srvconf` n'existe pas, il sera créé au build et modifiable par la suite avant chaque `run`
De même, si le fichier template `siteconf.in` n'existe pas, une version par défaut sera créée, modifiable par la suite.

### Exécution autonome du container

Il faut noter que l'image `docker` (`epi-multi-php:buster` dans notre exemple) est indépendante des _\<distrib-PHP>_ testées et de son propre système de build : le script `start` du container déduit les _\<distrib-PHP>_ et par suite les `VirtualHost`, du nom des packages `.deb` dans le répertoire `pkgs`. Pour cette raison, l'image n'est pas recréée à chaque lancement de `multi/bake`, il faut la supprimer explicitement, dans notre exemple par `./bake rm multi`.

Pour utiliser l'image `docker` (`epi-multi-php:buster` dans notre exemple) séparément de son système de build, il faut lui fournir un répertoire partagé (par exemple `fpm`) de structure :
```
fpm
├── pkgs
│   ├── epi-php-…_amd64.deb
│   └── epi-php-…_amd64.deb
├── srvconf
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
```
fpm/go path/to/web/site
```
lance l'image docker `epi-multi-php:buster` dans un container qui active Apache/FPM avec toutes les versions PHP définies par les paquets dans `fpm/pkgs`.

Enfin, le script `multi/bake`, comme le script `php/bake`, reconnait dans le répertoire principal le fichier `.norun` pour permettre la mise au point.

### Déploiement sur un serveur pour tests de FPM

Pour déployer sur un serveur un container `docker` de test FPM, il faut :

* sauvegarder l'image `docker` de `multi` pour la bonne version de Debian
  Par exemple, pour une `stretch` :
  ```
  docker save epi-multi-php:stretch | bzip2 >epi-multi-php_stretch.tbz
  ```
* sauvegarder le répertoire `pkgs`, le script `run` et le fichier `srvconf` de `debian/9/multi` :
  ```
  tar cjCf debian/9/multi fpm-deb9.tbz pkgs srvconf run
  ```
* installer si nécessaire `docker-ce` sur le serveur cible

* restaurer l'image docker :
  ```
  bunzip2 < epi-multi-php_stretch.tbz | docker load
  ```
* restaurer le répertoire `pkgs` et autres, par exemple dans /opt/fpm
  ```
  mkdir /opt/fpm
  tar xCf /opt/fpm fpm-deb9.tbz
  ```
* modifier selon les besoins le contenu de `pkgs` (suppression) et `srvconf` (modification)

* lancer le script run sur le `DocumentRoot` de son choix, par exemple `/var/www/html` :
  ```
  /opt/fpm/run /var/www/html
  ```
  C'est prêt ! Bon tests :-)

## Notes

* voir s'il faut gérer le rotate/reopen des logs de PHP-FPM
* voir les FAILED tests des make test ?
* correction des warnings du make install de PEAR 1.10 ?
* voir si on peut optimiser la phase de build en fonction du nombre de cores CPU
* voir s'il faut builder pour autre chose que amd64 (arm par ex)
* déployer sur prephp7a1 et tester
* déployer sur (https://github.com/Epiconcept-Paris/infra-packages-check)
