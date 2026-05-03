# fix_heights.py - 统一替换硬编码按钮高度和圆角为BUTTON常量
import re
import os

ROOT = r"E:\APP\family_food_app\entry\src\main\ets\pages"

# 排除备份文件
EXCLUDE = ['ScanPage_backup.ets', 'ScanPage_backup_v2.ets', 'Index.ets']

# 替换规则
REPLACEMENTS = {
    r'\.height\(48\)(?!\.)/': '.height(BUTTON.HEIGHT_MD)',
    r'\.borderRadius\(24\)': '.borderRadius(BUTTON.RADIUS_MD)',
    r'\.borderRadius\(26\)(?!\.)/': '.borderRadius(BUTTON.RADIUS_PRIMARY)',
    r'\.height\(44\)': '.height(BUTTON.HEIGHT_SECONDARY)',
    r'\.borderRadius\(22\)': '.borderRadius(BUTTON.RADIUS_SECONDARY)',
    r'\.height\(46\)': '.height(BUTTON.HEIGHT_SECONDARY)',
    r'\.borderRadius\(23\)': '.borderRadius(BUTTON.RADIUS_SECONDARY)',
    r'\.height\(56\)': '.height(BUTTON.HEIGHT_LG)',
    r'\.borderRadius\(28\)': '.borderRadius(BUTTON.RADIUS_LG)',
    r'\.height\(40\)': '.height(BUTTON.HEIGHT_SMALL)',
    r'\.borderRadius\(20\)': '.borderRadius(BUTTON.RADIUS_SMALL)',
}

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    # 按顺序替换，使用精确匹配避免误伤
    content = content.replace('.height(48)', '.height(BUTTON.HEIGHT_MD)')
    content = content.replace('.height(44)', '.height(BUTTON.HEIGHT_SECONDARY)')
    content = content.replace('.height(46)', '.height(BUTTON.HEIGHT_SECONDARY)')
    content = content.replace('.height(56)', '.height(BUTTON.HEIGHT_LG)')
    content = content.replace('.height(40)', '.height(BUTTON.HEIGHT_SMALL)')
    content = content.replace('.borderRadius(24)', '.borderRadius(BUTTON.RADIUS_MD)')
    content = content.replace('.borderRadius(22)', '.borderRadius(BUTTON.RADIUS_SECONDARY)')
    content = content.replace('.borderRadius(23)', '.borderRadius(BUTTON.RADIUS_SECONDARY)')
    content = content.replace('.borderRadius(26)', '.borderRadius(BUTTON.RADIUS_PRIMARY)')
    content = content.replace('.borderRadius(28)', '.borderRadius(BUTTON.RADIUS_LG)')
    content = content.replace('.borderRadius(20)', '.borderRadius(BUTTON.RADIUS_SMALL)')
    
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        changes = sum(1 for i in range(len(original)) if original[i] != content[i])
        return True, changes
    return False, 0

# 检查是否已有import
def ensure_import(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if 'BUTTON' in content and 'from' not in content.split('BUTTON')[0][-200:]:
        # 需要添加导入 - 但使用AppTheme的已有路径检查
        if 'AppTheme' in content or 'from' in content:
            return
    
    # 检查从AppTheme导入了什么
    has_apptheme = 'AppTheme' in content and ("'../constants/AppTheme'" in content or "'../constants/AppTheme'" in content)

for fname in sorted(os.listdir(ROOT)):
    if fname in EXCLUDE:
        continue
    if fname.endswith('.ets'):
        fpath = os.path.join(ROOT, fname)
        changed, cnt = fix_file(fpath)
        if changed:
            print(f"  ✓ {fname}: 已替换")

print("\n完成！")
