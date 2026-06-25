# PowerShell版本的修复脚本
# 修复zh_CN版本的string.json文件

$ErrorActionPreference = "Stop"

try {
    # 文件路径
    $baseFile = "E:\APP\family_food_app\entry\src\main\resources\base\element\string.json"
    $zhCnFile = "E:\APP\family_food_app\entry\src\main\resources\zh_CN\element\string.json"
    $backupFile = "E:\APP\family_food_app\entry\src\main\resources\zh_CN\element\string.json.backup"
    
    Write-Host "读取base文件: $baseFile"
    
    # 读取base文件
    $json = Get-Content $baseFile -Raw -Encoding UTF8 | ConvertFrom-Json
    
    Write-Host "总共 $($json.string.Count) 个字符串"
    
    # 定义需要缩短的字符串
    $shortenMap = @{
        'disclaimer' = '基于标签识别生成，不替代专业建议'
        'privacy_terms_desc' = '使用即表示同意服务条款。我们收集必要数据以提供个性化饮食建议。'
        'setup_profile_hint' = '为每位家庭成员设置健康目标，扫码即可看到个性化建议。'
        'recipe_community_hint' = '扫描后可创建食谱分享到社区，或看看别人怎么搭配'
        'status_affect_hint' = '这些状态会影响今天的适配报告和美食程度判断。'
    }
    
    # 更新字符串
    $updatedCount = 0
    foreach ($item in $json.string) {
        if ($shortenMap.ContainsKey($item.name)) {
            $oldValue = $item.value
            $newValue = $shortenMap[$item.name]
            
            if ($oldValue -ne $newValue) {
                Write-Host "`n更新 $($item.name):"
                Write-Host "  原长度: $($oldValue.Length) 字符"
                Write-Host "  新长度: $($newValue.Length) 字符"
                Write-Host "  原内容: $($oldValue.Substring(0, [Math]::Min(50, $oldValue.Length)))..."
                Write-Host "  新内容: $newValue"
                $item.value = $newValue
                $updatedCount++
            }
        }
    }
    
    Write-Host "`n总共更新了 $updatedCount 个字符串"
    
    # 备份原文件（如果存在）
    if (Test-Path $zhCnFile) {
        Write-Host "`n备份原文件到: $backupFile"
        if (Test-Path $backupFile) {
            Remove-Item $backupFile -Force
        }
        Move-Item $zhCnFile $backupFile -Force
    }
    
    # 写入新文件
    Write-Host "写入新文件: $zhCnFile"
    $json | ConvertTo-Json -Depth 10 | Out-File $zhCnFile -Encoding UTF8
    
    Write-Host "`n✅ 修复成功！"
    $fileInfo = Get-Item $zhCnFile
    Write-Host "新文件大小: $($fileInfo.Length) 字节"
    
    # 验证新文件
    Write-Host "`n验证新文件..."
    $verifyJson = Get-Content $zhCnFile -Raw -Encoding UTF8 | ConvertFrom-Json
    Write-Host "验证通过！总共 $($verifyJson.string.Count) 个字符串"
    
} catch {
    Write-Host "`n❌ 错误: $_"
    Write-Host $_.ScriptStackTrace
    exit 1
}
