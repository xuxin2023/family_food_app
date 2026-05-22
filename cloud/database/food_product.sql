-- 家庭食品适配助手 — GaussDB 云数据库 DDL
-- 部署于华为云 GaussDB(for MySQL)

-- 1. 食品商品主表
CREATE TABLE IF NOT EXISTS food_products (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    barcode VARCHAR(64) NOT NULL COMMENT '商品条码 (EAN-13/UPC-A)',
    product_name VARCHAR(512) NOT NULL DEFAULT '' COMMENT '商品名称(英文)',
    product_name_zh VARCHAR(512) NOT NULL DEFAULT '' COMMENT '商品名称(中文)',
    brands VARCHAR(256) NOT NULL DEFAULT '' COMMENT '品牌',
    manufacturers VARCHAR(512) NOT NULL DEFAULT '' COMMENT '生产商',
    ingredients_text TEXT COMMENT '配料表原文',
    ingredients_text_zh TEXT COMMENT '配料表中文',
    allergens_text TEXT COMMENT '过敏原',
    nutrition_grades VARCHAR(8) NOT NULL DEFAULT '' COMMENT '营养等级 a/b/c/d/e',
    nova_group INT DEFAULT 0 COMMENT 'NOVA加工等级(1-4)',
    ecoscore_grade VARCHAR(8) DEFAULT '' COMMENT '生态评分等级',
    ecoscore_score INT DEFAULT 0 COMMENT '生态评分值(0-100)',
    additives_tags TEXT COMMENT '添加剂标签 JSON数组',
    categories VARCHAR(512) DEFAULT '' COMMENT '分类标签',
    labels VARCHAR(512) DEFAULT '' COMMENT '标签(有机/素食等)',
    origins VARCHAR(256) DEFAULT '' COMMENT '原产国',
    packaging VARCHAR(256) DEFAULT '' COMMENT '包装类型',
    image_url VARCHAR(1024) DEFAULT '' COMMENT '商品图片URL',
    image_small_url VARCHAR(1024) DEFAULT '' COMMENT '缩略图URL',
    quantity VARCHAR(128) DEFAULT '' COMMENT '净含量',
    serving_size VARCHAR(128) DEFAULT '' COMMENT '建议份量',
    -- 营养信息 (每100g)
    energy_100g DECIMAL(10,2) DEFAULT 0 COMMENT '能量(kJ)',
    fat_100g DECIMAL(10,2) DEFAULT 0 COMMENT '脂肪(g)',
    saturated_fat_100g DECIMAL(10,2) DEFAULT 0 COMMENT '饱和脂肪(g)',
    carbohydrates_100g DECIMAL(10,2) DEFAULT 0 COMMENT '碳水化合物(g)',
    sugars_100g DECIMAL(10,2) DEFAULT 0 COMMENT '糖(g)',
    fiber_100g DECIMAL(10,2) DEFAULT 0 COMMENT '纤维素(g)',
    proteins_100g DECIMAL(10,2) DEFAULT 0 COMMENT '蛋白质(g)',
    salt_100g DECIMAL(10,2) DEFAULT 0 COMMENT '盐(g)',
    sodium_100g DECIMAL(10,2) DEFAULT 0 COMMENT '钠(g)',
    -- 元数据
    source VARCHAR(32) NOT NULL DEFAULT 'OFF' COMMENT '数据来源: OFF=OpenFoodFacts, USER=用户贡献, ADMIN=管理员',
    verify_status TINYINT NOT NULL DEFAULT 0 COMMENT '0=待审核 1=已通过 2=已拒绝',
    search_count INT DEFAULT 0 COMMENT '搜索热度',
    contributor_uid VARCHAR(64) DEFAULT '' COMMENT '贡献者UID',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY idx_barcode (barcode),
    INDEX idx_product_name (product_name(255)),
    INDEX idx_brands (brands),
    INDEX idx_nutrition_grades (nutrition_grades),
    INDEX idx_categories (categories(255)),
    INDEX idx_source (source),
    INDEX idx_search_count (search_count DESC),
    deleted_at TIMESTAMP NULL DEFAULT NULL COMMENT '软删除时间戳'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='食品商品信息主表';

-- 2. 用户扫描历史表
CREATE TABLE IF NOT EXISTS scan_history (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    uid VARCHAR(64) NOT NULL COMMENT '用户UID',
    member_id VARCHAR(64) NOT NULL DEFAULT '' COMMENT '家庭成员ID',
    barcode VARCHAR(64) NOT NULL COMMENT '扫描条码',
    product_id BIGINT DEFAULT NULL COMMENT '关联商品ID',
    scan_type VARCHAR(16) NOT NULL DEFAULT 'BARCODE' COMMENT '扫描类型: BARCODE/OCR/PHOTO/MANUAL',
    scan_source VARCHAR(32) NOT NULL DEFAULT 'mobile' COMMENT '扫描来源: mobile/tablet/2in1',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_uid (uid),
    INDEX idx_member_id (member_id),
    INDEX idx_barcode (barcode),
    INDEX idx_created_at (created_at DESC),
    CONSTRAINT fk_scan_product FOREIGN KEY (product_id) REFERENCES food_products(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='用户扫描历史记录';

-- 3. 用户贡献商品表
CREATE TABLE IF NOT EXISTS food_contributions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    uid VARCHAR(64) NOT NULL COMMENT '贡献者UID',
    barcode VARCHAR(64) NOT NULL COMMENT '商品条码',
    product_name VARCHAR(512) NOT NULL DEFAULT '',
    ingredients_text TEXT COMMENT '用户录入配料表',
    front_photo_url VARCHAR(1024) DEFAULT '' COMMENT '包装正面照OSS URL',
    nutrition_photo_url VARCHAR(1024) DEFAULT '' COMMENT '营养成分表照OSS URL',
    ingredients_photo_url VARCHAR(1024) DEFAULT '' COMMENT '配料表照OSS URL',
    status TINYINT NOT NULL DEFAULT 0 COMMENT '0=待审核 1=已录入 2=已拒绝',
    reviewer_uid VARCHAR(64) DEFAULT '' COMMENT '审核者UID',
    review_comment VARCHAR(512) DEFAULT '' COMMENT '审核意见',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_uid (uid),
    INDEX idx_barcode (barcode),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='用户贡献商品审核表';

-- 4. 用户健康画像表（云端同步）
CREATE TABLE IF NOT EXISTS user_health_profile (
    uid VARCHAR(64) NOT NULL COMMENT '用户UID',
    member_id VARCHAR(64) NOT NULL COMMENT '家庭成员ID',
    nickname VARCHAR(64) NOT NULL DEFAULT '' COMMENT '昵称',
    age_group VARCHAR(16) NOT NULL DEFAULT 'adult' COMMENT '年龄段',
    health_goals JSON COMMENT '健康目标 JSON数组',
    allergens JSON COMMENT '过敏原 JSON数组',
    chronic_conditions JSON COMMENT '慢性病 JSON数组',
    last_sync_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (uid, member_id),
    INDEX idx_uid (uid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='用户健康画像(云端)';
