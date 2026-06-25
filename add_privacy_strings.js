const fs = require('fs');

function addStringsToFile(filePath, newStrings) {
    try {
        // 读取JSON文件
        const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
        
        // 检查是否已存在，避免重复添加
        const existingNames = data.string.map(s => s.name);
        let addedCount = 0;
        
        for (const newStr of newStrings) {
            if (!existingNames.includes(newStr.name)) {
                data.string.push(newStr);
                addedCount++;
                console.log(`Added: ${newStr.name}`);
            } else {
                console.log(`Already exists: ${newStr.name}`);
            }
        }
        
        // 写回文件
        fs.writeFileSync(filePath, JSON.stringify(data, null, 2), 'utf8');
        console.log(`Successfully updated ${filePath}. Added ${addedCount} new strings.`);
        return true;
    } catch (e) {
        console.log(`Error updating ${filePath}: ${e.message}`);
        return false;
    }
}

// 定义要添加的新字符串资源
const newStrings = [
    {name: "view_detail", value: "View Detail"},
    {name: "view_policy", value: "View Policy"},
    {name: "close_dialog", value: "Close Dialog"},
    {name: "privacy_desc", value: "Please read and agree to our privacy policy and user agreement to continue using the app."},
    {name: "privacy_policy_desc", value: "How we collect, use, and protect your personal information"},
    {name: "user_agreement_desc", value: "Terms of service and usage rules for this application"},
    {name: "data_collection_list", value: "Data Collection List"},
    {name: "data_collection_list_desc", value: "View the complete list of data we collect"},
    {name: "data_local_only", value: "Your data is stored locally on your device only"},
    {name: "revoke_in_settings", value: "You can revoke consent anytime in Settings"},
    {name: "disagree_exit", value: "Disagree & Exit"}
];

// 更新base文件
const baseFile = 'E:/APP/family_food_app/entry/src/main/resources/base/element/string.json';
addStringsToFile(baseFile, newStrings);

console.log("All done!");
