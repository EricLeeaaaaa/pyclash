#!/bin/bash

# 安装必要的工具
apt-get update
apt-get install -y wget parallel

# 下载并安装 clash-speedtest
wget https://github.com/faceair/clash-speedtest/releases/latest/download/clash-speedtest_Linux_x86_64.tar.gz
tar -xzf clash-speedtest_Linux_x86_64.tar.gz
mv clash-speedtest /usr/local/bin/
rm clash-speedtest_Linux_x86_64.tar.gz

# 创建必要的目录
mkdir -p temp/results
mkdir -p output

# 定义测速函数
run_speedtest() {
    yaml_file="$1"
    filename=$(basename "$yaml_file" .yaml)
    mkdir -p "temp/$filename"
    cd "temp/$filename"
    
    echo "开始对 $filename 测速"
    
    clash-speedtest -c "../$yaml_file" -output csv -timeout 1s -size 52428800 -concurrent 4
    
    awk -v fn="$filename" 'NR>1 {print fn "," $0}' result.csv >> ../results/all_results.csv
    
    cd ../..
}

export -f run_speedtest

# 并行执行测速
find temp -maxdepth 1 -name "*.yaml" | parallel run_speedtest

# 对结果进行排序并输出到 temp/results.csv
echo "Filename,节点,带宽 (MB/s),延迟 (ms)" > temp/results.csv
sort -t',' -k3 -nr temp/results/all_results.csv >> temp/results.csv

# 提取前50个结果并输出到 output/top50.csv
echo "Filename,节点,带宽 (MB/s),延迟 (ms)" > output/top50.csv
sed -n '2,51p' temp/results.csv >> output/top50.csv

# 删除 temp 文件夹
rm -rf temp

echo "测速完成，前50个结果已保存到 output/top50.csv"
