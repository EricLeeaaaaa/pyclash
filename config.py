import yaml
import os

def load_yaml(file_path):
    """从文件加载 YAML 内容"""
    with open(file_path, 'r', encoding='utf-8') as file:
        return yaml.safe_load(file)

def save_yaml(data, file_path):
    """将数据保存为 YAML 文件"""
    with open(file_path, 'w', encoding='utf-8') as file:
        yaml.dump(data, file, default_flow_style=False, allow_unicode=True, sort_keys=False)

def merge_clash_config(base_config_path, proxies_config_path, output_path):
    """合并基础 Clash 配置和代理列表"""
    # 加载基础配置
    base_config = load_yaml(base_config_path)
    
    # 加载代理列表
    proxies_config = load_yaml(proxies_config_path)
    
    # 将代理列表添加到基础配置中
    base_config['proxies'] = proxies_config['proxies']
    
    # 保存合并后的配置
    save_yaml(base_config, output_path)

if __name__ == "__main__":
    base_config_path = 'config.yaml'  # 你提供的基础 Clash 配置文件
    proxies_config_path = 'merged.yml'  # 之前生成的包含代理列表的文件
    output_path = 'clash.yaml'  # 最终输出的 Clash 配置文件
    
    merge_clash_config(base_config_path, proxies_config_path, output_path)
    print(f"合并完成，最终配置已保存到 {output_path}")
