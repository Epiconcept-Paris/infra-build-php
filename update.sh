#!/bin/sh
#
#	update.sh - Check for any new versions of PHP and build them
#		    Used both by dev (!= 'php') and prod ('php') user-accounts
#
#	This script runs as two separate instances, the first one calling the second
#
#	The first instance is started daily by cron as the dev user (dev@binbuild*)
#	Sample of cron file in /etc/cron.d/php-build:
#
#	    MAILTO='c.girard@epiconcept.fr'
#	    MAILFROM='binbuild@epiconcept.fr'
#
#	    20 1 * * * dev infra-build-php/update.sh | mail -Es \
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
# shellcheck disable=SC2059	# Don't use variables in the printf format string
# shellcheck disable=SC2164	# Use 'cd ... || exit'
# shellcheck disable=SC2039	# In POSIX sh, 'local' & echo flags are undefined
# shellcheck disable=SC3043	# In POSIX sh, 'local' is undefined
# shellcheck disable=SC3037	# In POSIX sh, echo flags are undefined
#
Prg=$(basename "$0")
Dir=$(dirname "$0")
cd "$Dir"

#   Return current time as '+%Y-%m-%d %H:%M:%S'
now()
{
    local sep

    test "$1" && sep="$1" || sep=' '
    date "+%Y-%m-%d$sep%H:%M:%S"
}

#   Convert elapsed time (in s) of process to YYYY-DD-MM hh:mm:ss (Main code)
odate()
{
    local now old

    now=$(date '+%s')
    old=$((now - $1))
    date -d "@$old" '+%Y-%m-%d %H:%M:%S'
}

#   Return deb-name given deb-num
debname()
{
    local n

    case $1 in
	 8) n='jessie';;
	 9) n='stretch';;
	10) n='buster';;
	11) n='bullseye';;
	12) n='bookworm';;
	13) n='trixie';;
    esac
    echo $n
}

#   Return info on existing docker images for all releases of PHP major.minor $1.$2
pmm_dis()
{
    #global DkIms

    # Sample result of docker images
    #	REPOSITORY      TAG               IMAGE ID       CREATED         SIZE
    #	dev-build-php   stretch-8.1.21    bdd805140711   4 days ago      973MB
    #	dev-tests-php   buster-8.2.5      2e86b4147f78   5 days ago      308MB
    #	dev-build-php   bullseye-8.2.8    f419049cc46e   26 hours ago    1.12GB
    #	dev-build-php   buster-8.2.8      2c96c256dbf2   26 hours ago    963MB
    #
    # Given for example $1 = 8 and $2 = 2 (PHP 8.2), we want
    #
    #	8-10-build 8-11-build 5-10-tests
    #
    echo "$DkIms" | awk 'BEGIN {
	# Init array of Debian version names to numbers
	dn["jessie"]   =  8
	dn["stretch"]  =  9
	dn["buster"]   = 10
	dn["bullseye"] = 11
	dn["bookworm"] = 12
	dn["trixie"]   = 13
	s = " "
    }
    #	For all existing dev-*-php images
    {
	# split column 2
	split($2, d, "[-.]")
	print d[2] s d[3] s d[4] s dn[d[1]] s gensub(/^dev-([^\-]+)-php/, "\\1", 1, $1)
    }' |
	# We sort in descending order of releases (field 3)
	sort -k1n,1 -k2n,2 -k3nr,3 -k4n,4 -k5,5 |
	# We only output columns 3,4,5 as 1 & 2 are known
	awk "\$1==\"$1\" && \$2==\"$2\" {printf(\"%s%d-%d-%s\",sep,\$3,\$4,\$5); sep=\" \"}"
}

