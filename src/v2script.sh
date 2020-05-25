#!/bin/bash
export LC_ALL=C
export LANG=C
export LANGUAGE=en_US.UTF-8

branch="master"
VERSION="$(curl -fsL https://api.github.com/repos/phlinhng/v2ray-tcp-tls-web/releases/latest | grep tag_name | sed -E 's/.*"v(.*)".*/\1/')"

# /usr/local/bin/v2script ##main
# /usr/local/bin/v2sub ##subscription manager
# /usr/local/etc/v2script/config.json ##config

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
  sudoCmd="sudo"
else
  sudoCmd=""
fi

# copied from v2ray official script
# colour code
RED="31m"      # Error message
GREEN="32m"    # Success message
YELLOW="33m"   # Warning message
BLUE="36m"     # Info message
# colour function
colorEcho(){
  echo -e "\033[${1}${@:2}\033[0m" 1>& 2
}

#copied & modified from atrandys trojan scripts
#copy from 秋水逸冰 ss scripts
if [[ -f /etc/redhat-release ]]; then
  release="centos"
  systemPackage="yum"
  #colorEcho ${RED} "unsupported OS"
  #exit 0
elif cat /etc/issue | grep -Eqi "debian"; then
  release="debian"
  systemPackage="apt-get"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
  release="ubuntu"
  systemPackage="apt-get"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
  release="centos"
  systemPackage="yum"
  #colorEcho ${RED} "unsupported OS"
  #exit 0
elif cat /proc/version | grep -Eqi "debian"; then
  release="debian"
  systemPackage="apt-get"
elif cat /proc/version | grep -Eqi "ubuntu"; then
  release="ubuntu"
  systemPackage="apt-get"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
  release="centos"
  systemPackage="yum"
  #colorEcho ${RED} "unsupported OS"
  #exit 0
fi

# a trick to redisplay menu option
show_menu() {
  echo ""
  echo "1) 安装TCP+TLS+WEB"
  echo "2) 更新v2Ray-core"
  echo "3) 卸载TCP+TLS+WEB"
  echo "4) 显示vmess链接"
  echo "5) 管理订阅"
  echo "6) 设置电报代理"
  echo "7) VPS工具"
}

continue_prompt() {
  read -p "继续其他操作 (yes/no)? " choice
  case "${choice}" in
    y|Y|[yY][eE][sS] ) show_menu ;;
    * ) exit 0;;
  esac
}

read_json() {
  # jq [key] [path-to-file]
  ${sudoCmd} jq --raw-output $2 $1 2>/dev/null | tr -d '\n'
} ## read_json [path-to-file] [key]

write_json() {
  # jq [key = value] [path-to-file]
  jq -r "$2 = $3" $1 > tmp.$$.json && ${sudoCmd} mv tmp.$$.json $1 && sleep 1
} ## write_json [path-to-file] [key = value]

display_vmess() {
  if [[ $(read_json /usr/local/etc/v2script/config.json '.v2ray.install') != "true" ]]; then
    local V2_DOMAIN="$(read_json /usr/local/etc/v2script/config.json '.v2ray.tlsHeader')"
    local uuid="$(read_json /etc/v2ray/config.json '.inbounds[0].settings.clients[0].id')"
    local json="{\"add\":\"${V2_DOMAIN}\",\"aid\":\"0\",\"host\":\"\",\"id\":\"${uuid}\",\"net\":\"\",\"path\":\"\",\"port\":\"443\",\"ps\":\"${V2_DOMAIN}:443\",\"tls\":\"tls\",\"type\":\"none\",\"v\":\"2\"}"
    local uri="$(printf "${json}" | base64)"
    echo "vmess://${uri}" | tr -d '\n' && printf "\n"
  else
    colorEcho ${RED} "配置文件不存在"
    return 1
  fi
}

