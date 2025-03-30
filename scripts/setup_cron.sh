#!/bin/bash

# 检查是否已经有该 cron 任务，如果没有则添加 . 检查利用|| 表达式的lazy 计算
crontab -l 2>/dev/null | grep -q "scripts/monitor.sh" || (crontab -l 2>/dev/null; echo "*/15 * * * * /bin/bash /path/to/scripts/monitor.sh >> /path/to/logs/cron_monitor.log 2>&1") | crontab -

crontab -l 2>/dev/null | grep -q "scripts/generate_report.sh" || (crontab -l 2>/dev/null; echo "0 1 * * * /bin/bash /path/to/scripts/generate_report.sh >> /path/to/logs/cron_report.log 2>&1") | crontab -

echo "Cron 定时任务已被设置"