#   Remove old docker images
#	$@ is a list of (new) PHP version(s)
rm_odis()
{
    #global MaxRold
    local DkIms pv mj mn rl cr nr ni ii rel deb tag rm nd img out

    #	We keep only dev-*-php docker images and .debug/php/ trees
    #	Prod's epi-*-php docker images are handled by savedist.sh
    DkIms="$(docker images | grep 'dev-[^- ]*-php')"

    #   For all new version(s) mj.mn.rl
    for pv in "$@"
    do
	eval "$(echo $pv | sed -r 's/^([0-9]+)\.([0-9]+)\.([0-9]+)$/mj=\1 mn=\2 rl=\3/')"
	#echo "mj=$mj mn=$mn rl=$rl" >&2	# DBG

	cr=	# current rel
	nr=0	# number of rel since top
	ni=0	# number of images
	rm=
	#   For each image info (rel-deb-tag)
	for ii in $(pmm_dis $mj $mn)
	do
	    eval "$(echo $ii | sed -r 's/^([0-9]+)-([0-9]+)-([a-z]+)$/rel=\1 deb=\2 tag=\3/')"
	    if [ "$rel" != "$cr" ]; then
		#echo -n "rel=$rel" >&2							# DBG
		#test "$cr" && echo " (was rel=$cr ni=$ni nr=$nr)" >&2 || echo >&2	# DBG
		cr="$rel"	# rel changed
		nr=$((nr + 1))
		ni=1
	    else
		ni=$((ni + 1))
	    fi
	    #echo "cr=$cr deb=$deb tag=$tag ni=$ni" >&2	# DBG
	    test "$nr" -le "$MaxRold" && continue
	    test "$rm" && rm="$rm "
	    rm="${rm}dev-$tag-php:$(debname $deb)-$mj.$mn.$rel"
	done
	if [ "$rm" ]; then
	    nd=0
	    for img in $rm
	    do
		if out="$(docker rmi $img 2>&1)"; then
		    nd=$((nd + 1))
		    echo "Removed '$img' docker image" >&2
		else
		    echo "ERROR on 'docker rmi $img':\n$out" >&2
		fi
	    done
	    echo "Removed $nd/$ni dev-*-php docker images for PHP $mj.$mn.$cr"
	#else						# DBG
	#    echo "last cr=$cr ni=$ni nr=$nr" >&2	# DBG
	fi
    done
}

#   Remove old .debug/php/ trees
#	$@ is a list of (new) PHP version(s)
rm_ophp()
{
    :
    # TODO: write this code
}

