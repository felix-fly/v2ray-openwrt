# 目录

* [关于 v2ray-openwrt](#关于-v2ray-openwrt)
* [优化方案 v2ray-dnsmasq-dnscrypt](#优化方案-v2ray-dnsmasq-dnscrypt)
* [高速方案 openwrt-raspberry](#高速方案-openwrt-raspberry)
* [安装方式](#安装方式)
  * [自行构建ipk安装包](#自行构建ipk安装包)
  * [脚本安装（路由）](#脚本安装路由)
  * [手动安装方式（电脑）](#手动安装方式电脑)
* [配置透明代理（可选）](#配置透明代理可选)
* [尾声](#尾声)
* [更新记录](#更新记录)

# 关于 v2ray-openwrt

本文为在路由器openwrt中使用v2ray的简单流程，相关的配置说明请参考官方文档。

前段时间v2ray新增了xtls协议，性能大幅提升，但是从4.33开始由于某些原因又全面移除了该协议。

现在xray独立发布了，对于性能有要求的小伙伴可以前去体验xtls的效果。

* [xray-openwrt](https://github.com/felix-fly/xray-openwrt)

为了方便小伙伴们，这里给出参考配置文件：

* [客户端配置](./client.json) 
* [服务端配置](./server.md)

注意替换==包含的内容为你自己的配置，路由部分使用自定义的site文件，支持gw上网及各种广告过滤。

* [点此获取 site.dat 最新版](https://github.com/felix-fly/v2ray-adlist)

此方案相对简单，适合对性能要求不高，只要能正常爬网即可的情况使用，有更高要求的请看下面的方案。

# 优化方案 v2ray-dnsmasq-dnscrypt

如果v2ray一站式服务的方式不能满足你的需求，或者遇到了性能瓶颈（下载慢），可以试试另外一种优化方案：

* [https://github.com/felix-fly/v2ray-dnsmasq-dnscrypt](https://github.com/felix-fly/v2ray-dnsmasq-dnscrypt)

# 高速方案 openwrt-raspberry

使用树莓派4b安装openwrt配置独立服务trojan/v2ray，**千兆高速**解决方案，更高！更快！更强！性价比超软路由！

* [https://github.com/felix-fly/openwrt-raspberry](https://github.com/felix-fly/openwrt-raspberry)

# 安装方式

## 自行构建ipk安装包

看到小伙伴有这个想法，花了点时间，弄了个脚本，可以自行构建ipk包，方便到openwrt中安装

先克隆项目到某个linux环境下，windows的wsl未做测试，理论上应该也可以

```bash
git clone https://github.com/felix-fly/v2ray-openwrt.git
```

进入项目目录，运行脚本，参数为CPU平台，版本不指定默认为最新版

```bash
./package.sh amd64
```

生成的ipk包在当前路径下，形如 **v2ray-xxx.ipk** 

路由安装后需要自行修改配置文件

```bash
/etc/v2ray/config.json
```

对路由操作不熟悉的可以在打包前先修改

> ./package/data/etc/v2ray/config.json

需要使用v2ray路由策略也可以自行在此路径下加入site.dat等文件

可选的平台参数：

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

## 脚本安装（路由）

路由器CPU平台请自行查询确认，可选的平台参数同上

ssh登陆到路由器执行脚本，注意替换平台名称，路由器需联网及已安装wget。

```bash
wget https://raw.githubusercontent.com/felix-fly/v2ray-openwrt/master/install.sh
chmod +x install.sh
./install.sh 386
```

安装过程中需输入server域名及用户id，对于FPU选项，如果CPU不支持硬件浮点计算，则需要开启FPU。

脚本默认的v2ray版本可能不是最新，安装时可以手动输入当前最新版本。

## 手动安装方式（电脑）

### 下载v2ray

[release](https://github.com/felix-fly/v2ray-openwrt/releases)页面提供了各平台下的v2ray执行文件，可以直接下载使用。

默认已经过upx压缩，不支持压缩的保持不变。压缩包中仅包含v2ray执行文件，因为已经编译支持了json配置文件，运行不需要v2ctl。

### 上传软件及客户端配置文件

```
mkdir /etc/config/v2ray
cd /etc/config/v2ray
# 上传v2ray、config.json文件到该目录下，配置文件根据个人需求修改
chmod +x v2ray
```

### 添加服务

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

# 配置透明代理（可选）

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

# 尾声

v2ray一直在变化，现在已经将json解析默认内置了，之前的内容已经没有意义，故清理掉了，喜欢自行编译的小伙伴继续慢慢折腾。。。

# 更新记录
2020-12-23
* 添加目录
* 整理文案

2020-12-22
* 增加ipk打包脚本

2020-12-08
* 增加xray链接

2020-11-23
* 回退使用tls协议

2020-11-16
* 修改脚本使用新配置文件
* 脚本增加版本自定义

2020-11-13
* 使用xtls协议
* 优化文案

2020-07-08
* 增加server配置说明
* 优化文案

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

