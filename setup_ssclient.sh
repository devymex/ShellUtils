if [[ $# -lt 4 ]]; then
	echo "Usage: "$0" <SERVER_IP> <SERVER_PORT> <PROXY_PSWD> <LOCAL_PORT>"
	exit 0
fi

sudo apt-get -y install --no-install-recommends git gettext build-essential \
	autoconf libtool libpcre3-dev asciidoc xmlto libev-dev libc-ares-dev \
	automake libmbedtls-dev libsodium-dev libssl-dev

rm -rf shadowsocks-libev
git clone https://github.com/shadowsocks/shadowsocks-libev.git
cd shadowsocks-libev
git submodule update --init --recursive
./autogen.sh && ./configure && make
sudo make install
cd ..

rm -rf shadowsocks-obfs
git clone https://github.com/shadowsocks/simple-obfs.git
cd simple-obfs
git submodule update --init --recursive
./autogen.sh && ./configure && make
sudo make install
cd ..

IP=$1
SP=$2
PW=$3
LP=$4
sudo mkdir -p /etc/shadowsocks
printf "{\n\"server\":\"$IP\",\n\"server_port\":$SP,\n\"password\":\"$PW\",\n\
\"method\":\"chacha20-ietf-poly1305\",\n\"plugin\":\"obfs-local\",\n\
\"local_port\":$LP,\n\"plugin_opts\":\"obfs=http;obfs-host=www.bing.com\"\n}"\
> $IP.json
sudo mv $IP.json /etc/shadowsocks/

printf "[Unit]\nDescription=Shadowsocks-libev Default Local Service\n\
Documentation=man:shadowsocks-libev(8)\nAfter=network.target\n\n\
[Service]\nType=simple\nUser=root\nGroup=root\nLimitNOFILE=32768\n\
ExecStart=/usr/local/bin/ss-local -c /etc/shadowsocks/$IP.json\n\
CapabilityBoundingSet=CAP_NET_BIND_SERVICE\n\n[Install]\n\
WantedBy=multi-user.target\n" > ss-client@$IP.service
sudo mv ss-client@$IP.service /etc/systemd/system/

sudo systemctl daemon-reload
sudo systemctl start ss-client@$IP
sudo systemctl enable ss-client@$IP

