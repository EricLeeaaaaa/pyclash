#!/bin/bash

# 定义工作目录
WORK_DIR="$(pwd)"

# 安装必要的工具
apt-get update
apt-get install -y wget parallel

# 下载并安装 clash-speedtest
wget https://github.com/faceair/clash-speedtest/releases/latest/download/clash-speedtest_Linux_x86_64.tar.gz
tar -xzf clash-speedtest_Linux_x86_64.tar.gz
mv clash-speedtest /usr/local/bin/
rm clash-speedtest_Linux_x86_64.tar.gz

# 创建必要的目录
mkdir -p "${WORK_DIR}/temp/results"
mkdir -p "${WORK_DIR}/output"

# 定义测速函数
run_speedtest() {
    yaml_file="$1"
    filename=$(basename "$yaml_file")
    mkdir -p "${WORK_DIR}/temp/${filename%.*}"
    
    echo "开始对 $filename 测速"
    
    # 切换到目标目录
    cd "${WORK_DIR}/temp/${filename%.*}"
    
    # 执行测速
    clash-speedtest -c "${WORK_DIR}/temp/${filename}" -output csv -timeout 1s -size 52428800 -concurrent 4
    
    # 处理结果
    awk -v fn="${filename%.*}" 'NR>1 {print fn "," $0}' result.csv >> "${WORK_DIR}/temp/results/all_results.csv"
    
    # 返回原目录
    cd "${WORK_DIR}"
}

export -f run_speedtest
export WORK_DIR

# 并行执行测速
find "${WORK_DIR}/temp" -maxdepth 1 -name "*.yaml" | parallel run_speedtest

# 对结果进行排序并输出到 temp/results.csv
echo "Filename,节点,带宽 (MB/s),延迟 (ms)" > "${WORK_DIR}/temp/results.csv"
sort -t',' -k3 -nr "${WORK_DIR}/temp/results/all_results.csv" >> "${WORK_DIR}/temp/results.csv"

# 提取前50个结果并输出到 output/top50.csv
echo "Filename,节点,带宽 (MB/s),延迟 (ms)" > "${WORK_DIR}/output/top50.csv"
sed -n '2,51p' "${WORK_DIR}/temp/results.csv" >> "${WORK_DIR}/output/top50.csv"

# 删除 temp 文件夹
rm -r "${WORK_DIR}/temp"

echo "测速完成，前50个结果已保存到 ${WORK_DIR}/output/top50.csv"
