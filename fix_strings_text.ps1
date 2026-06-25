# 直接文本替换脚本
$filePath = "E:\APP\family_food_app\entry\src\main\resources\zh_CN\element\string.json"

# 读取文件内容
$content = Get-Content $filePath -Raw -Encoding UTF8

# 定义替换规则（基于字段名和行号）
$replacements = @(
    @{
        Name = "disclaimer"
        OldPattern = '"name": "disclaimer",\s+"value": "[^"]*"'
        NewValue = '"name": "disclaimer",
      "value": "基于标签识别生成，不替代专业建议"'
    },
    @{
        Name = "privacy_terms_desc"
        OldPattern = '"name": "privacy_terms_desc",\s+"value": "[^"]*"'
        NewValue = '"name": "privacy_terms_desc",
      "value": "使用即表示同意服务条款。我们收集必要数据以提供个性化饮食建议。"'
    },
    @{
        Name = "setup_profile_hint"
        OldPattern = '"name": "setup_profile_hint",\s+"value": "[^"]*"'
        NewValue = '"name": "setup_profile_hint",
      "value": "为每位家庭成员设置健康目标，扫码即可看到个性化建议。"'
    },
    @{
        Name = "recipe_community_hint"
        OldPattern = '"name": "recipe_community_hint",\s+"value": "[^"]*"'
        NewValue = '"name": "recipe_community_hint",
      "value": "扫描后可创建食谱分享到社区，或看看别人怎么搭配"'
    },
    @{
        Name = "status_affect_hint"
        OldPattern = '"name": "status_affect_hint",\s+"value": "[^"]*"'
        NewValue = '"name": "status_affect_hint",
      "value": "这些状态会影响今天的适配报告和美食程度判断。"'
    }
)

# 执行替换
foreach ($replacement in $replacements) {
    if ($content -match $replacement.OldPattern) {
        Write-Host "Replacing $($replacement.Name)..."
        $content = $content -replace $replacement.OldPattern, $replacement.NewValue
    } else {
        Write-Host "Pattern not found for $($replacement.Name)"
    }
}

# 写回文件
Set-Content $filePath $content -Encoding UTF8
Write-Host "File updated successfully!"
