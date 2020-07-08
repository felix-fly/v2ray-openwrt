# ubuntu 18.04下配置acme nginx及v2ray

## 服务器（vps）

自行搭建v2ray服务首先就需要有一个独立的服务器，俗称vps，有免费的，但是有些门槛，付费才是王道，当然也有不同的选择，这里会有价格、配置、线路等等很多方面的因素，详细的就不展开了，估计一天也说不完。笔者目前在用aws的[lightsail](https://aws.amazon.com/cn/lightsail/)，最低月租3.5刀，性价比还可以。

服务器操作系统此处选用的是ubuntu 18.04，其它的linux发行版可以参考。

配置环境，安装软件

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install wget unzip nginx -y
sudo mkdir /opt/www
sudo mkdir /opt/nginx-logs
sudo chown -R ubuntu:www-data /opt/www
```

## 域名

免费的不建议，可以找那种首年1元或者1美元的，用一年再换个，注册好了将域名的解析服务器指向cloudflare，这里是为了acme申请证书时方便使用，当然你也可以用自己喜欢的域名服务商。

将域名成功添加到cloudflare后，在域名概述页面右下方可以看到*区域ID*和*账户ID*

点击*获取您的 API 令牌*来创建API令牌，模板选*编辑区域 DNS*，*权限*默认编辑，*区域资源*可以指定特定区域（域名）也可所有区域，创建成功复制下令牌，后面需要。

添加YOUR_DOMAIN的域名解析A记录指向服务器ip，等后面配置完成应该也差不多生效了。

```bash
export CF_Token=复制的令牌
export CF_Account_ID=账户ID
export CF_Zone_ID=区域ID
```

## 安装配置acme获取免费证书

```bash
curl https://get.acme.sh | sh
source ~/.bashrc
~/.acme.sh/acme.sh --issue --dns dns_cf --dnssleep 30 -d YOUR_DOMAIN
```

## 配置nginx

修改YOUR_DOMAIN为你的域名

```bash
sudo rm /etc/nginx/sites-enabled/default
sudo bash -c 'cat > /etc/nginx/conf.d/default.conf<<EOF
server {
  listen 443 ssl http2;
  server_name YOUR_DOMAIN;
  index index.html;
  add_header Strict-Transport-Security "max-age=63072000; includeSubdomains; preload";
  ssl_certificate /home/ubuntu/.acme.sh/YOUR_DOMAIN/fullchain.cer;
  ssl_certificate_key /home/ubuntu/.acme.sh/YOUR_DOMAIN/YOUR_DOMAIN.key;
  ssl_ciphers TLS_CHACHA20_POLY1305_SHA256:TLS-AES-128-GCM-SHA256;
  ssl_protocols TLSv1.3;
  ssl_prefer_server_ciphers on;
  ssl_session_cache shared:SSL:10m;
  access_log /opt/nginx-logs/access.log;
  error_log /opt/nginx-logs/error.log;
  root /opt/www;
  location /path/ {
    proxy_redirect off;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host \$http_host;
    if (\$http_upgrade = "websocket" ) {
      proxy_pass http://127.0.0.1:1443;
    }
  }
}
EOF'
```

## 安装配置v2ray

可以使用官方的脚本安装，也可以安装笔者的单文件版。

```bash
V2RAY=4.26.0
sudo mkdir /etc/v2ray
wget https://github.com/felix-fly/v2ray-openwrt/releases/download/$V2RAY/v2ray-linux-amd64.tar.gz
sudo tar -xzvf v2ray-linux-amd64.tar.gz -C /etc/v2ray
sudo chmod +x /etc/v2ray/v2ray
rm v2ray-linux-amd64.tar.gz
sudo wget -P /etc/v2ray/ https://raw.githubusercontent.com/felix-fly/v2ray-openwrt/master/ubuntu/v2ray.service
sudo ln -s /etc/v2ray/v2ray.service /lib/systemd/system/
sudo systemctl enable v2ray.service
```

修改YOUR_ID及path

```bash
sudo bash -c 'cat > /etc/v2ray/config.json<<EOF
{
  "inbounds": [{
    "port": 1443,
    "protocol": "vmess",
    "settings": {
      "clients": [{
        "id": "YOUR_ID",
        "alterId": 4
      }]
    },
    "streamSettings": {
      "network": "ws",
      "wsSettings": {
        "path": "/path/"
      }
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  }]
}
EOF'
```

## 测试

最好重启一下server，本地开启v2ray配置好相关参数，hi起来
