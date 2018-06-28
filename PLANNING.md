## Planning

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
  * __Ajout du build (mod+CLI) de toute version 5.2.x de PHP__
  * __Ajout de l'extension APC à PHP 5.2.x__
  
* Phase 4 - Ajout du paquet d'extension MySQL sur PHP 7 : 2j
  * x Ajout de la génération de paquets pour des modules PHP dynamiques
  * x Cas particulier de mysql

* Phase 5 - Compléments : 1j
  * x Ajout de l'extension OAuth en static
