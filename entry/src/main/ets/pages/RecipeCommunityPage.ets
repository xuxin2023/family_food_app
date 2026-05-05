// RecipeCommunityPage.ets
// 食谱社区页面 — 浏览热门/最新食谱、分类筛选

import { router, promptAction } from '@kit.ArkUI';
import { safeBack, safePushUrl } from '../utils/RouterUtil';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppState } from '../AppState';
import { Recipe, RecipeCategory, RecipeDifficulty, DietTag, RecipeQueryParams } from '../model/Recipe';
import {
  AiRecipeRecommendation, AiRecipeRecommendationResult
} from '../model/AiModels';
import { COLORS, RADIUS, SPACING, BUTTON, FONT_SIZE, FONT_WEIGHT } from '../constants/AppTheme';
import { BasicDataSource } from '../utils/BasicDataSource';

const PAGE_SIZE = 10;

function getCategoryLabel(key: string): string {
  const map: Map<string, string> = new Map()
  map.set('breakfast', '早餐')
  map.set('lunch', '午餐')
  map.set('dinner', '晚餐')
  map.set('snack', '零食')
  map.set('beverage', '饮品')
  map.set('dessert', '甜品')
  map.set('soup', '汤羹')
  map.set('staple', '主食')
  return map.get(key) || key
}

function getCategoryEmoji(key: string): string {
  const map: Map<string, string> = new Map()
  map.set('breakfast', '🌅')
  map.set('lunch', '☀️')
  map.set('dinner', '🌙')
  map.set('snack', '🍿')
  map.set('beverage', '🥤')
  map.set('dessert', '🍰')
  map.set('soup', '🍲')
  map.set('staple', '🍚')
  return map.get(key) || '🍽️'
}

function getDietTagLabel(tag: DietTag): string {
  const map: Map<string, string> = new Map()
  map.set(DietTag.CHILD_FRIENDLY, '👶儿童')
  map.set(DietTag.ELDER_FRIENDLY, '👴老人')
  map.set(DietTag.LOW_SODIUM, '低钠')
  map.set(DietTag.LOW_SUGAR, '低糖')
  map.set(DietTag.LOW_FAT, '低脂')
  map.set(DietTag.HIGH_PROTEIN, '高蛋白')
  map.set(DietTag.VEGETARIAN, '素食')
  map.set(DietTag.ALLERGEN_FREE, '无过敏原')
  return map.get(tag) || tag
}

@Entry
@Component
struct RecipeCommunityPage {
  @State isLoading: boolean = true
  @State selectedCategory: string = ''
  @State sortBy: string = 'latest'
  @State aiRecommendations: AiRecipeRecommendation[] = []
  @State isLoadingAi: boolean = false
  @State showAiRecommend: boolean = false
  @State aiSummary: string = ''

  private appState: AppState = AppState.getInstance()
  private recipes: Recipe[] = []
  private recipeDS = new BasicDataSource<Recipe>()
  private readonly categoryKeys: string[] = ['breakfast', 'lunch', 'dinner', 'snack', 'beverage', 'dessert', 'soup', 'staple']

  async aboutToAppear() {
    // 检查是否从首页以AI推荐模式进入
    try {
      const params = router.getParams() as Record<string, Object>;
      if (params['aiMode'] === 'recommend') {
        this.showAiRecommend = true
        await this.loadAiRecommendations()
      }
    } catch (_e) { /* ignore */ }
    await this.loadRecipes()
  }

  async loadAiRecommendations() {
    this.isLoadingAi = true
    try {
      const members = await this.appState.getAllMembers()
      const memberIds = members.map(m => m.memberId)
      const result = await this.appState.getAiRecipeRecommendations(
        memberIds, undefined, undefined, 5
      )
      this.aiRecommendations = result.recommendations
      this.aiSummary = result.overallSummary
    } catch (e) {
      hilog.error(0x0000, 'RecipeCommunityPage', 'ai recommend error')
    }
    this.isLoadingAi = false
  }

  async loadRecipes() {
    this.isLoading = true
    try {
      const params: RecipeQueryParams = {
        offset: 0,
        limit: PAGE_SIZE,
        category: this.selectedCategory.length > 0 ? this.selectedCategory as RecipeCategory : undefined,
        sortBy: this.sortBy === 'popular' ? 'popular' : 'latest'
      }
      this.recipes = await this.appState.queryCommunityRecipes(params)
      this.recipeDS.reload(this.recipes)
    } catch (e) {
      hilog.error(0x0000, 'RecipeCommunityPage', 'load recipes error')
    }
    this.isLoading = false
  }

