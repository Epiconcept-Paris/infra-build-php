#!/bin/sh
#
#	Build packages for tools
#
#	Usage:	./tools.sh [<Debian-version>]
#
Prg=`basename $0`
Dir=`dirname $0`
DebTop=../debian

SupDeb()
{
    # global DebNum
    local v
    echo "Supported Debian versions (default $DebNum):" >&2
    ls $DebTop | sort -n | while read v; do test -f $DebTop/$v/name && printf "    %2d (`cat $DebTop/$v/name`)\n" $v; done >&2
}

#
#   Check usage
#
test "$Dir" = '.' || cd "$Dir"
test -d $DebTop || { echo "$Prg: missing '$DebTop' directory." >&2; exit 1; }
DebNum=`ls $DebTop | sort -n | tail -1`	# Default = latest
if [ $# -gt 1 ]; then
    echo "Usage: $Dir/$Prg [ <Debian-version> ]" >&2
    SupDeb
    exit 1
fi
#
#   Check Debian version
#
if [ "$1" ]; then
    if [ -f $DebTop/$2/name ]; then
	DebNum="$1"
    else
	echo "$Prg: unsupported Debian version \"$1\"" >&2
	SupDeb
	exit 1
    fi
fi
DebVer="`cat $DebTop/$DebNum/name`"
Tools=$DebTop/$DebNum/dist/tools
Logs=$Tools/.logs
#
#   Build the image
#
TOOLS_TOP=/opt/tools
TOOLS_BASE=epi-tools
TOOLS_IMG=$TOOLS_BASE:$DebVer
TOOLS_NAME=epi_tools

if docker ps | grep $TOOLS_NAME >/dev/null; then
    echo "Stopping the running '$TOOLS_NAME' container..."
    docker stop -t 5 $TOOLS_NAME >/dev/null
    while docker ps | grep $TOOLS_NAME >/dev/null
    do
	sleep 1
    done
fi
if docker ps -a | grep $TOOLS_NAME >/dev/null; then
    echo "Deleting the existing '$TOOLS_NAME' container..."
    docker rm $TOOLS_NAME >/dev/null
fi
if docker images | grep "$TOOLS_BASE *$DebVer" >/dev/null; then
    echo "Deleting the existing '$TOOLS_IMG' image..."
    docker rmi $TOOLS_IMG >/dev/null
fi

test -d $Logs || mkdir -p $Logs
echo "Building the '$TOOLS_IMG' image..."
#   Variables come in order of their appearance in Dockerfile-multi.in
DEBVER="$DebVer" TOOLS_TOP="$TOOLS_TOP" envsubst '$DEBVER $TOOLS_TOP' <Dockerfile.in | tee $Logs/Dockerfile | docker build -f - -t $TOOLS_IMG . >$Logs/docker.out 2>&1
#
#   Run the container
#
Cmd="docker run -ti -v `realpath $PWD/$Tools`:$TOOLS_TOP/dist --name $TOOLS_NAME --rm $TOOLS_IMG"
if [ -f ../.norun ]; then
    echo "Use:\n    $Cmd bash\nto run the tools container"
else
    echo "Running the '$TOOLS_NAME' container:\n    $Cmd"
    $Cmd
fi
