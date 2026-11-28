# 安装「汉化自动守护」：登录时自启，每 20 分钟检测一次，更新导致汉化丢失时自动重新汉化。
# 无需管理员权限（写入当前用户的启动文件夹）。
$ErrorActionPreference = 'Stop'

$here  = Split-Path -Parent $MyInvocation.MyCommand.Path
$guard = Join-Path $here 'auto_repatch.ps1'
$loop  = Join-Path $here 'watchdog_loop.ps1'
$startup = [Environment]::GetFolderPath('Startup')
$lnk = Join-Path $startup 'Antigravity汉化守护.lnk'

if (-not (Test-Path $guard) -or -not (Test-Path $loop)) {
    Write-Host "[ERR] 缺少 auto_repatch.ps1 或 watchdog_loop.ps1"; exit 1
}

# 1. 启动文件夹快捷方式（登录自启）
$sh = New-Object -ComObject WScript.Shell
$sc = $sh.CreateShortcut($lnk)
$sc.TargetPath = 'powershell.exe'
$sc.Arguments = '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $loop + '"'
$sc.WorkingDirectory = $here
$sc.Description = 'Antigravity 汉化自动守护（登录时启动）'
$sc.Save()
Write-Host "[OK] 已创建登录自启快捷方式: $lnk"

# 2. 立即启动一个守护进程
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
  Where-Object { $_.CommandLine -like '*watchdog_loop.ps1*' -and $_.CommandLine -notlike '*-Command*' } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
$ws = New-Object -ComObject WScript.Shell
$ws.Run('powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $loop + '"', 0, $false) | Out-Null
Write-Host "[OK] 守护进程已启动（每 20 分钟检测一次）"
Write-Host "[OK] 日志: $env:LOCALAPPDATA\agy-auto-repatch.log"
Write-Host ""
Write-Host "说明：Antigravity 每次自动更新会覆盖汉化；守护进程会在你下次登录或"
Write-Host "      关闭 Antigravity 后自动重新汉化，无需手动干预。"
