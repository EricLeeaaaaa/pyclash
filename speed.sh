#!/bin/bash

set -e  # 遇到错误时立即退出
set -x  # 打印执行的每一行命令

# 下载并解压最新的 clash-speedtest
LATEST_RELEASE=$(curl -s https://api.github.com/repos/faceair/clash-speedtest/releases/latest | grep "browser_download_url.*Linux_x86_64.tar.gz" | cut -d '"' -f 4)
curl -L $LATEST_RELEASE | tar xz

# 检查 clash-speedtest 是否成功解压并给予执行权限
if [ ! -f ./clash-speedtest ]; then
    echo "Error: clash-speedtest not found after extraction"
    exit 1
fi
chmod +x ./clash-speedtest

# 打印 clash-speedtest 的文件信息
ls -l ./clash-speedtest

# 检查 merged.yml 是否存在并打印其前几行
if [ ! -f merged.yml ]; then
    echo "Error: merged.yml not found"
    exit 1
fi
echo "First 10 lines of merged.yml:"
head -n 10 merged.yml

# 执行 clash-speedtest 并捕获详细输出
./clash-speedtest -c merged.yml -output csv -timeout 1s > results.csv 2>clash_speedtest_error.log

# 如果 clash-speedtest 失败，打印错误日志
if [ $? -ne 0 ]; then
    echo "clash-speedtest failed. Error log:"
    cat clash_speedtest_error.log
    exit 1
fi

# 检查 results.csv 是否生成
if [ ! -f results.csv ]; then
    echo "Error: results.csv not generated"
    exit 1
fi

# 处理 CSV 文件并更新 merged.yml
awk -F',' 'NR>1 && $2!="N/A" && $3!="N/A" {print $1}' results.csv > valid_servers.txt

# 检查 valid_servers.txt 是否生成
if [ ! -f valid_servers.txt ]; then
    echo "Error: valid_servers.txt not generated"
    exit 1
fi

# 读取 merged.yml 并只保留有效的服务器
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
        cmd = "grep -q \"^" server_name "$\" valid_servers.txt"
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
' merged.yml > merged_updated.yml

# 检查 merged_updated.yml 是否生成
if [ ! -f merged_updated.yml ]; then
    echo "Error: merged_updated.yml not generated"
    exit 1
fi

# 替换原文件
mv merged_updated.yml merged.yml

# 清理临时文件
rm results.csv valid_servers.txt clash-speedtest

echo "Script completed successfully"
