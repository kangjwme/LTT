#!/usr/bin/env bash
trap _exit INT QUIT TERM

_red() {
    printf '\033[0;31;31m%b\033[0m' "$1"
}

_green() {
    printf '\033[0;31;32m%b\033[0m' "$1"
}

_yellow() {
    printf '\033[0;31;33m%b\033[0m' "$1"
}

_blue() {
    printf '\033[0;31;36m%b\033[0m' "$1"
}

_exists() {
    local cmd="$1"
    if eval type type > /dev/null 2>&1; then
        eval type "$cmd" > /dev/null 2>&1
    elif command > /dev/null 2>&1; then
        command -v "$cmd" > /dev/null 2>&1
    else
        which "$cmd" > /dev/null 2>&1
    fi
    local rt=$?
    return ${rt}
}

_64bit(){
    if [ $(getconf WORD_BIT) = '32' ] && [ $(getconf LONG_BIT) = '64' ]; then
        return 0
    else
        return 1
    fi
}

_exit() {
    _red "\n腳本被強制停止，請輸入./ltt.sh重新執行\n"
    # clean up
    rm -fr speedtest.tgz speedtest-cli benchtest_*
    exit 1
}

get_opsy() {
    [ -f /etc/redhat-release ] && awk '{print $0}' /etc/redhat-release && return
    [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
    [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}

next() {
    printf "%-70s\n" "-" | sed 's/\s/-/g'
}

speed_test() {
    local nodeName="$2"
    [ -z "$1" ] && ./speedtest-cli/speedtest --progress=no --accept-license --accept-gdpr > ./speedtest-cli/speedtest.log 2>&1 || \
    ./speedtest-cli/speedtest --progress=no --server-id=$1 --accept-license --accept-gdpr > ./speedtest-cli/speedtest.log 2>&1
    if [ $? -eq 0 ]; then
        local dl_speed=$(awk '/Download/{print $3" "$4}' ./speedtest-cli/speedtest.log)
        local up_speed=$(awk '/Upload/{print $3" "$4}' ./speedtest-cli/speedtest.log)
        local latency=$(awk '/Latency/{print $2" "$3}' ./speedtest-cli/speedtest.log)
        if [[ -n "${dl_speed}" && -n "${up_speed}" && -n "${latency}" ]]; then
            printf "\033[0;33m%-20s\033[0;32m%-20s\033[0;31m%-24s\033[0;36m%-24s\033[0m\n" " ${nodeName}" "${up_speed}" "${dl_speed}" "${latency}"
        fi
    fi
}
#這邊可以自行新增speedtest節點
speed() {
    speed_test '' '最佳節點'
    speed_test '18445'  '台北 中華電信'
    speed_test '5334' '新北 台灣之星'
    speed_test '4940'  '台中 中華電信'
    speed_test '18458' '高雄 中華電信'
}

io_test() {
    (LANG=C dd if=/dev/zero of=benchtest_$$ bs=64k count=16k conv=fdatasync && rm -f benchtest_$$ ) 2>&1 | awk -F, '{io=$NF} END { print io}' | sed 's/^[ \t]*//;s/[ \t]*$//'
}

calc_disk() {
    local total_size=0
    local array=$@
    for size in ${array[@]}
    do
        [ "${size}" == "0" ] && size_t=0 || size_t=`echo ${size:0:${#size}-1}`
        [ "`echo ${size:(-1)}`" == "K" ] && size=0
        [ "`echo ${size:(-1)}`" == "M" ] && size=$( awk 'BEGIN{printf "%.1f", '$size_t' / 1024}' )
        [ "`echo ${size:(-1)}`" == "T" ] && size=$( awk 'BEGIN{printf "%.1f", '$size_t' * 1024}' )
        [ "`echo ${size:(-1)}`" == "G" ] && size=${size_t}
        total_size=$( awk 'BEGIN{printf "%.1f", '$total_size' + '$size'}' )
    done
    echo ${total_size}
}

check_virt(){
    _exists "dmesg" && virtualx="$(dmesg 2>/dev/null)"
    if _exists "dmidecode"; then
        sys_manu="$(dmidecode -s system-manufacturer 2>/dev/null)"
        sys_product="$(dmidecode -s system-product-name 2>/dev/null)"
        sys_ver="$(dmidecode -s system-version 2>/dev/null)"
    else
        sys_manu=""
        sys_product=""
        sys_ver=""
    fi
    if   grep -qa docker /proc/1/cgroup; then
        virt="Docker"
    elif grep -qa lxc /proc/1/cgroup; then
        virt="LXC"
    elif grep -qa container=lxc /proc/1/environ; then
        virt="LXC"
    elif [[ -f /proc/user_beancounters ]]; then
        virt="OpenVZ"
    elif [[ "${virtualx}" == *kvm-clock* ]]; then
        virt="KVM"
    elif [[ "${cname}" == *KVM* ]]; then
        virt="KVM"
    elif [[ "${cname}" == *QEMU* ]]; then
        virt="KVM"
    elif [[ "${virtualx}" == *"VMware Virtual Platform"* ]]; then
        virt="VMware"
    elif [[ "${virtualx}" == *"Parallels Software International"* ]]; then
        virt="Parallels"
    elif [[ "${virtualx}" == *VirtualBox* ]]; then
        virt="VirtualBox"
    elif [[ -e /proc/xen ]]; then
        virt="Xen"
    elif [[ "${sys_manu}" == *"Microsoft Corporation"* ]]; then
        if [[ "${sys_product}" == *"Virtual Machine"* ]]; then
            if [[ "${sys_ver}" == *"7.0"* || "${sys_ver}" == *"Hyper-V" ]]; then
                virt="Hyper-V"
            else
                virt="Microsoft VM"
            fi
        fi
    else
        virt="實體主機"
    fi
}

ipv4_info() {
    local org="$(wget -q -T10 -O- ipinfo.io/org)"
    local city="$(wget -q -T10 -O- ipinfo.io/city)"
    local country="$(wget -q -T10 -O- ipinfo.io/country)"
    local region="$(wget -q -T10 -O- ipinfo.io/region)"
    [[ -n "$org" ]] && echo " 數據中心登記	：	$(_blue "$org")"
    [[ -n "$city" && -n "country" ]] && echo " 主機詳細位置	：	$(_blue "$city / $country")"
    [[ -n "$region" ]] && echo " 主機所在省州	：	$(_blue "$region")"
}

install_speedtest() {
    if  [ ! -e "./speedtest-cli/speedtest" ]; then
        _64bit && sys_bit=x86_64 || sys_bit=i386
        url1="https://dl.bintray.com/ookla/download/ookla-speedtest-1.0.0-${sys_bit}-linux.tgz"
        url2="https://dl.lamp.sh/files/ookla-speedtest-1.0.0-${sys_bit}-linux.tgz"
        wget --no-check-certificate -q -T10 -O speedtest.tgz ${url1}
        if [ $? -ne 0 ]; then
            wget --no-check-certificate -q -T10 -O speedtest.tgz ${url2}
            [ $? -ne 0 ] && _red "錯誤: 無法執行speedtest.net測速.\n" && exit 1
        fi
        mkdir -p speedtest-cli && tar zxf speedtest.tgz -C ./speedtest-cli && chmod +x ./speedtest-cli/speedtest
        rm -f speedtest.tgz
    fi
}

! _exists "wget" && _red "錯誤: wget 指令未安裝！請先安裝在執行\n" && exit 1
# Get System information
cname=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
cores=$( awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo )
freq=$( awk -F'[ :]' '/cpu MHz/ {print $4;exit}' /proc/cpuinfo )
ccache=$( awk -F: '/cache size/ {cache=$2} END {print cache}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
tram=$( LANG=C; free -m | awk '/Mem/ {print $2}' )
uram=$( LANG=C; free -m | awk '/Mem/ {print $3}' )
swap=$( LANG=C; free -m | awk '/Swap/ {print $2}' )
uswap=$( LANG=C; free -m | awk '/Swap/ {print $3}' )
up=$( awk '{a=$1/86400;b=($1%86400)/3600;c=($1%3600)/60} {printf("%d 天, %d 小時 %d 分鐘\n",a,b,c)}' /proc/uptime )
if _exists "w"; then
    load=$( LANG=C; w | head -1 | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//' )
elif _exists "uptime"; then
    load=$( LANG=C; uptime | head -1 | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//' )
fi
opsy=$( get_opsy )
arch=$( uname -m )
if _exists "getconf"; then
    lbit=$( getconf LONG_BIT )
else
    echo ${arch} | grep -q "64" && lbit="64" || lbit="32"
fi
kern=$( uname -r )
disk_size1=($( LANG=C df -hPl | grep -wvE '\-|none|tmpfs|devtmpfs|by-uuid|chroot|Filesystem|udev|docker' | awk '{print $2}' ))
disk_size2=($( LANG=C df -hPl | grep -wvE '\-|none|tmpfs|devtmpfs|by-uuid|chroot|Filesystem|udev|docker' | awk '{print $3}' ))
disk_total_size=$( calc_disk "${disk_size1[@]}" )
disk_used_size=$( calc_disk "${disk_size2[@]}" )
tcpctrl=$( sysctl net.ipv4.tcp_congestion_control | awk -F ' ' '{print $3}' )
check_virt
clear
next
echo " 處理器型號	：	$(_blue "$cname")"
echo " 處理器核心	：	$(_blue "$cores")"
echo " 處理器時脈	：	$(_blue "$freq MHz")"
echo " 處理器快取	：	$(_blue "$ccache")"
echo " 總硬碟大小	：	$(_blue "$disk_total_size GB ($disk_used_size GB 已使用)")"
echo " 記憶體大小	：	$(_blue "$tram MB ($uram MB 已使用)")"
echo " SWAP總量	：	$(_blue "$swap MB ($uswap MB 已使用)")"
echo " 開機時間	：	$(_blue "$up")"
echo " 平均附載	：	$(_blue "$load")"
echo " 作業系統	：	$(_blue "$opsy")"
echo " 位元架構	：	$(_blue "$arch ($lbit 位元)")"
echo " 內核版本	：	$(_blue "$kern")"
echo " 虛擬技術	：	$(_blue "$virt")"
ipv4_info
next
io1=$( io_test )
echo " 讀寫速度(第一次測試)    : $(_yellow "$io1")"
io2=$( io_test )
echo " 讀寫速度(第二次測試)    : $(_yellow "$io2")"
io3=$( io_test )
echo " 讀寫速度(第三次測試)    : $(_yellow "$io3")"
ioraw1=$( echo $io1 | awk 'NR==1 {print $1}' )
[ "`echo $io1 | awk 'NR==1 {print $2}'`" == "GB/秒" ] && ioraw1=$( awk 'BEGIN{print '$ioraw1' * 1024}' )
ioraw2=$( echo $io2 | awk 'NR==1 {print $1}' )
[ "`echo $io2 | awk 'NR==1 {print $2}'`" == "GB/秒" ] && ioraw2=$( awk 'BEGIN{print '$ioraw2' * 1024}' )
ioraw3=$( echo $io3 | awk 'NR==1 {print $1}' )
[ "`echo $io3 | awk 'NR==1 {print $2}'`" == "GB/秒" ] && ioraw3=$( awk 'BEGIN{print '$ioraw3' * 1024}' )
next
install_speedtest && printf "%-20s%-20s%-24s%-24s\n" " 節點名稱" "上傳速度" "下載速度" "延遲"
speed && rm -fr speedtest-cli
next
