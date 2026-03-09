---
name: "tencent-ssl-deploy"
description: "自动申请腾讯云免费SSL证书并部署到服务器。Invoke when user needs to apply for Tencent Cloud SSL certificate and deploy it to server automatically."
---

# 腾讯云 SSL 证书自动申请与部署

## 功能概述

自动完成以下流程：
1. 通过腾讯云 API 申请免费 SSL 证书
2. 自动添加 DNS 验证记录
3. 等待证书签发
4. 下载证书文件
5. 部署到服务器 Nginx 目录
6. 重载 Nginx 服务

## 前置要求

### 1. 腾讯云账号准备
- 已完成腾讯云实名认证
- 域名 `shunze.lol` 和 `www.shunze.lol` 已托管在腾讯云云解析 DNS
- 已创建腾讯云 API 密钥（SecretId 和 SecretKey）

### 2. 服务器信息
- **服务器 IP**: 43.160.220.37
- **域名**: shunze.lol, www.shunze.lol
- **证书部署路径**: `/etc/nginx/ssl/`
- **Nginx 容器名称**: yunchuang-nginx

### 3. 安装依赖

```bash
# 安装腾讯云 CLI
pip install tccli

# 配置腾讯云凭证
tccli configure
# 输入 SecretId、SecretKey、ap-guangzhou 等信息
```

## 自动化脚本

### 主脚本: `scripts/deploy-ssl.sh`

```bash
#!/bin/bash

# 配置变量
DOMAIN="shunze.lol"
WWW_DOMAIN="www.shunze.lol"
SERVER_IP="43.160.220.37"
SSL_DIR="/etc/nginx/ssl"
CONTAINER_NAME="yunchuang-nginx"

# 腾讯云配置
SECRET_ID="${TENCENT_SECRET_ID}"
SECRET_KEY="${TENCENT_SECRET_KEY}"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查依赖
check_dependencies() {
    log_info "检查依赖..."
    
    if ! command -v tccli &> /dev/null; then
        log_error "未安装腾讯云 CLI，请先安装: pip install tccli"
        exit 1
    fi
    
    if [ -z "$SECRET_ID" ] || [ -z "$SECRET_KEY" ]; then
        log_error "请设置环境变量 TENCENT_SECRET_ID 和 TENCENT_SECRET_KEY"
        exit 1
    fi
    
    log_info "依赖检查通过"
}

# 申请证书
apply_certificate() {
    local domain=$1
    log_info "正在申请证书: $domain"
    
    # 申请证书
    local result=$(tccli ssl ApplyCertificate \
        --region ap-guangzhou \
        --ProductId 8 \
        --DomainName "$domain" \
        --ValidationMethod DNS \
        --AlgorithmType RSA)
    
    local cert_id=$(echo "$result" | jq -r '.CertificateId')
    
    if [ -z "$cert_id" ] || [ "$cert_id" == "null" ]; then
        log_error "证书申请失败"
        exit 1
    fi
    
    log_info "证书申请成功，ID: $cert_id"
    echo "$cert_id"
}

# 获取 DNS 验证信息
get_dns_validation() {
    local cert_id=$1
    log_info "获取 DNS 验证信息..."
    
    # 等待证书状态更新
    sleep 5
    
    local result=$(tccli ssl DescribeCertificateDetail \
        --region ap-guangzhou \
        --CertificateId "$cert_id")
    
    local dns_record=$(echo "$result" | jq -r '.DvAuthDetail.DvAuthSubDomain')
    local dns_value=$(echo "$result" | jq -r '.DvAuthDetail.DvAuthValue')
    
    echo "$dns_record|$dns_value"
}

# 添加 DNS 记录
add_dns_record() {
    local domain=$1
    local record=$2
    local value=$3
    
    log_info "添加 DNS 验证记录: $record -> $value"
    
    # 提取主域名
    local main_domain=$(echo "$domain" | awk -F'.' '{print $(NF-1)"."$NF}')
    
    tccli dnspod CreateRecord \
        --region ap-guangzhou \
        --Domain "$main_domain" \
        --SubDomain "$record" \
        --RecordType TXT \
        --RecordLine "默认" \
        --Value "$value"
    
    log_info "DNS 记录添加成功"
}

# 等待证书签发
wait_for_certificate() {
    local cert_id=$1
    log_info "等待证书签发（可能需要 5-30 分钟）..."
    
    local max_attempts=60
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        local result=$(tccli ssl DescribeCertificateDetail \
            --region ap-guangzhou \
            --CertificateId "$cert_id")
        
        local status=$(echo "$result" | jq -r '.Status')
        
        if [ "$status" == "1" ]; then
            log_info "证书已签发！"
            return 0
        elif [ "$status" == "2" ]; then
            log_error "证书申请被拒绝"
            exit 1
        fi
        
        log_info "当前状态: $status，等待中... ($attempt/$max_attempts)"
        sleep 60
        ((attempt++))
    done
    
    log_error "等待超时，证书未签发"
    exit 1
}

# 下载证书
download_certificate() {
    local cert_id=$1
    log_info "下载证书..."
    
    local result=$(tccli ssl DownloadCertificate \
        --region ap-guangzhou \
        --CertificateId "$cert_id")
    
    # 解析证书内容
    local cert_content=$(echo "$result" | jq -r '.Content' | base64 -d)
    local key_content=$(echo "$result" | jq -r '.Key' | base64 -d)
    
    # 保存证书
    echo "$cert_content" > cert.pem
    echo "$key_content" > key.pem
    
    log_info "证书下载完成"
}

# 部署证书到服务器
deploy_to_server() {
    log_info "部署证书到服务器 $SERVER_IP..."
    
    # 创建远程目录
    ssh root@$SERVER_IP "mkdir -p $SSL_DIR"
    
    # 上传证书文件
    scp cert.pem root@$SERVER_IP:$SSL_DIR/
    scp key.pem root@$SERVER_IP:$SSL_DIR/
    
    # 设置权限
    ssh root@$SERVER_IP "chmod 644 $SSL_DIR/cert.pem && chmod 600 $SSL_DIR/key.pem"
    
    log_info "证书部署完成"
}

# 重载 Nginx
reload_nginx() {
    log_info "重载 Nginx..."
    
    ssh root@$SERVER_IP "docker exec $CONTAINER_NAME nginx -s reload"
    
    log_info "Nginx 重载完成"
}

# 清理临时文件
cleanup() {
    log_info "清理临时文件..."
    rm -f cert.pem key.pem
}

# 主流程
main() {
    log_info "开始 SSL 证书自动申请与部署流程"
    log_info "域名: $DOMAIN, $WWW_DOMAIN"
    log_info "服务器: $SERVER_IP"
    
    check_dependencies
    
    # 申请主域名证书
    local cert_id=$(apply_certificate "$DOMAIN")
    
    # 获取并添加 DNS 验证
    local dns_info=$(get_dns_validation "$cert_id")
    local dns_record=$(echo "$dns_info" | cut -d'|' -f1)
    local dns_value=$(echo "$dns_info" | cut -d'|' -f2)
    
    add_dns_record "$DOMAIN" "$dns_record" "$dns_value"
    
    # 等待签发
    wait_for_certificate "$cert_id"
    
    # 下载证书
    download_certificate "$cert_id"
    
    # 部署到服务器
    deploy_to_server
    
    # 重载 Nginx
    reload_nginx
    
    # 清理
    cleanup
    
    log_info "SSL 证书申请与部署完成！"
    log_info "证书已部署到: $SSL_DIR"
    log_info "请访问 https://$DOMAIN 验证"
}

# 执行
main "$@"
```

