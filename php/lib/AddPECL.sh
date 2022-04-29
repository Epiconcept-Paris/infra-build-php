#
test `basename "$0"` = 'AddPECL.sh' && { echo "AddPECL.sh must be sourced from php/<Maj>/Dockervars.sh, not run separately" >&2; exit 1; }
#
#   Add hooks for PECL PHP extensions
#
#   AddPECL <URL-file> <Src-base> <Hook-name> <Hook-file> [<Version>]
#
AddPECL()
{
    # global PECLGET Php Dir Prg BLDCOPY BUILD_TOP
    local Tgz File Old

    if [ "$5" ]; then	# We want a specific version
	Tgz=$2-$5.tgz
	File=$Tgz
    else		# We want the last version
	# Read headers to determine the file name (and its version)
	Tgz=`curl -sISL "http://$PECLGET/$1" | sed -n 's/^Content-Disposition:.*filename=\(.*\)$/\1/p'`
	if [ -z "$Tgz" ]; then
	    Old=`ls $Php/files/$2-*.tgz 2>/dev/null`
	    test "$Old" && Tgz=`basename $Old`
	    if [ -z "$Tgz" ]; then
		echo "Failed to download $1 extension from $PECLGET/$1" >&2
		echo "Put it manually as $Php/files/$2-<version>.tgz and run $Dir/$Prg again" >&2
		exit 1
	    fi
	fi
	File=$1
    fi
    if [ ! -f $Php/files/$Tgz ]; then
	rm -vf $Php/files/$2-*.tgz | sed 's/^r/R/'	# sed for cosmetics
	echo "Fetching $3 `expr $Tgz : "$2-\(.*\).tgz"` extension..."
	curl -sSL "http://$PECLGET/$File" -o $Php/files/$Tgz
    fi
    BLDCOPY="$BLDCOPY
COPY $Php/files/$Tgz $BUILD_TOP/files"
    test -f $Php/files/$2.patch && BLDCOPY="$BLDCOPY
COPY $Php/files/$2.patch $BUILD_TOP/files"
    BLDCOPY="$BLDCOPY
COPY $Php/hooks/$4.sh $BUILD_TOP/hooks"
}
