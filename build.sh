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
	elif [[ $GOARCH == "arm" ]];then
		env CGO_ENABLED=0 GOARM=5 go build -o $TMP/v2ray_armv5 -ldflags "-s -w"
		env CGO_ENABLED=0 GOARM=6 go build -o $TMP/v2ray_armv6 -ldflags "-s -w"
		env CGO_ENABLED=0 GOARM=7 go build -o $TMP/v2ray_armv7 -ldflags "-s -w"
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
echo "Build ARGS: GOOS=${GOOS} GOARCH=${GOARCH}"
build_v2
packzip
cleanup
