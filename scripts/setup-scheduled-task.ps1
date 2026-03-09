# 云创AI - 设置Windows定时任务脚本
# 创建每天19点自动提交的任务

$taskName = "YunChuang-AI-AutoCommit"
$scriptPath = "F:\服务器代码-云创网站\服务器代码-云创网站\trae\YunChuang-AI\scripts\auto-commit.ps1"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  云创AI - 定时任务设置" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查脚本文件是否存在
if (-not (Test-Path $scriptPath)) {
    Write-Host "错误: 自动提交脚本不存在: $scriptPath" -ForegroundColor Red
    exit 1
}

# 删除已存在的同名任务
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Write-Host "发现已存在的任务，正在删除..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

# 创建任务动作
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`""

# 创建任务触发器（每天19:00）
$trigger = New-ScheduledTaskTrigger -Daily -At "19:00"

# 创建任务设置
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

# 创建任务对象
$task = New-ScheduledTask -Action $action -Trigger $trigger -Settings $settings

# 注册任务
Register-ScheduledTask -TaskName $taskName -InputObject $task -Force | Out-Null

Write-Host "定时任务创建成功!" -ForegroundColor Green
Write-Host ""
Write-Host "任务详情:" -ForegroundColor Cyan
Write-Host "   任务名称: $taskName" -ForegroundColor White
Write-Host "   执行时间: 每天 19:00" -ForegroundColor White
Write-Host "   执行脚本: $scriptPath" -ForegroundColor White
Write-Host ""
Write-Host "管理命令:" -ForegroundColor Cyan
Write-Host "   查看任务: Get-ScheduledTask -TaskName '$taskName'" -ForegroundColor Gray
Write-Host "   运行任务: Start-ScheduledTask -TaskName '$taskName'" -ForegroundColor Gray
Write-Host "   删除任务: Unregister-ScheduledTask -TaskName '$taskName' -Confirm:`$false" -ForegroundColor Gray
Write-Host ""
Write-Host "注意: 请确保已配置GitHub认证，否则推送会失败" -ForegroundColor Yellow