#   Build $1 (dev/prod) PHP version $2 for Debian $3 (1st and 2nd instances)
build()
{
    #global Bake Fifo
    local bd dir ff xc mis

    bd=$(cat "$(bldnum $2)")
    echo "Building $1 PHP version $2 for Debian $3...$CR"
    #	We use a fifo to get $Bake's exit code even though we process it's stdout
    dir="debian/$3/dist/$2-$bd"
    ff="$dir/.fail"
    mkdir -p $dir
    rm -f "$ff"
    <$Fifo sed -u 's/$//' | tee "$dir/mk.out" | sed -u 's/$//' &
    $Bake $2 $3 >$Fifo 2>&1
    xc=$?
    if [ $xc -eq 0 ]; then
	mis=$(bin/chkdebs $3 $2 $bd)
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
	eval "$(echo $bf | sed -r 's;debian/([0-9]+)/dist/([.0-9]+)-([0-9]+)/\.fail;dv=\1 pv=\2 bn=\3;')"
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
    local debs adds upds blds upvs apvs bres fail prod xc dv pv bf bn dd s

    test "$#" -gt 0 && { echo "$Prg: no arguments needed" >&3; exit 1; }

    #	Gather all supported Debian versions
    debs=
    for dv in $(cd 'debian'; echo [0-9] [0-9][0-9])
    do
	test -f "debian/$dv/name" || { echo "$Prg: no 'name' in 'debian/$dv' ?$CR" >&2; continue; }
	test -f "debian/$dv/mkre" || { echo "$Prg: no 'mkre' in 'debian/$dv' ?$CR" >&2; continue; }
	test -f "debian/$dv/.noupd" && continue	# Used when adding a new Debian version
	test "$debs" && debs="$debs $dv" || debs="$dv"
    done

    #   Determine possible new PHP versions or PHP versions to update
    #	We check the existence of BUILD_NUM files in $(git ls-files)
    #	to determine if a version is not already known or needs an update
    adds=
    upds=
    blds=
    upvs=
    apvs=
    for pv in $(./bake latest)
    do
	bf="$(bldnum $pv)"
	git ls-files | grep -q "^$bf" && {
	    # Gather PHP versions to update
	    if git status $bf | grep -Eq "^${TAB}modified: +$bf$"; then
		test "$upds" && upds="$upds $pv" || upds="$pv"
		# Gather report's 2nd arg
		test "$upvs" && upvs="$upvs,$pv" || upvs="$pv"
	    fi
	    continue
	}
	# Gather new PHP versions
	test "$adds" && adds="$adds $pv" || adds="$pv"
	# Gather BUILD_NUM paths
	test "$blds" && blds="$blds $bf" || blds="$bf"
	# Gather report's 1st arg
	test "$apvs" && apvs="$apvs,$pv" || apvs="$pv"
    done

    #	No new or to-update PHP version, check for previously failed builds
    if [ -z "$apvs" -a -z "$upvs" ]; then
	fail="$(failed)"
	test "$fail" && report - - $fail >&3
	exit 0
    fi
    echo "Debian versions: $debs$CR"
    test "$adds" && echo "New PHP version(s): $adds$CR"
    test "$upds" && echo "PHP version(s) to update: $upds$CR"

    #	Some PHP versions need update
    for pv in $upds
    do
	bf="$(bldnum $pv)"
	git add "$bf"
    done
    if [ "$upds" ]; then
	echo "$upvs" | grep -q ',' && s='s' || s=
	git commit -m "Update PHP version$s $(echo $upvs | sed 's/,/, /g')" | sed 's/$//'
    fi

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
    if [ "$adds" ]; then
	echo "$apvs" | grep -q ',' && s='s' || s=
	git commit -m "Add new PHP version$s $(echo $apvs | sed 's/,/, /g')" | sed 's/$//'
    fi

    #	Bake 'dev' builds
    bres=
    prod=
    tag='upd'
    for pv in $upds dev $adds
    do
	test "$pv" = 'dev' && { tag=$pv; continue; }
	for dv in $debs
	do
	    echo $pv | grep -Eq "$(cat "debian/$dv/mkre")" || continue
	    build 'dev' $pv $dv
	    xc=$?
	    test "$bres" && bres="$bres $tag:$pv:$dv:$xc" || bres="$tag:$pv:$dv:$xc"
	    test -s "debian/$dv/dist/$pv-$(cat "$(bldnum $pv)")/.fail" || {
		test "$prod" && prod="$prod $pv:$dv" || prod="$pv:$dv"
	    }
	done
    done
    echo "Prod=\"$prod\"$CR"

    #   Run phase2 on $prod
    #
    #	sudo below assumes rights to call $PhpDir/$Prg as 'php' without password
    #	Sample sudoers.d entry:
    #	    # Allow 'dev' to run php-prod/update.sh as 'php' without password
    #	    dev ALL = (php) NOPASSWD: /home/php/php-prod/update.sh
    #
    #	There MUST be a symlink $PhpDir to the actual 'prod' git repo
    #
    test "$prod" && bres="$bres $(sudo -iu 'php' "$PhpDir/$Prg" $prod)"
    echo "aPvs=\"$apvs\" uPvs=\"$upvs\" bRes=\"$bres\"$CR"
    test "$apvs" || apvs='-'
    test "$upvs" || upvs='-'
    report $apvs $upvs $bres >&3
    rm_odis $adds >&3	# Remove old docker images
    rm_ophp $adds >&3	# Remove old .debug/php/ trees
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
	eval "$(echo $arg | awk -F: '{printf("pv=%s dv=%s", $1, $2)}')"
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

    #   Remember that we saved initial stdout as fd=3
    #	If we did not >&3, the output would go to $Log
    echo "$res" >&3
}

