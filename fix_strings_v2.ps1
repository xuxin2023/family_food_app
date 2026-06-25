# PowerShell script to fix long strings in JSON file
$ErrorActionPreference = "Stop"

try {
    # 读取JSON文件
    $filePath = "E:\APP\family_food_app\entry\src\main\resources\zh_CN\element\string.json"
    Write-Host "Reading file: $filePath"
    
    $jsonContent = Get-Content $filePath -Raw -Encoding UTF8
    $jsonData = $jsonContent | ConvertFrom-Json
    
    Write-Host "Total strings found: $($jsonData.string.Count)"
    
    # 定义需要缩短的字符串
    $shortenMap = @{
        'disclaimer' = '基于标签识别生成，不替代专业建议'
        'privacy_terms_desc' = '使用即表示同意服务条款。我们收集必要数据以提供个性化饮食建议。'
        'setup_profile_hint' = '为每位家庭成员设置健康目标，扫码即可看到个性化建议。'
        'recipe_community_hint' = '扫描后可创建食谱分享到社区，或看看别人怎么搭配'
        'status_affect_hint' = '这些状态会影响今天的适配报告和美食程度判断。'
    }
    
    # 更新字符串
    $updated = $false
    foreach ($item in $jsonData.string) {
        if ($shortenMap.ContainsKey($item.name)) {
            $oldLength = $item.value.Length
            $newValue = $shortenMap[$item.name]
            $newLength = $newValue.Length
            
            if ($item.value -ne $newValue) {
                Write-Host "Updating $($item.name): $oldLength -> $newLength chars"
                $item.value = $newValue
                $updated = $true
            }
        }
    }
    
    if ($updated) {
        # 写回文件
        Write-Host "Writing updated file..."
        $jsonData | ConvertTo-Json -Depth 10 | Set-Content $filePath -Encoding UTF8
        Write-Host "File updated successfully!"
    } else {
        Write-Host "No updates needed."
    }
    
} catch {
    Write-Host "Error: $_"
    Write-Host $_.ScriptStackTrace
}
