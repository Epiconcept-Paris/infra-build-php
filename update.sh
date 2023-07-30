#!/bin/sh
#
#	update.sh - Check for any new versions of PHP and build them
#		    Used both by dev (!= 'php') and prod ('php') user-accounts
#
#	This script runs as two separate instances, the first one calling the second
#
#	The first instance is started daily by cron as the dev user (cdt@cty1 as of 2023)
#	Sample of cron file in /etc/cron.d/phpbuild:
#
#	    MAILTO='c.girard@epiconcept.fr'
#	    MAILFROM='cty1@epiconcept.fr'
#
#	    20 1 * * * cdt infra-build-php/update.sh | mail -Es \
#		"$(hostname) PHP build(s) of new version(s)" -a "From: $MAILFROM" $MAILTO
#
#	It checks for new PHP versions.
#	If none, and there are no previous failed builds, it simply exits and no mail is sent
#	If there are unfixed previous failed builds, it reminds about them by mail
#	If any new PHP version, it adds/commits their BUILD_NUM file, attempts to compile them
#	and gathers results and successfully built versions (PHP:Debian) for second instance
#
#	The second instance is then called as the 'php' user by the first instance with
#	all the versions succesfully compiled by the first instance passed as arguments.
#	These versions are compiled again and if successful, their build is pushed
#	on files.epiconcept.fr and the results gathered in any case and returned
#	on stdout to the first instance
#
#	If the whole process went without error, the first instance then does
#	a git push of the commit of BUILD_NUM files
#	In any case, a report is then generated reporting successful compiles
#	and the place of logs to examine for any error
#
# shellcheck disable=SC2086	# Double quote to prevent globbing
# shellcheck disable=SC2039	# In POSIX sh, 'local' is undefined
#
Prg=$(basename "$0")
Dir=$(dirname "$0")
cd "$Dir"

#   Convert elapsed time (in s) of process to YYYY-DD-MM hh:mm:ss (Main code)
odate()
{
    local now old

    now=$(date '+%s')
    old=$((now - $1))
    date -d "@$old" '+%Y-%m-%d %H:%M:%S'
}

#   Build $1 (dev/prod) PHP version $2 for Debian $3 (1st and 2nd instances)
build()
{
    #global Bake Fifo
    local dir ff xc mis

    echo "Building $1 PHP version $2 for Debian $3...$CR"
    #	We use a fifo to get $Bake's exit code even though we process it's stdout
    dir="debian/$3/dist/$2-1"
    ff="$dir/.fail"
    mkdir -p $dir
    rm -f "$ff"
    <$Fifo sed -u 's/$//' | tee "$dir/mk.out" | sed -u 's/$//' &
    $Bake $2 $3 >$Fifo 2>&1
    xc=$?
    if [ $xc -eq 0 ]; then
	mis=$(bin/chkdebs $3 $2)
	test "$mis" && {
	    echo "WARNING: missing $mis packages for PHP $1 on Debian $2$CR"; 
	    echo "$xc $mis" >$ff
	}
    else
	echo $xc >$ff
    fi
    return $xc
}

#   Gather any previously failed builds (1st instance)
failed()
{
    local fail bf dv pv bn

    fail=
    for bf in debian/*/dist/*/.fail
    do
	test -f $bf || continue
	eval $(echo $bf | sed -r 's;debian/([0-9]+)/dist/([.0-9]+)-([0-9]+)/\.fail;dv=\1 pv=\2 bn=\3;')
	test "$bn" -ne 1 && { echo "WARNING: '$bf' on BUILD_NUM '$bn' > 1. Discarded.$CR"; continue; }
	test "$fail" && fail="$fail "
	fail="${fail}fail:$pv:$dv"
    done
    echo -n "$fail"
}

#   Return BUILD_NUM file path given for PHP version $1 (1st instance)
bldnum()
{
    echo "php/$(echo "$1" | awk -F. '{print $1}')/$1/BUILD_NUM"
}

