#!/bin/sh
#
#	apt-lib.sh - APT functions gathered from APT code in apt-mods.diff
#
#	UNTESTED !!! For reference only
#
DebTop='debian'
AptLst=
AptDeb=

AptInit()
{
    # global AptLst AptDeb
    local f dir deb dv

    for f in $(cd $DebTop; ls [0-9]*/name | sort -n)
    do
	dir=`dirname $f`
	test -f $dir/mkre || continue
	deb=`basename $dir`
	dv=$dir/Dockervars.sh
	test -f $dv && grep -q '^APT_SRC=.*http://' $dv && AptLst="$AptLst$deb "
    done
}

#   Start the aptlocal http server:	AptStart $deb
AptStart()
{
    # global AptLst AptDeb BinDir DebTop
    local deb

    deb=$1
    echo " $AptLst" | grep -q " $deb " || return
    test "$AptDeb" || { $BinDir/aptsrv "$DebTop/$deb" && trap AptStop 0 2 15 && AptDeb=$deb; }
}

# AptDeb can be tested with:
#test "$deb" != "$AptDeb" && AptStop
AptStop()
{
    # global AptDeb BinDir
    test "$AptDeb" && $BinDir/aptsrv stop && trap 0 2 15 && AptDeb=
}
