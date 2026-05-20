# 华为云 FunctionGraph + API Gateway 部署指南

## 目录结构
```
cloud/
├── DEPLOY_GUIDE.md              # 本文件
├── database/
│   └── food_product.sql         # GaussDB 数据库 DDL
└── functions/
    └── searchByBarcode/
        └── index.ts             # 条码搜索云函数
```

## 1. 前置条件

- 华为云账号（已实名认证）
- 开通以下服务：
  - **FunctionGraph** — 函数工作流
  - **API Gateway (APIG)** — API网关
  - **GaussDB(for MySQL)** — 云数据库

## 2. GaussDB 数据库部署

### 2.1 创建实例
```bash
# 在华为云控制台操作：
#   1. 进入 GaussDB(for MySQL) → 购买数据库实例
#   2. 规格建议: 2 vCPU / 8 GB（开发阶段）
#   3. 设置 root 密码
```

### 2.2 创建数据库
```sql
CREATE DATABASE family_food CHARACTER SET utf8mb4;
```

### 2.3 执行建表脚本
```bash
mysql -h <GAUSSDB_ENDPOINT> -u <USER> -p family_food < cloud/database/food_product.sql
```

## 3. FunctionGraph 部署

### 3.1 打包函数
```bash
cd cloud/functions/searchByBarcode
npm init -y
npm install mysql2

# 打包为 zip
zip -r function.zip index.ts package.json node_modules/
```

### 3.2 创建函数
在华为云控制台：
1. FunctionGraph → 创建函数
2. 运行时: Node.js 18
3. 上传 function.zip
4. 设置环境变量:
   - `GAUSSDB_ENDPOINT` = `<数据库连接地址>`
   - `GAUSSDB_USER` = `<数据库用户名>`
   - `GAUSSDB_PASSWORD` = `<数据库密码>`
   - `GAUSSDB_DB_NAME` = `family_food`
5. 入口函数: `index.handler`

## 4. API Gateway 配置

### 4.1 创建 API
1. API Gateway → 创建 API 分组
2. 分组名: `family-food-api`
3. 创建 API:
   - 路径: `/v1/searchByBarcode`
   - 方法: `POST`
   - 后端: FunctionGraph → 选择 `searchByBarcode`

### 4.2 发布
1. 将 API 发布到 `RELEASE` 环境
2. 获取 API 访问地址，格式: `https://{apig-id}.apig.cn-north-4.huaweicloudapis.com/v1`

### 4.3 更新客户端
在 `entry/src/main/ets/service/CloudBackendService.ets` 替换:
```typescript
// 替换为实际地址
const API_BASE_URL = 'https://{apig-id}.apig.cn-north-4.huaweicloudapis.com/v1'
```

## 5. 测试

```bash
# 测试云函数
curl -X POST 'https://{apig-id}.apig.cn-north-4.huaweicloudapis.com/v1/searchByBarcode' \
  -H 'Content-Type: application/json' \
  -d '{"barcode": "6901234567890"}'
```

## 6. 成本估算（月度）

| 服务 | 规格 | 月费(CNY) |
|------|------|-----------|
| GaussDB | 2 vCPU / 8 GB | ~400 |
| FunctionGraph | 按调用量 | ~0 (免费额度内) |
| API Gateway | 按调用量 | ~0 (免费额度内) |
| **合计** | | **~400** |
