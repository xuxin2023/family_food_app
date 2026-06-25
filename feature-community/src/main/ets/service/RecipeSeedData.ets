// RecipeSeedData.ets
// 食谱社区种子数据 — 首次安装时填充示例食谱，避免空白页面

import {
  Recipe, RecipeIngredient, RecipeStep, RecipeNutrition,
  RecipeDifficulty, RecipeCategory, DietTag
} from 'hsp_core';

const SEED_BASE_TIME: number = 1700000000000;

function makeIngredient(name: string, amount: string, alternative: string): RecipeIngredient {
  const ing: RecipeIngredient = new RecipeIngredient();
  ing.name = name;
  ing.amount = amount;
  ing.alternative = alternative;
  return ing;
}

function makeStep(stepNumber: number, description: string, durationMinutes: number): RecipeStep {
  const step: RecipeStep = new RecipeStep();
  step.stepNumber = stepNumber;
  step.description = description;
  step.imageUrl = '';
  step.durationMinutes = durationMinutes;
  return step;
}

function makeNutrition(calories: number, protein: string, fat: string, carbohydrate: string,
  sodium: string, sugar: string, fiber: string): RecipeNutrition {
  const n: RecipeNutrition = {
    calories: calories,
    protein: protein,
    fat: fat,
    carbohydrate: carbohydrate,
    sodium: sodium,
    sugar: sugar,
    fiber: fiber
  };
  return n;
}

function buildRecipe(recipeId: string, title: string, description: string,
  category: RecipeCategory, difficulty: RecipeDifficulty, totalMinutes: number, servings: number,
  authorName: string, likeCount: number, commentCount: number, bookmarkCount: number,
  ingredients: RecipeIngredient[], steps: RecipeStep[], nutrition: RecipeNutrition,
  dietTags: DietTag[], timeOffset: number): Recipe {
  const recipe: Recipe = new Recipe();
  recipe.recipeId = recipeId;
  recipe.title = title;
  recipe.description = description;
  recipe.coverImageUrl = '';
  recipe.authorUid = 'seed_author';
  recipe.authorName = authorName;
  recipe.authorAvatar = '';
  recipe.category = category;
  recipe.difficulty = difficulty;
  recipe.totalMinutes = totalMinutes;
  recipe.servings = servings;
  recipe.ingredients = ingredients;
  recipe.steps = steps;
  recipe.nutrition = nutrition;
  recipe.dietTags = dietTags;
  recipe.relatedFoodId = '';
  recipe.fromGroupId = '';
  recipe.createdAt = SEED_BASE_TIME + timeOffset;
  recipe.updatedAt = SEED_BASE_TIME + timeOffset;
  recipe.likeCount = likeCount;
  recipe.commentCount = commentCount;
  recipe.bookmarkCount = bookmarkCount;
  recipe.isApproved = true;
  recipe.isDraft = false;
  return recipe;
}

/**
 * 返回食谱社区种子数据（8 道示例食谱，覆盖早餐/午餐/晚餐/零食）
 */
