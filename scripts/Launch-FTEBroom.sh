#!/usr/bin/env sh
set -eu
cd -- "$(dirname -- "$0")"
exec ./fteqw-gl64 -ftebroom-child-processes -window -nohome -noupdates -condebug -basedir "$PWD" +exec ftebroom.cfg "$@"
