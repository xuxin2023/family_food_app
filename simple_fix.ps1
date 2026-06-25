# 简单的文件复制和修复脚本
$source = "E:\APP\family_food_app\entry\src\main\resources\base\element\string.json"
$dest = "E:\APP\family_food_app\entry\src\main\resources\zh_CN\element\string.json"

Write-Host "开始修复..."

# 读取源文件
$content = Get-Content $source -Raw -Encoding UTF8

# 写入目标文件
Set-Content $dest $content -Encoding UTF8 -NoNewline

Write-Host "文件已复制！"

# 验证
$json = Get-Content $dest -Raw -Encoding UTF8 | ConvertFrom-Json
Write-Host "验证成功！总共 $($json.string.Count) 个字符串"
