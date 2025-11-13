# HackNews淘金程序

这是一个用于抓取 Hacker News 帖子及其所有评论的工具，可以将数据保存为 JSON 或 Markdown 格式。

## 核心功能

- 根据 HN 帖子 ID 抓取完整帖子和评论
- 支持 JSON 和 Markdown 两种输出格式
- 数据清洗功能：只保留核心信息并按时间排序
- 自动化处理脚本：一键生成AI分析prompt

## 快速开始

### macOS/Linux
```bash
# 安装依赖
npm install

# 抓取帖子并生成AI分析prompt
./process-hn.sh <HN_POST_ID> [format] [--no-analyze]

# 示例
./process-hn.sh 8863 json --no-analyze  # 仅生成prompt并复制到粘贴板
./process-hn.sh 8863 json               # 生成prompt并调用Claude分析
```

### Windows
```cmd
# 安装依赖
npm install

# 使用批处理脚本
process-hn.bat <HN_POST_ID> [format] [--no-analyze]

# 或使用PowerShell脚本 (推荐)
powershell -ExecutionPolicy Bypass -File .\process-hn.ps1 <HN_POST_ID> [-Format <json|md>] [-NoAnalyze]

# 示例
powershell -ExecutionPolicy Bypass -File .\process-hn.ps1 8863 -Format json -NoAnalyze  # 仅生成prompt并复制到粘贴板
powershell -ExecutionPolicy Bypass -File .\process-hn.ps1 8863 -Format json             # 生成prompt并调用Claude分析
```

## 输出文件

- `output/帖子标题-clean.json` - 清洗后的数据
- `output/final-prompt-帖子标题-clean.txt` - 完整的AI分析prompt

## Prompt模板

Prompt模板来自宝玉，位于 `prompt-template.txt` 文件中。

## 使用支持

使用中如有问题，请找岚叔（https://x.com/LufzzLiz）