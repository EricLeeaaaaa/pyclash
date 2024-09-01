#!/bin/bash

# 安装必要的工具
apt-get update
apt-get install -y wget parallel

# 下载并安装 clash-speedtest
wget https://github.com/faceair/clash-speedtest/releases/latest/download/clash-speedtest_Linux_x86_64.tar.gz
tar -xzf clash-speedtest_Linux_x86_64.tar.gz
mv clash-speedtest /usr/local/bin/
rm clash-speedtest_Linux_x86_64.tar.gz

# 创建临时目录来存储结果
mkdir -p temp_results

# 定义测速函数
run_speedtest() {
    yaml_file="$1"
    filename=$(basename "$yaml_file" .yaml)
    mkdir -p "$filename"
    cd "$filename"
    
    # 执行测速
    clash-speedtest -c "../$yaml_file" -output csv -timeout 1s -size 52428800 -concurrent 4
    
    # 处理结果并添加文件名作为新列
    awk -v fn="$filename" 'NR>1 {print fn "," $0}' result.csv >> ../temp_results/all_results.csv
    
    cd ..
}

export -f run_speedtest

# 并行执行测速
find temp -name "*.yaml" | parallel run_speedtest

# 对结果进行排序并输出到 results.csv
echo "Filename,节点,带宽 (MB/s),延迟 (ms)" > results.csv
sort -t',' -k3 -nr temp_results/all_results.csv >> results.csv

# 清理临时文件
rm -r temp_results

echo "测速完成，结果已保存到 results.csv"
