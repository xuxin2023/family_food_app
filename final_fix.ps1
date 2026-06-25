# 最终修复脚本 - 使用字节操作
$filePath = "E:\APP\family_food_app\entry\src\main\resources\zh_CN\element\string.json"

# 读取文件字节
$bytes = [System.IO.File]::ReadAllBytes($filePath)
$content = [System.Text.Encoding]::UTF8.GetString($bytes)

# 查找有问题的部分
$problemText = '"value": "基于标签识别生成，不替代专业建议"name": "join_group",'
$fixedText = @'
"value": "基于标签识别生成，不替代专业建议"
    },
    {
      "name": "join_group",
'@

if ($content.Contains($problemText)) {
    Write-Host "Found problem, fixing..."
    $content = $content.Replace($problemText, $fixedText)
    
    # 写回文件
    $newBytes = [System.Text.Encoding]::UTF8.GetBytes($content)
    [System.IO.File]::WriteAllBytes($filePath, $newBytes)
    
    Write-Host "File fixed successfully!"
} else {
    Write-Host "Problem text not found. Checking if already fixed..."
    
    # 验证JSON
    try {
        $json = $content | ConvertFrom-Json
        Write-Host "JSON is valid! Total strings: $($json.string.Count)"
        
        # 检查disclaimer字段
        $disclaimer = $json.string | Where-Object { $_.name -eq 'disclaimer' }
        if ($disclaimer) {
            Write-Host "Disclaimer value: $($disclaimer.value)"
            Write-Host "Disclaimer length: $($disclaimer.value.Length)"
        }
    } catch {
        Write-Host "JSON Error: $_"
    }
}