## 使用说明

### 1. 设置环境变量

```bash
export TENCENT_SECRET_ID="your-secret-id"
export TENCENT_SECRET_KEY="your-secret-key"
```

### 2. 配置 SSH 免密登录

确保本地可以免密登录服务器：

```bash
ssh-copy-id root@43.160.220.37
```

### 3. 执行脚本

```bash
chmod +x scripts/deploy-ssl.sh
./scripts/deploy-ssl.sh
```

## 定时自动续期

添加 crontab 任务，每 60 天自动续期：

```bash
# 编辑 crontab
crontab -e

# 添加以下内容（每 60 天执行一次）
0 2 */60 * * /path/to/deploy-ssl.sh >> /var/log/ssl-renew.log 2>&1
```

## 注意事项

1. **免费证书限制**：
   - 有效期 90 天
   - 仅支持单域名，不支持泛域名
   - 每个腾讯云账号最多 50 张免费证书

2. **DNS 验证**：
   - 域名必须托管在腾讯云云解析 DNS
   - 验证记录添加后需要等待 DNS 传播（通常 5-30 分钟）

3. **证书格式**：
   - 证书文件：`cert.pem`
   - 私钥文件：`key.pem`
   - 与 nginx.conf 中配置的路径一致

## 故障排查

### 证书申请失败
```bash
# 查看证书详情
tccli ssl DescribeCertificateDetail --CertificateId "证书ID"
```

### DNS 验证失败
```bash
# 检查 DNS 记录是否生效
dig TXT _dnsauth.shunze.lol
```

### Nginx 重载失败
```bash
# 检查证书文件是否存在
ssh root@43.160.220.37 "ls -la /etc/nginx/ssl/"

# 检查 Nginx 配置
docker exec yunchuang-nginx nginx -t
```
