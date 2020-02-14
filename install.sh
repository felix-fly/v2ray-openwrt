#!/bin/sh

VERSION=4.22.1
# DIR=/etc/config/v2ray
DIR=./tmp

platform="$1"
all=",386,amd64,arm,arm64,mips,mipsle,mips64,mips64le,ppc64,ppc64le,s390x,"
result=$(echo $all | grep ",${platform},")
if [[ "$result" != "" ]]
then
  echo "Your router platform: $platform"
else
  echo "Unknown platform: $platform"
  exit
fi

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

read -p "Enter the server address:" server
read -p "Enter the user id:" user
read -p "Enter the ws path:" path

read -r -p "Enable UDP support? [y/N] " input
case $input in
  [yY][eE][sS]|[yY])
		echo "Yes"
    config="udp"
		;;
  *)
    echo "No"
    config="tcp"
    ;;
esac

mkdir -p $DIR
cd $DIR
wget https://github.com/felix-fly/v2ray-openwrt/releases/download/$VERSION/v2ray-linux-$platform.tar.gz -O v2ray.tar.gz
wget https://raw.githubusercontent.com/felix-fly/v2ray-openwrt/master/v2ray.service
wget https://raw.githubusercontent.com/felix-fly/v2ray-openwrt/master/client-$config.json -O config.json
wget https://raw.githubusercontent.com/felix-fly/v2ray-adlist/master/site.dat

tar -xzvf v2ray.tar.gz
if [[ $float == "float" ]]
then
  rm v2ray
  mv -f v2ray_softfloat v2ray
else
  rm -f v2ray_softfloat
fi
rm -f v2ray.tar.gz
chmod +x v2ray v2ray.service

ln -s $DIR/v2ray.service /etc/init.d/v2ray
/etc/init.d/v2ray enable

read -r -p "Start v2ray now? [y/N] " input
case $input in
  [yY][eE][sS]|[yY])
		echo "Yes"
    /etc/init.d/v2ray start
		;;
  *)
    echo "No"
    ;;
esac

