#!/usr/bin/env bash
###################################################################
#
#   脚本功能：从文本文件中批量导入机器(system)配置到Cobbler中
#   使用方法：将文本文件放在脚本同目录下执行脚本即可
#   脚本日期：2020-05-29
#   脚本版本：1.0
#   脚本编码：UTF-8
#   脚本作者：LZC
#   										
###################################################################

# 如异常退出，打印已执行的内容
trap 'ecol "DONELIST" "$doneList"' EXIT


# 定义变量
ip=""
mac=""
ifName=""
static=""
netmask=""
gateway=""
sysName=""
ksFilePath=""
nameServer=""
profileName=""

sysCmd=""
lineNum=0
mission=""
ifPre="eth"
doneList=""
action="edit"
cmdPre="cobbler system"
systemListFile="systemlist.txt"
ksBasePath="/var/lib/cobbler/kickstarts"
kernelOpt="\"biosdevname=0 net.ifnames=0\""


# 函数 控制提示颜色/异常退出
# 传参 $1:提示类型  $2:提示内容
ecol(){
    if [[ "$1" == "RUN" || "$1" == "SUCCESS" ]];then
        #green
        echo -e "\033[32;1m[$1] $2\033[0m"
    elif [[ "$1" == "NONE" || "$1" == "ERROR" || "$1" == "FAIL" ]];then
        #red
        echo -e "\033[31;1m[$1] (line:$lineNum) $2\033[0m"
        exit 1
    elif [[ "$1" == "DONELIST" ]];then
        #yellow
        if [[ "$2" != "" ]];then
            echo -e "\033[33;1m[$1] $2\033[0m"
        fi
    else
        echo "$*"
    fi
}

# 函数 判断system是否存在
# 传参 $1:待检验system名
# 返回 存在:返回原值 不存在:返回空
hasSys(){
    sysList=$(cobbler system list)
    hasSysCount=0
    for sys in $sysList;do
        if [ "$sys" == "$1" ];then
            hasSysCount=$(( hasSysCount + 1 ))
        fi
    done    
    if [[ $hasSysCount != 0 ]];then
        echo "$1"
    fi
}

# 函数 判断profile是否存在
# 传参 $1:待检验profile名
# 返回 存在:返回原值 不存在:返回空
hasProfile(){
    profileList=$(cobbler profile list)
    hasProCount=0
    for pro in $profileList;do
        if [ "$pro" == "$1" ];then
            hasProCount=$(( hasProCount + 1 ))
        fi
    done    
    if [[ $hasProCount != 0 ]];then
        echo "$1"    
    fi
}

# 函数 判断KS文件是否存在
# 传参 $1:待检验KS文件的绝对路径
# 返回 存在:返回原值 不存在:返回空
hasKS(){
    if [ -f "$1" ];then
        echo "$1"    
    fi
}

# 函数 判断是否有IP及IP格式校验
# 传参 $1:待检验IP值
# 返回 有单个IP:返回原值 有英文逗号分隔的多个IP:返回空格分隔的多个IP 无IP/IP格式错误:返回空
isIP(){
    ipList=$(echo "$1" | awk -F, '{if(NF==1) print $0;else {for(i=1;i<NF;i++) if($i!="") printf $i" " ; printf $NF}}')
    hasIPCount=0
    errIPCount=0
    for perip in $ipList;do
        if [[ $perip =~ ^(([1-9]?[0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.){3}([1-9]?[0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])$ ]];then
            hasIPCount=$(( hasIPCount + 1 ))
        else
            errIPCount=$(( errIPCount + 1 ))
        fi
    done
    if [ $errIPCount == 0 ];then
        if [ $hasIPCount -gt 1 ];then
            echo "\"$ipList\""
        elif [ $hasIPCount -eq 1 ];then
            echo "$ipList" 
        fi
    fi
}

# 函数 校验是否是MAC地址格式
# 传参 $1:待检验MAC地址
# 返回 是:返回原值 否:返回空
isMAC(){
    if [[ $1 =~ ^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$ ]];then
        echo "$1" 
    fi
}

# 函数 校验是否是static格式
# 传参 $1:待检验static值
# 返回 是:返回原值 否:返回空
isStatic(){
    if [[ "${1,,}" == "static" || "${1,,}" == "true" ]];then
        echo "True"
    elif [[ "${1,,}" == "dhcp" || "${1,,}" == "false" ]];then
        echo "False"
    fi    
}

# 函数 校验取值
# 传参 $1:需要值的类型 $2:值
getRealValue(){
    case $1 in
        Profile)
            hasProfile "$2"
            ;;
        KS)
            hasKS "$2"
            ;;
        IP)
            isIP "$2"
            ;;
        MAC)
            isMAC "$2"
            ;;  
        Static)
            isStatic "$2"
            ;;
    esac
}
    
