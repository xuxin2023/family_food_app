const fs = require('fs');
const path = require('path');

try {
    // 读取JSON文件
    const filePath = path.join('E:', 'APP', 'family_food_app', 'entry', 'src', 'main', 'resources', 'zh_CN', 'element', 'string.json');
    console.log('Reading file:', filePath);
    
    const data = fs.readFileSync(filePath, 'utf8');
    const json = JSON.parse(data);
    
    console.log('Total strings found:', json.string.length);
    
    // 定义需要缩短的字符串
    const shortenMap = {
        'disclaimer': '基于标签识别生成，不替代专业建议',
        'privacy_terms_desc': '使用即表示同意服务条款。我们收集必要数据以提供个性化饮食建议。',
        'setup_profile_hint': '为每位家庭成员设置健康目标，扫码即可看到个性化建议。',
        'recipe_community_hint': '扫描后可创建食谱分享到社区，或看看别人怎么搭配',
        'status_affect_hint': '这些状态会影响今天的适配报告和美食程度判断。'
    };
    
    // 更新字符串
    let updated = false;
    json.string.forEach(item => {
        if (shortenMap[item.name]) {
            const oldLength = item.value.length;
            const newValue = shortenMap[item.name];
            const newLength = newValue.length;
            
            if (item.value !== newValue) {
                console.log(`Updating ${item.name}: ${oldLength} -> ${newLength} chars`);
                item.value = newValue;
                updated = true;
            }
        }
    });
    
    if (updated) {
        // 写回文件
        console.log('Writing updated file...');
        fs.writeFileSync(filePath, JSON.stringify(json, null, 2), 'utf8');
        console.log('File updated successfully!');
    } else {
        console.log('No updates needed.');
    }
    
} catch (error) {
    console.error('Error:', error.message);
    console.error(error.stack);
}
