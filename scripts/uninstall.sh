#!/bin/sh
#copyright by monlor
source /etc/profile &> /dev/null
source ${MBROOT}/bin/base

loginfo "正在卸载工具箱..."

loginfo "停止所有插件"

${MBROOT}/scripts/monitor.sh applist.txt stop

loginfo "删除定时任务"
cru c 

loginfo "删除所有工具箱配置信息"
pc_delete "#mixbox" /etc/profile

power_boot_del "mixbox"

firewall_restart_del "mixbox"

loginfo "See You!"

rm -rf ${MBROOT}