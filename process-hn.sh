#!/bin/bash
#set -x
#auth: 岚叔

# HN帖子处理脚本
# 用法: ./process-hn.sh <HN_POST_ID> [format] [--no-analyze]

# 加载用户的shell配置以获取自定义函数
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
elif [ -f ~/.zshrc ]; then
    source ~/.zshrc
fi

set -e  # 遇到错误时退出

# 检查参数
if [ $# -lt 1 ]; then
    echo "用法: $0 <HN_POST_ID> [format] [--no-analyze]"
    echo "格式: json (默认) 或 md"
    echo "选项: --no-analyze 仅生成prompt文件，不调用Claude分析"
    echo "示例: $0 8863"
    echo "示例: $0 8863 md"
    echo "示例: $0 8863 json --no-analyze"
    exit 1
fi

HN_POST_ID=$1
FORMAT="json"
NO_ANALYZE=false

# 解析参数
if [ $# -ge 2 ]; then
    if [ "$2" = "--no-analyze" ]; then
        NO_ANALYZE=true
    elif [ "$2" = "json" ] || [ "$2" = "md" ]; then
        FORMAT=$2
        if [ "$3" = "--no-analyze" ]; then
            NO_ANALYZE=true
        fi
    else
        echo "Invalid format. Use \"json\" or \"md\""
        exit 1
    fi
fi

echo "开始处理 HN 帖子 ID: $HN_POST_ID"
if [ "$NO_ANALYZE" = true ]; then
    echo "模式: 仅生成prompt文件，不执行分析"
else
    echo "模式: 完整流程（生成prompt并执行分析）"
fi

# 步骤1: 抓取并清洗数据
echo "步骤1: 抓取并清洗数据..."
# 保存主程序输出以获取确切的文件名
OUTPUT=$(node index.js "$HN_POST_ID" "$FORMAT" --clean)
echo "$OUTPUT"

# 从输出中提取清洗文件名
if [ "$FORMAT" = "md" ]; then
    CLEAN_FILE=$(echo "$OUTPUT" | grep "Successfully saved clean data to" | sed -E 's/.*Successfully saved clean data to (.*)/\1/')
else
    CLEAN_FILE=$(echo "$OUTPUT" | grep "Successfully saved clean data to" | sed -E 's/.*Successfully saved clean data to (.*)/\1/')
fi

if [ -z "$CLEAN_FILE" ] || [ ! -f "$CLEAN_FILE" ]; then
    echo "错误: 未找到清洗后的文件"
    exit 1
fi

echo "找到清洗文件: $CLEAN_FILE"

# 步骤2: 合成完整prompt
echo "步骤2: 合成完整prompt..."
# 读取清洗后的数据
HN_CONTENT=$(cat "$CLEAN_FILE")

# 读取prompt模板
PROMPT_TEMPLATE=$(cat prompt-template.txt)

# 直接拼接模板和内容
FINAL_PROMPT="${PROMPT_TEMPLATE}

## HN讨论内容

${HN_CONTENT}"

# 保存最终prompt到文件
PROMPT_OUTPUT="output/final-prompt-$(basename "$CLEAN_FILE" .${CLEAN_FILE##*.}).txt"
echo "$FINAL_PROMPT" > "$PROMPT_OUTPUT"
echo "最终prompt已保存到: $PROMPT_OUTPUT"

# 步骤3: 调用Claude生成最终结果
if [ "$NO_ANALYZE" = true ]; then
    echo "最终prompt已保存到: $PROMPT_OUTPUT"

    # 跨平台复制到粘贴板
    echo "正在尝试复制内容到粘贴板..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v pbcopy &> /dev/null; then
            cat "$PROMPT_OUTPUT" | pbcopy
            echo "✅ 内容已复制到粘贴板 (macOS)"
        else
            echo "⚠️  未找到pbcopy命令，请安装以支持粘贴板复制"
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command -v xclip &> /dev/null; then
            cat "$PROMPT_OUTPUT" | xclip -selection clipboard
            echo "✅ 内容已复制到粘贴板 (Linux - xclip)"
        elif command -v xsel &> /dev/null; then
            cat "$PROMPT_OUTPUT" | xsel --clipboard --input
            echo "✅ 内容已复制到粘贴板 (Linux - xsel)"
        else
            echo "⚠️  请安装xclip或xsel以支持粘贴板复制"
            echo "   Ubuntu/Debian: sudo apt-get install xclip | xsel"
            echo "   CentOS/RHEL: sudo yum install xclip | xsel"
            echo "   Fedora: sudo dnf install xclip | xsel"
        fi
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        # Windows
        if command -v clip &> /dev/null; then
            cat "$PROMPT_OUTPUT" | clip
            echo "✅ 内容已复制到粘贴板 (Windows)"
        else
            echo "⚠️  未找到clip命令"
        fi
    else
        echo "⚠️  当前操作系统不支持自动复制到粘贴板"
        echo "   请手动复制文件内容: $PROMPT_OUTPUT"
    fi
else
    echo "步骤3: 调用Claude生成最终结果..."
    # 调用Claude进行分析
    #cat "$PROMPT_OUTPUT" | claude-zp -p #岚叔专用
    cat "$PROMPT_OUTPUT" | claude -p
    echo "分析完成!"
fi
