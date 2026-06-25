const fs = require('fs');

// 读取JSON文件
const data = fs.readFileSync('E:/APP/family_food_app/entry/src/main/resources/zh_CN/element/string.json', 'utf8');
const json = JSON.parse(data);

// 找出所有长度超过30的字符串
const longStrings = json.string.filter(item => item.value.length > 30);

// 打印结果
longStrings.forEach(item => {
    console.log(`${item.name} (${item.value.length}): ${item.value}`);
});
