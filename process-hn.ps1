# HN帖子处理脚本 (PowerShell版本)
# 用法: .\process-hn.ps1 <HN_POST_ID> [-Format <json|md>] [-NoAnalyze]

param(
    [Parameter(Mandatory=$true)]
    [string]$HNPostId,

    [Parameter(Mandatory=$false)]
    [ValidateSet("json", "md")]
    [string]$Format = "json",

    [Parameter(Mandatory=$false)]
    [switch]$NoAnalyze
)

try {
    Write-Host "开始处理 HN 帖子 ID: $HNPostId"
    if ($NoAnalyze) {
        Write-Host "模式: 仅生成prompt文件，不执行分析"
    } else {
        Write-Host "模式: 完整流程（生成prompt并执行分析）"
    }

    # 检查依赖文件是否存在
    if (-not (Test-Path "index.js")) {
        Write-Error "错误: 未找到 index.js 文件"
        exit 1
    }

    if (-not (Test-Path "prompt-template.txt")) {
        Write-Error "错误: 未找到 prompt-template.txt 文件"
        exit 1
    }

    # 确保output目录存在
    if (-not (Test-Path "output")) {
        New-Item -ItemType Directory -Name "output" | Out-Null
    }

    # 步骤1: 抓取并清洗数据
    Write-Host "步骤1: 抓取并清洗数据..."
    $output = node index.js $HNPostId $Format --clean
    Write-Host $output

    # 从输出中提取清洗文件名
    $cleanFile = ""
    $outputLines = $output -split "`n"
    foreach ($line in $outputLines) {
        if ($line -match "Successfully saved clean data to (.*)") {
            $cleanFile = $matches[1].Trim()
            break
        }
    }

    # 如果正则匹配失败，尝试根据常规命名规则构建文件名
    if (-not $cleanFile -or -not (Test-Path $cleanFile)) {
        $extension = if ($Format -eq "md") { "md" } else { "json" }
        $cleanFile = "output/hn-post-$HNPostId-clean.$extension"
    }

    if (-not (Test-Path $cleanFile)) {
        Write-Error "错误: 未找到清洗后的文件 $cleanFile"
        exit 1
    }

    Write-Host "找到清洗文件: $cleanFile"

    # 步骤2: 合成完整prompt
    Write-Host "步骤2: 合成完整prompt..."
    # 读取清洗后的数据
    $hnContent = Get-Content -Path $cleanFile -Raw

    # 读取prompt模板
    $promptTemplate = Get-Content -Path "prompt-template.txt" -Raw

    # 合成最终prompt
    $finalPrompt = "$promptTemplate

## HN讨论内容

$hnContent"

    # 生成输出文件名
    $promptOutput = "output/final-prompt-hn-post-$HNPostId-$Format.txt"

    # 保存最终prompt到文件
    $finalPrompt | Out-File -FilePath $promptOutput -Encoding UTF8
    Write-Host "最终prompt已保存到: $promptOutput"

    # 步骤3: 调用Claude生成最终结果
    if ($NoAnalyze) {
        Write-Host "最终prompt已保存到: $promptOutput"

        # 复制到粘贴板
        Write-Host "正在尝试复制内容到粘贴板..."
        Get-Content -Path $promptOutput | Set-Clipboard
        Write-Host "✅ 内容已复制到粘贴板 (Windows)"
    } else {
        Write-Host "步骤3: 调用Claude生成最终结果..."
        # 检查claude命令是否存在
        $claudeExists = Get-Command "claude" -ErrorAction SilentlyContinue
        if ($claudeExists) {
            # 调用Claude进行分析
            Get-Content -Path $promptOutput | claude -p
            Write-Host "分析完成!"
        } else {
            Write-Warning "警告: 未找到claude命令，请确保已安装Claude CLI工具"
            Write-Host "您可以使用 --no-analyze 参数仅生成prompt文件"
            exit 1
        }
    }

    Write-Host "处理完成!"
} catch {
    Write-Error "处理过程中发生错误: $_"
    exit 1
}