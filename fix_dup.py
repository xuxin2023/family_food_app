import re

with open('E:\\APP\\family_food_app\\entry\\src\\main\\ets\\service\\IapService.ets', 'r', encoding='utf-8') as f:
    content = f.read()

# First version of getPurchaseHistory (lines 907-922) - no doc comment before it
# Second version has comment "获取已保存的购买记录列表（沙箱测试报告用）" before it
# Remove the FIRST occurrence only

pattern = r'  async getPurchaseHistory\(\): Promise<PurchaseRecord\[\]> \{\n    if \(!this\.context\) \{\n      return \[\];\n    \}\n    try \{\n      const dataStore = await preferences\.getPreferences\(this\.context, PREF_IAP\);\n      const historyJson = dataStore\.getSync\(KEY_PURCHASE_HISTORY, '\[\]'\) as string;\n      const history: PurchaseRecord\[\] = JSON\.parse\(historyJson\);\n      return history;\n    \} catch \(err\) \{\n      return \[\];\n    \}\n  \}\n\n'

if re.search(pattern, content):
    result = re.sub(pattern, '', content, count=1)
    with open('E:\\APP\\family_food_app\\entry\\src\\main\\ets\\service\\IapService.ets', 'w', encoding='utf-8') as f:
        f.write(result)
    print('SUCCESS: Removed first duplicate getPurchaseHistory')
else:
    print('FAIL: Pattern not matched')
    # Show exact lines 905-925 for debugging
    lines = content.split('\n')
    for i in range(904, min(926, len(lines))):
        print(f'{i+1}: |{lines[i]}|')
