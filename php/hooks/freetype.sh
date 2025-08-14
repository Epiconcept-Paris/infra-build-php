#
#	freetype.sh - Install freetype-config if missing
#
Cmd=freetype-config
Bin=/usr/bin
if grep -q $Cmd configure; then		# Remember $CWD is /usr/src/php
    if [ ! -f $Bin/$Cmd ]; then
	test "$Dbg" && echo "Creating $Bin/$Cmd replacement"
	echo "#!/bin/sh\n\nexec pkg-config freetype2 \"\$@\"" >$Bin/$Cmd
	chmod +x $Bin/$Cmd
    fi
fi
