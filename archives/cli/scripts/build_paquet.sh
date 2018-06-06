#!/bin/bash

cheminPack=/opt/debbuild
#sed -i $cheminPack/etc/apache2/mods-available/php7.load -e "s#/opt/debbuild##"
cp -r /paquet/* $cheminPack
find $cheminPack -type d -exec chmod 755 {} \;
find $cheminPack -type f ! -path "${cheminPack}/DEBIAN/*" ! -path "${cheminPack}/usr/local/bin/*" -exec chmod 644 {} \;
chmod 755 ${cheminPack}/DEBIAN/*
chmod 755 $cheminPack/usr/bin/* 
rm -rf $cheminPack$cheminPack
sortie=$(fakeroot dpkg-deb -Zgzip --build $cheminPack /opt/output/)
fichier=$(echo $sortie | grep "building package" | sed -e "s/.*in '//g" -e 's/deb.*/deb/g')
echo -e $sortie

lintian $fichier
