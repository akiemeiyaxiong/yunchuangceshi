# 云创网站部署脚本
# 服务器: 43.160.220.37
# 用户: ubuntu
# 密码: yunchuang001?

$server = "43.160.220.37"
$user = "ubuntu"
$password = "yunchuang001?"

Write-Host "=== 云创网站部署脚本 ===" -ForegroundColor Green
Write-Host "服务器: $server" -ForegroundColor Cyan
Write-Host ""

# 步骤1: 创建远程目录
Write-Host "[1/6] 创建远程目录..." -ForegroundColor Yellow
$command = "echo '$password' | sudo -S mkdir -p /home/ubuntu/app && echo '目录创建成功'"
ssh -o StrictHostKeyChecking=no -o PasswordAuthentication=yes $user@$server $command

Write-Host ""
Write-Host "[2/6] 上传项目文件..." -ForegroundColor Yellow
Write-Host "正在上传 server 目录..."
scp -r -o StrictHostKeyChecking=no server $user@${server}:/home/ubuntu/app/

Write-Host "正在上传 nginx 目录..."
scp -r -o StrictHostKeyChecking=no nginx $user@${server}:/home/ubuntu/app/

Write-Host "正在上传 docker-compose.yml..."
scp -o StrictHostKeyChecking=no docker-compose.yml $user@${server}:/home/ubuntu/app/

Write-Host ""
Write-Host "[3/6] 配置 SSL 证书..." -ForegroundColor Yellow
$sslCommand = @"
echo '$password' | sudo -S bash -c '
mkdir -p /home/ubuntu/app/nginx/ssl
cd /home/ubuntu/app/nginx/ssl

# 生成自签名证书（用于测试）
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \\
    -keyout key.pem -out cert.pem \\
    -subj "/C=CN/ST=Beijing/L=Beijing/O=Yunchuang/OU=IT/CN=shunze.lol"

chmod 600 key.pem cert.pem
echo "SSL证书生成完成"
'
"@
ssh -o StrictHostKeyChecking=no $user@$server $sslCommand

Write-Host ""
Write-Host "[4/6] 构建并启动 Docker 容器..." -ForegroundColor Yellow
$dockerCommand = @"
echo '$password' | sudo -S bash -c '
cd /home/ubuntu/app
docker compose down 2>/dev/null || true
docker compose up -d --build
echo "容器启动完成"
sleep 5
docker compose ps
'
"@
ssh -o StrictHostKeyChecking=no $user@$server $dockerCommand

Write-Host ""
Write-Host "[5/6] 配置防火墙..." -ForegroundColor Yellow
$firewallCommand = @"
echo '$password' | sudo -S bash -c '
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
ufw status verbose
'
"@
ssh -o StrictHostKeyChecking=no $user@$server $firewallCommand

Write-Host ""
Write-Host "[6/6] 验证部署..." -ForegroundColor Yellow
$verifyCommand = @"
echo '$password' | sudo -S bash -c '
echo "=== 容器状态 ==="
docker compose -f /home/ubuntu/app/docker-compose.yml ps

echo ""
echo "=== 健康检查 ==="
curl -s -k https://localhost/health || echo "健康检查失败"

echo ""
echo "=== API 测试 ==="
curl -s -k https://localhost/api/health || echo "API 测试失败"
'
"@
ssh -o StrictHostKeyChecking=no $user@$server $verifyCommand

Write-Host ""
Write-Host "=== 部署完成 ===" -ForegroundColor Green
Write-Host "网站地址: https://shunze.lol" -ForegroundColor Cyan
Write-Host "请确保域名已解析到 $server" -ForegroundColor Yellow
