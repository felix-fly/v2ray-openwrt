#!/bin/bash

# v2ray release package path
path=~/go/src/v2ray.com/core/bazel-bin/release
rm -rf dist
mkdir dist
for file in $path/v2ray-*.zip; do
  mkdir tmp
  name=${file##*/}
  base=${name%.zip}
  unzip $file "v2ray*" -d tmp
  rm -f tmp/*.sig
  chmod +w tmp/v2ray*
  upx -k --best --lzma tmp/*
  # remove upx bak file
  rm -f tmp/*.~
  zip -j -q -r dist/$base.zip tmp
  rm -rf tmp
  sleep 5
done
