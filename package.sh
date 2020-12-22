#!/bin/bash

VERSION=latest

platform="$1"
all=",386,amd64,armv5,armv6,armv7,arm64,mips,mipsle,mips64,mips64le,ppc64,ppc64le,s390x,"
result=$(echo $all | grep ",${platform},")
if [[ "$result" != "" ]]
then
  echo "Your router platform: $platform"
else
  echo "Unknown platform: $platform"
  exit
fi

read -p "Enter the v2ray version(Default: $VERSION):" ver

version=${ver:-"$VERSION"}

float=""
if [[ $platform == "mips" || $platform == "mipsle" ]]
then
  read -r -p "Enable FPU support(soft-float)? [y/N] " input
  case $input in
    [yY][eE][sS]|[yY])
      echo "Yes"
      float="float"
      ;;
    *)
      echo "No"
      float=""
      ;;
  esac
fi

mkdir tmp
cp -r package/* tmp
cd tmp

if [[ $version == "latest" ]]
then
  wget https://github.com/felix-fly/v2ray-openwrt/releases/latest/download/v2ray-linux-$platform.tar.gz -O v2ray.tar.gz
else
  wget https://github.com/felix-fly/v2ray-openwrt/releases/download/$version/v2ray-linux-$platform.tar.gz -O v2ray.tar.gz
fi

tar -xzvf v2ray.tar.gz
if [[ $float == "float" ]]
then
  rm -f v2ray
  mv v2ray_softfloat v2ray
else
  rm -f v2ray_softfloat
fi
rm -f v2ray.tar.gz

chmod +x v2ray
filesize=`ls -l v2ray | awk '{ print $5 }'`

mkdir -p data/usr/bin
mv v2ray data/usr/bin

sed -i "s/==VERSION==/$version/g" ./control/control
sed -i "s/==SIZE==/$filesize/g" ./control/control

cd control
tar -zcf ../control.tar.gz * --owner=0 --group=0
cd ..
rm -rf control

cd data
tar -zcf ../data.tar.gz * --owner=0 --group=0
cd ..
rm -rf data

tar -zcf ../v2ray-$version.ipk * --owner=0 --group=0
cd ..
rm -rf tmp
