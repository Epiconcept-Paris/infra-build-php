#
#	php/5/Dockervars.sh - Define extra Dockerfile vars depending on PHP version
#
Php=$PhpTop$Maj

#
#   Add other files
#
AddExtra()
{
    # global Php Maj Min BLDCOPY BUILD_TOP TSTCOPY TESTS_TOP BUILD_REQ TESTS_REQ CLI_DEPS
    local dir file lib off cmn

    #   Handle specific patch/package files
    dir="$Php/files/$Maj.$Min"
    if [ -d $dir ]; then
	if [ -f "$dir/lenny-debs" ]; then
	    Main='http://archive.debian.org/debian/pool/main'
	    mkdir -p "$dir/srv"
	    while read deb
	    do
		file="$(basename $deb).deb"
		test -f $dir/$file && continue
		(cd "$dir/srv"; curl -sOR "$Main/$deb.deb")
	    done <"$dir/lenny-debs"
	    BLDCOPY="$BLDCOPY
COPY $dir/lenny-debs $BUILD_TOP/files"
	fi
	for file in $dir/*.patch $dir/deb-CVE/*.patch $dir/*.deb $dir/srv/*.deb
	do
	    test -f "$file" || continue	# *.patch or *.deb patterns may not match
	    case $file in
		*mysql*off_*.deb)	off=$file; lib=`basename "$file" | awk -F_ '{print $1}'`;;
		*mysql-common_*.deb)	cmn=$file;;
		*)			;;	# Other .deb or .patch
	    esac
	    BLDCOPY="$BLDCOPY
COPY $file $BUILD_TOP/files"
	done

	BLDCOPY="$BLDCOPY
COPY $Php/hooks/files.sh $BUILD_TOP/hooks"
	if [ "$cmn" -a "$off" ]; then
	    echo "Using MySQL `expr "$off" : '[^_]*_\([^-]*\)-'` packages found in $PhpGit$dir"
	    TSTCOPY="RUN mkdir $BUILD_TOP/pkgs
COPY $cmn $TESTS_TOP/pkgs
COPY $off $TESTS_TOP/pkgs"
	    BUILD_REQ=`echo "$BUILD_REQ" | sed 's/ [^ ]*mysql[^ ]*//g'`
	    TESTS_REQ=`echo "$TESTS_REQ" | sed -r 's/ lib(mysql|mariadb)client[^ ]*//'`
	    CLI_DEPS=`echo "$CLI_DEPS"   | sed -r "s/ lib(mysql|mariadb)client[^ ]*/ $lib,/"`
	fi
    fi
    #   PHP 5.3- uses autoconf 2.13
    test $Min -le 3 && BUILD_REQ=`echo "$BUILD_REQ" | sed 's/ autoconf/ autoconf2.13/'`

    #	PEAR man pages
    #	From http://pear.php.net/package/PEAR_Manpages/download (see Download link)
    #	Latest: http://download.pear.php.net/package/PEAR_Manpages-1.10.0.tgz
    BLDCOPY="$BLDCOPY
COPY ${PhpTop}files/PEAR_Manpages-1.10.0.tgz $BUILD_TOP/files
COPY ${PhpTop}hooks/pearman.sh $BUILD_TOP/hooks"

    #	Add patch for Debian 9+
    if [ $DebNum -ge 9 ]; then
	BLDCOPY="$BLDCOPY
COPY ${PhpTop}hooks/mysqli.sh $BUILD_TOP/hooks"
    fi

    #	Add package and patch for Debian 10+
    if [ $DebNum -ge 10 ]; then
	BUILD_REQ="ed $BUILD_REQ"	# For php/pkgs/00-cli/install
	BLDCOPY="$BLDCOPY
COPY ${PhpTop}hooks/freetype.sh $BUILD_TOP/hooks"
    fi
}

#
#   Main
#   global Php BLDCOPY BUILD_TOP Tbz PhpLst BUILD_REQ TESTS_REQ CLI_DEPS
#
. ${PhpTop}lib/AddPECL.sh

BLDCOPY="RUN mkdir $BUILD_TOP/hooks"

echo "Checking $Tbz for OpCache..."
if grep '/ext/opcache/' $PhpLst >/dev/null; then
    AddPECL APCu apcu APCu apcu 4.0.11	# Last version to support PHP5
else
    AddPECL APC APC APC apc
fi
if ! grep '/ext/fileinfo/' $PhpLst >/dev/null; then
    AddPECL Fileinfo Fileinfo FileInfo fileinfo
    BUILD_REQ="$BUILD_REQ libmagic-dev"
    TESTS_REQ="$TESTS_REQ libmagic1"
    CLI_DEPS="$CLI_DEPS, libmagic1"
fi
AddPECL oauth oauth OAuth oauth 1.2.3	# Last version to support PHP5
AddPECL ssh2 ssh2 SSH2 ssh2 0.12 
AddExtra
