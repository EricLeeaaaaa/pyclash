#!/bin/bash

# 检查 config/source.yaml 文件是否存在
if [ ! -f config/source.yaml ]; then
    echo "Error: config/source.yaml file not found"
    exit 1
fi

# 确保 temp 目录存在
mkdir -p temp

# 读取 config/source.yaml 文件
while IFS=': ' read -r name url
do
  # 跳过空行和注释行
  [[ -z "$name" || "${name:0:1}" == "#" ]] && continue
  
  # 去除可能存在的引号
  url=$(echo "$url" | tr -d '"')
  
  echo "Downloading $name from $url"
  
  # 下载文件并重命名
  curl -L "$url" -o "temp/$name.yaml"
  
  # 检查下载是否成功
  if [ $? -eq 0 ]; then
    echo "Successfully downloaded $name.yaml"
  else
    echo "Failed to download $name.yaml"
  fi

done < config/source.yaml

echo "Download process completed."
