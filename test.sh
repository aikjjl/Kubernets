5
固化IP
#getenforce
setenforce 0
systemctl stop firewalld
#epel源
yum install -y epel-release
#国内的base源
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
修改主机名(建议服务和主机不强关联)
hostnamectl set-hostname hdss7-11.host.com
hostnamectl set-hostname hdss7-12.host.com
hostnamectl set-hostname hdss7-21.host.com
hostnamectl set-hostname hdss7-22.host.com
hostnamectl set-hostname hdss7-200.host.com

#必要工具
yum install -y wget net-tools telnet tree nmap sysstat dos2unix bind-utils

#####################################自建DNS系统
7-11
yum install -y bind
配置文件
vi /etc/named.conf

    options   {
    listen-on port 53 { 10.4.7.11; };
    //listen-on-v6 port 53 { ::1; };        //IPV6禁用
    directory       "/var/named";
    dump-file       "/var/named/data/cache_dump.db";
    statistics-file "/var/named/data/named_stats.txt";
    memstatistics-file "/var/named/data/named_mem_stats.txt";
    recursing-file  "/var/named/data/named.recursing";
    secroots-file   "/var/named/data/named.secroots";
    allow-query     { any; };       //指定哪些客户端能用DNS解析
    forwarders      { 10.4.7.254; };        //上级DNS,访问外网时走
    /*
     - If you are building an AUTHORITATIVE DNS server, do NOT enable recursion.
    - If you are building a RECURSIVE (caching) DNS server, you need to enable
      recursion.
    - If your recursive DNS server has a public IP address, you MUST enable access
     control to limit queries to your legitimate users. Failing to do so will
    cause your server to become part of large scale DNS amplification
    attacks. Implementing BCP38 within your network would greatly
    reduce such attack surface
    */
    recursion yes;  //递归查询

    dnssec-enable no;       //关
    dnssec-validation no;   //关

    检查配置文件语法
    named-checkconf
    区域配置文件,最后添加

vi /etc/named.rfc1912.zones
    zone "host.com" IN {
          type master;
          file "host.com.zone";
          allow-update { 10.4.7.11; };
    };

    zone "hod.com" IN {
          type master;
          file "od.com.zone";
          allow-update { 10.4.7.11; };
    };



区域数据文件
vi /var/named/host.com.zone

$ORIGIN host.com.
$TTL 600        ; 10 minutes
@       IN SOA  dns.host.com. dnsadmin.host.com. (
                                2020053001  ; serial
                                10800       ; refresh (3 hours)
                                900         ; retry (15 minutes)
                                604800      ; expire (1 week)
                                86400       ; minmum (1 day)
                                )
                        NS dns.host.com.
$TTL 60; 1 minutes
dns       A   10.4.7.11
hdss7-11  A   10.4.7.11
hdss7-12  A   10.4.7.12
hdss7-21  A   10.4.7.21
hdss7-22  A   10.4.7.22
hdss7-200 A   10.4.7.200
;注释

vi /var/named/od.com.zone

$ORIGIN od.com.
$TTL 600        ; 10 minutes
@       IN SOA  dns.od.com. dnsadmin.od.com. (
                                2020053001  ; serial
                                10800       ; refresh (3 hours)
                                900         ; retry (15 minutes)
                                604800      ; expire (1 week)
                                86400       ; minmum (1 day)
                                )
                        NS dns.od.com.
$TTL 60; 1 minutes
dns       A   10.4.7.11


检查配置文件语法
named-checkconf
启动bind
systemctl start named
解析测试
dig -t A hdss7-21.host.com @10.4.7.11 +short

5
修改DNS1 10.4.7.11
修改win机的首选dns 10.4.7.11，自动跃点选10





#####################################自签证书
hdss-200
/usr/bin/下
wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -O /usr/bin/cfssl
wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 -O /usr/bin/cfssl-json
wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64 -O /usr/bin/cfssl-certinfo
chmod +x /usr/bin/cfssl*
cd /opt/
mkdir certs
cd certs
根证书
vi opt/certs/ca-csr.json
{
    "CN": "OldboyEdu",
    "host": [
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
      {
        "C": "CN",
        "ST": "guangdong",
        "L": "shenzhen",
        "O": "d",
        "OU": "devops"
      }
    ],
    "ca": {
        "expiry": "1000000h"
    }
}

#生成证书并承载在文件
cfssl gencert -initca ca-csr.json | cfssl-json -bare ca


#####################################docker
hdss7-200
hdss7-21
hdss7-22

curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
mkdir -p /data/docker

hdss7-200
vi /etc/docker/daemon.json
{
  "graph": "/data/docker",
  "storage-driver": "overlay2",
  "insecure-registries": ["registry.access.redhat.com","quay.io","harbor.od.com"],
  "registries-mirrors": ["https://q2gro4ke.mirror.aliyuncs.com"],
  "bip": "172.17.200.1/24",
  "exec-opts": ["native.cgroupdriver=systemd"],
  "live-restore": true
}

hdss7-21
vi /etc/docker/daemon.json
{
  "graph": "/data/docker",
  "storage-driver": "overlay2",
  "insecure-registries": ["registry.access.redhat.com","quay.io","harbor.od.com"],
  "registries-mirrors": ["https://q2gro4ke.mirror.aliyuncs.com"],
  "bip": "172.17.21.1/24",
  "exec-opts": ["native.cgroupdriver=systemd"],
  "live-restore": true
}

hdss7-22
vi /etc/docker/daemon.json
{
  "graph": "/data/docker",
  "storage-driver": "overlay2",
  "insecure-registries": ["registry.access.redhat.com","quay.io","harbor.od.com"],
  "registries-mirrors": ["https://q2gro4ke.mirror.aliyuncs.com"],
  "bip": "172.17.22.1/24",
  "exec-opts": ["native.cgroupdriver=systemd"],
  "live-restore": true
}

systemctl start docker



#####################################私有镜像仓库
hdss7-200
建议选1.7.5以上
mkdir /opt/src
wget https://github.com/goharbor/harbor/releases/download/v1.8.5/harbor-offline-installer-v1.8.5.tgz
tar zxf harbor-offline-installer-v1.8.5.tgz -C /opt/
ln -s /opt/harbor-v1.8.5/ /opt/harbor  #做个软链接，便于升级

vim harbor.yml
hostname: harbor.od.com
port: 180
harbor_admin_password: Harbor12345
data_volume: /data/harbor
location: /data/harbor/logs


mkdir -p /data/harbor/logs
yum install -y docker-compose
./install.sh
docker-compose ps
yum install -y nginx

vim /etc/nginx/conf.d/harbor.od.com.conf
server {
  listen  80;
  server_name harbor.od.com;
  client_max_body_size 1000m;
  location / {
      proxy_pass http://127.0.0.1:180;
    }

  }

nginx -t
systemctl start nginx
systemctl enable nginx


hdss7-11
vi /var/named/od.com.zone
注意前滚序号
harbor          A               10.4.7.200

systemctl restart named
dig -t A harbor.od.com +short

浏览器打开harbor.od.com验证

hdss7-200
docker pull nginx:1.7.9
docker tag 84581e99d807 harbor.od.com/public/nginx:1.7.9  打镜像
docker login harbor.od.com
docker push















