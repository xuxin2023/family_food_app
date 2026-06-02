@echo off
echo SettingsPage.ets size:
for %%A in ("entry\src\main\ets\pages\SettingsPage.ets") do echo %%~zA
echo Git backup size:
for %%A in ("SettingsPage_git_backup.txt") do echo %%~zA
echo Total lines in SettingsPage.ets:
find /c /v "" "entry\src\main\ets\pages\SettingsPage.ets"
