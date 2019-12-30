#!/usr/bin/env bash

NOW=$(date '+%Y%m%d-%H%M%S')
BASH=$(dirname $(readlink -f "$0"))
TMP=$BASH/tmp

CODENAME="user"
BUILDNAME=$NOW

cleanup () { rm -rf $TMP; }
trap cleanup INT TERM ERR

build_v2() {
  cd $BASH/v2ray-core
	echo ">>> Update source code name ..."
	sed -i "s/^[ \t]\+codename.\+$/\tcodename = \"${CODENAME}\"/;s/^[ \t]\+build.\+$/\tbuild = \"${BUILDNAME}\"/;" core.go

	echo ">>> Compile v2ray ..."
	cd main
	env CGO_ENABLED=0 go build -o $TMP/v2ray${EXESUFFIX} -ldflags "-s -w"
	if [[ $GOARCH == "mips" || $GOARCH == "mipsle" ]];then
		env CGO_ENABLED=0 GOMIPS=softfloat go build -o $TMP/v2ray_softfloat -ldflags "-s -w"
	fi
	if [[ $GOOS == "windows" ]];then
	  env CGO_ENABLED=0 go build -o $TMP/wv2ray${EXESUFFIX} -ldflags "-s -w -H windowsgui"
	fi

	cd ..
	git checkout -- core.go
}

packzip() {
	echo ">>> Generating zip package"
	cd $BASH
  upx --best --lzma $TMP/*
	zip -qj bin/v2ray-${GOOS}-${GOARCH}.zip $TMP/*
}

GOOS=$1
GOARCH=$2
GOMIPS=

if [ "$1" = "windows" ]; then
  EXESUFFIX=.exe
else
  EXESUFFIX=
fi

export GOOS GOARCH
echo "Build ARGS: GOOS=${GOOS} GOARCH=${GOARCH}"
build_v2
packzip
cleanup
