# Antigravity 汉化守护常驻循环
# 由启动文件夹的快捷方式在登录时静默启动；每 20 分钟调用一次 auto_repatch.ps1。
$ErrorActionPreference = 'SilentlyContinue'
$guard = 'C:\Users\31483\Documents\deepseek-harness\default-workspace\antigravity-zh-一键汉化包\auto_repatch.ps1'
$intervalMin = 20
$log = Join-Path $env:LOCALAPPDATA 'agy-auto-repatch.log'

function W([string]$m){ try { Add-Content -LiteralPath $log -Value ("{0} {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'),$m) -Encoding UTF8 } catch {} }

W "守护进程启动（每 $intervalMin 分钟检测一次）"
while ($true) {
    try {
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File $guard | Out-Null
    } catch {
        W "守护调用异常: $($_.Exception.Message)"
    }
    Start-Sleep -Seconds ($intervalMin * 60)
}
