# 云创AI自动提交脚本
# 每天19点自动提交代码到GitHub

$ErrorActionPreference = "Stop"

# 设置工作目录
$repoPath = "F:\服务器代码-云创网站\服务器代码-云创网站\trae\YunChuang-AI"
Set-Location $repoPath

# 获取当前日期时间
$date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$commitMessage = "Auto commit: $date"

try {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  云创AI - 自动提交脚本" -ForegroundColor Cyan
    Write-Host "  时间: $date" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    # 检查是否有变更
    $status = git status --porcelain
    if ([string]::IsNullOrWhiteSpace($status)) {
        Write-Host "📋 没有检测到变更，无需提交" -ForegroundColor Yellow
        exit 0
    }

    Write-Host "📊 检测到以下变更:" -ForegroundColor Green
    git status --short
    Write-Host ""

    # 添加所有变更
    Write-Host "➕ 正在添加变更到暂存区..." -ForegroundColor Blue
    git add -A

    # 提交变更
    Write-Host "💾 正在提交变更..." -ForegroundColor Blue
    git commit -m "$commitMessage"

    # 推送到远程仓库
    Write-Host "🚀 正在推送到GitHub..." -ForegroundColor Blue
    git push origin main

    Write-Host ""
    Write-Host "✅ 自动提交成功完成！" -ForegroundColor Green
    Write-Host "   提交时间: $date" -ForegroundColor Green
    Write-Host "   提交信息: $commitMessage" -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "❌ 自动提交失败!" -ForegroundColor Red
    Write-Host "   错误信息: $_" -ForegroundColor Red
    exit 1
}
