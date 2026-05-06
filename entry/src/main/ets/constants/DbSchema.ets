// DbSchema.ets
// RDB 数据库表名、字段名常量定义
// 所有 Repository 统一引用此文件，消除 SQL 字段名字符串散落在代码中的问题
// 修改表结构时，只需修改此文件一处即可

// ===== 食品标签表 (food_label) =====
export const TABLE_FOOD_LABEL = 'food_label';
export const COL_FOOD_ID = 'food_id';
export const COL_FOOD_NAME = 'food_name';
export const COL_BARCODE = 'barcode';
export const COL_INGREDIENTS = 'ingredients';
export const COL_NUTRITION = 'nutrition';
export const COL_ALLERGEN_HINTS = 'allergen_hints';
export const COL_MANUFACTURER = 'manufacturer';
export const COL_SC_NUMBER = 'sc_number';
export const COL_PRINCIPAL = 'principal';
export const COL_TRUSTEE = 'trustee';
export const COL_TRACE_CODE = 'trace_code';
export const COL_SOURCE = 'source';
export const COL_IDENTIFIED_AT = 'identified_at';

// ===== 家庭成员表 (family_profile) =====
export const TABLE_FAMILY_PROFILE = 'family_profile';
export const COL_MEMBER_ID = 'member_id';
export const COL_NICKNAME = 'nickname';
export const COL_AGE_GROUP = 'age_group';
export const COL_HEALTH_GOALS = 'health_goals';
export const COL_ALLERGENS = 'allergens';
export const COL_SODIUM_BUDGET = 'sodium_budget';
export const COL_SUGAR_BUDGET = 'sugar_budget';
export const COL_CALORIE_BUDGET = 'calorie_budget';
export const COL_FAT_BUDGET = 'fat_budget';
export const COL_MEAL_TIMES = 'meal_times';
export const COL_BEDTIME = 'bedtime';

// ===== 扫描历史表 (scan_history) =====
export const TABLE_SCAN_HISTORY = 'scan_history';
export const COL_ID = 'id';
export const COL_LEVEL = 'level';
export const COL_MAX_AMOUNT = 'max_amount';
export const COL_REASONS = 'reasons';
export const COL_SCANNED_AT = 'scanned_at';

// ===== 饮食记录表 (diet_record) =====
export const TABLE_DIET_RECORD = 'diet_record';
export const COL_DATE = 'date';
export const COL_SCENARIO = 'scenario';
export const COL_MEAL_TYPE = 'meal_type';
export const COL_AMOUNT_G = 'amount_g';
export const COL_SODIUM_INTAKE = 'sodium_intake';
export const COL_SUGAR_INTAKE = 'sugar_intake';
export const COL_CALORIE_INTAKE = 'calorie_intake';
export const COL_FAT_INTAKE = 'fat_intake';
export const COL_RECORDED_AT = 'recorded_at';

// ===== 食谱相关表 =====
export const TABLE_RECIPE = 'recipe';
export const TABLE_RECIPE_COMMENT = 'recipe_comment';
export const TABLE_RECIPE_LIKE = 'recipe_like';
export const TABLE_RECIPE_BOOKMARK = 'recipe_bookmark';
export const COL_RECIPE_ID = 'recipe_id';
export const COL_TITLE = 'title';
export const COL_DESCRIPTION = 'description';
export const COL_COVER_IMAGE_URL = 'cover_image_url';
export const COL_AUTHOR_UID = 'author_uid';
export const COL_AUTHOR_NAME = 'author_name';
export const COL_AUTHOR_AVATAR = 'author_avatar';
export const COL_CATEGORY = 'category';
export const COL_DIFFICULTY = 'difficulty';
export const COL_TOTAL_MINUTES = 'total_minutes';
export const COL_SERVINGS = 'servings';
export const COL_STEPS = 'steps';
export const COL_DIET_TAGS = 'diet_tags';
export const COL_RELATED_FOOD_ID = 'related_food_id';
export const COL_FROM_GROUP_ID = 'from_group_id';
export const COL_CREATED_AT = 'created_at';
export const COL_UPDATED_AT = 'updated_at';
export const COL_LIKE_COUNT = 'like_count';
export const COL_COMMENT_COUNT = 'comment_count';
export const COL_BOOKMARK_COUNT = 'bookmark_count';
export const COL_IS_APPROVED = 'is_approved';
export const COL_IS_DRAFT = 'is_draft';
export const COL_COMMENT_ID = 'comment_id';
export const COL_CONTENT = 'content';
export const COL_PARENT_ID = 'parent_id';
export const COL_IS_EDITED = 'is_edited';
export const COL_UID = 'uid';
export const COL_NOTE = 'note';

// ===== 家庭群组相关表 =====
export const TABLE_FAMILY_GROUP = 'family_group';
export const TABLE_GROUP_MEMBER = 'group_member';
export const TABLE_JOIN_REQUEST = 'join_request';
export const TABLE_GROUP_FEED = 'group_feed';
export const COL_GROUP_ID = 'group_id';
export const COL_GROUP_NAME = 'group_name';
export const COL_GROUP_AVATAR = 'group_avatar';
export const COL_OWNER_UID = 'owner_uid';
export const COL_OWNER_NAME = 'owner_name';
export const COL_INVITE_CODE = 'invite_code';
export const COL_MAX_MEMBERS = 'max_members';
export const COL_MEMBER_COUNT = 'member_count';
export const COL_IS_ARCHIVED = 'is_archived';
export const COL_DISPLAY_NAME = 'display_name';
export const COL_ROLE = 'role';
export const COL_JOIN_METHOD = 'join_method';
export const COL_JOINED_AT = 'joined_at';
export const COL_LAST_ACTIVE_AT = 'last_active_at';
export const COL_IS_LEFT = 'is_left';
export const COL_LOCAL_MEMBER_ID = 'local_member_id';
export const COL_REQUEST_ID = 'request_id';
export const COL_REQUESTER_UID = 'requester_uid';
export const COL_REQUESTER_NAME = 'requester_name';
export const COL_MESSAGE = 'message';
export const COL_STATUS = 'status';
export const COL_REQUESTED_AT = 'requested_at';
export const COL_REVIEWED_AT = 'reviewed_at';
export const COL_REVIEWER_UID = 'reviewer_uid';
export const COL_FEED_ID = 'feed_id';
export const COL_FEED_TYPE = 'feed_type';
export const COL_SENDER_UID = 'sender_uid';
export const COL_SENDER_NAME = 'sender_name';

// ===== 跨表通用字段 =====
// member_id 已在 COL_MEMBER_ID 中定义
// food_id 已在 COL_FOOD_ID 中定义
// created_at 已在 COL_CREATED_AT 中定义
// updated_at 已在 COL_UPDATED_AT 中定义
