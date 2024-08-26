import requests
import yaml
import os

def load_urls_from_file(filename):
    """从文件中加载URL。"""
    with open(filename, 'r', encoding='utf-8') as file:
        return yaml.safe_load(file)

def fetch_yaml(url):
    """从URL获取YAML内容。"""
    try:
        response = requests.get(url)
        response.raise_for_status()  # 对错误响应抛出HTTPError
        return yaml.safe_load(response.text)
    except requests.RequestException as err:
        print(f"获取 {url} 失败: {err}")
        return None

def merge_proxies(urls):
    """合并来自多个URL的代理配置。"""
    merged_proxies = []
    for name, url in urls.items():
        config_data = fetch_yaml(url)
        if config_data and 'proxies' in config_data:
            for proxy in config_data['proxies']:
                # 创建新的代理字典，保留所有原始字段
                new_proxy = {**proxy, 'name': f"{name}-{proxy['name']}"}
                merged_proxies.append(new_proxy)
    return merged_proxies

def save_merged_yaml(proxies):
    """将合并的代理配置保存到一个YAML文件中。"""
    result_config = {'proxies': proxies}
    with open('merged.yaml', 'w', encoding='utf-8') as output_file:
        yaml.dump(result_config, output_file, default_flow_style=False, allow_unicode=True, sort_keys=False)

if __name__ == "__main__":
    # 从 source.yaml 文件加载 URL
    urls = load_urls_from_file('source.yaml')
    
    merged_proxies = merge_proxies(urls)
    save_merged_yaml(merged_proxies)

    print("合并后的代理已保存到 merged.yaml")
    print(f"合并的代理总数: {len(merged_proxies)}")