#   Generate the report email text (all stdout goes to fd:3)
report()
{
    #global Dir Log Prg PhpDir
    local dir pvs res bt pv dv xc bd bD ff mE mP mB mS mF mL mis

    #	Arguments are:
    #	    <add-vers>[,<add-vers>] | '-'
    #	    <upd-vers>[,<upd-vers>] | '-'
    #	    <result>[ result]...
    if [ "$1" != '-' ]; then
	pvs="$1"
	if echo "$pvs" | grep -q ','; then
	    echo "New PHP versions $(echo $pvs | sed 's/,/, /g') were found !"	# Multiple
	else
	    echo "A new PHP version $pvs was found"	# Just one
	fi
    elif [ "$2" = '-' ]; then	# Special case of failures $1 = '-' && $2 = '-'
	# For no new version with no remaining failures, report is never called
	echo "No new PHP version was found, but some build failures remain :"
    fi
    shift

    if [ "$1" != '-' ]; then
	pvs="$1"
	if echo "$pvs" | grep -q ','; then
	    echo "PHP versions $(echo $pvs | sed 's/,/, /g') were updated !"	# Multiple
	else
	    echo "PHP version $pvs was updated"	# Just one
	fi
    fi
    shift

    dir="$(basename "$Dir")"
    mE="\n===== See %s for output and possible errors of %s\n"
    printf "$mE" "$dir/$Log" "$dir/$Prg"

    #   res format:
    #
    #	upd:$pv:$dv:$xc
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
	test "$pv" -a "$dv" && { bd="$(cat "$(bldnum $pv)")"; bD="debian/$dv/dist/$pv-$bd"; }
	mP='Previous'
	mB="%s build %s of PHP for Debian %s"
	mS='completed successfully'
	mF='FAILED'
	mL="See '$bD/mk.out' and '$bD/.logs/make.out' for details"
	mD="Saving dists"
	mR="Synchronizing with the APT repo"
	case $bt in
	    fail)
		ff="$bD/.fail"
		if [ -f "$ff" ]; then
		    read -r xc mis < "$ff"
		    if [ "$xc" -ne 0 ]; then
			printf "$mB $mF (xc=%s)\n" "$mP 'dev'" "$pv-$bd" $dv $xc
		    elif [ "$mis" ]; then
			printf "$mB $mS, but packages %s are missing\n" "$mP 'dev'" "$pv-$bd" $dv $mis
		    else
			echo "$mP '$ff' file contains exit code 0 ?"
		    fi
		    echo "    $mL"
		else
		    echo "File '$ff' disappeared ?" >&2
		fi
		;;

	    plog)   printf "$mE" "$PhpDir/$xc" "$PhpDir/$Prg";;

	    dev|upd|prod)
		if [ "$xc" -eq 0 ]; then
		    ff="$bD/.fail"
		    if [ -f "$ff" ]; then
			read -r xc mis < "$ff"
			printf "$mB $mS, but a '$ff' file\n" "'$bt'" "$pv-$bd" $dv
			echo "    shows that packages $mis are missing."
			echo "    $mL"
		    else
			printf "$mB $mS.\n" "'$bt'" "$pv-$bd" $dv
		    fi
		else
		    printf "$mB $mF (xc=%s)\n" "'$bt'" "$pv-$bd" $dv $xc
		    echo "    $mL"
		fi
		;;

	    save|send)
		test "$bt" = 'save' && echo -n "\n$mD" || echo -n "$mR"
		if [ "$xc" -eq 0 ]; then
		    echo -n " $mS"
		    test "$bt" = 'send' && echo "." || save_diffs
		else
		    echo " $mF (xc=$xc)"
		fi
		;;

	    *)  echo "Unknown tag '$bt'"
		;;
	esac
    done
}

