#!/bin/bash

# 设置错误处理
set -e  # 遇到错误时立即退出
set -o pipefail  # 如果任何命令失败，则整个管道失败
set -x  # 打印执行的每一行命令

# 定义变量
DOWNLOAD_URL="https://api.github.com/repos/faceair/clash-speedtest/releases/latest"
ARCHIVE_NAME="clash-speedtest_Linux_x86_64.tar.gz"
EXECUTABLE_NAME="clash-speedtest"
MERGED_FILE="output/merged.yaml"
VALID_SERVERS_FILE="valid_servers.txt"
MAX_SERVERS=500  # 保留的最大服务器数量

# 下载并解压最新的 clash-speedtest
echo "Downloading the latest release of clash-speedtest..."
LATEST_RELEASE=$(curl -s "$DOWNLOAD_URL" | grep "browser_download_url.*Linux_x86_64.tar.gz" | cut -d '"' -f 4)
if [ -z "$LATEST_RELEASE" ]; then
    echo "Error: Failed to retrieve the latest release URL"
    exit 1
fi

echo "Downloading from $LATEST_RELEASE..."
curl -L "$LATEST_RELEASE" -o "$ARCHIVE_NAME"
echo "Extracting clash-speedtest..."
tar -xzf "$ARCHIVE_NAME" "$EXECUTABLE_NAME"

# 检查 clash-speedtest 是否成功解压并给予执行权限
if [ ! -f "./$EXECUTABLE_NAME" ]; then
    echo "Error: $EXECUTABLE_NAME not found after extraction"
    exit 1
fi
chmod +x "./$EXECUTABLE_NAME"

# 检查 merged.yaml 是否存在并打印其前几行
if [ ! -f "$MERGED_FILE" ]; then
    echo "Error: $MERGED_FILE not found"
    exit 1
fi
echo "First 10 lines of $MERGED_FILE:"
head -n 10 "$MERGED_FILE"

# 执行 clash-speedtest
echo "Running clash-speedtest..."
"./$EXECUTABLE_NAME" -c "$MERGED_FILE" -output csv -timeout 1s

# 检查 result.csv 是否生成
if [ ! -f "result.csv" ]; then
    echo "Error: result.csv not generated"
    exit 1
fi

# 处理 CSV 文件并限制服务器数量为前500个
echo "Processing result.csv and limiting to top $MAX_SERVERS servers..."
awk -F',' 'NR>1 && $2!="N/A" && $3!="N/A" {print $1}' "result.csv" | head -n "$MAX_SERVERS" > "$VALID_SERVERS_FILE"

# 检查 valid_servers.txt 是否生成
if [ ! -f "$VALID_SERVERS_FILE" ]; then
    echo "Error: $VALID_SERVERS_FILE not generated"
    exit 1
fi

# 读取 merged.yaml 并只保留有效的服务器
echo "Filtering $MERGED_FILE based on valid servers..."
awk '
BEGIN {
    in_proxies = 0
    buffer = ""
}
/^proxies:/ {
    in_proxies = 1
    print
    next
}
in_proxies && /^  -/ {
    buffer = $0 "\n"
    getline
    while ($0 ~ /^    /) {
        buffer = buffer $0 "\n"
        getline
    }
    if (buffer ~ /name: ([^,]+)/) {
        server_name = gensub(/.*name: ([^,]+).*/, "\\1", "g", buffer)
        cmd = "grep -q \"^" server_name "$\" '"$VALID_SERVERS_FILE"'"
        if (system(cmd) == 0) {
            printf "%s", buffer
        }
    }
    buffer = ""
    if ($0 !~ /^  -/) {
        print
    }
    next
}
!in_proxies || $0 !~ /^  -/ {
    print
}
' "$MERGED_FILE" > "${MERGED_FILE%.yaml}_filtered.yaml"

# 检查 merged_filtered.yaml 是否生成
FILTERED_MERGED_FILE="${MERGED_FILE%.yaml}_filtered.yaml"
if [ ! -f "$FILTERED_MERGED_FILE" ]; then
    echo "Error: $FILTERED_MERGED_FILE not generated"
    exit 1
fi

# 替换原文件
echo "Replacing $MERGED_FILE with $FILTERED_MERGED_FILE..."
mv "$FILTERED_MERGED_FILE" "$MERGED_FILE"

# 清理临时文件
echo "Cleaning up temporary files..."
rm -f "$VALID_SERVERS_FILE" "$EXECUTABLE_NAME" "$ARCHIVE_NAME" result.csv

echo "Script completed successfully"
