#!/bin/sh

black=$(tput setaf 0); red=$(tput setaf 1); green=$(tput setaf 2); yellow=$(tput setaf 3)
blue=$(tput setaf 4); magenta=$(tput setaf 5); cyan=$(tput setaf 6); white=$(tput setaf 7)
bold=$(tput bold); normal=$(tput sgr0)
wangka=`cat /proc/net/dev |awk -F: 'function trim(str){sub(/^[ \t]*/,"",str); sub(/[ \t]*$/,"",str); return str } NR>2 {print trim($1)}'  |grep -Ev '^lo|^sit|^stf|^gif|^dummy|^vmnet|^vir|^gre|^ipip|^ppp|^bond|^tun|^tap|^ip6gre|^ip6tnl|^teql|^venet|^docker' |awk 'NR==1 {print $0}'`
upsudu=300

tc_location=$( command -v tc )

if [[ ! -a $tc_location ]]; then
    echo; echo "${bold}${red}警告 ${white}未检测到 tc ，限速命令无法执行${normal}"; echo
    exit 1
fi

if [[ ! $1 == "" ]] && [[ ! $2 == "" ]]; then

    interface=`echo "$1"`
    uploadrate=`echo "$2"`
    burstspeed=$(($uploadrate/10))
    burstspeedmbit=`echo ${burstspeed}mbit`
    uploadratembit=`echo ${uploadrate}mbit`
    tc qdisc del dev $interface root >> /dev/null 2>&1
    tc qdisc add dev $interface root handle 1: tbf rate $uploadratembit burst $burstspeedmbit latency 1s >> /dev/null 2>&1
    tc qdisc add dev $interface parent 1: handle 11: pfifo_fast >> /dev/null 2>&1

else

echo -e "${bold}"
echo -e "${green}(01) ${white}限制全局上传速度"
echo -e "${green}(02) ${white}解除全局上传限速"
echo -e "${green}(03) ${white}退出"
echo -e ""
echo -ne "${yellow}${bold}你想做什么？ (默认选择解除限速)${normal} "; read response
# echo -e "${green}(04) ${white}给 Deluge 限速"
# echo -e "${green}(05) ${white}给 qBittorrent 限速"
# echo -e "${green}(06) ${white}给 rTorrent 限速"
# echo -e "${green}(07) ${white}给 Transmission 限速"
#echo -ne ""

case $response in
    1 | 01) xxxsp=1 ;;
    2 | 02 | "") xxxsp=2 ;;
    3 | 03) xxxsp=3 ;;
    *) xxxsp=2 ;;
esac

if [ "${xxxsp}" == "1" ]; then

    echo
    read -e -p "${bold}请输入你要限速的网卡名字，一般用默认的就可以了：${yellow}" -i $wangka interface

    wangkaexist=`ifconfig | grep $interface`
    if [[ ! "${wangkaexist}" ]]; then
        echo; echo "${bold}${red}警告 ${white}未检测到名为 ${green}${interface}${white} 的网卡 ，限速命令无法执行${normal}"; echo
        exit 1
    fi

    echo -ne "${normal}"
    read -e -p "${bold}请输入你要限制的上行网速（Mbps）：${yellow}" -i $upsudu uploadrate
    echo -e "${normal}"
    burstspeed=$(($uploadrate/10))
    burstspeedmbit=`echo ${burstspeed}mbit`
    uploadratembit=`echo ${uploadrate}mbit`

    tc qdisc del dev $interface root >> /dev/null 2>&1
    tc qdisc add dev $interface root handle 1: tbf rate $uploadratembit burst $burstspeedmbit latency 1s >> /dev/null 2>&1
    tc qdisc add dev $interface parent 1: handle 11: pfifo_fast >> /dev/null 2>&1
    echo "${bold}${green}已将全局上传速度限制到 ${uploadrate}Mbps${normal}"; echo

elif [ "${xxxsp}" == "2" ]; then

    echo; read -e -p "${bold}请输入你要解除限速的网卡名字：${yellow}" -i $wangka interface
    tc qdisc del dev $interface root >> /dev/null 2>&1
    echo; echo -e "${bold}${green}全局限速应该已经解除了${normal}"; echo

else

    exit 0

fi

fi

