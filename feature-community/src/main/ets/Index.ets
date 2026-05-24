// feature-community 社区功能模块入口
// Sprint3: 源码已物理迁移至本模块

// ===== 社区服务 =====
export { RecipeCommunityService, CreateRecipeParams } from './src/main/ets/service/RecipeCommunityService';
export { CommunityFoodService } from './src/main/ets/service/CommunityFoodService';
export { FamilyGroupService } from './src/main/ets/service/FamilyGroupService';

// ===== 社区数据仓库 =====
export { RecipeRepository } from './src/main/ets/repository/RecipeRepository';
export { FamilyGroupRepository } from './src/main/ets/repository/FamilyGroupRepository';

// ===== 社区图片服务 =====
export { CommunityImageService, ImageUploadResult } from './src/main/ets/service/CommunityImageService';

// ===== 社区组件 =====
export { CommunityFeedCard } from './src/main/ets/components/CommunityFeedCard';
export { RecipeCard } from './src/main/ets/components/RecipeCard';
export { CommentList } from './src/main/ets/components/CommentList';
export { LikeButton } from './src/main/ets/components/LikeButton';
