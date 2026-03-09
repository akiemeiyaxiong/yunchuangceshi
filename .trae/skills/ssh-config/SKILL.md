---
name: "ssh-config"
description: "SSH免密登录配置信息。当需要连接远程服务器或遇到SSH密码问题时自动调用。"
---

# SSH 免密登录配置

## 服务器信息

- **服务器IP**: 43.160.220.37
- **用户**: ubuntu
- **密码**: yunchuang001?
- **用途**: 生产服务器部署
- **免密登录状态**: ✅ 已配置

## 免密登录配置（已配置）

### 密钥文件位置
- **私钥**: `C:\Users\Administrator\.ssh\id_rsa_yunchuang`
- **公钥**: `C:\Users\Administrator\.ssh\id_rsa_yunchuang.pub`
- **SSH配置**: `C:\Users\Administrator\.ssh\config`

### SSH配置文件内容
```
Host yunchuang
    HostName 43.160.220.37
    User ubuntu
    IdentityFile ~/.ssh/id_rsa_yunchuang
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

## 连接命令

### 方式1: 使用别名（推荐，免密）
```bash
ssh yunchuang
```

### 方式2: 使用完整命令（免密）
```bash
ssh ubuntu@43.160.220.37
```

### 方式3: 指定密钥文件（免密）
```bash
ssh -i ~/.ssh/id_rsa_yunchuang ubuntu@43.160.220.37
```

### 方式4: 密码登录（备用）
```bash
ssh -o StrictHostKeyChecking=no ubuntu@43.160.220.37
# 密码: yunchuang001?
```### 问题: 每次连接需要输入密码

## 注意事项

- 确保 `~/.ssh/config` 权限为 600
- 确保 `~/.ssh/id_rsa` 权限为 600
- 不要将私钥文件路径设置为目录

## 常用操作命令

### 连接服务器（免密）
```bash
ssh yunchuang
```

### 上传文件（免密）
```bash
# 使用别名
scp ./local-file yunchuang:~/remote-path/

# 使用完整命令
scp -i ~/.ssh/id_rsa_yunchuang ./local-file ubuntu@43.160.220.37:~/remote-path/
```

### 下载文件（免密）
```bash
# 使用别名
scp yunchuang:~/remote-file ./local-path/

# 使用完整命令
scp -i ~/.ssh/id_rsa_yunchuang ubuntu@43.160.220.37:~/remote-file ./local-path/
```

### 上传文件
```bash
scp -r ./local-file ubuntu@43.160.220.37:~/remote-path/
```

### 下载文件
```bash
scp ubuntu@43.160.220.37:~/remote-file ./local-path/
```

---

## 常见问题与解决方案

### 问题1: 连接超时 (Connection timed out)

**现象**: `ssh: connect to host 43.166.220.37 port 22: Connection timed out`

**解决方案**:
1. 检查服务器 IP 是否正确
2. 检查安全组/防火墙是否放行 22 端口
3. 检查网络连接: `ping 43.160.220.37`
4. 确认服务器是否开机运行

---

## 自动化部署方案

### 方案1: 使用 sshpass (推荐用于脚本)

**安装 sshpass**:
```bash
# Windows (通过 chocolatey)
choco install sshpass

# Linux
sudo apt-get install sshpass
```

**部署脚本**:
```bash
#!/bin/bash
SERVER="43.160.220.37"
USER="ubuntu"
PASS="yunchuang001?"

# 创建目录
sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@$SERVER "mkdir -p ~/app"

# 上传文件
sshpass -p "$PASS" scp -r server $USER@$SERVER:~/app/
sshpass -p "$PASS" scp -r nginx $USER@$SERVER:~/app/
sshpass -p "$PASS" scp docker-compose.yml $USER@$SERVER:~/app/

# 执行部署
sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@$SERVER "cd ~/app && docker compose up -d"
```

### 方案2: 使用 expect 自动化交互

**安装 expect**:
```bash
# Linux
sudo apt-get install expect
```

**expect 脚本**:
```bash
#!/usr/bin/expect
set timeout 30
set server "43.160.220.37"
set user "ubuntu"
set password "yunchuang001?"

spawn ssh -o StrictHostKeyChecking=no $user@$server
expect "password:"
send "$password\r"
expect "$ "
send "mkdir -p ~/app\r"
expect "$ "
send "exit\r"
interact
```

---

# MySQL 数据库连接配置

## 数据库信息

- **内网IP**: 10.3.4.14
- **端口**: 3306
- **账号**: root
- **密码**: Scc20010117
- **用途**: 生产数据库

## 连接方式

### 通过SSH隧道连接（本地开发，免密）

由于MySQL是内网地址，需要先通过SSH隧道转发：

```bash
# 使用别名（免密）
ssh -L 3307:10.3.4.14:3306 yunchuang -N

# 或使用完整命令（免密）
ssh -i ~/.ssh/id_rsa_yunchuang -L 3307:10.3.4.14:3306 ubuntu@43.160.220.37 -N
```

然后本地连接：
```bash
mysql -h 127.0.0.1 -P 3307 -u root -p'Scc20010117'
```

### 在服务器上直接连接（免密）

```bash
ssh yunchuang "mysql -h 10.3.4.14 -P 3306 -u root -p'Scc20010117' -e 'SHOW DATABASES;'"
```
```

### Node.js 连接示例

```javascript
const mysql = require('mysql2/promise');

const pool = mysql.createPool({
  host: '10.3.4.14',
  port: 3306,
  user: 'root',
  password: 'Scc20010117',
  database: 'yunchuang',
  waitForConnections: true,
  connectionLimit: 10,
});
```

## 域名信息

- 主域名: shunze.lol
- www域名: www.shunze.lol

## 注意事项

- ✅ **免密登录已配置**，优先使用 `ssh yunchuang` 连接服务器
- MySQL为内网地址，本地开发需通过SSH隧道访问
- 密码包含特殊字符时需用引号包裹
- 生产环境建议使用环境变量存储密码
- 私钥文件 `id_rsa_yunchuang` 请妥善保管，不要泄露给他人
