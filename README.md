[![CodeFactor](https://www.codefactor.io/repository/github/zongchenup/cobbler-import/badge/master)](https://www.codefactor.io/repository/github/zongchenup/cobbler-import/overview/master)
[![BCH compliance](https://bettercodehub.com/edge/badge/zongchenup/Cobbler-Import?branch=master)](https://bettercodehub.com/)
[![code-inspector](https://www.code-inspector.com/project/8727/score/svg)](https://www.code-inspector.com/project/8727/score/svg)
# Cobbler-Import

## 脚本功能

通过循环遍历配置文件的每一行，对每行内容进行拆分解析、数据校验和数据转换，最后组合成Cobbler命令并执行。

## 脚本特性
- 过滤空行和 **#** 注释
- 没有system则添加，有则更新( **慎!!!** 可能会覆盖)
- IP地址、MAC地址格式校验
- 主机名作为system的name值
- 内核参数已默认网卡设备名为"ethX"
- 数据格式异常则退出脚本
- 异常退出会打印已执行列表
- 显示数据异常行号

## 使用注意
- 确保脚本、配置文件为unix格式

## 配置文件样例

```
1)Node1   CentOS7.8-x86_64 Node1.ks
eth0 00:00:00:00:00:01 dhcp
eth1 00:00:00:00:00:02 static 192.168.66.16 255.255.255.0 192.168.66.1

2)Node2   RedHat6.9-x86_64 114.114.114.114,8.8.8.8
eth0 00:00:00:00:00:03 static 192.168.66.17 255.255.255.0 
eth1 00:00:00:00:00:0A static 192.168.88.17 255.255.255.0

3)Node3   RedHat7.6-x86_64  RedHat7.6-x86_64.ks  8.8.8.8
eth0 00:00:00:00:00:0B static 192.168.66.18 255.255.255.0  192.168.66.1
eth1 00:00:00:00:00:0C static 192.168.88.18 255.255.255.0  192.168.88.1
```
具体可参考systemlist.txt文件
