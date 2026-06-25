const fs = require('fs');

const filePath = 'E:/APP/family_food_app/entry/src/main/resources/zh_CN/element/string.json';
const newStrings = [
    {name: "hot_food_scan_now", value: "立即扫描"},
    {name: "hot_food_view_hot_foods", value: "查看热门食品"},
    {name: "hot_food_view_more", value: "查看更多"},
    {name: "nutrition_trend_summary", value: "营养趋势摘要"},
    {name: "view_detail", value: "查看详情"},
    {name: "view_policy", value: "查看政策"},
    {name: "close_dialog", value: "关闭对话框"},
    {name: "privacy_desc", value: "我们重视您的隐私"},
    {name: "privacy_policy_desc", value: "了解我们如何收集、使用和保护您的个人信息"},
    {name: "user_agreement_desc", value: "了解使用本应用的权利和义务"},
    {name: "data_collection_list", value: "数据收集清单"},
    {name: "data_collection_list_desc", value: "查看我们收集的具体数据项及用途"},
    {name: "data_local_only", value: "您的数据仅存储在本地设备"},
    {name: "revoke_in_settings", value: "您可随时在设置中撤销授权"},
    {name: "disagree_exit", value: "不同意并退出"}
];

try {
    const content = fs.readFileSync(filePath, 'utf8');
    console.log('File content length:', content.length);
    
    const data = JSON.parse(content);
    console.log('Parsed successfully. String count:', data.string.length);
    
    const existingNames = data.string.map(s => s.name);
    let addedCount = 0;
    
    for (const newStr of newStrings) {
        if (!existingNames.includes(newStr.name)) {
            data.string.push(newStr);
            addedCount++;
            console.log('Added:', newStr.name);
        } else {
            console.log('Already exists:', newStr.name);
        }
    }
    
    fs.writeFileSync(filePath, JSON.stringify(data, null, 2), 'utf8');
    console.log('Successfully updated file. Added', addedCount, 'new strings.');
} catch (e) {
    console.error('Error:', e.message);
    console.error('Stack:', e.stack);
}
