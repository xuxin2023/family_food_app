# 简单的文本替换脚本
$filePath = "E:\APP\family_food_app\entry\src\main\resources\zh_CN\element\string.json"

# 读取文件
$content = Get-Content $filePath -Raw -Encoding UTF8

# 查找并替换有问题的disclaimer字段
$searchPattern = '"name": "disclaimer",
      "value": "基于标签识别生成，不替代专业建议"name": "join_group",'

$replacePattern = '"name": "disclaimer",
      "value": "基于标签识别生成，不替代专业建议"
    },
    {
      "name": "join_group",'

if ($content -match [regex]::Escape($searchPattern)) {
    Write-Host "Found malformed disclaimer, fixing..."
    $content = $content -replace [regex]::Escape($searchPattern), $replacePattern
    Set-Content $filePath $content -Encoding UTF8
    Write-Host "Fixed!"
} else {
    Write-Host "Pattern not found, trying alternative..."
    
    # 尝试另一种模式
    $altPattern = '"value": "基于标签识别生成，不替代专业建议"name": "join_group",'
    $altReplace = '"value": "基于标签识别生成，不替代专业建议"
    },
    {
      "name": "join_group",'
    
    if ($content -match [regex]::Escape($altPattern)) {
        Write-Host "Found alternative pattern, fixing..."
        $content = $content -replace [regex]::Escape($altPattern), $altReplace
        Set-Content $filePath $content -Encoding UTF8
        Write-Host "Fixed!"
    } else {
        Write-Host "No pattern found. Checking JSON validity..."
        try {
            $json = $content | ConvertFrom-Json
            Write-Host "JSON is valid. Total strings: $($json.string.Count)"
        } catch {
            Write-Host "JSON Error: $_"
        }
    }
}
