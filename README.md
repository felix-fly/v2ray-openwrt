# v2ray-openwrt

本文为在路由器openwrt中使用v2ray的简单流程，相关的配置请参考官方文档，为了方便小伙伴们，这里给出了一个[配置样例](./client-config.json)供参考。注意替换==包含的内容为你自己的配置，路由部分使用自定义的site文件，支持gw上网及各种广告过滤，site.dat文件可以从[v2ray-adlist](https://gitee.com/felix-fly/v2ray-adlist)获取最新版。

随着v2ray功能的不断完善，相应的体积也一直在增加，以目前4.18版本为例，这里使用的mipsle平台的v2ray已经超过了14mb，v2ctl也有10mb，如果你的路由器存储空间不是足够大，那么精简或者说压缩v2ray的体积势在必行。

下载路由器硬件对应平台的压缩包到电脑并解压。

## 另一种解决方案（优化方案）

如果v2ray一站式服务的方式不能满足你的需求，或者遇到了性能瓶颈（下载慢），可以试试另外一种解决方案（优化方案）：

[v2ray-dnsmasq-dnscrypt](https://gitee.com/felix-fly/v2ray-dnsmasq-dnscrypt)

## 压缩体积

```
upx -k --best --lzma v2ray
upx -k --best --lzma v2ctl
```

UPX在这里功不可没，之前是直接不带任何参数压缩，体积还可接受，但是目前这个版本压缩后也有4.9mb的块头，笔者的k2p表示吃不消。于是参数化之后发现体积缩小至3.3mb，比现在使用的版本还小一些。如果你不追求极致，到此就可以洗洗睡了（厄～，那个～，好像还没完呢。。。）。

## 极致压缩

之前就有人发过相关的教程修改all.go文件，通过减少依赖缩小v2ray的体积，那时还是用的vbuild编译，现在已经使用bazel来build了。可以参考这个[issue](https://github.com/v2ray/v2ray-core/issues/1506)修改all.go文件:

```
main/distro/all/all.go
```

修改后类似这个样子，tls暂时先保留，是否可以去掉待验证。

关于JSON配置这里，有两种选择，代码里的注释已经说明了，默认的配置是依赖v2ctl来处理JSON文件，而另外一种选择jsonem的话，v2ray可以直接处理JSON文件，不再依赖v2ctl，只是体积会相应的增大。

```
package all

import (
  // The following are necessary as they register handlers in their init functions.

  // Required features. Can't remove unless there is replacements.
  _ "v2ray.com/core/app/dispatcher"
  _ "v2ray.com/core/app/proxyman/inbound"
  _ "v2ray.com/core/app/proxyman/outbound"

  // Other optional features.
  _ "v2ray.com/core/app/log"
  _ "v2ray.com/core/app/router"

  // Inbound and outbound proxies.
  _ "v2ray.com/core/proxy/blackhole"
  _ "v2ray.com/core/proxy/dokodemo"
  _ "v2ray.com/core/proxy/freedom"
  _ "v2ray.com/core/proxy/socks"
  _ "v2ray.com/core/proxy/vmess/outbound"

  // Transports
  _ "v2ray.com/core/transport/internet/tls"
  _ "v2ray.com/core/transport/internet/websocket"
  
  // Transport headers
  _ "v2ray.com/core/transport/internet/headers/tls"

  // JSON config support. Choose only one from the two below.
  // The following line loads JSON from v2ctl
  _ "v2ray.com/core/main/json"
  // The following line loads JSON internally
  // Use this one v2ctl will be useless
  // _ "v2ray.com/core/main/jsonem"

  // Load config from file or http(s)
  _ "v2ray.com/core/main/confloader/external"
)
```

然后编译你要的平台安装包

```
bazel clean
bazel build --action_env=GOPATH=$GOPATH --action_env=PATH=$PATH //release:v2ray_linux_mipsle_package
```

经过减少依赖项打包出来的v2ray体积为10mb多一点，再结合UPX最终的大小控制在了2.5mb，顿时感觉一身轻松啊（我是路由器，嘎嘎～）。

如果采用jsonem的话打包出来的v2ray体积为15mb多，UPX之后约3.6mb，个人觉得还ok，这样的话在路由器中可以直接使用json配置文件而不再需要额外转换为pb文件。当然最终的选择取决于你自己的实际需求。

**ps：文末有福利！文末有福利！文末有福利！**

## 上传软件

```
mkdir /etc/config/v2ray
cd /etc/config/v2ray
# 上传v2ray相关文件到该目录下，配置文件自行百度
chmod +x v2ray v2ctl
```

## 添加服务

```
vi /etc/config/v2ray/v2ray.service
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
  # limit vsz to 64mb (you can change it according to your device)
  ulimit -v 65536
  service_start $ROOT/v2ray
#  Only use v2ray via pb config without v2ctl on low flash machine
#  service_start $ROOT/v2ray -config=$ROOT/config.pb -format=pb
}

stop() {
  service_stop $ROOT/v2ray
}
```

服务自启动

```
chmod +x /etc/config/v2ray/v2ray.service
ln -s /etc/config/v2ray/v2ray.service /etc/init.d/v2ray
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

**对于采用jsonem方式编译的v2ray可以直接读取json文件，不再需要转换。**

主要针对小内存设备，v2ray + v2ctl原始程序体积较大，比较占内存（路由的内存相当于电脑的硬盘，并非运存）。使用pb文件可以不依赖v2ctl，使用pd的缺点是不能在路由中直接修改配置文件了。

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
iptables -t nat -A V2RAY -d 0.0.0.0 -j RETURN
iptables -t nat -A V2RAY -d 127.0.0.0 -j RETURN
iptables -t nat -A V2RAY -d 192.168.1.0/24 -j RETURN
# From lans redirect to Dokodemo-door's local port
iptables -t nat -A V2RAY -s 192.168.1.0/24 -p tcp -j REDIRECT --to-ports 12345
iptables -t nat -A PREROUTING -p tcp -j V2RAY
```

## 送福利

release页面提供了linux平台下的v2ray执行文件，默认已经过upx压缩，不支持压缩的保持不变。压缩包中仅包含v2ray执行文件，因为已经编译支持了json配置文件，运行不需要v2ctl，也无需额外转换pb文件。

## 更新记录
2019-07-02
* 4.19.1

2019-05-31
* linux各平台编译好的文件可在release下载

2019-05-21
* 代码迁移至码云，修正链接地址

2019-03-13
* 增加了内置json处理的相关说明

2019-03-12
* 更新v2ray到4.18
* 增加压缩流程

2018-12-10
* 增加了客户端配置样例，方便使用

2018-11-03
* 修改文件路径到/etc/config下，更新固件理论上应该可以保留，待测试

