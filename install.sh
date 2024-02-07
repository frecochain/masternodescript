#!/bin/bash

PORT=49330
RPCPORT=49331
CONF_DIR=~/.freco
COINZIP='https://github.com/frecochain/FRECO/releases/download/v1.0/freco-linux.zip'

cd ~
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 must be run as root.${NC}"
   exit 1
fi

function configure_systemd {
  cat << EOF > /etc/systemd/system/freco.service
[Unit]
Description=Freco Service
After=network.target
[Service]
User=root
Group=root
Type=forking
ExecStart=/usr/local/bin/frecod
ExecStop=-/usr/local/bin/freco-cli stop
Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5
[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  sleep 2
  systemctl enable freco.service
  systemctl start freco.service
}

echo ""
echo ""
DOSETUP="y"

if [ $DOSETUP = "y" ]  
then
  apt-get update
  apt install zip unzip git curl wget -y
  cd /usr/local/bin/
  wget $COINZIP
  unzip *.zip
  rm freco-qt freco-tx freco-linux.zip
  chmod +x freco*
  
  mkdir -p $CONF_DIR
  cd $CONF_DIR

fi

 IP=$(curl -s4 api.ipify.org)
 echo ""
 echo "Configure your masternodes now!"
 echo "Detecting IP address:$IP"
 echo ""
 echo "Enter masternode private key"
 read PRIVKEY
 
  echo "rpcuser=user"`shuf -i 100000-10000000 -n 1` >> freco.conf_TEMP
  echo "rpcpassword=pass"`shuf -i 100000-10000000 -n 1` >> freco.conf_TEMP
  echo "rpcallowip=127.0.0.1" >> freco.conf_TEMP
  echo "rpcport=$RPCPORT" >> freco.conf_TEMP
  echo "listen=1" >> freco.conf_TEMP
  echo "server=1" >> freco.conf_TEMP
  echo "daemon=1" >> freco.conf_TEMP
  echo "maxconnections=250" >> freco.conf_TEMP
  echo "masternode=1" >> freco.conf_TEMP
  echo "" >> freco.conf_TEMP
  echo "port=$PORT" >> freco.conf_TEMP
  echo "externalip=$IP:$PORT" >> freco.conf_TEMP
  echo "masternodeaddr=$IP:$PORT" >> freco.conf_TEMP
  echo "masternodeprivkey=$PRIVKEY" >> freco.conf_TEMP
  mv freco.conf_TEMP freco.conf
  cd
  echo ""
  echo -e "Your ip is ${GREEN}$IP:$PORT${NC}"

	## Config Systemctl
	configure_systemd
  
echo ""
echo "Commands:"
echo -e "Start Freco Service: ${GREEN}systemctl start freco${NC}"
echo -e "Check Freco Status Service: ${GREEN}systemctl status freco${NC}"
echo -e "Stop Freco Service: ${GREEN}systemctl stop freco${NC}"
echo -e "Check Masternode Status: ${GREEN}freco-cli getmasternodestatus${NC}"

echo ""
echo -e "${GREEN}Freco Masternode Installation Done${NC}"
exec bash
exit