#   Phase 1 - Build 'dev' packages (ran as (non-'php') user)
phase1()
{
    local debs phps blds res fail prod xc dv pv bf bn dd

    test "$#" -gt 0 && { echo "$Prg: no arguments needed" >&3; exit 1; }

    #	Gather all supported Debian versions
    debs=
    for dv in $(cd 'debian'; echo [0-9] [0-9][0-9])
    do
	test -f "debian/$dv/name" || { echo "$Prg: no 'name' in 'debian/$dv' ?$CR" >&2; continue; }
	test -f "debian/$dv/mkre" || { echo "$Prg: no 'mkre' in 'debian/$dv' ?$CR" >&2; continue; }
	test "$debs" && debs="$debs $dv" || debs="$dv"
    done

    #   Determine possible new PHP versions
    #	We check the existence of BUILD_NUM files in $(git ls-files)
    phps=
    blds=
    res=
    for pv in $(./bake latest)
    do
	bf="$(bldnum $pv)"
	git ls-files | grep "^$bf" >/dev/null && continue	# Ignore if exists
	# Gather PHP versions
	test "$phps" && phps="$phps $pv" || phps="$pv"
	# Gather BUILD_NUM paths
	test "$blds" && blds="$blds $bf" || blds="$bf"
	# Gather result's first arg
	test "$res" && res="$res,$pv" || res="$pv"
    done

    #	No new PHP version, check for previously failed builds
    if [ -z "$res" ]; then
	fail="$(failed)"
	test "$fail" && report - $fail >&3
	exit 0
    fi
    echo "Debian versions: $debs$CR"
    echo "New PHP version(s): $phps$CR"

    #	New PHP version(s) appeared since last run
    for bf in $blds
    do
	dd="$(dirname $bf)"
	mkdir -p "$dd"
	if [ -f "$bf" ]; then
	    bn="$(cat "$bf")"
	    test "$bn" -ne 1 && echo "WARNING: '$bf' already has BUILD_NUM '$bn' > 1. Using '1'.$CR"
	fi
	echo '1' >"$bf"
	git add "$bf"
    done
    git commit -m "Add new PHP versions $(echo $res | sed 's/,/, /g')" | sed 's/$//'

    #	Bake 'dev' builds
    prod=
    for pv in $phps
    do
	for dv in $debs
	do
	    echo $pv | egrep "$(cat "debian/$dv/mkre")" >/dev/null || continue
	    build 'dev' $pv $dv
	    xc=$?
	    res="$res dev:$pv:$dv:$xc"
	    test -s "debian/$dv/dist/$pv-1/.fail" || {
		test "$prod" && prod="$prod $pv:$dv" || prod="$pv:$dv"
	    }
	done
    done
    echo "Prod=\"$prod\"$CR"

    #   Run phase2 on $prod
    #
    #	sudo below assumes rights to call $PhpDir/$Prg as 'php' without password
    #	Sample sudoers.d entry:
    #	    # Allow 'cdt' to run php-prod/update.sh as 'php' without password
    #	    cdt ALL = (php) NOPASSWD: php-prod/update.sh
    #
    #	There MUST be a symlink $PhpDir to the actual 'prod' git repo
    #
    test "$prod" && res="$res $(sudo -iu 'php' "$PhpDir/$Prg" $prod)"
    echo "Res=\"$res\"$CR"
    report $res >&3
}

#   Phase 2 - Build 'prod' packages (ran as 'php' user)
#   Final res return is done on fd:3
phase2()
{
    local arg pv dv res

    test "$#" -eq 0 && { echo "$Prg: missing php:deb arg(s)" >&3; exit 1; }
    res="plog:$Log"
    git pull 2>&1 | sed 's/$//'

    #	Build PHP versions
    for arg in "$@"
    do
	eval $(echo $arg | awk -F: '{printf("pv=%s dv=%s", $1, $2)}')
	#echo "arg=$arg pv=$pv dv=$dv$CR"
	build 'prod' $pv $dv
	xc=$?
	res="$res prod:$pv:$dv:$xc"
    done

    #	Save dists (with possible errors)
    <$Fifo sed -u 's/$//' &
    ./savedist.sh >$Fifo 2>&1
    res="$res save:$?"

    #	Send packages to files.epiconcept.fr
    <$Fifo sed -u 's/$//' &
    ./send.sh >$Fifo 2>&1
    res="$res send:$?"

    echo "$res" >&3
}

