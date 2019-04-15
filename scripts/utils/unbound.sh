#!/bin/bash

UNBOUND_HOME=/etc/unbound
UNBOUND_CONFIG=unbound.conf

# LOG_DIR="/var/log/unbound"
LOG_FILE="unbound.log"

REFUSE_IP4="0.0.0.0\/0"
ALLOW_IP4="127.0.0.0\/8"


# install unbound name-server (dns chache)
#sudo yum install -y unbound bind-utils

# unbound.conf config
# Change bind "# interface: 0.0.0.0" -> "interface: 0.0.0.0"
# change access-control rule
# "# access-control: 0.0.0.0/0 refuse" -> "# access-control: custom-CIDR refuse"
# "# access-control: 127.0.0.0/8 allow" -> "# access-control: custom-CIDR allow"

BIND_CONFIG="interface: 0.0.0.0"
ALLOW_CONFIG="access-control: $ALLOW_IP4 allow"
REFUES_CONFIG="access-control: $REFUSE_IP4 refuse"
LOG_CONFIG="logfile: \"\/etc\/unbound\/$LOG_FILE\""
USAGE_SYS_LOG="use-syslog: no"
FORWARD_IP="8.8.8.8"


TAB=$(echo -e '\t')
D_BIND_CONFIG="$TAB# interface: 0.0.0.0"
D_ALLOW_CONFIG="$TAB# access-control: 127.0.0.0\/8 allow"
D_REFUES_CONFIG="$TAB# access-control: 0.0.0.0\/0 refuse"
D_LOG_CONFIG="$TAB# logfile: \"\""
D_USAGE_SYS_LOG="$TAB# use-syslog: yes"

function LINE_CHK() {
  for L in $1; do
    CHK=$(sed -n ${L}p $UNBOUND_HOME/$UNBOUND_CONFIG)
    if [[ $CHK == $2 ]]; then
      echo $4
    elif [[ $CHK == $3 ]]; then
      sed -i ''"${L}"'s/'"$3"'/'"$2"'/' $UNBOUND_HOME/$UNBOUND_CONFIG
    fi
  done
}


BIND_LINE=($(sed -n '/'"$D_BIND_CONFIG"'/=' $UNBOUND_HOME/$UNBOUND_CONFIG))
ALLOW_LINE=($(sed -n '/'"$D_ALLOW_CONFIG"'/=' $UNBOUND_HOME/$UNBOUND_CONFIG))
REFUSE_LINE=($(sed -n '/'"$D_REFUES_CONFIG"'/=' $UNBOUND_HOME/$UNBOUND_CONFIG))
LOG_LINE=($(sed -n '/'"$D_LOG_CONFIG"'/=' $UNBOUND_HOME/$UNBOUND_CONFIG))
USAGE_SYS_LOG_LINE=($(sed -n '/'"$D_USAGE_SYS_LOG"'/=' $UNBOUND_HOME/$UNBOUND_CONFIG))

LINE_CHK $BIND_LINE "$TAB$BIND_CONFIG" "$D_BIND_CONFIG" "unbound server already binding to all."
LINE_CHK $ALLOW_LINE "$TAB$ALLOW_CONFIG" "$D_ALLOW_CONFIG" "unbound server already set allow config."
LINE_CHK $REFUSE_LINE "$TAB$REFUES_CONFIG" "$D_REFUES_CONFIG" "unbound server already set refuse config."
LINE_CHK $LOG_LINE "$TAB$LOG_CONFIG" "$D_LOG_CONFIG" "unbound server already set log file config."
LINE_CHK $USAGE_SYS_LOG_LINE "$TAB$USAGE_SYS_LOG" "$D_USAGE_SYS_LOG" "unbound server already set log file not use syslog."


echo 'forward-zone:' >> $UNBOUND_HOME/$UNBOUND_CONFIG
echo "${TAB}name: \".\"" >> $UNBOUND_HOME/$UNBOUND_CONFIG
echo "${TAB}forward-addr: $FORWARD_IP" >> $UNBOUND_HOME/$UNBOUND_CONFIG


# Create Log file
if ! [ -e $UNBOUND_HOME/$LOG_FILE ]; then
  echo ' ' > $UNBOUND_HOME/$LOG_FILE
  sudo chmod 777 $UNBOUND_HOME/$LOG_FILE
  sudo chown root:unbound $UNBOUND_HOME/$LOG_FILE
fi

# 설정 확인
unbound-control-setup && unbound-checkconf
if [[ $? != 0 ]]; then
  echo "ubound setting has an error."
  exit 1
else
  # 자동 재시작 등록 및 unboud 서버 시작
  systemctl enable unbound && systemctl start unbound
fi

# 질의 가능한지 확인
nslookup google.com 127.0.0.1
# 요청 상세 확인
unbound-host -d google.com

# 보안 설정 오픈 (외부로 dns 질의하는 설정)
# firewall-cmd --permanent --add-service dns && firewall-cmd --reload

exit 0