#   Report on save diffs if any
save_diffs()
{
    #global PhpTop
    local log nbd dir rep nbt

    log="$PhpTop/update.log/$(date '+%Y-%m-%d')"
    nbd=$(grep -c 'differs from' "$log")
    test "$nbd" -eq 0 && { echo '.'; return; }
    echo ","
    dir="$PhpTop"
    test -L "$dir" && dir="$(readlink "$dir")"
    rep="$(dirname "$dir")/php-debs"
    nbt=$(cd "$rep"; find [0-9] [1-9][0-9] -maxdepth 1 -type d | grep / | sort -n | wc -l)
    if [ "$nbd" -eq 1 ]; then
	echo "    but $nbd dist / $nbt total differs from its saved version"
    else
	echo "    but $nbd dists / $nbt total differ from their saved versions"
    fi
    cat <<EOF
    (see $log for details)
    The original dists have been kept as reference. If you want
    to discard them, type as the 'php' user in ~php/php-prod :
	./savedist.sh mv | sh	OR   ./savedist.sh rm | sh
    and then   ./savedist.sh   again to save the new dists,
    followed by a   ./send.sh   to update the APT repo.
EOF

}

#   On exit, gather empty log in $LogDir/.idle
cleanup()
{
    #global LogDir Log
    local idle

    idle="$LogDir/.idle"
    if [ $(wc -l <$Log) -eq 1 ]; then
	# Only add to $Log if 1st addition today
	grep -q "^===== $(date '+%Y-%m-%d') " "$idle" || cat "$Log" >>"$idle"
	rm "$Log"
    fi
    return 0
}

# ===== Main ===================================

#   Check that a 'php' user exists
grep -q '^php:' /etc/passwd || { echo "$Prg: no (required) 'php' user on $(hostname)" >&2; exit 1; }

#   Setup Globals
MaxRold=3	# Max PHP releases (per maj.min) we preserve old docker-images & .debug/php/ for
PhpHome=~php
PhpDir='php-prod'
PhpTop="$PhpHome/$PhpDir"
Bake='php/bake'
Usr=$(id -un)
TAB='	'
CR=''

DefProxy='http://proxy:3128'
test -f ~/.bash_profile && eval "$(grep 'http_proxy' ~/.bash_profile)"
test "$http_proxy" || export http_proxy="$DefProxy"
test "$https_proxy" || export https_proxy="$DefProxy"

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
trap cleanup 0
echo "===== $(now) ===== User: $Usr =====$CR"

test "$LANG" || { LANG='C.UTF-8'; echo "	Set LANG=\"$LANG\"$CR"; }
if [ "$LC_ALL" -a "$LC_ALL" != "$LANG" ]; then
    echo "	Unset LC_ALL=\"$LC_ALL\" (!= LANG=\"$LANG\")$CR"
    unset LC_ALL
fi

