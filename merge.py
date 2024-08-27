import requests
import yaml

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

def merge_proxies(urls, ban_filename):
    """合并来自多个URL的代理配置，过滤掉包含ban.txt中的词语的代理，并基于代理名称去重。"""
    merged_proxies = {}

    # 加载ban.txt中的禁用词列表
    with open(ban_filename, 'r', encoding='utf-8') as file:
        ban_list = [line.strip() for line in file if line.strip()]

    def is_banned(proxy):
        """检查代理配置是否包含ban_list中的任意一个词。"""
        proxy_str = yaml.dump(proxy, default_flow_style=False, allow_unicode=True)
        return any(ban_word in proxy_str for ban_word in ban_list)

    for name, url in urls.items():
        config_data = fetch_yaml(url)
        
        # 如果没有配置数据或没有代理，直接跳过
        if not config_data or 'proxies' not in config_data:
            continue
        
        for proxy in config_data['proxies']:
            # 创建新的代理字典，保留所有原始字段
            proxy_name = f"{name}-{proxy['name']}"
            
            # 如果代理名称已经存在，或者包含禁用词，则跳过（去重和过滤）
            if proxy_name in merged_proxies or is_banned(proxy):
                continue
            
            # 添加到合并后的字典中
            merged_proxies[proxy_name] = {**proxy, 'name': proxy_name}

    # 返回去重后的代理列表
    return list(merged_proxies.values())

def save_merged_yaml(proxies, output_filename):
    """将合并的代理配置保存到一个YAML文件中。"""
    result_config = {'proxies': proxies}
    with open(output_filename, 'w', encoding='utf-8') as output_file:
        yaml.dump(result_config, output_file, default_flow_style=False, allow_unicode=True, sort_keys=False)

if __name__ == "__main__":
    # 从 config/source.yaml 文件加载 URL
    urls = load_urls_from_file('config/source.yaml')
    
    # 合并代理并过滤掉包含ban.txt中词语的代理
    merged_proxies = merge_proxies(urls, 'ban.txt')
    
    # 将合并后的代理配置保存到 output/merged.yaml
    save_merged_yaml(merged_proxies, 'output/merged.yaml')

    print("合并后的代理已保存到 output/merged.yaml")
    print(f"合并的代理总数: {len(merged_proxies)}")
