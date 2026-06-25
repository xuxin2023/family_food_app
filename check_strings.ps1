# 读取JSON文件
$jsonContent = Get-Content "E:\APP\family_food_app\entry\src\main\resources\zh_CN\element\string.json" -Raw -Encoding UTF8
$jsonData = $jsonContent | ConvertFrom-Json

# 找出所有长度超过30的字符串
$longStrings = $jsonData.string | Where-Object { $_.value.Length -gt 30 }

# 显示结果
foreach ($item in $longStrings) {
    Write-Host "$($item.name) ($($item.value.Length)): $($item.value)"
}
