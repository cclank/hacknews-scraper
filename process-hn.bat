@echo off
REM HN帖子处理脚本 (Windows批处理版本)
REM 用法: process-hn.bat <HN_POST_ID> [format] [--no-analyze]

setlocal enabledelayedexpansion

REM 检查参数
if "%1"=="" (
    echo 用法: %0 ^<HN_POST_ID^> [format] [--no-analyze]
    echo 格式: json (默认) 或 md
    echo 选项: --no-analyze 仅生成prompt文件，不调用Claude分析
    echo 示例: %0 8863
    echo 示例: %0 8863 md
    echo 示例: %0 8863 json --no-analyze
    exit /b 1
)

set HN_POST_ID=%1
set FORMAT=json
set NO_ANALYZE=false

REM 解析参数
if not "%2"=="" (
    if "%2"=="--no-analyze" (
        set NO_ANALYZE=true
    ) else if "%2"=="json" (
        set FORMAT=json
        if "%3"=="--no-analyze" set NO_ANALYZE=true
    ) else if "%2"=="md" (
        set FORMAT=md
        if "%3"=="--no-analyze" set NO_ANALYZE=true
    ) else (
        echo Invalid format. Use "json" or "md"
        exit /b 1
    )
)

echo 开始处理 HN 帖子 ID: %HN_POST_ID%
if "%NO_ANALYZE%"=="true" (
    echo 模式: 仅生成prompt文件，不执行分析
) else (
    echo 模式: 完整流程（生成prompt并执行分析）
)

REM 步骤1: 抓取并清洗数据
echo 步骤1: 抓取并清洗数据...
REM 保存主程序输出以获取确切的文件名
for /f "delims=" %%i in ('node index.js "%HN_POST_ID%" "%FORMAT%" --clean') do set OUTPUT=%%i
echo %OUTPUT%

REM 从输出中提取清洗文件名 (简化处理，实际需要更复杂的解析)
set CLEAN_FILE=
for /f "tokens=*" %%i in ('node index.js "%HN_POST_ID%" "%FORMAT%" --clean ^| findstr "Successfully saved clean data to"') do (
    for /f "tokens=*" %%a in ("%%i") do set CLEAN_FILE_LINE=%%a
)

REM 简化处理：假设文件名格式为 output/hn-post-{ID}-clean.{ext}
if "%FORMAT%"=="md" (
    set CLEAN_FILE=output/hn-post-%HN_POST_ID%-clean.md
) else (
    set CLEAN_FILE=output/hn-post-%HN_POST_ID%-clean.json
)

if not exist "%CLEAN_FILE%" (
    echo 错误: 未找到清洗后的文件 %CLEAN_FILE%
    exit /b 1
)

echo 找到清洗文件: %CLEAN_FILE%

REM 步骤2: 合成完整prompt
echo 步骤2: 合成完整prompt...
REM 读取清洗后的数据
set "TEMP_FILE=%TEMP%\hn_content.txt"
type "%CLEAN_FILE%" > "%TEMP_FILE%"
set /p HN_CONTENT=<"%TEMP_FILE%"

REM 读取prompt模板
set "PROMPT_TEMPLATE_FILE=prompt-template.txt"
if not exist "%PROMPT_TEMPLATE_FILE%" (
    echo 错误: 未找到prompt模板文件 %PROMPT_TEMPLATE_FILE%
    exit /b 1
)

REM 合成最终prompt (简化处理)
set "PROMPT_OUTPUT=output\final-prompt-%HN_POST_ID%.txt"
copy "%PROMPT_TEMPLATE_FILE%" "%PROMPT_OUTPUT%" >nul
echo. >> "%PROMPT_OUTPUT%"
echo ## HN讨论内容 >> "%PROMPT_OUTPUT%"
echo. >> "%PROMPT_OUTPUT%"
type "%CLEAN_FILE%" >> "%PROMPT_OUTPUT%"
echo 最终prompt已保存到: %PROMPT_OUTPUT%

REM 步骤3: 调用Claude生成最终结果
if "%NO_ANALYZE%"=="true" (
    echo 最终prompt已保存到: %PROMPT_OUTPUT%

    REM 复制到粘贴板
    echo 正在尝试复制内容到粘贴板...
    type "%PROMPT_OUTPUT%" | clip
    echo ✅ 内容已复制到粘贴板 (Windows)
) else (
    echo 步骤3: 调用Claude生成最终结果...
    REM 调用Claude进行分析
    type "%PROMPT_OUTPUT%" | claude -p
    echo 分析完成!
)

REM 清理临时文件
if exist "%TEMP_FILE%" del "%TEMP_FILE%"

echo 处理完成!