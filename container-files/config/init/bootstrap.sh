#!/bin/sh
set -eu
export TERM=xterm
CONTAINERIP=$(ifconfig eth0 | grep 'inet '| grep -v 'inet6' | awk '{ print $2}')
RANDOMHAM=$(date +%s|sha256sum|base64|head -c 10)
RANDOMSPAM=$(date +%s|sha256sum|base64|head -c 10)
RANDOMVIRUS=$(date +%s|sha256sum|base64|head -c 10)
# Bash Colors
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
white=`tput setaf 7`
bold=`tput bold`
reset=`tput sgr0`
separator=$(echo && printf '=%.0s' {1..100} && echo)

# Functions
log() {
  if [[ "$@" ]]; then echo "${bold}${green}[ZIMBRA `date +'%T'`]${reset} $@";
  else echo; fi
}

get_zimbra() {
  log "Downloading zimbra"
  mkdir -p /tmp/zcs
  curl -L -o /tmp/zcs/zcs.tgz http://192.168.37.83/download/zcs-8.6.0_GA_1153.RHEL7_64.20141215151110.tgz
  tar zxvf /tmp/zcs/zcs.tgz -C /tmp/zcs/ --strip-components 1
  rm -f /tmp/zcs/zcs.tgz
  log "Zimbra downloaded."
}

install_zimbra() {
  log "Installing Zimbra..."
  cd /tmp/zcs/
  ./install.sh -s --platform-override < /etc/zimbra/installation-keystrokes
  # Fix ipv6 issue in RHEL7
  mv /zmconfigdctl /opt/zimbra/bin/zmconfigdctl
  log "Zimbra installed"
}

update_config() {
  ZIMBRA_CONFIG="/etc/zimbra/default.config"
  ZONE_CONFIG="/etc/named/zone.conf"
  OPTIONS_CONFIG="/etc/named/options.conf"
  log "Updating ${bold}${white}default.config${reset} file."
  sed -i "s|\$DOMAIN|"${DOMAIN}"|g" ${ZIMBRA_CONFIG}
  sed -i "s|\$HOSTNAME|"${HOSTNAME}"|g" ${ZIMBRA_CONFIG}
  sed -i "s|\$CONTAINERIP|"${CONTAINERIP}"|g" ${ZIMBRA_CONFIG}
  sed -i "s|\$RANDOMHAM|"${RANDOMHAM}"|g" ${ZIMBRA_CONFIG}
  sed -i "s|\$RANDOMSPAM|"${RANDOMSPAM}"|g" ${ZIMBRA_CONFIG}
  sed -i "s|\$RANDOMVIRUS|"${RANDOMVIRUS}"|g" ${ZIMBRA_CONFIG}
  sed -i "s|\$PASSWORD|"${PASSWORD}"|g" ${ZIMBRA_CONFIG}
  log "${bold}${white}default.config${reset} file updated."
  # DNS
  log "Updating ${bold}${white}DNS${reset} config."
  sed -i "s|\$DOMAIN|"${DOMAIN}"|g" ${OPTIONS_CONFIG}
  sed -i "s|\$DOMAIN|"${DOMAIN}"|g" ${ZONE_CONFIG}
  sed -i "s|\$CONTAINERIP|"${CONTAINERIP}"|g" ${ZONE_CONFIG}
  log "${bold}${white}DNS${reset} config updated."
  mv -f /etc/named/options.conf /etc/named.conf
}

start_zimbra() {
  log "Configuring and starting Zimbra"
  /opt/zimbra/libexec/zmsetup.pl -c /etc/zimbra/default.config
  log "Server started..."
}

atom_support() {
  if [[ ${ATOM_SUPPORT} == "true" ]]; then
    log "Atom editor support being installed."
    curl -o /usr/local/bin/rmate https://raw.githubusercontent.com/aurora/rmate/master/rmate && \
    chmod +x /usr/local/bin/rmate && \
    mv /usr/local/bin/rmate /usr/local/bin/atom
    log "Atom editor support added."
  fi
}

clean_install() {
  log "Removing all temp files."
  rm -rf /tmp/zcs
  log "temp files removed."
}

patch_zimbra() {
  log "Downloading Patch for 8.6.0GA"
  curl -L -o /tmp/zcs/patch.tgz https://files.zimbra.com/downloads/8.6.0_GA/zcs-patch-8.6.0_GA_1182.tgz
  mkdir p /tmp/zcs/patch
  tar zxvf /tmp/zcs/patch.tgz -C /tmp/zcs/patch/ --strip-components 1
  rm -f /tmp/zcs/patch.tgz
  log "Patch downloaded"
  log "Patching installation"
  chown -R zimbra:zimbra /tmp/zcs/patch
  cd /tmp/zcs/patch
  su -c "/opt/zimbra/bin/zmmailboxdctl stop" zimbra
  ./installPatch.sh
  su -c "/opt/zimbra/bin/zmcontrol restart" zimbra
  su -c "/opt/zimbra/bin/zmcontrol status" zimbra
  log "Zimbra Patched"
}

### Magic starts here

# Update config
update_config
atom_support

# Start DNS, cron and rsyslog
named -c /etc/named.conf
crond
rsyslogd -f /etc/rsyslog.conf

# Check if Zimbra already installed
ZIMBRA_DIR="/opt/zombra/"
if [ -d ${ZIMBRA_DIR} ]; then
  log "Zimbra already installed. Starting configuration..."
else
  get_zimbra
  install_zimbra
fi
# Starting all servers - Long task
start_zimbra
patch_zimbra

# Clean
clean_install
