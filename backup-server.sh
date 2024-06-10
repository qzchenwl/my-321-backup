#!/bin/bash

set -xe

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# 切换工作目录到配置文件所在目录
cd "$SCRIPT_DIR"

# 配置变量
SERVICE_NAME="my-321-backup-server"
RSYNC_CONFIG_FILE="rsyncd.conf"
SERVICE_LOG_FILE="./rsyncd.log"
SERVICE_PID_FILE="./rsyncd.pid"
SERVICE_SCRIPT="$0"

# 启动服务
start_service() {
    rsync --daemon --config="$RSYNC_CONFIG_FILE"
    echo "Service started."
}

# 停止服务
stop_service() {
    kill $(cat $SERVICE_PID_FILE)
    echo "Service stopped."
}

# 启用开机启动
enable_autostart() {
    cp "$SERVICE_NAME.plist" "$HOME/Library/LaunchAgents/"
    sed -i "s|{{SCRIPT_DIR}}|$SCRIPT_DIR|g" "$HOME/Library/LaunchAgents/$SERVICE_NAME.plist"
    launchctl load "$HOME/Library/LaunchAgents/$SERVICE_NAME.plist"
    echo "Autostart enabled."
}

# 停用开机启动
disable_autostart() {
    launchctl unload "$HOME/Library/LaunchAgents/$SERVICE_NAME.plist"
    echo "Autostart disabled."
}

# 列出rsync状态
show_status() {
    ps aux | grep --color rsync
}

# 执行操作
case "$1" in
    "start")
        start_service
        ;;
    "stop")
        stop_service
        ;;
    "enable")
        enable_autostart
        ;;
    "disable")
        disable_autostart
        ;;
    "status")
        show_status
        ;;
    *)
        echo "Usage: $0 {start|stop|enable|disable|status}"
        exit 1
        ;;
esac