display_vmess_full() {
  if [ ! -d "/usr/bin/v2ray" ]; then
    colorEcho ${RED} "尚末安装v2Ray"
    return 1
  elif [ ! -f "/usr/local/etc/v2script/config.json" ]; then
    colorEcho ${RED} "配置文件不存在"
    return 1
  fi

  #${sudoCmd} ${systemPackage} install coreutils jq -y
  local V2_DOMAIN="$(read_json /usr/local/etc/v2script/config.json '.v2ray.tlsHeader')"
  local uuid="$(read_json /etc/v2ray/config.json '.inbounds[0].settings.clients[0].id')"
  local json="{\"add\":\"${V2_DOMAIN}\",\"aid\":\"0\",\"host\":\"\",\"id\":\"${uuid}\",\"net\":\"\",\"path\":\"\",\"port\":\"443\",\"ps\":\"${V2_DOMAIN}:443\",\"tls\":\"tls\",\"type\":\"none\",\"v\":\"2\"}"
  local uri="$(printf "${json}" | base64)"
  write_json /usr/local/etc/v2script/config.json '.sub.nodes[0]' "$(printf "\"vmess://${uri}\"" | tr -d '\n')"

  echo "${V2_DOMAIN}:443"
  echo "${uuid} (aid: 0)" && echo ""
  echo "vmess://${uri}" | tr -d '\n' && printf "\n"
}

generate_link() {
  if [ ! -d "/usr/bin/v2ray" ]; then
    colorEcho ${RED} "尚末安装v2Ray"
    return 1
  elif [ ! -f "/usr/local/etc/v2script/config.json" ]; then
    colorEcho ${RED} "配置文件不存在"
    return 1
  fi

  if [ "$(read_json /usr/local/etc/v2script/config.json '.sub.enabled')" != "true" ]; then
    write_json /usr/local/etc/v2script/config.json '.sub.enabled' "true"
  fi

  if [ "$(read_json /usr/local/etc/v2script/config.json '.sub.uri')" != "" ]; then
    write_json /usr/local/etc/v2script/config.json '.sub.uri' \"\"
  fi

  #${sudoCmd} ${systemPackage} install uuid-runtime coreutils jq -y
  local uuid="$(read_json /etc/v2ray/config.json '.inbounds[0].settings.clients[0].id')"
  local V2_DOMAIN="$(read_json /usr/local/etc/v2script/config.json '.v2ray.tlsHeader')"

  read -p "输入节点名称[留空则使用默认值]: " remark

  if [ -z "${remark}" ]; then
    remark="${V2_DOMAIN}:443"
  fi

  local json="{\"add\":\"${V2_DOMAIN}\",\"aid\":\"0\",\"host\":\"\",\"id\":\"${uuid}\",\"net\":\"\",\"path\":\"\",\"port\":\"443\",\"ps\":\"${remark}\",\"tls\":\"tls\",\"type\":\"none\",\"v\":\"2\"}"
  local uri="$(printf "${json}" | base64)"
  local sub="$(printf "vmess://${uri}" | tr -d '\n' | base64)"

  local randomName="$(uuidgen | sed -e 's/-//g' | tr '[:upper:]' '[:lower:]' | head -c 16)" #random file name for subscription
  write_json /usr/local/etc/v2script/config.json '.sub.uri' "\"${randomName}\""

  printf "${sub}" | tr -d '\n' | ${sudoCmd} tee /var/www/html/${randomName} >/dev/null
  echo "https://${V2_DOMAIN}/${randomName}" | tr -d '\n' && printf "\n"
}

get_docker() {
  if [ ! -x "$(command -v docker)" ]; then
    curl -sL https://get.docker.com/ | ${sudoCmd} bash
    # install docker-compose
    #${sudoCmd} curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    #${sudoCmd} chmod +x /usr/local/bin/docker-compose
  fi
}