# 函数 生成cobbler命令
# 传参 $1:要生成命令的类型
genCmd(){
    action="edit"
    hostCheck=$(hasSys "$sysName")
    if [[ "$hostCheck" == "" ]];then
        action="add"
    fi
    sysHostOpt="--name=$sysName --hostname=$sysName --kopts=$kernelOpt"
    case $1 in
        HosPro)
            sysCmd="$cmdPre $action $sysHostOpt --profile=$profileName"
            ;;
        HosProKS)
            sysCmd="$cmdPre $action $sysHostOpt --profile=$profileName --kickstart=$ksFilePath"
            ;;
        HosProDns)
            sysCmd="$cmdPre $action $sysHostOpt --profile=$profileName --name-servers=$nameServer"
            ;;
        HosProKSDns)
            sysCmd="$cmdPre $action $sysHostOpt --profile=$profileName --kickstart=$ksFilePath --name-servers=$nameServer"
            ;;
        EthMacSta)
            sysCmd="$cmdPre $action --name=$sysName --interface=$ifName --mac-address=$mac --static=$static"
            ;;
        EthMacStaIpMsk)
            sysCmd="$cmdPre $action --name=$sysName --interface=$ifName --mac-address=$mac --static=$static --ip-address=$ip --netmask=$netmask"
            ;;
        EthMacStaIpMskGtw)
            sysCmd="$cmdPre $action --name=$sysName --interface=$ifName --mac-address=$mac --static=$static --ip-address=$ip --netmask=$netmask --if-gateway=$gateway"
            ;;
    esac    
}

# 函数 对system行进行处理
# 传参 $1:system行
makeSysLine(){
    sysName=${1#*)}
	#getValue "profileName" "$2"
    profileName=$(getRealValue "Profile" "$2")
    [ -z "$profileName" ] && ecol "NONE" "Profile is None: $2" 
    ksFilePath=$(getRealValue "KS" "${ksBasePath}/$3")
    nameServer=$(getRealValue "IP" "$3")
    case $# in
        2)
            genCmd "HosPro"
            ;;
        3)
            if [[ $ksFilePath != "" ]];then
                genCmd "HosProKS"
            else
                if [[ $nameServer != "" ]];then
                    genCmd "HosProDns"
                else
                    ecol "ERROR" "KS File or NameServer error: $3"
                fi
            fi
            ;;
        4)
            [ -z "$ksFilePath" ] && ecol "NONE" "KS File is None: $3" 
            nameServer=$(getRealValue "IP" "$4")
            [ -z "$nameServer" ] && ecol "ERROR" "IP format error: $4"
            genCmd "HosProKSDns"
            ;;
        *)
            ecol "ERROR" "Argms count error: $#"
            ;;
    esac
}

# 函数 对interface行进行处理
# 传参 $1:interface行
makeEthLine(){
    ifName="$1"
    mac=$(getRealValue "MAC" "$2")
    [ -z "$mac" ] && ecol "ERROR" "MAC format error: $2"
    static=$(getRealValue "Static" "$3")
    [ -z "$static" ] && ecol "ERROR" "Static value error: $3"
    ip=$(getRealValue "IP" "$4")
    netmask=$(getRealValue "IP" "$5")
    gateway=$(getRealValue "IP" "$6")
    case $# in
        3)
            genCmd "EthMacSta"
            ;;
        5)
            [ -z "$ip" ] && ecol "ERROR" "IP format error: $4"
            [ -z "$netmask" ] && ecol "ERROR" "IP format error: $5"
            genCmd "EthMacStaIpMsk"
            ;;
        6)
            [ -z "$ip" ] && ecol "ERROR" "IP format error: $4"
            [ -z "$netmask" ] && ecol "ERROR" "IP format error: $5"
            [ -z "$gateway" ] && ecol "ERROR" "IP format error: $6"
            genCmd "EthMacStaIpMskGtw"
            ;;
        *)
            ecol "ERROR" "Argms count error: $#"
            ;;
    esac
}

# 函数 执行cobbler命令
run(){
    ecol "RUN" "Starting $mission"
    eval "$sysCmd"
    if [ $? -eq 0 ];then
        ecol "SUCCESS" "$mission successfully!"
        doneList="${doneList}\n[line:$lineNum] $mission"
    else
        ecol "FAIL" "$mission failed!"
    fi
}

# 函数 执行cobbler sync命令
runSync(){
    ecol "RUN" "Starting Cobbler Sync!"
    cobbler sync
    if [ $? -eq 0 ];then
        ecol "SUCCESS" "ALL DONE~~~"
        doneList=""
    else
        ecol "FAIL" "SYNC FAILED!!!"
    fi
}



# 脚本主体，while循环遍历文本文件每一行，读取相应的值生成cobber命令
while read line;do
    lineNum=$(( lineNum + 1 ))
    # 跳过#注释行和空行
    if [[ $line =~ ^$ || $line =~ ^# ]];then
        continue
    fi
    # 判断是system行还是interface行
    if [[ $line =~ ^[0-9]{1,3}\) ]];then
        makeSysLine $line
        mission="$action $sysName"
        #cmd=$(hostLine $line)
    elif [[ $line =~ ^$ifPre ]];then
        makeEthLine $line
        mission="$action $ifName on $sysName"
        #cmd=$(ifLine $line)
    fi
    # 输出生成的命令
    echo "$sysCmd"
    # 执行命令
    run
done < $systemListFile
# 最后同步cobbler
runSync







