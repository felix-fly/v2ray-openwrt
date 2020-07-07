#!/bin/sh

VERSION=4.26.0
DIR=/etc/config/v2ray
# DIR=./tmp

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

read -p "Enter the server address:" server
read -p "Enter the user id:" user
read -p "Enter the ws path:" path

path=${path//\//}

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
wget https://github.com/felix-fly/v2ray-openwrt/releases/download/$VERSION/v2ray-linux-$platform.tar.gz -O /tmp/v2ray.tar.gz
wget https://raw.githubusercontent.com/felix-fly/v2ray-openwrt/master/v2ray.service
wget https://raw.githubusercontent.com/felix-fly/v2ray-openwrt/master/client-$config.json -O config.json
wget https://raw.githubusercontent.com/felix-fly/v2ray-adlist/master/site.dat

tar -xzvf /tmp/v2ray.tar.gz -C /tmp
if [[ $float == "float" ]]
then
  rm -f /tmp/v2ray
  mv /tmp/v2ray_softfloat v2ray
else
  rm -f /v2ray_softfloat
  mv /tmp/v2ray v2ray
fi
rm -f /tmp/v2ray.tar.gz
chmod +x v2ray v2ray.service

ln -s $DIR/v2ray.service /etc/init.d/v2ray
/etc/init.d/v2ray enable

sed -i "s/==YOUR DOMAIN or SERVER ADDRESS==/$server/" config.json
sed -i "s/==YOUR USER ID==/$user/" config.json
sed -i "s/==YOUR ENTRY PATH==/\/$path\//" config.json

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