set_docker() {
  if [[ $(read_json /usr/local/etc/v2script/config.json '.mtproto.installed') == "true" ]]; then
    if [ ! "$(${sudoCmd} docker ps -q --filter ancestor=nineseconds/mtg)" ]; then
      ${sudoCmd} docker rm $(${sudoCmd} docker stop $(${sudoCmd} docker ps -q --filter ancestor=nineseconds/mtg) 2>/dev/null) 2>/dev/null
      # start mtproto ## reference https://raw.githubusercontent.com/9seconds/mtg/master/run.sh
      ${sudoCmd} docker run -d --restart=always --name mtg --ulimit nofile=51200:51200 -p 127.0.0.1:3128:3128 nineseconds/mtg:latest run "$(read_json /usr/local/etc/v2script/config.json '.mtproto.secret')"
    fi
  fi

  if [[ $(read_json /usr/local/etc/v2script/config.json '.sub.api.installed') == "true" ]]; then
    if [ ! "$(${sudoCmd} docker ps -q --filter ancestor=tindy2013/subconverter)" ]; then
      ${sudoCmd} docker rm $(${sudoCmd} docker stop $(${sudoCmd} docker ps -q --filter ancestor=tindy2013/subconverter) 2>/dev/null) 2>/dev/null
      ${sudoCmd} docker run -d --restart=always -p 127.0.0.1:25500:25500 -v /usr/local/etc/v2script/pref.ini:/base/pref.ini tindy2013/subconverter:latest
    fi
  fi
}

get_proxy() {
  if [ ! -f "/usr/local/bin/tls-shunt-proxy" ]; then
    colorEcho ${BLUE} "tls-shunt-proxy is not installed. start installation"
    curl -sL https://raw.githubusercontent.com/liberal-boy/tls-shunt-proxy/master/dist/install.sh | ${sudoCmd} bash
    colorEcho ${GREEN} "tls-shunt-proxy is installed."
  fi
}

set_proxy() {
  ${sudoCmd} /bin/cp /etc/tls-shunt-proxy/config.yaml /etc/tls-shunt-proxy/config.yaml.bak 2>/dev/null
  wget -q https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/config/config.yaml -O /tmp/config_new.yaml

  if [[ $(read_json /usr/local/etc/v2script/config.json '.v2ray.installed') == "true" ]]; then
    sed -i "s/FAKEV2DOMAIN/$(read_json /usr/local/etc/v2script/config.json '.v2ray.tlsHeader')/g" /tmp/config_new.yaml
    sed -i "s/##V2RAY@//g" /tmp/config_new.yaml
  fi

  if [[ $(read_json /usr/local/etc/v2script/config.json '.sub.api.installed') == "true" ]]; then
    sed -i "s/FAKEAPIDOMAIN/$(read_json /usr/local/etc/v2script/config.json '.sub.api.tlsHeader')/g" /tmp/config_new.yaml
    sed -i "s/##SUBAPI@//g" /tmp/config_new.yaml
  fi

  if [[ $(read_json /usr/local/etc/v2script/config.json '.mtproto.installed') == "true" ]]; then
    sed -i "s/FAKEMTDOMAIN/$(read_json /usr/local/etc/v2script/config.json '.mtproto.fakeTlsHeader')/g" /tmp/config_new.yaml
    sed -i "s/##MTPROTO@//g" /tmp/config_new.yaml
  fi

  ${sudoCmd} /bin/cp -f /tmp/config_new.yaml /etc/tls-shunt-proxy/config.yaml
}

