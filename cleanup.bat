@echo off
cd /d E:\APP\family_food_app
git rm --cached SharePage_backup.ets SharePage_fixed.py.tmp DashboardPage_head.txt devdb_head.txt
git rm --cached "entry/src/main/ets/pages/DietDiaryPage.ets~" "entry/src/main/ets/pages/FamilyGroupPage.ets~" "entry/src/main/ets/pages/GroupFeedPage.ets~" "entry/src/main/ets/pages/RecipeCommunityPage.ets~" "entry/src/main/ets/pages/RecipeDetailPage.ets~"
echo.
echo ---- Done ----
echo Now run:
echo   git commit -m "chore: clean up backup and tmp files"
echo   git push
pause
