@echo off
cd /d E:\APP\family_food_app
echo [1] git rm --cached build-profile.json5
git rm --cached build-profile.json5
echo.
echo [2] git status --short
git status --short
echo.
echo === DONE ===
