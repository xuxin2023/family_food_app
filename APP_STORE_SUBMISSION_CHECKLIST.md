# 华为应用商店提审合规检查清单

> 项目: family_food_app (com.familyfood.helper)  
> 目标: HarmonyOS 6.1 AppGallery  
> 版本: v5.0.0

## 1. 隐私与合规 ✅

- [x] **隐私政策 HTTPS 链接** — `PrivacyDialogPage.ets` 首次启动弹窗，含可点击 HTTPS 链接
- [x] **用户协议确认** — 首次启动要求用户同意隐私政策 + 用户协议
- [x] **数据删除功能** — SettingsPage 提供"清除本地数据"入口
- [x] **数据导出功能** — SettingsPage 提供 `exportData()` 按钮
- [x] **用户数据删除云函数** — `user-data-deletion` 华为云云函数已就绪
- [x] **权限最小化** — 摄像头/相册/麦克风权限按需申请，拒绝后提供降级方案
- [x] **敏感数据加密** — AES-256-GCM 加密过敏原/健康档案，RDB S3安全级别

## 2. 青少年保护 ✅

- [x] **青少年模式** — `TeenModeManager.ets`：60分钟/天限制 + 22:00-06:00锁定
- [x] **内容过滤** — 青少年模式下过滤酒精/成人内容
- [x] **购买限制** — 青少年模式下禁止内购
- [x] **夜间锁定** — 22:00-06:00自动锁定，不可跳过

## 3. 支付合规 ✅

- [x] **仅华为支付** — `IapService.ets` 只用 `@kit.IAPKit`
- [x] **零第三方支付** — 无支付宝/微信跳转
- [x] **服务端收据验证** — `IapServerValidator.ets`
- [x] **订阅恢复** — `restorePurchases()` 恢复用户订阅

## 4. 内容合规 ✅

- [x] **无法违规内容** — 无涉政/涉黄/涉暴
- [x] **食品推荐有科学依据** — NutriScore/NovaGroup/EcoScore 三大评级体系
- [x] **数据来源标注** — 本地扫描/OpenFoodFacts/用户贡献标注清晰
- [x] **AI 免责声明** — AI 营养建议标注"仅供参考，请咨询专业医生"

## 5. 技术合规 ✅

- [x] **API 23 兼容** — 全部使用 `@kit.*` 导入，零 `@ohos.*` 废弃API
- [x] **TYPE CHECK SUCCESSFUL** — hvigor 全部12模块编译通过
- [x] **防抓包** — `SecureHttpClient` SSL Pinning + `AntiCaptureDetector` 代理检测
- [x] **无障碍** — `AccessibilityManager` + `AccessibilityUtil` + `AccessibilityCompliance` 全覆盖
- [x] **暗黑模式** — ThemeColors 主题系统，300ms内切换无闪烁
- [x] **分布式适配** — `DeviceAdapter` PHONE/TABLET/2IN1 + SM/MD/LG breakpoint

## 6. 应用信息 ✅

- [x] 应用名称: 家庭食品适配助手
- [x] 包名: com.familyfood.helper
- [x] 版本号: 5.0.0
- [x] SDK版本: HarmonyOS 6.1.0 (API 23)
- [x] 设备类型: phone, tablet, 2in1
- [x] 模块数: 12 (1 entry + 7 hsp + 4 feature)

## 7. 构建制品 ✅

- [ ] Release HAP 构建
- [ ] 代码混淆 + 符号裁剪
- [ ] HAP ≤ 100MB
- [ ] 应用截图 (至少3张)
- [ ] 应用描述文本

## 提审操作步骤

1. DevEco Studio → Build → Build HAP(s)/APP(s) → Build APP(s)
2. 登录 AppGallery Connect → 我的应用 → 新建应用
3. 上传 HAP 包 + 截图 + 隐私政策链接
4. 填写应用描述 + 功能说明 + 权限说明
5. 提交审核