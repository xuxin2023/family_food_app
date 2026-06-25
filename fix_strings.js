const fs = require('fs');

// 读取JSON文件
const filePath = 'E:/APP/family_food_app/entry/src/main/resources/zh_CN/element/string.json';
const data = fs.readFileSync(filePath, 'utf8');
const json = JSON.parse(data);

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
    if (shortenMap[item.name] && item.value !== shortenMap[item.name]) {
        console.log(`Updating ${item.name}: ${item.value.length} -> ${shortenMap[item.name].length}`);
        item.value = shortenMap[item.name];
        updated = true;
    }
});

if (updated) {
    // 写回文件
    fs.writeFileSync(filePath, JSON.stringify(json, null, 2), 'utf8');
    console.log('File updated successfully!');
} else {
    console.log('No updates needed.');
}
