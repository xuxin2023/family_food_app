@echo off
chcp 65001 >nul
echo 正在修复string.json文件...

set SOURCE=E:\APP\family_food_app\entry\src\main\resources\base\element\string.json
set DEST=E:\APP\family_food_app\entry\src\main\resources\zh_CN\element\string.json
set BACKUP=E:\APP\family_food_app\entry\src\main\resources\zh_CN\element\string.json.backup

REM 备份原文件
if exist "%DEST%" (
    echo 备份原文件...
    if exist "%BACKUP%" del "%BACKUP%"
    ren "%DEST%" string.json.backup
)

REM 复制base文件
echo 复制base文件...
copy "%SOURCE%" "%DEST%" >nul

echo 修复完成！
echo.
echo 请手动修改以下字符串：
echo 1. disclaimer: "基于标签识别生成，不替代专业建议"
echo 2. privacy_terms_desc: "使用即表示同意服务条款。我们收集必要数据以提供个性化饮食建议。"
echo 3. setup_profile_hint: "为每位家庭成员设置健康目标，扫码即可看到个性化建议。"
echo 4. recipe_community_hint: "扫描后可创建食谱分享到社区，或看看别人怎么搭配"
echo 5. status_affect_hint: "这些状态会影响今天的适配报告和美食程度判断。"
echo.
pause
