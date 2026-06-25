$f = 'E:/APP/family_food_app/entry/src/main/ets/pages/SettingsPage.ets'
$c = [System.IO.File]::ReadAllText($f, [System.Text.Encoding]::UTF8)

$reps = @{
    "settings_backup_failed" = "'备份失败'"
    "settings_restore_failed" = "'恢复失败'"
    "settings_clear_data_confirm" = "'settings_confirm_clear_title'"
    "settings_clear_data_message" = "'settings_confirm_clear_msg'"
    "settings_confirm" = "'settings_confirm_clear'"
    "settings_clear_data_success" = "'settings_data_cleared_restart'"
    "settings_clear_data_failed" = "'settings_clear_failed_retry'"
    "settings_delete_account_success" = "'settings_account_deleted'"
    "settings_delete_account_failed" = "'settings_delete_failed_retry'"
    "settings_data_section" = "'settings_data_management'"
    "settings_backup_data" = "'settings_export_data'"
    "settings_backup_data_desc" = "'settings_export_data_desc'"
    "settings_restore_data" = "'settings_import_data'"
    "settings_restore_data_desc" = "'settings_import_data_desc'"
    "settings_delete_account_confirm_message" = "'settings_delete_confirm_message'"
    "settings_data_collection" = "'settings_collection_list'"
    "settings_save_today_status_accessibility" = "'保存今日健康状态'"
}

foreach ($old in $reps.Keys) {
    $newVal = $reps[$old]
    if ($newVal.StartsWith("'")) {
        $c = $c -replace "\$r\(`"app\.string\.$old`"\)", $newVal.Substring(1, $newVal.Length - 2)
    } else {
        $c = $c -replace "\$r\(`"app\.string\.$old`"\)", "`$r(`"app.string.$newVal`")"
    }
}

[System.IO.File]::WriteAllText($f, $c, [System.Text.Encoding]::UTF8)
Write-Host "DONE"