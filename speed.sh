#!/bin/bash

# 设置工作目录
WORK_DIR="output"
cd "$WORK_DIR" || exit 1

# 下载并解压 clash-speedtest
wget https://github.com/faceair/clash-speedtest/releases/latest/download/clash-speedtest_Linux_x86_64.tar.gz
tar -xzvf clash-speedtest_Linux_x86_64.tar.gz clash-speedtest
rm clash-speedtest_Linux_x86_64.tar.gz

# 执行 clash-speedtest
./clash-speedtest -c merged.yaml -output csv -timeout 1s -size 52428800 -concurrent 32 > result.csv

# 处理 result.csv 文件，限制服务器数量为前50个
sed '1d' result.csv | sort -t',' -k2 -nr | head -n 50 > top50.csv

# 提取前50个节点的名称
cut -d',' -f1 top50.csv > top50_names.txt

# 处理 merged.yaml 文件并直接覆盖
awk '
BEGIN {
    print "proxies:"
}
/^- name:/ {
    in_proxy = 1
    proxy = $0
    next
}
in_proxy {
    proxy = proxy "\n" $0
    if ($0 ~ /^$/) {
        in_proxy = 0
        if (system("grep -q \"" $2 "\" top50_names.txt") == 0) {
            print proxy
        }
    }
}
' merged.yaml > merged.yaml.new && mv merged.yaml.new merged.yaml

# 清理临时文件
rm top50.csv top50_names.txt result.csv clash-speedtest

echo "处理完成，原 merged.yaml 文件已更新。"
