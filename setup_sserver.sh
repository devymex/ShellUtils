#!/bin/bash

if [[ $# -lt 3 ]]; then
	echo "Usage: "$0" <SERVER_IP> <SERVER_PORT> <PROXY_PSWD>"
	exit 0
fi

apt-get update
apt-get -y install --no-install-recommends git gettext build-essential \
	autoconf libtool libpcre3-dev asciidoc xmlto libev-dev libc-ares-dev \
	automake libmbedtls-dev libsodium-dev libssl-dev

rm -rf shadowsocks-libev
git clone https://github.com/shadowsocks/shadowsocks-libev.git
cd shadowsocks-libev
git submodule update --init --recursive
./autogen.sh && ./configure && make
make install
cd ..

rm -rf shadowsocks-obfs
git clone https://github.com/shadowsocks/simple-obfs.git
cd simple-obfs
git submodule update --init --recursive
./autogen.sh && ./configure && make
make install
cd ..

IP=$1
SP=$2
PW=$3
mkdir -p /etc/shadowsocks
printf "{\n\"server\":\"$IP\",\n\"server_port\":$SP,\n\"password\":\"$PW\",\n\
\"method\":\"chacha20-ietf-poly1305\",\n\"plugin\":\"obfs-server\",\n\
\"plugin_opts\":\"obfs=http\"\n}"\
> /etc/shadowsocks/server.json

printf "[Unit]\nDescription=Shadowsocks-libev Default Local Service\n\
Documentation=man:shadowsocks-libev(8)\nAfter=network.target\n\
[Service]\nType=simple\nUser=root\nGroup=root\nLimitNOFILE=32768\n\
ExecStart=/usr/local/bin/ss-server -c /etc/shadowsocks/server.json\n\
CapabilityBoundingSet=CAP_NET_BIND_SERVICE\n[Install]\n\
WantedBy=multi-user.target\n" > /etc/systemd/system/ss-server.service
systemctl daemon-reload
systemctl start ss-server
systemctl enable ss-server
ps -aux | grep ss-server
