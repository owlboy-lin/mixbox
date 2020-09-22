#!/bin/sh -euo pipefail
#copyright by monlor
source /tmp/mixbox.conf
source ${MBROOT}/bin/base

APPNAME="$1"
ACTION="$2"
assert_nil APPNAME ACTION && exit 1

source ${MBROOT}/apps/${APPNAME}/${APPNAME}.conf

source ${MBROOT}/apps/${APPNAME}/${APPNAME}.sh

_is_running() {
	local flag=0
	for i in "$@"; do
		!(pidof "${i}" &> /dev/null) && flag=1 && break
	done
	return ${flag}
}

_running() {
	res="运行中"
	[ -n "${port}" ] && res="${res}，端口号：${port}"
	echo ${res}
	return 0
}

_stopped() {
	res="未运行"
	echo ${res}
	return 1
}

check_running() {
	local flag=1
	[ -z "$@" ] && flag=$(is_running; echo $?) || flag=$(_is_running "$@"; echo $?)
	[ ${flag} -eq 0 ] && loginfo "插件${appname}已经在运行！" && return 0
	return 1
}

# 传入二进制程序参数，则检查是否运行；不传入则取插件脚本中的is_running变量
default_status() {
	local flag=1
	[ -z "$@" ] && flag=$(is_running; echo $?) || flag=$(_is_running "$@"; echo $?)
	[ ${flag} -eq 0 ] && _running || _stopped
}

status_app() {
	if type status &> /dev/null; then
		status 
	else
		default_status 
	fi
}
 
restart() {
	loginfo "======================="
	stop_app
	sleep 1
	start_app
	loginfo "======================="
}

watch() {
	if [ "${enabled}" -eq 1 ]; then
		status_app &> /dev/null || restart
	fi
}

check_port() {
	[ -z ${port} ] && return
	for i in `echo ${port} | tr ',' '\n'`;do
		if [ -n "$(netstat -ntulp | grep :${i})" ]; then
			logwarn "检测到端口：${i} 被以下进程占用！clash无法启动！" 
			logerror "$(netstat -ntulp |grep :${i})"
		fi
	done
}

start_app() {
	check_port
	# check binfile
	download_binfile ${binfile} || exit 1
	start
	status_app &> /dev/null || logerror "服务启动失败！"
}

stop_app() {
	# todo 停止时关闭守护进程
	if [ "${enabled}" -eq 0 ]; then
		pc_delete ${APPNAME} ${MBROOT}/config/watch.txt 
	fi
	# 检查日志，清除
	logclear
	stop
}

save() {
	if [ "${enabled}" -eq 1 ]; then
		restart
	else
		stop
	fi
}

reload_app() {
	if type reload &> /dev/null; then
		reload
	else
		restart
	fi
}
case "${ACTION}" in 
	start) start_app ;;
	stop) stop_app ;;
	restart) restart ;;
	status) status_app ;;
	watch) watch ;;
	reload) reload_app ;;
	save) save ;;
	*) type ${ACTION} &> /dev/null && ${ACTION} ;;
esac