#   Find out with ps if another instance of this $Prg script is running
#
#   We need of course to eliminate our own instances of the script
#   It may seem at first that there should be only this script and its child
#	in the eval "$(ps ...)" below. Here is a sample of what ps normally sees:
#
#        PID    PPID ELAPSED CMD
#    ...
#        722       1 2019307   /usr/sbin/cron -f -L 7
#    2963222     722       0     /usr/sbin/CRON -f -L 7
#    2963223 2963222       0       /bin/sh -c build-php/update.sh | mail -Es "$(hostname) PHP build(s)...
#    2963224 2963223       0         /bin/sh build-php/update.sh
#    2963241 2963224       0           /bin/sh build-php/update.sh
#    2963242 2963241       0             ps -eHo pid,ppid,etimes,cmd
#    2963243 2963241       0             awk $2 != 2
#    2963244 2963241       0             tee update.log/ps_2025-10-23_00:15:01.txt
#    2963245 2963241       0             awk -v pid=2963224 -v cmd=build-php/update.sh  ?BEGIN { ppid=0 ...
#    2963225 2963223       0         mail -Es binbuilda1 PHP build(s) of new version(s) -a From: ...
#
#    So we would just need to exclude the processes with PID 2963224 (our script) and 2963241 (its child)
#    Note that this child (the $(ps...) process) has 4 children, one for each command of the pipeline
#    This is standard behaviour of dash (bin/sh in Debian Linux) for pipelines (man dash)
#
#    But once in a while (more system load ?), we get from 'ps' something like this:
#
#        PID    PPID ELAPSED CMD
#    ...
#        722       1 2019187   /usr/sbin/cron -f -L 7
#    2958259     722       0     /usr/sbin/CRON -f -L 7
#    2958261 2958259       0       /bin/sh -c build-php/update.sh | mail -Es "$(hostname) PHP build(s)...
#    2958263 2958261       0         /bin/sh build-php/update.sh
#    2958289 2958263       0           /bin/sh build-php/update.sh
#    2958290 2958289       0             ps -eHo pid,ppid,etimes,cmd
#    2958291 2958289       0             /bin/sh build-php/update.sh
#    2958292 2958289       0             tee update.log/ps_2025-10-23_15:04:01.txt
#    2958293 2958289       0             awk -v pid=2958263 -v cmd=build-php/update.sh  ?BEGIN { ppid=0 ...
#    2958264 2958261       0         mail -Es binbuilda1 PHP build(s) of new version(s) -a From: ...
#
#    We can see here that the 'awk $2 != 2' command has not yet appeared as process 2958291,
#	instead, we just see a fork of the $(ps...) process, which still has 4 children
#
#    So it means that we must not only discard our $Prg process and its $(ps...) child, but also the 4
#    children of the latter (in this debug pipeline; in the production code, there would only be 2 children)
#
#    To do this, we save the PID of the $(ps...) process & discard all processes that have it as PPID
#
test "$Usr" = 'php' || {
    PsLog="update.log/ps_$(now _).txt"
    # Maximum debug in $BugLog, to trace $Prg when it is started every minute
    BugLog="update.log/bugLog"		# MDBG
    echo -n "$(now) " >>$BugLog		# MDBG
    # We check $5 below because $4 is '/bin/sh'
    # 'nep' is the number of embryo processes (successfully discarded)
    #Prod: Out="$(ps -eHo pid,ppid,etimes,cmd | awk -v "pid=$$" -v "cmd=$Dir/$Prg" '
    Out="$(ps -eHo pid,ppid,etimes,cmd | awk '$2 != 2' | tee $PsLog | awk -v "pid=$$" -v "cmd=$Dir/$Prg" '
	BEGIN { ppid=0; nep=0
		printf("PID=%d Cmd=\"%s\" ",pid,cmd) >"/dev/stderr"	# MDBG
	}
	$5 == cmd && $1 != pid {
		if ($2 == pid) ppid = $1
		else if (ppid > 0 && $2 == ppid) nep++
		else printf("Oth=%d Et=%d\n",$1,$3)
	}
	END { if (nep > 0) printf("Nep=%d\n", nep) }' 2>>$BugLog	# MDBG
    )"
    echo "$Out" | sed -n '1p; 2,$s/^/\t/p' >>$BugLog	# MDBG
    if [ "$Out" ]; then
	OthLog='update.log/Oth'		# MDBG
	Nbl=$(echo "$Out" | wc -l)
	if [ "$Nbl" -eq 1 ]; then
	    eval "$Out"
	    if expr "$Out" : 'Nep=' >/dev/null; then
		echo "	Discarded $Nep embryo process(es)$CR"
	    else
		echo "$Prg: another instance (PID=$Oth) is running since $(odate $Et)" >>"$OthLog" #>&3
	    fi
	else	# Actually VERY unlikely (defensive programming) because,
		# if an older instance of $Prg is detected, no other can start
	    echo "$Prg: $Nbl other instances are already running" >>"$OthLog" # MDBG >&3
	    echo "$Out" | while read -r line; do
		eval "$line"
		if expr "$line" : 'Nep=' >/dev/null; then
		    echo "	Discarded $Nep embryo process(es)$CR"
		else
		    echo "	PID=$Oth running since $(odate $Et)" >>"$OthLog" # MDBG >&3
		fi
	    done
	fi
	test "$Oth" && exit 1
    fi
    test "$(grep -c "/bin/sh $Dir/$Prg" $PsLog)" -eq 2 && rm -f $PsLog	# MDBG
}

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
