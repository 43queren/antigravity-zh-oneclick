# Antigravity 自动重汉化守护脚本
# 由 Windows 任务计划程序调用：登录时 + 周期性检查。
# 检测到 app.asar 被官方更新还原（汉化丢失）时自动重新注入汉化。
# 为避免打断工作：仅当 Antigravity 未运行时才动手；运行中则跳过并记录。
param([switch]$Force)

$ErrorActionPreference = 'Stop'

$asar  = 'C:\Users\31483\AppData\Local\Programs\antigravity\resources\app.asar'
$pkg   = 'C:\Users\31483\Documents\deepseek-harness\default-workspace\antigravity-zh-一键汉化包'
$py    = 'C:\Users\31483\AppData\Local\Programs\Python\Python310\python.exe'
$log   = Join-Path $env:LOCALAPPDATA 'agy-auto-repatch.log'
$tag   = 'Antigravity Chinese Translation Injection v3-full'

function Write-Log([string]$Message) {
    $line = "{0} {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    try { Add-Content -LiteralPath $log -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue } catch {}
    Write-Host $line
}

try {
    if (-not (Test-Path -LiteralPath $asar)) {
        Write-Log '跳过：app.asar 不存在（Antigravity 未安装？）'
        exit 0
    }
    if (-not (Test-Path -LiteralPath $py)) {
        Write-Log "跳过：Python 不存在 ($py)"
        exit 1
    }
    if (-not (Test-Path -LiteralPath (Join-Path $pkg 'install.py'))) {
        Write-Log "跳过：汉化脚本不存在 ($pkg)"
        exit 1
    }

    # 检测汉化标记：app.asar 中文件以明文存储，直接搜 ASCII 标记即可
    $bytes = [System.IO.File]::ReadAllBytes($asar)
    $ascii = [System.Text.Encoding]::ASCII.GetString($bytes)
    if ($ascii.Contains($tag)) {
        Write-Log '状态正常：已汉化，无需操作'
        exit 0
    }

    Write-Log '检测到汉化已被更新还原，准备重新汉化…'

    $appRunning = @(Get-Process -Name 'Antigravity' -ErrorAction SilentlyContinue).Count -gt 0
    if ($appRunning -and -not $Force) {
        Write-Log 'Antigravity 正在运行，为避免打断工作而跳过；下次登录或关闭后会自动重试'
        exit 0
    }
    if ($appRunning -and $Force) {
        Write-Log '强制模式：关闭 Antigravity…'
        Get-CimInstance Win32_Process -Filter "Name='Antigravity.exe'" | ForEach-Object {
            Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
        }
        Start-Sleep -Seconds 3
    }

    # 清除会导致 Electron 以 Node 模式启动的环境变量（任务环境通常没有，稳妥起见）
    $env:ELECTRON_RUN_AS_NODE = $null
    $env:DEV_URL = $null

    Write-Log '执行汉化注入…'
    $output = & $py (Join-Path $pkg 'install.py') --asar $asar 2>&1 | Out-String
    $code = $LASTEXITCODE
    Write-Log $output.Trim()

    if ($code -eq 0) {
        # 二次校验
        $bytes2 = [System.IO.File]::ReadAllBytes($asar)
        $ascii2 = [System.Text.Encoding]::ASCII.GetString($bytes2)
        if ($ascii2.Contains($tag)) {
            Write-Log '✓ 自动重汉化成功'
        } else {
            Write-Log '✗ 注入脚本返回成功，但未检测到汉化标记，请人工检查'
        }
    } else {
        Write-Log "✗ 汉化脚本失败，退出码 $code"
    }
} catch {
    Write-Log "异常：$($_.Exception.Message)"
}
