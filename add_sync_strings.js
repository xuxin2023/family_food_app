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
const newStringsZh = [
    {name: "sync_conflict_title", value: "同步冲突"},
    {name: "sync_conflict_type_prefix", value: "类型："},
    {name: "sync_conflict_local_version", value: "本地版本"},
    {name: "sync_conflict_cloud_version", value: "云端版本"},
    {name: "sync_conflict_local_default", value: "无本地数据"},
    {name: "sync_conflict_cloud_default", value: "无云端数据"},
    {name: "sync_conflict_use_local_acc", value: "使用本地版本"},
    {name: "sync_conflict_use_cloud_acc", value: "使用云端版本"}
];

const newStringsEn = [
    {name: "sync_conflict_title", value: "Sync Conflict"},
    {name: "sync_conflict_type_prefix", value: "Type: "},
    {name: "sync_conflict_local_version", value: "Local Version"},
    {name: "sync_conflict_cloud_version", value: "Cloud Version"},
    {name: "sync_conflict_local_default", value: "No local data"},
    {name: "sync_conflict_cloud_default", value: "No cloud data"},
    {name: "sync_conflict_use_local_acc", value: "Use local version"},
    {name: "sync_conflict_use_cloud_acc", value: "Use cloud version"}
];

// 更新zh_CN文件
const zhFile = 'E:/APP/family_food_app/entry/src/main/resources/zh_CN/element/string.json';
addStringsToFile(zhFile, newStringsZh);

// 更新en_US文件
const enFile = 'E:/APP/family_food_app/entry/src/main/resources/en_US/element/string.json';
addStringsToFile(enFile, newStringsEn);

console.log("All done!");
