# Planning

## Première partie DONE

* Phase 1 - Version quelconque PHP7 : 4j dont 1j preparation/évaluation
  * x Génération des paquets DEB (mod + CLI) pour toute version 7.[12].x de PHP passée en argument
  * x Ajout de l'extension APCu
  * x Hooks (shell scripts appelés si présents) pour config/customisation
  * x Nettoyer les erreurs lintian (build du paquet DEB)
  * x Gérer l'incompatibilité des paquets epi-php* avec php5*/php7* des distros
  * x Documentation des commandes de build, ajout de version, etc

* Phase 2 - Amélirations et corrections version PHP 7 : 2j 
  * x Ajout des tests de build (make test) et extraction des erreurs (php_report...)
  * x Analyser et résoudre/ignorer les warnings au make install de PHP7
  * __Ajouter la signature des paquets__

* Phase 3 - Version quelconque PHP 5.2 : 2j
  * x Ajout du build (mod+CLI) de toute version 5.2.x de PHP (sur jessie)
  * x Ajout de l'extension APC à PHP 5.2.x
  
* Phase 4 - Ajout du paquet d'extension MySQL sur PHP 7 : 2j
  * x Ajout de la génération de paquets pour des modules PHP dynamiques
  * x Cas particulier de mysql

* Phase 5 - Compléments : 2j
  * x Ajout de l'extension OAuth en static
  * x Ajout de la géneration d'un prototype de paquet FPM
  
## Seconde partie DONE

* x build des paquets PHP 5.6 et PHP 7.x
  * x avec le binaire FPM
  * x un service gérant le daemon
  * x une configuration minimale
  * x pas de blocage ni d'interactions si on installe toutes les versions sur un même serveur
  * x pour Debian Stretch
* * modification sur les paquets php-cli
  * x pouvoir les installer en parallèle (binaire et configuration)
  * x choix du PHP via Debian alternatives
* * la configuration PHP doit être
  * x propre à chaque version
  * x commune à PHP CLI et PHP FPM
  * x stockée par exemple dans /etc/php/7.1/php.ini et /etc/php/7.1/conf.d/*.ini
  * x si possible, modifier la conf pour mod_php pour qu'elle utilise le même fichier (et qu'on soit en cohérence)
* x utilisation du container Docker de test pour tester le déploiement et les bascules, avec un POC (deux vhosts utilisant des versions différentes de PHP). Notre script de gestion des vhosts intégrera cela.

## Remarques

* nom unique (epi_build_php) pour le container de build, donc impossible de lancer des builds en parallèle
