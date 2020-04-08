#!/bin/bash

gc_maxlifetime=$(php -i |grep session.gc_maxlifetime | awk '{print $5}')
save_path=/var/lib/php/sessions
sudo find -O3 "$save_path/" -ignore_readdir_race -depth -mindepth 1 -name 'sess_*' -type f -cmin "+$gc_maxlifetime" -delete