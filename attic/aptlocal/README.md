### `aptsrv`: Démarrage et arrêt d'un serveur de dépôt APT local
Ce script a été conçu pour pouvoir continuer à faire des *build*s pour Debian 8 (`jessie`) bien que les clés GPG standard dans cette version de Debian aient expiré en 2023.  
Il utilise le module `http.server` de `python3` pour gérer un dépôt APT local (ici `debian/8/repo`) à partir des fichiers `repo-*.txz` se trouvant dans la répertoire de la version Debian (ici `debian/8`).  
Le script est automatiquement lancé et arrêté par `bake` et ne dépend en principe pas de la version Debian.