get_caddy() {
  if [ ! -f "/usr/local/bin/caddy" ]; then
    ${sudoCmd} ${systemPackage} libcap2-bin -y -qq
    
    curl -sL https://getcaddy.com | ${sudoCmd} bash -s personal
    # Give the caddy binary the ability to bind to privileged ports (e.g. 80, 443) as a non-root user
    ${sudoCmd} setcap 'cap_net_bind_service=+ep' /usr/local/bin/caddy

    # create user for caddy
    ${sudoCmd} groupadd -g 33 www-data
    ${sudoCmd} useradd -g www-data --no-user-group --no-create-home --shell /usr/sbin/nologin --system --uid 33 www-data
  
    ${sudoCmd} mkdir -p /usr/local/etc/caddy && ${sudoCmd} chown -R root:root /usr/local/etc/caddy
    ${sudoCmd} mkdir -p /usr/local/etc/ssl/caddy && ${sudoCmd} chown -R root:www-data /usr/local/etc/ssl/caddy
    ${sudoCmd} chmod 0770 /usr/local/etc/ssl/caddy
    
    local caddy_service=$(mktemp)
    cat > ${caddy_service} <<-EOF
[Unit]
Description=Caddy HTTP/2 web server
Documentation=https://caddyserver.com/docs
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service

\; Do not allow the process to be restarted in a tight loop. If the
\; process fails to start, something critical needs to be fixed.
StartLimitIntervalSec=14400
StartLimitBurst=10

[Service]
Restart=on-abnormal

\; User and group the process will run as.
User=www-data
Group=www-data

\; Letsencrypt-issued certificates will be written to this directory.
Environment=CADDYPATH=/usr/local/etc/ssl/caddy

\; Always set "-root" to something safe in case it gets forgotten in the Caddyfile.
ExecStart=/usr/local/bin/caddy -log stdout -log-timestamps=false -agree=true -conf=/usr/local/etc/caddy/Caddyfile -root=/var/tmp
ExecReload=/bin/kill -USR1 $MAINPID

\; Use graceful shutdown with a reasonable timeout
KillMode=mixed
KillSignal=SIGQUIT
TimeoutStopSec=5s

\; Limit the number of file descriptors; see `man systemd.exec` for more limit settings.
LimitNOFILE=1048576
\; Unmodified caddy is not expected to use more than that.
LimitNPROC=512

\; Use private /tmp and /var/tmp, which are discarded after caddy stops.
PrivateTmp=true
\; Use a minimal /dev (May bring additional security if switched to 'true', but it may not work on Raspberry Pi's or other devices, so it has been disabled in this dist.)
PrivateDevices=false
\; Hide /home, /root, and /run/user. Nobody will steal your SSH-keys.
ProtectHome=true
\; Make /usr, /boot, /etc and possibly some more folders read-only.
ProtectSystem=full
\; … except /etc/ssl/caddy, because we want Letsencrypt-certificates there.
\;   This merely retains r/w access rights, it does not add any new. Must still be writable on the host!
ReadWritePaths=/etc/ssl/caddy
ReadWriteDirectories=/etc/ssl/caddy

\; The following additional security directives only work with systemd v229 or later.
\; They further restrict privileges that can be gained by caddy. Uncomment if you like.
\; Note that you may have to add capabilities required by any plugins in use.
\;CapabilityBoundingSet=CAP_NET_BIND_SERVICE
\;AmbientCapabilities=CAP_NET_BIND_SERVICE
\;NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF
    
    ${sudoCmd} mv ${caddy_service} /etc/systemd/system/caddy.service
    ${sudoCmd} chown root:root /etc/systemd/system/caddy.service
    ${sudoCmd} chmod 644 /etc/systemd/system/caddy.service
  fi
}

get_v2ray() {
  ${sudoCmd} ${systemPackage} install curl -y -qq
  curl -sL https://install.direct/go.sh | ${sudoCmd} bash
}

install_v2ray() {
  read -p "解析到本VPS的域名: " V2_DOMAIN
  write_json /usr/local/etc/v2script/config.json ".v2ray.tlsHeader" "\"${V2_DOMAIN}\""

  # install requirements
  # coreutils: for base64 command
  # uuid-runtime: for uuid generating
  # ntp: time syncronise service
  # jq: json toolkits
  # unzip: to decompress web templates
  ${sudoCmd} ${systemPackage} update -qq
  ${sudoCmd} ${systemPackage} install curl coreutils wget ntp jq uuid-runtime unzip -y -qq

  cd $(mktemp -d)
  wget -q https://github.com/phlinhng/v2ray-tcp-tls-web/archive/${branch}.zip
  unzip -q ${branch}.zip && rm -f ${branch}.zip ## will unzip the source to current path and remove the archive file
  cd v2ray-tcp-tls-web-${branch}

  if [ ! -d "/usr/local/etc/v2script" ]; then
    mkdir -p /usr/local/etc/v2script ## folder for scripts configuration
  elif [ ! -f "/usr/local/etc/v2script/config.json" ]; then
    wget -q https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/config/v2scirpt.json -O /usr/local/etc/v2script/config.json
  fi

  # install v2ray-core
  if [ ! -d "/usr/bin/v2ray" ]; then
    get_v2ray
    colorEcho ${BLUE} "Building v2ray.service for domainsocket"
    local ds_service=$(mktemp)
    cat > ${ds_service} <<-EOF
[Unit]
Description=V2Ray - A unified platform for anti-censorship
Documentation=https://v2ray.com https://guide.v2fly.org
After=network.target nss-lookup.target
Wants=network-online.target

[Service]
# If the version of systemd is 240 or above, then uncommenting Type=exec and commenting out Type=simple
#Type=exec
Type=simple
# Runs as root or add CAP_NET_BIND_SERVICE ability can bind 1 to 1024 port.
# This service runs as root. You may consider to run it as another user for security concerns.
# By uncommenting User=v2ray and commenting out User=root, the service will run as user v2ray.
# More discussion at https://github.com/v2ray/v2ray-core/issues/1011
#User=root
User=v2ray
CapabilityBoundingSet=CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=yes

ExecStartPre=$(which mkdir) -p /tmp/v2ray-ds
ExecStartPre=$(which rm) -rf /tmp/v2ray-ds/*.sock

ExecStart=/usr/bin/v2ray/v2ray -config /etc/v2ray/config.json

ExecStartPost=$(which sleep) 1
ExecStartPost=$(which chmod) 666 /tmp/v2ray-ds/v2ray.sock

Restart=on-failure
#Restart=always
#RestartSec=10
# Don't restart in the case of configuration error
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
EOF
    # add new user and overwrite v2ray.service
    # https://github.com/v2ray/v2ray-core/issues/1011
    ${sudoCmd} useradd -d /etc/v2ray/ -M -s /sbin/nologin v2ray
    ${sudoCmd} mv ${ds_service} /etc/systemd/system/v2ray.service
    ${sudoCmd} chown -R v2ray:v2ray /var/log/v2ray
    write_json /usr/local/etc/v2script/config.json ".v2ray.installed" "true"
  fi

  # install tls-shunt-proxy
  get_proxy
  
  # install caddy
  ${sudoCmd} docker rm $(${sudoCmd} docker stop $(${sudoCmd} docker ps -q --filter ancestor=abiosoft/caddy) 2>/dev/null) 2>/dev/null
  get_caddy

  # prevent some bug
  ${sudoCmd} rm -rf /var/www/html
  ${sudoCmd} rm -rf /usr/local/etc/ssl/caddy/*
  ${sudoCmd} rm -f /usr/local/etc/Caddyfile # path for old version v2script

  # create config files
  colorEcho ${BLUE} "Setting v2Ray"
  sed -i "s/FAKEPORT/$(read_json /etc/v2ray/config.json '.inbounds[0].port')/g" ./config/v2ray.json
  sed -i "s/FAKEUUID/$(read_json /etc/v2ray/config.json '.inbounds[0].settings.clients[0].id')/g" ./config/v2ray.json
  ${sudoCmd} /bin/cp -f ./config/v2ray.json /etc/v2ray/config.json

  colorEcho ${BLUE} "Setting tls-shunt-proxy"
  set_proxy

  colorEcho ${BLUE} "Setting caddy"
  sed -i "s/FAKEV2DOMAIN/${V2_DOMAIN}/g" ./config/Caddyfile
  ${sudoCmd} /bin/cp -f ./config/Caddyfile /usr/local/etc/caddy

  # choose and copy a random  template for dummy web pages
  colorEcho ${BLUE} "Building dummy web site"
  local template="$(curl -s https://raw.githubusercontent.com/phlinhng/web-templates/master/list.txt | shuf -n  1)"
  wget -q https://raw.githubusercontent.com/phlinhng/web-templates/master/${template}
  ${sudoCmd} mkdir -p /var/www/html
  ${sudoCmd} unzip -q ${template} -d /var/www/html
  ${sudoCmd} /bin/cp -f ./custom/robots.txt /var/www/html/robots.txt

  # set crontab to auto update geoip.dat and geosite.dat
  (crontab -l 2>/dev/null; echo "0 7 * * * wget -q https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geoip.dat -O /usr/bin/v2ray/geoip.dat >/dev/null >/dev/null") | ${sudoCmd} crontab -
  (crontab -l 2>/dev/null; echo "0 7 * * * wget -q https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geosite.dat -O /usr/bin/v2ray/geosite.dat >/dev/null >/dev/null") | ${sudoCmd} crontab -

  # stop nginx service for user who had used the old version of script
  #${sudoCmd} systemctl stop nginx 2>/dev/null
  #${sudoCmd} systemctl disable nginx 2>/dev/null

  # kill process occupying port 80
  ${sudoCmd} kill -9 $(lsof -t -i:80) 2>/dev/null

  # activate services
  colorEcho ${BLUE} "Activating services"
  ${sudoCmd} systemctl enable ntp
  ${sudoCmd} systemctl start ntp
  ${sudoCmd} systemctl enable v2ray
  ${sudoCmd} systemctl restart v2ray ## restart v2ray to enable new config
  ${sudoCmd} systemctl enable tls-shunt-proxy
  ${sudoCmd} systemctl restart tls-shunt-proxy ## restart tls-shunt-proxy to enable new config
  ${sudoCmd} systemctl enable caddy
  ${sudoCmd} systemctl restart caddy
  ${sudoCmd} systemctl daemon-reload
  ${sudoCmd} systemctl reset-failed

  colorEcho ${GREEN} "安装TCP+TLS+WEB成功!"
  display_vmess_full

  read -p "生成订阅链接 (yes/no)? " linkConfirm
  case "${linkConfirm}" in
    y|Y|[yY][eE][sS] ) generate_link ;;
    * ) return 0;;
  esac
}

rm_v2script() {
  ${sudoCmd} ${systemPackage} install curl -y -qq
  curl -sL https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/tools/rm_v2script.sh | bash
  exit 0
}

display_mtproto() {
  if [[ $(read_json /usr/local/etc/v2script/config.json '.v2ray.tlsHeader') == "" ]] &&  [[ $(read_json /usr/local/etc/v2script/config.json '.mtproto.secret') != "" ]];then
    echo "tg://proxy?server=`curl -s https://api.ipify.org`&port=443&secret=$(read_json /usr/local/etc/v2script/config.json '.mtproto.secret')"
  elif  [[ $(read_json /usr/local/etc/v2script/config.json '.v2ray.installed') == "true" ]] &&  [ $(read_json /usr/local/etc/v2script/config.json '.mtproto.secret') != "" ];then
    echo "tg://proxy?server=$(read_json /usr/local/etc/v2script/config.json '.v2ray.tlsHeader')&port=443&secret=$(read_json /usr/local/etc/v2script/config.json '.mtproto.secret')"
  fi
}

install_mtproto() {
  if [[ $(read_json /usr/local/etc/v2script/config.json '.mtproto.installed') != "true" ]]; then
    ${sudoCmd} ${systemPackage} update -qq
    ${sudoCmd} ${systemPackage} install curl -y -qq

    if [ ! -d "/usr/local/etc/v2script" ]; then
      ${sudoCmd} mkdir -p /usr/local/etc/v2script ## folder for scripts configuration
    elif [ ! -f "/usr/local/etc/v2script/config.json" ]; then
      wget -q https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/config/v2scirpt.json -O /usr/local/etc/v2script/config.json
    fi

    get_proxy
    get_docker
    # pre-run this to pull image
    ${sudoCmd} docker run --rm nineseconds/mtg generate-secret tls -c "www.fast.com" >/dev/null

    # generate random header from txt files
    local FAKE_TLS_HEADER="$(curl -s https://raw.githubusercontent.com/phlinhng/my-scripts/master/text/mainland_cdn.txt | shuf -n 1)"
    local secret="$(${sudoCmd} docker run --rm nineseconds/mtg generate-secret tls -c ${FAKE_TLS_HEADER})"

    # writing configurations & setting tls-shunt-proxy
    write_json "/usr/local/etc/v2script/config.json" ".mtproto.installed" "true"
    write_json "/usr/local/etc/v2script/config.json" ".mtproto.fakeTlsHeader" "\"${FAKE_TLS_HEADER}\""
    write_json "/usr/local/etc/v2script/config.json" ".mtproto.secret" "\"${secret}\""
    set_proxy

    set_docker

    # activate service
    ${sudoCmd} systemctl enable docker
    ${sudoCmd} systemctl start docker
    ${sudoCmd} systemctl enable tls-shunt-proxy
    ${sudoCmd} systemctl restart tls-shunt-proxy
    ${sudoCmd} systemctl daemon-reload
    colorEcho ${GREEN} "电报代理设置成功!"
  fi

  display_mtproto
}

check_status() {
  printf "脚本状态: "
  if [[ $(read_json /usr/local/etc/v2script/config.json '.v2ray.installed') == "true" ]]; then
    colorEcho ${GREEN} "己安装"
  else
    colorEcho ${YELLOW} "未安装"
  fi

  if [[ $(read_json /usr/local/etc/v2script/config.json '.sub.enabled') == "true" ]]; then
    printf "订阅链接: "
    colorEcho ${GREEN} "https://$(read_json /usr/local/etc/v2script/config.json '.v2ray.tlsHeader')/$(read_json /usr/local/etc/v2script/config.json '.sub.uri')"
  fi

  printf "电报代理: "
  if [[ $(read_json /usr/local/etc/v2script/config.json '.v2ray.installed') == "false" ]] && [[ $(read_json /usr/local/etc/v2script/config.json '.mtproto.secret') != "" ]];then
    colorEcho ${GREEN} "tg://proxy?server=`curl -s https://api.ipify.org`&port=443&secret=$(read_json /usr/local/etc/v2script/config.json '.mtproto.secret')"
  elif [[ $(read_json /usr/local/etc/v2script/config.json '.mtproto.secret') != "" ]];then
    colorEcho ${GREEN} "tg://proxy?server=$(read_json /usr/local/etc/v2script/config.json '.v2ray.tlsHeader')&port=443&secret=$(read_json /usr/local/etc/v2script/config.json '.mtproto.secret')"
  else
    colorEcho ${YELLOW} "未设置"
  fi

  if [[ ! $(cat /proc/swaps | wc -l) -gt 1 ]]; then
    echo ""
    colorEcho ${YELLOW} "检测到Swap未开启 建议启用"
  fi

  if [ -f /usr/sbin/aliyun-service ]; then
    colorEcho ${RED} "检测到阿里云监测服务 建议卸载"
  fi

  echo ""
}

vps_tools() {
  ${sudoCmd} ${systemPackage} install wget -y -qq
  wget -q -N https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/tools/vps_tools.sh -O /tmp/vps_tools.sh && chmod +x /tmp/vps_tools.sh && ${sudoCmd} /tmp/vps_tools.sh
  exit 0
}

menu() {
  colorEcho ${YELLOW} "v2Ray TCP+TLS+WEB with Domainsocket automated script v${VERSION}"
  colorEcho ${YELLOW} "author: phlinhng"
  echo ""

  check_status

  PS3="选择操作[输入任意值或按Ctrl+C退出]: "
  COLUMNS=39
  options=("安装TCP+TLS+WEB" "更新v2Ray-core" "卸载TCP+TLS+WEB" "显示vmess链接" "管理订阅" "设置电报代理" "VPS工具")
  select opt in "${options[@]}"
  do
    case "${opt}" in
      "安装TCP+TLS+WEB") install_v2ray && continue_prompt ;;
      "更新v2Ray-core") get_v2ray && continue_prompt ;;
      "卸载TCP+TLS+WEB") rm_v2script ;;
      "显示vmess链接") display_vmess && continue_prompt ;;
      "管理订阅") v2sub && exit 0 ;;
      "设置电报代理") install_mtproto && continue_prompt;;
      "VPS工具") vps_tools ;;
      *) break ;;
    esac
  done

}

menu
