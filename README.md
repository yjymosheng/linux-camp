# 综合项目：自动化网站监控与报告系统

这个项目将创建一个完整的服务，可以定期检查多个网站的可用性、响应时间和内容变化，并生成详细报告，是一个实用的系统管理工具。

## 项目概述

系统将：

1. 监控多个网站的状态
2. 记录响应时间和可用性
3. 检测页面内容变化
4. 生成日报和周报
6. 提供一个简单的网页界面查看统计数据

## 实现流程与具体步骤

### 一、系统环境准备 （10分）

1. 准备好Ubuntu系统（物理机或虚拟机）
2. 创建专用目录结构
3. 创建配置文件
#### 创建专用目录结构
```bash

项目根目录/
├── scripts/
│   └── monitor.sh    # 监控主脚本
│   └── setup_cron.sh
│   └── generate_report.sh
├── config.txt        # 监控配置
├── reports/
├── logs/             # 日志目录（自动创建）
│   ├── Baidu/     # 每个网站的独立目录
│   │   └── status.log
│   │   └── alerts.log
│   ├── Gitee/
│   │   └── status.log
│   │   └── alerts.log    
└── data/
    └── all_checks.log  # 汇总统计数据
```
#### 创建配置文件
`config.txt`
```
# 网站监控配置文件
# 格式: 网站名称 URL 
Gitee https://gitee.com 
Baidu https://baidu.com 
```

### 二、编写核心监控脚本（30分）

`scripts/monitor.sh`脚本需实现如下的功能：
  读取`config.txt`中的网站的名称及其url，然后使用`curl`发送HTTP请求，将检查结果其记录在对应网站的`status.log`中 格式为`日期 时间 响应码 响应时间 内容摘要（下载内容的 MD5 哈希值）`示例日志行：`2023-10-01 14:30:45 200 0.872 a1b2c3d4e5f6g7h8i9j0`

当HTTP状态码非`2xx`/`3xx`时将记录告警到对应网站的`alerts.log` 中，示例告警：`警告: Baidu 404`

最后保存所有检查记录到`all_checks.log`格式为`日期 时间 网站名称 状态码 响应时间`用于后续统计分析

### 三、编写报告生成脚本（30分）

generate_report.sh脚本需实现以下功能：
首先统计网站可用性摘要（各网站各状态码出现次数统计），其次统计各网站的平均相应时间，最后统计异常记录（从alerts.log提取昨日告警），并且将结果保存在`reports/daily_report_YYYY-MM-DD.txt`（YYYY-MM-DD为当前年月日，例如2025-3-15）中

示例报告文件结构：
```text
网站监控日报告: 2023-10-01
=================================
网站可用性摘要:
example 200 状态码: 24 次
test-site 404 状态码: 5 次

响应时间统计 (秒):
example 平均: 0.873
test-site 平均: 1.245

异常情况:
警告: example 返回状态码 500
```

### 四、设置定时任务（10分）

`setup_cron.sh`需满足每15分钟运行一次`scripts/monitor.sh`并且将输出保存在`logs/cron_monitor.log`，每天凌晨一点运行`scripts/generate_report.sh`并且将结果保存在`logs/cron_report.log`中

### 5. 设置Web服务器（20分）

1. 安装Nginx
2. 配置Nginx虚拟主机

```bash
# 配置Nginx虚拟主机，注意替换！
server {
    listen 80;
    server_name localhost;
    
    root /home/$(whoami)/website-monitor/www;
    index index.html;
    
    location / {
        try_files $uri $uri/ =404;
    }
}
```

3. 启用站点

```bash
sudo systemctl restart nginx
```

4. 创建网页界面在www/index.html，具体网页代码如下（涉及简单的HTML）

```html
<!DOCTYPE html>
<html>
<head>
  <title>网站监控系统</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 40px; }
    h1 { color: #2c3e50; }
    ul { list-style-type: none; padding: 0; }
    li { margin-bottom: 10px; }
    a { text-decoration: none; color: #3498db; }
    a:hover { text-decoration: underline; }
  </style>
</head>
<body>
  <h1>网站监控系统</h1>
  <p>欢迎使用网站监控系统！</p>
  
  <h2>报告列表</h2>
  <ul id="reports">
    <li>加载中...</li>
  </ul>

  <script>
    // 简单的脚本以列出报告文件
    fetch('/')
      .then(response => response.text())
      .then(html => {
        const parser = new DOMParser();
        const doc = parser.parseFromString(html, 'text/html');
        const links = Array.from(doc.querySelectorAll('a'))
          .filter(a => a.href.includes('daily_report'))
          .map(a => a.href.split('/').pop());
        
        const reportsList = document.getElementById('reports');
        reportsList.innerHTML = '';
        
        if (links.length === 0) {
          reportsList.innerHTML = '<li>暂无报告</li>';
          return;
        }
        
        links.forEach(link => {
          const li = document.createElement('li');
          const a = document.createElement('a');
          a.href = link;
          a.textContent = link.replace('.html', '');
          li.appendChild(a);
          reportsList.appendChild(li);
        });
      })
      .catch(error => {
        console.error('Error:', error);
        document.getElementById('reports').innerHTML = '<li>加载报告列表失败</li>';
      });
  </script>
</body>
</html>
```

