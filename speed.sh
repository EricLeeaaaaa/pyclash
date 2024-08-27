#!/bin/bash

# 下载并解压最新的 clash-speedtest
LATEST_RELEASE=$(curl -s https://api.github.com/repos/faceair/clash-speedtest/releases/latest | grep "browser_download_url.*Linux_x86_64.tar.gz" | cut -d '"' -f 4)
curl -L $LATEST_RELEASE | tar xz

# 执行 clash-speedtest
./clash-speedtest -c merged.yml -output csv -timeout 1s > results.csv

# 处理 CSV 文件并更新 merged.yml
awk -F',' 'NR>1 && $2!="N/A" && $3!="N/A" {print $1}' results.csv > valid_servers.txt

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

# 替换原文件
mv merged_updated.yml merged.yml

# 清理临时文件
rm results.csv valid_servers.txt clash-speedtest
