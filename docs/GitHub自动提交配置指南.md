# GitHub 自动提交配置指南

本文档说明如何配置云创AI项目的GitHub自动提交功能。

## 目录

- [仓库信息](#仓库信息)
- [本地Git配置](#本地git配置)
- [SSH密钥配置](#ssh密钥配置)
- [定时任务配置](#定时任务配置)
- [自动提交脚本说明](#自动提交脚本说明)
- [更新日志说明](#更新日志说明)
- [常用命令](#常用命令)
- [故障排除](#故障排除)

---

## 仓库信息

| 项目 | 值 |
|------|------|
| 仓库地址 | https://github.com/akiemeiyaxiong/yunchuangceshi |
| SSH地址 | git@github.com:akiemeiyaxiong/yunchuangceshi.git |
| 分支 | main |

---

## 本地Git配置

### 用户信息配置

```bash
git config --global user.name "akiemeiyaxiong"
git config --global user.email "akiemeiyaxiong@gmail.com"
```

### SSH配置

本项目使用SSH方式连接GitHub，配置文件位于：

- SSH密钥：`C:\Users\Administrator\.ssh\id_ed25519_yunchuang`
- SSH配置：`C:\Users\Administrator\.ssh\config`
- Git配置：`F:\服务器代码-云创网站\服务器代码-云创网站\trae\YunChuang-AI\.git\config`

### Git配置内容

`.git/config` 文件包含以下SSH命令配置：

```ini
[core]
    sshCommand = ssh -i C:/Users/Administrator/.ssh/id_ed25519_yunchuang
[remote "origin"]
    url = git@github.com:akiemeiyaxiong/yunchuangceshi.git
    fetch = +refs/heads/*:refs/remotes/origin/*
```

---

## SSH密钥配置

### 密钥信息

- 密钥类型：ED25519
- 密钥文件：`id_ed25519_yunchuang`（私钥）和 `id_ed25519_yunchuang.pub`（公钥）
- 密钥位置：`C:\Users\Administrator\.ssh\`

### 添加SSH公钥到GitHub

1. 打开 GitHub → Settings → SSH and GPG keys
2. 点击 "New SSH key"
3. 填写Title（如：YunChuang-AI Windows）
4. 在Key中粘贴公钥内容：

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAhDsLxO+I1s0xLm3R1R/EYIXlTLTkTjUzNnoSKtcoiO yunchuang-ai
```

5. 点击 "Add SSH key"

### SSH连接测试

```bash
ssh -i ~/.ssh/id_ed25519_yunchuang -T git@github.com
```

成功后会显示：
```
Hi akiemeiyaxiong! You've successfully authenticated, but GitHub does not provide shell access.
```

---

## 定时任务配置

### 任务信息

| 项目 | 值 |
|------|------|
| 任务名称 | YunChuang-AI-AutoCommit |
| 执行频率 | 每天 19:00 |
| 执行脚本 | scripts/auto-commit-with-changelog.ps1 |

### 创建定时任务

以管理员身份打开PowerShell，运行：

```powershell
$taskName = "YunChuang-AI-AutoCommit"
$scriptPath = "F:\服务器代码-云创网站\服务器代码-云创网站\trae\YunChuang-AI\scripts\auto-commit-with-changelog.ps1"
schtasks /create /tn $taskName /tr "powershell.exe -ExecutionPolicy Bypass -File `"$scriptPath`"" /sc daily /st 19:00 /f
```

### 管理定时任务

```powershell
# 查看任务状态
schtasks /query /tn "YunChuang-AI-AutoCommit" /fo list

# 手动执行任务
schtasks /run /tn "YunChuang-AI-AutoCommit"

# 删除任务
schtasks /delete /tn "YunChuang-AI-AutoCommit" /f
```

---

## 自动提交脚本说明

### 脚本位置

- 主脚本：`scripts/auto-commit-with-changelog.ps1`

### 脚本功能

1. 检查代码变更
2. 生成变更摘要（新增/修改/删除的文件列表）
3. 自动更新 CHANGELOG.md
4. 提交所有变更
5. 推送到GitHub

### 脚本输出示例

```
========================================
  云创AI - 自动提交脚本（带更新日志）
  时间: 2026-03-09 19:00:00
========================================

📊 检测到以下变更:
 M qianduan/index.html
?? qianduan/new-page.html

📝 本次更新摘要:
## 更新摘要 - 2026-03-09

### ✨ 新增文件
- qianduan/new-page.html

### 📝 修改文件
- qianduan/index.html

✅ 已更新 CHANGELOG.md

➕ 正在添加变更到暂存区...
💾 正在提交变更...
🚀 正在推送到GitHub...

✅ 自动提交成功完成！
```

---

## 更新日志说明

### 文件位置

`CHANGELOG.md`

### 日志格式

```markdown
# 更新日志 (Changelog)

## [Unreleased]

### 新增文件
- file1.txt
- file2.js

### 修改文件
- app.js
- index.html

---

## [1.0.0] - 2026-03-09

### Added
- 云创AI网站前端页面
- 后端API服务器
```

### 分类说明

- **✨ 新增文件**：新创建的文件
- **📝 修改文件**：已存在且被修改的文件
- **🗑️ 删除文件**：被删除的文件

---

## 常用命令

### 手动提交和推送

```bash
# 添加所有变更
git add -A

# 提交变更
git commit -m "your commit message"

# 推送到GitHub
git push origin main
```

### 查看状态

```bash
# 查看当前状态
git status

# 查看变更详情
git diff

# 查看提交历史
git log --oneline
```

### 更新本地代码

```bash
# 拉取最新代码
git pull origin main
```

---

## 故障排除

### 问题1：SSH连接失败

**错误信息**：
```
git@github.com: Permission denied (publickey)
```

**解决方案**：
1. 确认SSH公钥已添加到GitHub
2. 检查SSH密钥路径是否正确
3. 运行测试命令：
   ```bash
   ssh -i ~/.ssh/id_ed25519_yunchuang -T git@github.com
   ```

### 问题2：推送被拒绝

**错误信息**：
```
error: failed to push some refs
hint: Updates were rejected because the remote contains work that you do not have locally
```

**解决方案**：
```bash
git pull origin main
git push origin main
```

### 问题3：定时任务不执行

**检查步骤**：
1. 确认任务存在：
   ```powershell
   schtasks /query /tn "YunChuang-AI-AutoCommit"
   ```
2. 手动运行测试：
   ```powershell
   powershell -ExecutionPolicy Bypass -File "F:\服务器代码-云创网站\服务器代码-云创网站\trae\YunChuang-AI\scripts\auto-commit-with-changelog.ps1"
   ```
3. 检查Windows事件查看器中的任务日志

---

## 相关文件清单

| 文件 | 说明 |
|------|------|
| `.gitignore` | Git忽略文件配置 |
| `CHANGELOG.md` | 更新日志 |
| `scripts/auto-commit-with-changelog.ps1` | 自动提交脚本 |
| `.git/config` | Git仓库配置 |

---

*本文档最后更新：2026-03-09*
