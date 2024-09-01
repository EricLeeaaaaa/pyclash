#!/bin/bash

# 检查 config/source.yaml 文件是否存在
if [ ! -f config/source.yaml ]; then
    echo "Error: config/source.yaml file not found"
    exit 1
fi

# 读取 source.yaml 文件并下载文件
while IFS=': ' read -r name url
do
    # 跳过空行和注释行
    if [[ -z "$name" || "$name" == \#* ]]; then
        continue
    fi
    
    # 去除可能存在的引号
    url=$(echo $url | tr -d '"')
    
    echo "Downloading $name from $url"
    
    # 使用 curl 下载文件并重命名
    curl -L -o "$name.yaml" "$url"
    
    # 检查下载是否成功
    if [ $? -eq 0 ]; then
        echo "Successfully downloaded $name.yaml"
    else
        echo "Failed to download $name.yaml"
    fi
    
    echo "------------------------"
done < config/source.yaml

echo "Download process completed"
