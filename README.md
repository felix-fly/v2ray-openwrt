# v2ray-openwrt

本文为在路由器openwrt中使用v2ray的简单流程，相关的配置请参考官方文档，为了方便小伙伴们，这里给出的配置样例 [仅TCP](./client-tcp.json) [支持UDP](./client-udp.json) 供参考，配置采用ws作为底层传输协议，服务端及nginx相关配置可度娘。注意替换==包含的内容为你自己的配置，路由部分使用自定义的site文件，支持gw上网及各种广告过滤，site.dat文件可以从[v2ray-adlist](https://github.com/felix-fly/v2ray-adlist)获取最新版。

此方案相对简单，适合对性能要求不高，只要能正常爬网即可的情况使用，有更高要求的请看下面的方案。

## 优化方案

如果v2ray一站式服务的方式不能满足你的需求，或者遇到了性能瓶颈（下载慢），可以试试另外一种优化方案：

[https://github.com/felix-fly/v2ray-dnsmasq-dnscrypt](https://github.com/felix-fly/v2ray-dnsmasq-dnscrypt)

## 高速方案，更高！更快！更强

使用树莓派4b安装openwrt配置独立服务trojan/v2ray，**千兆高速**解决方案，性价比超软路由。

[https://github.com/felix-fly/openwrt-raspberry](https://github.com/felix-fly/openwrt-raspberry)

## 安装脚本

路由器CPU平台请自行查询确认，支持的平台如下

* 386
* amd64
* armv5
* armv6
* armv7
* arm64
* mips
* mipsle
* mips64
* mips64le
* ppc64
* ppc64le

ssh登陆到路由器执行脚本，路由器需联网及已安装wget。

```bash
wget https://raw.githubusercontent.com/felix-fly/v2ray-openwrt/master/install.sh
chmod +x install.sh
./install.sh 386
```

CPU不支持硬件浮点计算时需要开启FPU。

## 下载压缩好的v2ray

[release](https://github.com/felix-fly/v2ray-openwrt/releases)页面提供了各平台下的v2ray执行文件，可以直接下载使用。

默认已经过upx压缩，不支持压缩的保持不变。压缩包中仅包含v2ray执行文件，因为已经编译支持了json配置文件，运行不需要v2ctl。

## 上传软件及客户端配置文件

```
mkdir /etc/config/v2ray
cd /etc/config/v2ray
# 上传v2ray、config.json文件到该目录下，配置文件根据个人需求修改
chmod +x v2ray
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
  service_start $ROOT/v2ray
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

## 透明代理（可选）

使用iptables实现，当前系统是否支持请先自行验证。开启UDP需要 iptables-mod-tproxy 模块，请确保已经安装好。

以下为iptables规则，直接在ssh中运行可以工作，但是路由重启后会失效，可以在`luci-网络-防火墙-自定义规则`下添加，如果当前系统没有该配置，可以使用开机自定义脚本实现，详情请咨询度娘。

规则中局域网的ip段（192.168.1.0）和v2ray监听的端口（12345）请结合实际情况修改。

```
# Only TCP
iptables -t nat -N V2RAY
iptables -t nat -A V2RAY -d 0.0.0.0 -j RETURN
iptables -t nat -A V2RAY -d 127.0.0.0 -j RETURN
iptables -t nat -A V2RAY -d 192.168.1.0/24 -j RETURN
# From lans redirect to Dokodemo-door's local port
iptables -t nat -A V2RAY -s 192.168.1.0/24 -p tcp -j REDIRECT --to-ports 12345
iptables -t nat -A PREROUTING -p tcp -j V2RAY
```

```
# With UDP support
ip rule add fwmark 1 table 100
ip route add local 0.0.0.0/0 dev lo table 100
iptables -t mangle -N V2RAY
iptables -t mangle -A V2RAY -d 0.0.0.0 -j RETURN
iptables -t mangle -A V2RAY -d 127.0.0.0 -j RETURN
iptables -t mangle -A V2RAY -d 192.168.1.0/24 -j RETURN
# From lans redirect to Dokodemo-door's local port
iptables -t mangle -A V2RAY -p tcp -s 192.168.1.0/24 -j TPROXY --on-port 12345 --tproxy-mark 1
iptables -t mangle -A V2RAY -p udp -s 192.168.1.0/24 -j TPROXY --on-port 12345 --tproxy-mark 1
iptables -t mangle -A PREROUTING -j V2RAY
```

# 长尾

以下内容一般来说不需要继续看了，如果你想自己定制v2ray，come on!

## 普通压缩

首先下载路由器硬件对应平台的压缩包到电脑并解压。

v2ray功能强大，相应的体积也很硕大，以目前4.18版本为例，这里使用的mipsle平台的v2ray已经超过了14mb，v2ctl也有10mb，对于路由器这种存储空间不是很富裕的设备，原生的v2ray实在是太大了。

压缩势在必行，这里使用upx

```
upx -k --best --lzma v2ray
upx -k --best --lzma v2ctl
```

UPX是个厉害角色，之前是直接不带任何参数压缩，体积还可接受，但是目前这个版本压缩后也有4.9mb的块头，笔者的k2p表示吃不消。于是参数化之后发现体积缩小至3.3mb，比现在使用的版本还小一些。如果你不追求极致，到此就可以洗洗睡了（厄～，那个～，好像还没完呢。。。）。

## 极致压缩

之前就有人发过相关的教程修改all.go文件，通过减少依赖缩小v2ray的体积，那时还是用的vbuild编译，现在已经使用bazel来build了。可以参考这个[issue](https://github.com/v2ray/v2ray-core/issues/1506)修改all.go文件:

```
main/distro/all/all.go
```

关于JSON配置这里，有两种选择，代码里的注释已经说明了，默认的配置是依赖v2ctl来处理JSON文件，而另外一种选择jsonem的话，v2ray可以直接处理JSON文件，不再依赖v2ctl，只是体积会相应的增大。这里改为使用jsonem。

需要指出的是，当使用jsonem时，通过减少依赖并不能进一步缩小v2ray的体积，个人猜测可能jsonem也引用了这些依赖。

```
package all

import (
  ...

  // JSON config support. Choose only one from the two below.
  // The following line loads JSON from v2ctl
  // _ "v2ray.com/core/main/json"
  // The following line loads JSON internally
  _ "v2ray.com/core/main/jsonem"

  ...
)
```

然后编译你要的平台安装包

```
bazel clean
bazel build --action_env=GOPATH=$GOPATH --action_env=PATH=$PATH //release:v2ray_linux_mipsle_package
```

采用jsonem的话打包出来的v2ray体积为15mb多，UPX之后约3.6mb，个人觉得还ok，这样的话在路由器中可以直接读取json配置文件而不再需要v2ctl。

## 更新记录
2020-06-09
* 添加树莓派4b方案链接

2020-02-17
* 增加了安装脚本

2019-12-21
* 添加了自动build的action

2019-12-06
* 增加UDP

2019-10-16
* 使用最新代码编译 4.20.0
* 简化流程
* 增加了服务端配置样例

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

