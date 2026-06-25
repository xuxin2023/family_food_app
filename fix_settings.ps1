$f = 'E:/APP/family_food_app/entry/src/main/ets/pages/SettingsPage.ets'
$c = [System.IO.File]::ReadAllText($f, [System.Text.Encoding]::UTF8)

$c = $c -replace "\`$r\('app\.string\.settings_check_update_failed'\)", "`$r('app.string.settings_update_failed_retry')"
$c = $c -replace "\`$r\('app\.string\.settings_export_failed'\)", "`$r('app.string.settings_export_failed_retry')"
$c = $c -replace "\`$r\('app\.string\.settings_backup_failed'\)", [char]34+'备份失败'+[char]34
$c = $c -replace "\`$r\('app\.string\.settings_restore_failed'\)", [char]34+'恢复失败'+[char]34
$c = $c -replace "\`$r\('app\.string\.settings_clear_data_confirm'\)", "`$r('app.string.settings_confirm_clear_title')"
$c = $c -replace "\`$r\('app\.string\.settings_clear_data_message'\)", "`$r('app.string.settings_confirm_clear_msg')"
$c = $c -replace "\`$r\('app\.string\.settings_confirm'\)", "`$r('app.string.settings_confirm_clear')"
$c = $c -replace "\`$r\('app\.string\.settings_clear_data_success'\)", "`$r('app.string.settings_data_cleared_restart')"
$c = $c -replace "\`$r\('app\.string\.settings_clear_data_failed'\)", "`$r('app.string.settings_clear_failed_retry')"
$c = $c -replace "\`$r\('app\.string\.settings_delete_account_success'\)", "`$r('app.string.settings_account_deleted')"
$c = $c -replace "\`$r\('app\.string\.settings_delete_account_failed'\)", "`$r('app.string.settings_delete_failed_retry')"
$c = $c -replace "\`$r\('app\.string\.settings_data_section'\)", "`$r('app.string.settings_data_management')"
$c = $c -replace "\`$r\('app\.string\.settings_backup_data'\)", "`$r('app.string.settings_export_data')"
$c = $c -replace "\`$r\('app\.string\.settings_backup_data_desc'\)", "`$r('app.string.settings_export_data_desc')"
$c = $c -replace "\`$r\('app\.string\.settings_restore_data'\)", "`$r('app.string.settings_import_data')"
$c = $c -replace "\`$r\('app\.string\.settings_restore_data_desc'\)", "`$r('app.string.settings_import_data_desc')"
$c = $c -replace "\`$r\('app\.string\.settings_delete_account_confirm_message'\)", "`$r('app.string.settings_delete_confirm_message')"
$c = $c -replace "\`$r\('app\.string\.settings_data_collection'\)", "`$r('app.string.settings_collection_list')"
$c = $c -replace "\`$r\('app\.string\.settings_save_today_status'\)", [char]34+'保存今日状态'+[char]34
$c = $c -replace "\`$r\('app\.string\.settings_save_today_status_accessibility'\)", [char]34+'保存今日健康状态'+[char]34

[System.IO.File]::WriteAllText($f, $c, [System.Text.Encoding]::UTF8)
Write-Host "DONE"