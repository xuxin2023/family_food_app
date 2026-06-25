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
    {name: "hot_food_scan_now", value: "Scan Now"},
    {name: "hot_food_view_hot_foods", value: "View Hot Foods"},
    {name: "hot_food_view_more", value: "View More"}
];

// 更新base文件
const baseFile = 'E:/APP/family_food_app/entry/src/main/resources/base/element/string.json';
addStringsToFile(baseFile, newStrings);

console.log("All done!");
