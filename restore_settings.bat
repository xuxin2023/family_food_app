@echo off
cd /d "E:\APP\family_food_app"
git checkout HEAD -- entry/src/main/ets/pages/SettingsPage.ets 2>&1
echo Exit code: %ERRORLEVEL%
