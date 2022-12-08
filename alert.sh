#!/bin/bash

ABS=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)

cd $ABS
echo "disponibles"
https_proxy=http://proxy.admin2:3128 http_proxy=$https_proxy ./bake latest

echo "presents"
./bake ls | grep dist |sed -e 1d -e 's#.*/##g' -e 's/-[0-9]*$//' |sort -u
