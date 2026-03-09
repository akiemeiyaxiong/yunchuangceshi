# 云创AI自动提交脚本（带更新日志）
# 每天19点自动提交代码到GitHub，并生成更新日志

$ErrorActionPreference = "Stop"

# 设置工作目录
$repoPath = "F:\服务器代码-云创网站\服务器代码-云创网站\trae\YunChuang-AI"
Set-Location $repoPath

# 获取当前日期时间
$date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$dateShort = Get-Date -Format "yyyy-MM-dd"
$commitMessage = "Auto commit: $date"

try {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  云创AI - 自动提交脚本（带更新日志）" -ForegroundColor Cyan
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

    # 获取变更摘要
    $changedFiles = git diff --name-only
    $addedFiles = git status --porcelain | Select-String "^\?\?" | ForEach-Object { $_.Line.Substring(3) }
    $modifiedFiles = git status --porcelain | Select-String "^ M" | ForEach-Object { $_.Line.Substring(3) }
    $deletedFiles = git status --porcelain | Select-String "^ D" | ForEach-Object { $_.Line.Substring(3) }

    # 生成本次更新内容
    $updateContent = @()
    $updateContent += "## 更新摘要 - $dateShort"
    $updateContent += ""
    
    if ($addedFiles) {
        $updateContent += "### ✨ 新增文件"
        $addedFiles | ForEach-Object { $updateContent += "- $_" }
        $updateContent += ""
    }
    
    if ($modifiedFiles) {
        $updateContent += "### 📝 修改文件"
        $modifiedFiles | ForEach-Object { $updateContent += "- $_" }
        $updateContent += ""
    }
    
    if ($deletedFiles) {
        $updateContent += "### 🗑️ 删除文件"
        $deletedFiles | ForEach-Object { $updateContent += "- $_" }
        $updateContent += ""
    }

    # 显示更新摘要
    Write-Host "📝 本次更新摘要:" -ForegroundColor Cyan
    $updateContent | ForEach-Object { Write-Host $_ }
    Write-Host ""

    # 更新 CHANGELOG.md
    $changelogPath = "$repoPath\CHANGELOG.md"
    if (Test-Path $changelogPath) {
        $changelogContent = Get-Content $changelogPath -Raw
        
        # 在 [Unreleased] 部分添加本次更新
        $unreleasedPattern = "## \[Unreleased\]"
        $updateEntry = $updateContent -join "`n"
        
        # 在 Unreleased 后插入本次更新
        $newChangelogContent = $changelogContent -replace "(## \[Unreleased\]\r?\n)", "`$1`n$updateEntry`n"
        
        Set-Content $changelogPath $newChangelogContent -NoNewline
        Write-Host "✅ 已更新 CHANGELOG.md" -ForegroundColor Green
        Write-Host ""
    }

    # 添加所有变更（包括CHANGELOG的更新）
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
    Write-Host "   更新日志: 已更新 CHANGELOG.md" -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "❌ 自动提交失败!" -ForegroundColor Red
    Write-Host "   错误信息: $_" -ForegroundColor Red
    exit 1
}
