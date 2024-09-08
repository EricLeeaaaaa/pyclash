import yaml
import json
import subprocess
import os
import requests
from time import sleep
from typing import List, Dict
from urllib.parse import urlparse

SPEEDTEST_TIMES = 1  # 每个节点测速次数

def load_yaml_from_file(file_path: str) -> Dict:
    """
    从本地文件读取 YAML 文件并返回字典格式的数据。
    """
    with open(file_path, 'r', encoding='utf-8') as file:
        return yaml.safe_load(file)

def load_yaml_from_url(url: str) -> Dict:
    """
    从 URL 下载 YAML 文件并返回字典格式的数据。
    """
    response = requests.get(url)
    response.raise_for_status()  # 如果请求失败则抛出异常
    return yaml.safe_load(response.text)

def save_yaml(data: Dict, file_path: str):
    """
    将字典格式的数据保存为 YAML 文件。
    """
    with open(file_path, 'w', encoding='utf-8') as file:
        yaml.dump(data, file, allow_unicode=True)

def speedtest(proxy: Dict) -> float:
    """
    对单个代理进行测速，并返回平均下载速度（Mbps）。
    """
    avg_speed = 0.0
    speeds = []
    for _ in range(SPEEDTEST_TIMES):
        process = subprocess.run(['speedtest', '--accept-gdpr', '-f', 'json'], capture_output=True, text=True)
        try:
            result = json.loads(process.stdout)
            speed = float(result['download']['bandwidth']) * 8 / 1048576.0  # 转换为 Mbps
            speeds.append(speed)
        except (KeyError, json.JSONDecodeError):
            speeds.append(0.0)
    
    if speeds:
        avg_speed = sum(speeds) / len(speeds)
    
    return avg_speed

def sort_proxies_by_speed(proxies: List[Dict]) -> List[Dict]:
    """
    对代理列表按下载速度进行排序。
    """
    for proxy in proxies:
        print(f"Testing {proxy['name']} ...")
        proxy['speed'] = speedtest(proxy)
        print(f"{proxy['name']} speed: {proxy['speed']:.2f} Mbps")
    
    return sorted(proxies, key=lambda x: x['speed'], reverse=True)

def process_yaml(input_path_or_url: str):
    """
    读取本地 YAML 文件或 URL，对 `proxies` 进行测速并排序，最终输出排序后的 `proxies` 集合。
    """
    if urlparse(input_path_or_url).scheme in ('http', 'https'):
        data = load_yaml_from_url(input_path_or_url)
    else:
        data = load_yaml_from_file(input_path_or_url)
    
    if 'proxies' not in data:
        raise ValueError("YAML 文件中未找到 'proxies' 字段")
    
    sorted_proxies = sort_proxies_by_speed(data['proxies'])
    data['proxies'] = sorted_proxies
    
    save_yaml(data, 'sorted_proxies.yaml')
    print("Sorted proxies saved to 'sorted_proxies.yaml'")

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description='Test and sort proxies in a YAML file or from a URL.')
    parser.add_argument('input', metavar='input', type=str, help='Path to the YAML file or URL containing proxies')
    args = parser.parse_args()
    
    process_yaml(args.input)
