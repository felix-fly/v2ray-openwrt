#!/usr/bin/env bash

NOW=$(date '+%Y%m%d-%H%M%S')
BASE=$(dirname $(readlink -f "$0"))
TMP=$BASE/tmp

CODENAME="user"
BUILDNAME=$NOW

cleanup () { rm -rf $TMP; }
trap cleanup INT TERM ERR

build_v2() {
  cd $BASE/v2ray-core
	echo ">>> Update source code name ..."
	sed -i "s/^[ \t]\+codename.\+$/\tcodename = \"${CODENAME}\"/;s/^[ \t]\+build.\+$/\tbuild = \"${BUILDNAME}\"/;" core.go

	echo ">>> Compile v2ray ..."
	cd main
	if [[ $GOARCH == "mips" || $GOARCH == "mipsle" ]];then
		env CGO_ENABLED=0 go build -o $TMP/v2ray -ldflags "-s -w"
		env CGO_ENABLED=0 GOMIPS=softfloat go build -o $TMP/v2ray_softfloat -ldflags "-s -w"
	elif [[ $GOOS == "windows" ]];then
		env CGO_ENABLED=0 go build -o $TMP/v2ray.exe -ldflags "-s -w"
		env CGO_ENABLED=0 go build -o $TMP/wv2ray.exe -ldflags "-s -w -H windowsgui"
	elif [[ $GOARCH == "armv5" ]];then
		env CGO_ENABLED=0 GOARCH=arm GOARM=5 go build -o $TMP/v2ray -ldflags "-s -w"
	elif [[ $GOARCH == "armv6" ]];then
		env CGO_ENABLED=0 GOARCH=arm GOARM=6 go build -o $TMP/v2ray -ldflags "-s -w"
	elif [[ $GOARCH == "armv7" ]];then
		env CGO_ENABLED=0 GOARCH=arm GOARM=7 go build -o $TMP/v2ray -ldflags "-s -w"
	else
    env CGO_ENABLED=0 go build -o $TMP/v2ray -ldflags "-s -w"
  fi

	cd ..
	git checkout -- core.go
}

packzip() {
	echo ">>> Generating zip package"
	cd $TMP
  upx --best --lzma *
	tar -czvf $BASE/bin/v2ray-${GOOS}-${GOARCH}.tar.gz *
  cd $BASE
}

GOOS=$1
GOARCH=$2

export GOOS GOARCH
go version
echo "Build ARGS: GOOS=${GOOS} GOARCH=${GOARCH}"
build_v2
packzip
cleanup
