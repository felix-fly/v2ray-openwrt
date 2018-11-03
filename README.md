# v2ray-openwrt

本文为在路由器openwrt中使用v2ray的简单流程，相关的配置请参考官方文档。

下载路由器硬件对应平台的压缩包到电脑并解压。

## 上传软件

```
mkdir /etc/config/v2ray
cd /etc/config/v2ray
# 上传v2ray相关文件到该目录下，配置文件自行百度
chmod +x v2ray v2ctl
```

## 添加服务

```
vi /etc/config/v2ray.service
```

贴入以下内容保存退出

```
#!/bin/sh /etc/rc.common
# "new(er)" style init script
# Look at /lib/functions/service.sh on a running system for explanations of what other SERVICE_
# options you can use, and when you might want them.

START=80
ROOT=/etc/config/v2ray
SERVICE_WRITE_PID=1
SERVICE_DAEMONIZE=1

start() {
  service_start $ROOT/v2ray
#   Only use v2ray via pb config without v2ctl on low flash machine
#   service_start $ROOT/v2ray -config=$ROOT/config.pb -format=pb
}

stop() {
  service_stop $ROOT/v2ray
}
```

服务自启动

```
chmod +x /etc/config/v2ray.service
ln -s /etc/config/v2ray.service /etc/init.d/v2ray
/etc/init.d/v2ray enable
```

开启

```
/etc/init.d/v2ray start
```

关闭

```
/etc/init.d/v2ray stop
```

## 生成pb文件（可选）

主要针对小内存设备，v2ray + v2ctl原始程序体积较大，比较占内存（路由的内存相当于电脑的硬盘，并非运存）。使用pb文件可以不依赖v2ctl，同时可以使用upx进一步压缩v2ray程序的体积。使用pd的缺点是不能在路由中直接修改配置文件了。

```
# 在电脑（这里是linux系统）上使用v2ctl转换json配置文件
./v2ctl config < ./config.json > ./config.pb
```

## 透明代理（可选）

使用iptables实现，当前系统是否支持请先自行验证。

以下为iptables规则，直接在ssh中运行可以工作，但是路由重启后会失效，可以在`luci-网络-防火墙-自定义规则`下添加，如果当前系统没有该配置，可以使用开机自定义脚本实现，详情请咨询度娘。

规则中局域网的ip段（192.168.1.0）和v2ray监听的端口（12345）请结合实际情况修改。

```
iptables -t nat -N V2RAY
iptables -t nat -A V2RAY -d 0.0.0.0/8 -j RETURN
iptables -t nat -A V2RAY -d 127.0.0.0/8 -j RETURN
iptables -t nat -A V2RAY -d 192.168.1.0/24 -j RETURN
# From lans redirect to Dokodemo-door's local port
iptables -t nat -A V2RAY -s 192.168.1.0/24 -p tcp -j REDIRECT --to-ports 12345
iptables -t nat -A PREROUTING -p tcp -j V2RAY
iptables -t nat -A OUTPUT -p tcp -j V2RAY
```

## 更新记录
2018-11-03
* 修改文件路径到/etc/config下，更新固件理论上应该可以保留，待测试