#   Generate the report email text (all stdout goes to fd:3)
report()
{
    #global Dir Log Prg PhpDir
    local dir pvs res bt pv dv xc bd ff mE mP mB mS mF mL mis

    dir="$(basename "$Dir")"
    mE="===== See %s for output and errors of %s"
    printf "$mE\n" "$dir/$Log" "$dir/$Prg"

    #	Arguments are <php-vers>[,<php-vers>] | '-' <result>[ result]...
    if [ "$1" != '-' ]; then
	pvs="$1"
	if echo "$pvs" | grep ',' >/dev/null; then
	    echo "New PHP versions $(echo $pvs | sed 's/,/, /g') were found !"	# Multiple
	else
	    echo "A new PHP version $pvs was found"	# Just one
	fi
    else	# Special case of failures $1 = '-'
	# For no new version with no remaining failures, report is never called
	echo "No new PHP version was found, but some build failures remain :"
    fi
    shift

    #   res format:
    #
    #	dev:$pv:$dv:$xc
    #	plog:$lf
    #	prod:$pv:$dv:$xc
    #	fail:$pv:$dv
    #	save:$xc
    #	send:$xc
    #
    for res in "$@"
    do
	eval "$(echo $res | awk -F: 'NF>2{printf("bt=%s pv=%s dv=%s xc=%s",$1,$2,$3,NF>3?$4:"")}')"
	eval "$(echo $res | awk -F: 'NF<3{printf("bt=%s xc=%s",$1,$2)}')"
	test "$pv" -a "$dv" && bd="debian/$dv/dist/$pv-1"
	mP='Previous'
	mB="%s build of PHP %s for Debian %s"
	mS='completed successfully'
	mF='FAILED'
	mL="See '$bd/mk.out' and '$bd/.logs/make.out' for details"
	mD="Saving dists"
	mR="Sending packages to APT repo"
	case $bt in
	    fail)
		ff="$bd/.fail"
		if [ -f "$ff" ]; then
		    read xc mis < "$ff"
		    if [ "$xc" -ne 0 ]; then
			printf "$mB $mF (xc=%s)\n" "$mP 'dev'" $pv $dv $xc
		    elif [ "$mis" ]; then
			printf "$mB $mS, but packages %s are missing\n" "$mP 'dev'" $pv $dv $mis
		    else
			echo "$mP '$ff' file contains exit code 0 ?"
		    fi
		    echo "    $mL"
		else
		    echo "File '$ff' disappeared ?" >&2
		fi
		;;

	    plog)   printf "\n$mE\n" "$PhpDir/$xc" "$PhpDir/$Prg";;

	    dev|prod)
		if [ "$xc" -eq 0 ]; then
		    ff="$bd/.fail"
		    if [ -f "$ff" ]; then
			read xc mis < "$ff"
			printf "$mB $mS, but a '$ff' file\n" "'$bt'" $pv $dv
			echo "    shows that packages $mis are missing."
			echo "    $mL"
		    else
			printf "$mB $mS.\n" "'$bt'" $pv $dv
		    fi
		else
		    printf "$mB $mF (xc=%s)\n" "'$bt'" $pv $dv $xc
		    echo "    $mL"
		fi
		;;

	    save|send)
		test "$bt" = 'save' && echo -n "\n$mD" || echo -n "$mR"
		if [ "$xc" -ne 0 ]; then
		    echo " $mF (xc=$xc)"
		else
		    echo " $mS."
		fi
		;;
	esac
    done
}

# ===== Main ===================================

#   Check that a 'php' user exists
grep '^php:' /etc/passwd >/dev/null || { echo "$Prg: no 'php' user (required) on $(hostname)" >&2; exit 1; }

#   Setup Globals
PhpHome=~php
PhpDir='php-prod'
PhpTop="$PhpHome/$PhpDir"
Bake='php/bake'
eval "$(grep 'http_proxy' ~/.bash_profile)"
Usr=$(id -un)
CR=''
xmp=42	# exit-code for missing packages

#   Setup Log and fds
LogDir="$(basename $Prg .sh).log"
Log="$LogDir/$(date '+%Y-%m-%d')"
Fifo="$LogDir/.fifo"
mkdir -p $LogDir
test -p "$Fifo" || mkfifo "$Fifo"
#   All script stdout and stderr will go to $Log
#   To put message in the final email, output to fd:3
exec 3>&1	# Save stdout
exec >$Log 2>&1
date "+===== %Y-%m-%d %H:%M:%S ===== User: $Usr =====$CR"
#date "+===== %Y-%m-%d %H:%M:%S =====" >&3	# DBG

#   Find out if another instance is running
#	We filter out $2 (PPID) as well as $1 (PID) to eliminate the $() subshell
#ps -eo pid,ppid,etimes,cmd | grep "$(echo "$Dir/$Prg" | sed -r 's/^(.)/[\1]/')"	# DBG
eval "$(ps -eo pid,ppid,etimes,cmd | awk "\$5==\"$Dir/$Prg\" && \$1!=$$ && \$2!=$$ {printf(\"Old=%d Et=%d\",\$1,\$3)}")"
#echo "Dir=$Dir Prg=$Prg PID=$$ Old=\"$Old\""	# DBG
test "$Old" && { echo "$Prg: another instance (PID=$Old) is running since $(odate $Et)" >&3; exit 1; }

#   Check for environment (scripts and working dir)
Cant="$Prg: cannot find the"
# ! 'php'
test -x "$Bake"  || { echo "$Cant script '$Bake' in '$PWD'" >&3; exit 1; }
test -d 'debian' || { echo "$Cant direcory 'debian' in '$PWD'" >&3; exit 1; }
# 'php'
test -x "$PhpTop/$Bake"  || { echo "$Cant script '$Bake' in '$PhpTop'" >&3; exit 1; }
test -d "$PhpTop/debian" || { echo "$Cant direcory 'debian' in '$PhpTop'" >&3; exit 1; }
#sleep 70	# DBG
#exit 0		# DBG

#   Switch to proper instance according to $Usr
if [ "$Usr" = 'php' ]; then
    phase2 "$@"
else
    phase1 "$@"
fi
exit 0
