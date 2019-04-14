#!bin/bash

BIND_HOME=/etc
BIND_CONFIG_FILE=named.conf
BIND_PORT=8053


BIND_V4_CONFIG="listen-on port $BIND_PORT { 127.0.0.1; };"
BIND_V6_CONFIG="listen-on port $BIND_PORT { none; };"
RECURION_CONFIG="recursion no;"

D_BIND_V4_CONFIG="listen-on port 53 { 127.0.0.1; };"
D_BIND_V6_CONFIG="listen-on port 53 { ::1; };"
D_RECURION_CONFIG="recursion yes;"

TAB=$(echo -e "\t")

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



sudo yum install -y bind
if [[ $? != 0 ]]; then
  exit 1
fi
systemctl enable named


BIND_V4_LINE=($(sed -n '/'"$D_BIND_V4_CONFIG"'/=' $BIND_HOME/$BIND_CONFIG_FILE))
BIND_V6_LINE=($(sed -n '/'"$D_BIND_V6_CONFIG"'/=' $BIND_HOME/$BIND_CONFIG_FILE))
RECURSION_LINE=($(sed -n '/'"$D_RECURION_CONFIG"'/=' $BIND_HOME/$BIND_CONFIG_FILE))

LINE_CHK $BIND_V4_LINE "$BIND_V4_CONFIG" "$D_BIND_V4_CONFIG" "bind server already binding to all.(ip-v4)"
LINE_CHK $BIND_V6_LINE "$BIND_V6_CONFIG" "$D_BIND_V6_CONFIG" "bind server already binding to all.(ip-v6)"
LINE_CHK $RECURSION_LINE "$RECURION_CONFIG" "$D_RECURION_CONFIG" "bind server already set about recursion.(deny)"

# 설정 확인
named-checkconf
# SELinux 설정
semanage port -a -t dns_port_t -p tcp 8053


# 순방향 db 파일 생성
# $TTL 3h
# @ IN SOA n1.centos7.home. admin.centos7.home.(
# 20190415  ; Serial yyyymmddnn
# 3h        ; Refresh After 3 hours
# 1h        ; Retry after 1 hour
# 1w        ; Expire after 1 week
# 1h        ; Minimum regative caching

# ; add your name servers here for your domain
  # IN  NS  ns1.centos7.home.
# ; add your mail server here for you domain
  # IN  MX  10  mailhost.centos7.home.
# ; now follows the actual domain name to IP
# ; address mappings:

# ; first add all referenced hostnames from above
# )

# '$TTL 3h'
# '@ IN SOA n1.centos7.home. admin.centos7.home.('
# '20190415'"$TAB"'; Serial yyyymmddnn'
# '3h'"$TAB$TAB$TAB"'Refresh After 3 hours'

# 역방향 db 파일 생성

exit 0
