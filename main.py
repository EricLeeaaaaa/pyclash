import requests
import yaml
import os

# 定义要获取YAML文件的URL字典
urls = {
    'ermaozi': 'https://raw.githubusercontent.com/ermaozi/get_subscribe/main/subscribe/clash.yml',
    'clashfree': 'https://raw.githubusercontent.com/aiboboxx/clashfree/main/clash.yml',
    # 根据需要添加更多URL，格式为 '自定义名称': 'URL'
}

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
            proxies = [
                {**proxy, 'name': f"{name}-{proxy['name']}"}
                for proxy in config_data['proxies']
            ]
            merged_proxies.extend(proxies)
    return merged_proxies

def save_merged_yaml(proxies):
    """将合并的代理配置保存到一个YAML文件中。"""
    result_config = {'proxies': proxies}
    with open('merged.yaml', 'w', encoding='utf-8') as output_file:
        yaml.dump(result_config, output_file, default_flow_style=False, allow_unicode=True)

if __name__ == "__main__":
    merged_proxies = merge_proxies(urls)
    save_merged_yaml(merged_proxies)

    print("合并后的代理已保存到 merged.yaml")
    print(f"合并的代理总数: {len(merged_proxies)}")
