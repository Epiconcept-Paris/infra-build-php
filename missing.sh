for ver in $(./bake ver | grep -E '[0-9]+[.][0-9]+[.][0-9]+' | sed 's/ //g'); do if [ -z "$(find debian -name "*$ver*")" ]; then echo $ver; fi; done
