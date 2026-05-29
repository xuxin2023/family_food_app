# 安全审计报告

**项目**: 家庭食品适配助手 (Family Food Advisor)
**审计日期**: 2026-05-29
**审计版本**: v2.0.0
**审计结论**: 合格（附缓解措施）

---

## 1. 数据加密

| 项目 | 实现 | 风险等级 |
|------|------|----------|
| 对称加密算法 | AES-256-GCM | ✅ 低 |
| 密钥管理 | HUKS (Universal Keystore Kit) | ✅ 低 |
| 密钥存储位置 | TEE 安全区域 | ✅ 低 |
| 密钥轮换 | 应用升级时自动轮换 | ✅ 低 |
| 数据库加密 | RDB encrypt=true, SecurityLevel=S3 | ✅ 低 |
| Preferences 加密 | 安全级别 S2 | ✅ 低 |

**说明**: 所有敏感数据（过敏原档案、健康信号、BMI数据）均使用 AES-256-GCM 加密，密钥由 HUKS 生成并存储在 TEE 中，应用层无法直接获取明文密钥。

## 2. 网络安全

| 项目 | 实现 | 风险等级 |
|------|------|----------|
| 证书钉定 (Certificate Pinning) | ✅ 已实现 | ✅ 低 |
| TOFU 信任首次使用 | ✅ 已实现 | ✅ 低 |
| 明文传输禁用 | cleartextTrafficPermitted=false | ✅ 低 |
| HTTPS 强制 | 全部 API 走 HTTPS | ✅ 低 |
| 请求签名 | HMAC-SHA256 签名 + 时间戳防重放 | ✅ 低 |
| User-Agent 混淆 | 不暴露框架版本信息 | ✅ 低 |

**说明**: 对 OpenFoodFacts、AgentArts AI 等外部 API 全部启用证书钉定。首次连接记录证书指纹，后续变更时告警用户（TOFU）。network_config.json 禁用明文传输。

## 3. 权限最小化

| 权限 | 状态 | 用途 |
|------|------|------|
| ohos.permission.INTERNET | ✅ 保留 | API 网络访问 |
| ohos.permission.GET_NETWORK_INFO | ✅ 保留 | 离线模式判断 |
| ohos.permission.CAMERA | ✅ 保留 | 扫码功能 |
| ohos.permission.VIBRATE | ✅ 保留 | 扫码成功反馈 |
| ohos.permission.KEEP_BACKGROUND_RUNNING | ✅ 保留 | 扫码 Service |
| ohos.permission.READ_PASTEBOARD | ✅ 保留 | 链接导入 |
| ohos.permission.WRITE_PASTEBOARD | ✅ 保留 | 分享功能 |
| ohos.permission.APPROXIMATELY_LOCATION | ✅ 保留 | 附近商店（可选） |
| **ohos.permission.MICROPHONE** | **✅ 已移除** | 原语音输入，已改用文字输入 |

**结论**: 已移除 MICROPHONE 权限，当前权限集均为必要权限，无不合理过度申请。

## 4. 敏感数据存储

| 数据类型 | 存储方式 | 加密 |
|----------|----------|------|
| API Token/密钥 | Asset Store Kit (ASSET_TAG_SECRET) | ✅ |
| 用户过敏原档案 | RDB (encrypt=true, S3) | ✅ |
| 健康信号数据 | RDB (encrypt=true, S3) | ✅ |
| 用户偏好设置 | Preferences (安全级别 S2) | ✅ |
| 离线操作队列 | Preferences (安全级别 S2) | ✅ |
| 备份文件 | AES-256-GCM 加密后写入 .enc | ✅ |

**说明**: 不使用明文 SharedPreferences。Token 类凭证使用 Asset Store Kit 存储，系统级加密保护。

## 5. 数据完整性

| 项目 | 实现 |
|------|------|
| HMAC 校验 | 备份文件写入时生成 HMAC-SHA256，恢复时验证 |
| Schema 版本号检查 | 导入时比对 DB_SCHEMA_VERSION，不兼容则拒绝 |
| 请求签名校验 | API 响应包含签名，客户端验证 |
| 数据库迁移校验 | 升级迁移后完整性检查 |

## 6. 隐私合规

| 项目 | 实现 | 状态 |
|------|------|------|
| 首次启动隐私弹窗 | PrivacyConsentDialog + PrivacyDialogPage | ✅ |
| 隐私政策可访问 | 设置页 + 弹窗内链接 | ✅ |
| 数据导出功能 | DataBackupService.exportBackup() | ✅ |
| 数据删除功能 | 设置页"删除所有数据" | ✅ |
| 账号注销 | 华为账号注销流程 | ✅ |
| 权限运行时申请 | 动态申请 + 拒绝后降级 | ✅ |
| 青少年模式 | TeenModePage + 时间/内容限制 | ✅ |
| 防窥保护 | AntiPeepShield (Device Security Kit) | ✅ |

## 7. 防抓包/中间人攻击

| 防护措施 | 实现 | 说明 |
|----------|------|------|
| 证书钉定 | ✅ | 固定 API 证书指纹，防止中间人 |
| 请求签名 | ✅ | HMAC-SHA256 + 时间戳，防篡改重放 |
| TOFU | ✅ | 首次记录证书指纹，变更告警 |
| 代理检测 | ☐ 建议增强 | 检测系统代理设置，提醒用户 |

## 8. 已知风险与缓解措施

| 风险 | 等级 | 缓解措施 |
|------|------|----------|
| Root 设备 HUKS 降级 | 中 | 检测设备安全状态，敏感操作告警 |
| 离线数据同步冲突 | 低 | SyncConflictResolver + last-write-wins |
| AI 响应内容安全 | 低 | OnDeviceAiEngine 过滤 + 输出审查 |
| 旧版本备份数据恢复 | 低 | Schema 版本检查 + 不兼容拒绝 |
| 扫码结果被篡改 | 低 | 扫码结果不做本地持久化，每次实时查询 |
| 第三方库漏洞 | 低 | 定期更新依赖 + DevEco 安全扫描 |
| 系统代理抓包 | 中 | 建议增加代理检测逻辑 |

---

**审计人**: CodeArts 自动化审计
**下次审计**: 版本升级时触发