export function getRecipeSeedData(): Recipe[] {
  const recipes: Recipe[] = [];

  // 1. 早餐 — 燕麦水果碗
  recipes.push(buildRecipe(
    'seed_recipe_001', '燕麦水果碗', '清爽高纤的快手早餐，燕麦搭配时令水果与酸奶，营养均衡又饱腹。',
    RecipeCategory.BREAKFAST, RecipeDifficulty.EASY, 10, 2,
    '营养小厨娘', 128, 6, 21,
    [
      makeIngredient('即食燕麦', '60克', '快熟燕麦'),
      makeIngredient('无糖酸奶', '150克', '牛奶'),
      makeIngredient('蓝莓', '40克', '草莓'),
      makeIngredient('香蕉', '1根', '芒果'),
      makeIngredient('蜂蜜', '1茶匙', '枫糖浆')
    ],
    [
      makeStep(1, '将燕麦倒入碗中，加入少量温水浸泡 3 分钟至软化。', 5),
      makeStep(2, '倒掉多余水分，加入酸奶搅拌均匀。', 2),
      makeStep(3, '将香蕉切片，与蓝莓一同铺在表面，淋上蜂蜜即可。', 3)
    ],
    makeNutrition(320, '12g', '6g', '48g', '80mg', '18g', '7g'),
    [DietTag.LOW_SODIUM, DietTag.HIGH_FIBER, DietTag.CHILD_FRIENDLY],
    0
  ));

  // 2. 早餐 — 蔬菜鸡蛋饼
  recipes.push(buildRecipe(
    'seed_recipe_002', '蔬菜鸡蛋饼', '金黄软嫩的鸡蛋饼，藏满胡萝卜与西葫芦，孩子也爱吃。',
    RecipeCategory.BREAKFAST, RecipeDifficulty.EASY, 15, 3,
    '妈妈的味道', 96, 4, 15,
    [
      makeIngredient('鸡蛋', '3个', '鸭蛋'),
      makeIngredient('胡萝卜', '半根', '南瓜'),
      makeIngredient('西葫芦', '半根', '黄瓜'),
      makeIngredient('面粉', '2汤匙', '玉米淀粉'),
      makeIngredient('盐', '少许', '低钠盐'),
      makeIngredient('食用油', '1汤匙', '橄榄油')
    ],
    [
      makeStep(1, '胡萝卜、西葫芦擦成细丝，撒少许盐腌制 2 分钟后挤去水分。', 4),
      makeStep(2, '鸡蛋打散，加入蔬菜丝与面粉，搅拌成均匀面糊。', 3),
      makeStep(3, '平底锅刷油，倒入面糊摊成圆饼，小火煎至两面金黄。', 8)
    ],
    makeNutrition(265, '16g', '14g', '20g', '420mg', '4g', '3g'),
    [DietTag.CHILD_FRIENDLY, DietTag.HIGH_PROTEIN],
    1
  ));

  // 3. 午餐 — 番茄牛腩饭
  recipes.push(buildRecipe(
    'seed_recipe_003', '番茄牛腩饭', '酸甜浓郁的番茄炖牛腩，汤汁拌饭一绝，全家都爱。',
    RecipeCategory.LUNCH, RecipeDifficulty.MEDIUM, 90, 4,
    '家常大厨', 213, 18, 47,
    [
      makeIngredient('牛腩', '500克', '牛腱'),
      makeIngredient('番茄', '4个', '番茄罐头'),
      makeIngredient('洋葱', '1个', '大葱'),
      makeIngredient('土豆', '2个', '胡萝卜'),
      makeIngredient('生姜', '3片', '姜粉'),
      makeIngredient('生抽', '2汤匙', '酱油'),
      makeIngredient('料酒', '1汤匙', '黄酒'),
      makeIngredient('米饭', '适量', '面条')
    ],
    [
      makeStep(1, '牛腩切块，冷水下锅焯水去血沫，捞出洗净备用。', 10),
      makeStep(2, '番茄顶部划十字，开水烫后去皮切块；洋葱、土豆切块。', 8),
      makeStep(3, '锅中热油爆香姜片洋葱，下番茄炒出红油，加入牛腩翻炒。', 8),
      makeStep(4, '加入生抽、料酒与足量热水，大火烧开转小火炖 60 分钟。', 60),
      makeStep(5, '加入土豆块继续炖 15 分钟至软烂，收汁后配米饭食用。', 15)
    ],
    makeNutrition(580, '34g', '22g', '52g', '680mg', '8g', '5g'),
    [DietTag.HIGH_PROTEIN, DietTag.ELDER_FRIENDLY],
    2
  ));

  // 4. 午餐 — 鸡胸肉牛油果沙拉
  recipes.push(buildRecipe(
    'seed_recipe_004', '鸡胸肉牛油果沙拉', '低脂高蛋白的轻食午餐，鲜嫩鸡胸搭配 creamy 牛油果，减脂期首选。',
    RecipeCategory.LUNCH, RecipeDifficulty.EASY, 20, 2,
    '健身达人', 87, 3, 31,
    [
      makeIngredient('鸡胸肉', '1块（约200克）', '火鸡胸'),
      makeIngredient('牛油果', '1个', '鸡蛋'),
      makeIngredient('混合生菜', '100克', '罗马生菜'),
      makeIngredient('小番茄', '8颗', '圣女果'),
      makeIngredient('柠檬汁', '1汤匙', '白醋'),
      makeIngredient('橄榄油', '1茶匙', '亚麻籽油'),
      makeIngredient('黑胡椒', '少许', '白胡椒')
    ],
    [
      makeStep(1, '鸡胸肉用盐、黑胡椒腌制 10 分钟，煎熟后切薄片。', 12),
      makeStep(2, '牛油果去核切块，小番茄对半切开，生菜洗净沥干。', 5),
      makeStep(3, '所有食材放入大碗，淋柠檬汁与橄榄油，撒黑胡椒拌匀。', 3)
    ],
    makeNutrition(410, '38g', '22g', '14g', '180mg', '3g', '8g'),
    [DietTag.LOW_FAT, DietTag.HIGH_PROTEIN, DietTag.LOW_SUGAR],
    3
  ));

  // 5. 晚餐 — 清蒸鲈鱼
  recipes.push(buildRecipe(
    'seed_recipe_005', '清蒸鲈鱼', '原汁原味的清蒸鲈鱼，鱼肉细嫩鲜美，少油健康的老少皆宜之选。',
    RecipeCategory.DINNER, RecipeDifficulty.MEDIUM, 25, 3,
    '粤式阿叔', 176, 9, 33,
    [
      makeIngredient('鲈鱼', '1条（约500克）', '鳜鱼'),
      makeIngredient('生姜', '1块', '姜粉'),
      makeIngredient('大葱', '1根', '小葱'),
      makeIngredient('蒸鱼豉油', '3汤匙', '生抽'),
      makeIngredient('食用油', '2汤匙', '香油'),
      makeIngredient('料酒', '1汤匙', '黄酒')
    ],
    [
      makeStep(1, '鲈鱼处理干净，鱼身两侧划刀，抹料酒与姜片去腥。', 5),
      makeStep(2, '盘底铺葱段姜片，放上鲈鱼，水开后大火蒸 8-10 分钟。', 10),
      makeStep(3, '倒掉蒸出的腥水，撒葱丝，淋蒸鱼豉油。', 3),
      makeStep(4, '另锅烧热油，浇在葱丝上激出香味即成。', 5)
    ],
    makeNutrition(230, '32g', '8g', '4g', '520mg', '1g', '0.5g'),
    [DietTag.LOW_FAT, DietTag.HIGH_PROTEIN, DietTag.LOW_SODIUM, DietTag.ELDER_FRIENDLY],
    4
  ));

  // 6. 晚餐 — 红烧排骨
  recipes.push(buildRecipe(
    'seed_recipe_006', '红烧排骨', '色泽红亮、肉质酥烂的经典红烧排骨，浓香下饭的家常硬菜。',
    RecipeCategory.DINNER, RecipeDifficulty.HARD, 70, 4,
    '外婆的厨房', 302, 24, 58,
    [
      makeIngredient('猪小排', '600克', '肋排'),
      makeIngredient('生姜', '4片', '姜粉'),
      makeIngredient('大葱', '1根', '小葱'),
      makeIngredient('八角', '2颗', '桂皮'),
      makeIngredient('冰糖', '20克', '白糖'),
      makeIngredient('生抽', '2汤匙', '酱油'),
      makeIngredient('老抽', '1汤匙', '酱油'),
      makeIngredient('料酒', '2汤匙', '黄酒')
    ],
    [
      makeStep(1, '排骨冷水下锅，加料酒姜片焯水，撇沫后捞出洗净。', 10),
      makeStep(2, '锅中少许油，下冰糖小火炒出焦糖色。', 5),
      makeStep(3, '下排骨翻炒上色，加入生抽、老抽、料酒、八角、葱姜。', 5),
      makeStep(4, '加入没过排骨的热水，大火烧开转小火炖 40 分钟。', 40),
      makeStep(5, '大火收汁至浓稠，汤汁包裹排骨即可出锅。', 10)
    ],
    makeNutrition(620, '28g', '38g', '28g', '820mg', '12g', '1g'),
    [DietTag.HIGH_PROTEIN],
    5
  ));

  // 7. 零食 — 香蕉松饼（无油无糖）
  recipes.push(buildRecipe(
    'seed_recipe_007', '香蕉松饼', '只用香蕉和鸡蛋的无添加松饼，软糯香甜，宝宝辅食也适合。',
    RecipeCategory.SNACK, RecipeDifficulty.EASY, 15, 2,
    '辅食妈妈', 154, 7, 19,
    [
      makeIngredient('熟透香蕉', '2根', '牛油果'),
      makeIngredient('鸡蛋', '2个', '鸭蛋'),
      makeIngredient('面粉', '3汤匙', '燕麦粉')
    ],
    [
      makeStep(1, '香蕉放入碗中用叉子压成泥。', 3),
      makeStep(2, '加入鸡蛋与面粉，搅拌成均匀面糊。', 3),
      makeStep(3, '不粘锅小火，舀入面糊煎至表面冒泡，翻面再煎 1 分钟。', 9)
    ],
    makeNutrition(180, '8g', '5g', '26g', '60mg', '14g', '3g'),
    [DietTag.LOW_SUGAR, DietTag.LOW_SODIUM, DietTag.CHILD_FRIENDLY, DietTag.ALLERGEN_FREE],
    6
  ));

  // 8. 零食 — 紫薯燕麦球
  recipes.push(buildRecipe(
    'seed_recipe_008', '紫薯燕麦球', '高纤饱腹的紫色小点心，紫薯天然甜糯，下午茶解馋零负担。',
    RecipeCategory.SNACK, RecipeDifficulty.EASY, 30, 4,
    '素食笔记', 119, 5, 16,
    [
      makeIngredient('紫薯', '2个（约300克）', '红薯'),
      makeIngredient('即食燕麦', '50克', '糯米粉'),
      makeIngredient('牛奶', '30毫升', '豆浆'),
      makeIngredient('蜂蜜', '1汤匙', '枫糖浆'),
      makeIngredient('椰蓉', '适量', '芝麻')
    ],
    [
      makeStep(1, '紫薯去皮切块，上锅蒸 15 分钟至软烂。', 15),
      makeStep(2, '取出压成泥，加入燕麦、牛奶、蜂蜜拌匀。', 5),
      makeStep(3, '搓成小球，裹上椰蓉，冷藏 10 分钟定型即可。', 10)
    ],
    makeNutrition(140, '3g', '2g', '28g', '50mg', '10g', '4g'),
    [DietTag.LOW_FAT, DietTag.HIGH_FIBER, DietTag.VEGETARIAN],
    7
  ));

  return recipes;
}