  build() {
    Column() {
      // 顶栏
      Row() {
        Text('<')
          .fontSize(24)
          .fontColor(COLORS.PRIMARY)
          .onClick(() => { safeBack() })
        Text($r('app.string.recipe_community'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 12 })
        Blank()
        Text($r('app.string.share_publish_recipe'))
          .fontSize(14)
          .fontColor(COLORS.PRIMARY)
          .onClick(() => {
            safePushUrl('pages/RecipeCreatePage')
          })
      }
      .width('100%')
      .padding(16)

      // 分类导航
      Scroll() {
        Row({ space: 8 }) {
          this.categoryChip('全部', '')
          ForEach(this.categoryKeys, (key: string) => {
            this.categoryChip(getCategoryLabel(key), key)
          })
        }
        .padding({ left: 16, right: 16, bottom: 8 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .width('100%')
      .height(44)

      // AI推荐Tab + 排序Tab
      Row({ space: 8 }) {
        this.sortTab('✨ AI推荐', 'ai')
        this.sortTab('最新', 'latest')
        this.sortTab('热门', 'popular')
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 8 })

      if (this.sortBy === 'ai') {
        // AI推荐模式
        if (this.isLoadingAi) {
          LoadingProgress()
            .width(32)
            .height(32)
            .margin({ top: 60 })
        } else if (this.aiRecommendations.length > 0) {
          this.aiRecommendList()
        } else {
          Text($r('app.string.click_refresh_ai'))
            .fontSize(14)
            .fontColor(COLORS.TEXT_GRAY_9E9E)
            .margin({ top: 60 })
            .width('100%')
            .textAlign(TextAlign.Center)
        }
      } else if (this.isLoading) {
        LoadingProgress()
          .width(32)
          .height(32)
          .margin({ top: 100 })
      } else if (this.recipeDS.totalCount() === 0) {
        this.emptyState()
      } else {
        this.recipeList()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_PAGE)
  }

  @Builder
  categoryChip(label: string, value: string) {
    Text(label)
      .fontSize(13)
      .fontColor(this.selectedCategory === value ? COLORS.WHITE : COLORS.TEXT_SECONDARY)
      .backgroundColor(this.selectedCategory === value ? COLORS.PRIMARY : COLORS.BG_DIVIDER)
      .padding({ left: 14, right: 14, top: 6, bottom: 6 })
      .borderRadius(16)
      .onClick(() => {
        this.selectedCategory = value
        this.loadRecipes()
      })
  }

  @Builder
  sortTab(label: string, value: string) {
    Text(label)
      .fontSize(14)
      .fontWeight(this.sortBy === value ? FontWeight.Bold : FontWeight.Regular)
      .fontColor(this.sortBy === value ? COLORS.PRIMARY : COLORS.TEXT_GRAY_9E9E)
      .onClick(() => {
        this.sortBy = value
        if (value === 'ai') {
          this.loadAiRecommendations()
        } else {
          this.loadRecipes()
        }
      })
  }

  @Builder
  emptyState() {
    Column() {
      Text('🍳')
        .fontSize(60)
        .margin({ bottom: 16 })
      Text($r('app.string.no_recipe_yet'))
        .fontSize(16)
        .fontColor(COLORS.TEXT_GRAY_6161)
        .margin({ bottom: 8 })
      Text($r('app.string.recipe_community_hint'))
        .fontSize(13)
        .fontColor(COLORS.TEXT_GRAY_9E9E)
        .textAlign(TextAlign.Center)
        .margin({ bottom: 16 })
      Button('发布第一个食谱')
        .height(BUTTON.HEIGHT_SECONDARY)
        .backgroundColor(COLORS.PRIMARY)
        .borderRadius(BUTTON.RADIUS_SECONDARY)
        .fontColor(COLORS.WHITE)
        .fontSize(14)
        .onClick(() => {
          router.pushUrl({ url: 'pages/RecipeCreatePage' })
        })
    }
    .width('100%')
    .padding({ top: 60 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  recipeList() {
    List() {
      LazyForEach(this.recipeDS, (recipe: Recipe) => {
        ListItem() {
          this.recipeCard(recipe)
        }
      }, (recipe: Recipe) => `${recipe.recipeId}`)
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ left: 16, right: 16 })
    .cachedCount(5)
  }

  @Builder
  aiRecommendList() {
    Column() {
      // AI总评卡片
      Column() {
        Row({ space: 6 }) {
          Text('🤖').fontSize(20)
          Text($r('app.string.ai_recommend')).fontSize(16).fontWeight(FontWeight.Bold).fontColor(COLORS.PRIMARY)
        }
        .margin({ bottom: 8 })

        Text(this.aiSummary)
          .fontSize(13)
          .fontColor(COLORS.TEXT_GRAY_6161)
          .textAlign(TextAlign.Start)
          .width('100%')

        Text($r('app.string.ai_match_desc'))
          .fontSize(11)
          .fontColor(COLORS.TEXT_GRAY_9E9E)
          .margin({ top: 4 })
      }
      .width('100%')
      .padding(16)
      .backgroundColor(COLORS.BG_WARM_PINK)
      .borderRadius(RADIUS.LG)
      .margin({ bottom: 12 })

      // 推荐列表
      ForEach(this.aiRecommendations, (rec: AiRecipeRecommendation) => {
        Column() {
          this.recipeCard(rec.recipe)

          // AI推荐理由
          if (rec.reason.length > 0) {
            Row({ space: 4 }) {
              Text('💡').fontSize(12)
              Text(rec.reason)
                .fontSize(12)
                .fontColor(COLORS.ACCENT_PURPLE)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .padding({ left: 12, right: 12, top: 4, bottom: 8 })
          }

          // 匹配度和营养提示
          if (rec.nutritionTip.length > 0) {
            Text('📌 ' + rec.nutritionTip)
              .fontSize(11)
              .fontColor(COLORS.TEXT_GRAY_9E9E)
              .padding({ left: 12, right: 12, bottom: 8 })
              .width('100%')
          }
        }
        .width('100%')
        .backgroundColor(COLORS.WHITE)
        .borderRadius(RADIUS.LG)
        .margin({ bottom: 12 })
        .shadow({ radius: 2, color: COLORS.SHADOW_LIGHT, offsetY: 1 })
        .onClick(() => {
          try {
            router.pushUrl({ url: 'pages/RecipeDetailPage', params: { recipeId: rec.recipe.recipeId } })
          } catch (_e) {
            // ignore
          }
        })
      })
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
  }

  @Builder
  recipeCard(recipe: Recipe) {
    Column() {
      // 封面图占位
      Column() {
        if (recipe.coverImageUrl.length > 0) {
          Image(recipe.coverImageUrl)
            .width('100%')
            .height(160)
            .objectFit(ImageFit.Cover)
            .borderRadius({ topLeft: RADIUS.LG, topRight: RADIUS.LG })
        } else {
          Column() {
            Text(getCategoryEmoji(recipe.category))
              .fontSize(48)
          }
          .width('100%')
          .height(140)
          .backgroundColor(COLORS.BG_WARM_PINK)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
      }

      Column() {
        Text(recipe.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Row({ space: 6 }) {
          if (recipe.dietTags.length > 0) {
            ForEach(recipe.dietTags.slice(0, 2), (tag: DietTag) => {
              Text(getDietTagLabel(tag))
                .fontSize(10)
                .fontColor(COLORS.ACCENT_GREEN)
                .backgroundColor(COLORS.BG_LIGHT_GREEN)
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .borderRadius(6)
            })
          }
        }
        .margin({ top: 6 })

        Row({ space: 16 }) {
          Row({ space: 4 }) {
            Text('👍').fontSize(12)
            Text(`${recipe.likeCount}`).fontSize(11).fontColor(COLORS.TEXT_GRAY_9E9E)
          }
          Row({ space: 4 }) {
            Text('💬').fontSize(12)
            Text(`${recipe.commentCount}`).fontSize(11).fontColor(COLORS.TEXT_GRAY_9E9E)
          }
          Row({ space: 4 }) {
            Text('⏱️').fontSize(12)
            Text(`${recipe.totalMinutes}分钟`).fontSize(11).fontColor(COLORS.TEXT_GRAY_9E9E)
          }
          Blank()
          Text(getCategoryLabel(recipe.category) || recipe.category)
            .fontSize(11)
            .fontColor(COLORS.TEXT_GRAY_9E9E)
        }
        .width('100%')
        .margin({ top: 8 })
      }
      .padding(14)
    }
    .width('100%')
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.LG)
    .margin({ bottom: 14 })
    .onClick(() => {
      const navParams: Record<string, Object> = new Object() as Record<string, Object>
      navParams['recipeId'] = recipe.recipeId
      safePushUrl('pages/RecipeDetailPage', navParams)
    })
  }

  private getDietTagLabel(tag: DietTag): string {
    return getDietTagLabel(tag)
  }
}
