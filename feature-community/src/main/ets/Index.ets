// feature-community 社区功能模块入口
// Sprint3: 源码已物理迁移至本模块

// ===== 社区服务 =====
export { RecipeCommunityService, CreateRecipeParams } from './service/RecipeCommunityService';
export { CommunityFoodService } from './service/CommunityFoodService';
export { FamilyGroupService, CreateGroupParams } from './service/FamilyGroupService';

// ===== 社区数据仓库 =====
export { RecipeRepository } from './repository/RecipeRepository';
export { FamilyGroupRepository } from './repository/FamilyGroupRepository';

// ===== 社区图片服务 =====
export { CommunityImageService, ImageUploadResult } from './service/CommunityImageService';

// ===== 社区组件 =====
export { CommunityFeedCard } from './components/CommunityFeedCard';
export { RecipeCard } from './components/RecipeCard';
export { CommentList } from './components/CommentList';
export { LikeButton } from './components/LikeButton';
