// RecipeCommunityPage.ets
// 食谱社区页面 — 浏览热门/最新食谱、分类筛选

import {
  safeBack, safePushUrl, getPageParams, Recipe, RecipeCategory, DietTag, RecipeQueryParams, safeParseRecipeCategory, COLORS, RADIUS, BUTTON, BasicDataSource, PAGE_SIZE_CONFIG, HILOG_DOMAIN_DEFAULT, AiRecipeRecommendation, AiRecipeRecommendationResult, AiRecipeRequest, getCategoryLabel, getCategoryEmoji, getDietTagLabel, ImageCache
} from 'hsp_core';
import { BackButton } from '../components/BackButton';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppState } from '../AppState';
import { ErrorFallback } from '../components/ErrorFallback';
import { RecipeCard, LikeButton } from 'feature_community';


const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

const PAGE_SIZE = PAGE_SIZE_CONFIG.RECIPE_COMMUNITY_PAGE_SIZE;

@Entry
@ComponentV2
struct RecipeCommunityPage {
  @Local isLoading: boolean = true
  @Local selectedCategory: string = ''
  @Local sortBy: string = 'latest'
  @Local aiRecommendations: AiRecipeRecommendation[] = []
  @Local isLoadingAi: boolean = false
  @Local showAiRecommend: boolean = false
  @Local aiSummary: string = ''
  @Local errorMessage: ResourceStr = ''
  private componentActive: boolean = true

  private appState: AppState = AppState.getInstance()
  private recipes: Recipe[] = []
  private recipeDS = new BasicDataSource<Recipe>()
  private readonly categoryKeys: string[] = ['breakfast', 'lunch', 'dinner', 'snack', 'beverage', 'dessert', 'soup', 'staple']

  async aboutToAppear() {
    const params = getPageParams();
    if (params !== null && params !== undefined && params!.get('aiMode') === 'recommend') {
      this.showAiRecommend = true
      await Promise.all([
        this.loadAiRecommendations(),
        this.loadRecipes()
      ])
    } else {
      await this.loadRecipes()
    }
  }

  aboutToDisappear(): void {
    this.componentActive = false
  }

  async loadAiRecommendations(): Promise<void> {
    this.isLoadingAi = true
    try {
      const members = await this.appState.getAllMembers()
      const request = new AiRecipeRequest()
      request.memberIds = members.map(m => m.memberId)
      request.limit = 5
      request.mealCategory = ''
      request.preference = ''
      const result = await this.appState.getAiRecipeRecommendation(request)
      this.aiRecommendations = result.recommendations
      this.aiSummary = result.overallSummary
    } catch (e) {
      hilog.error(DOMAIN_ZERO, 'RecipeCommunityPage', 'ai recommend error')
    }
    this.isLoadingAi = false
  }

  async loadRecipes(): Promise<void> {
    this.isLoading = true
    this.errorMessage = ''
    try {
      const params = new RecipeQueryParams()
      params.offset = 0
      params.limit = PAGE_SIZE
      params.category = this.selectedCategory.length > 0 ? safeParseRecipeCategory(this.selectedCategory) : undefined
      params.sortBy = this.sortBy === 'popular' ? 'popular' : 'latest'
      this.recipes = await this.appState.queryCommunityRecipes(params)
      this.recipeDS.reload(this.recipes)
    } catch (e) {
      hilog.error(DOMAIN_ZERO, 'RecipeCommunityPage', 'load recipes error')
      this.errorMessage = $r('app.string.recipe_community_load_failed') as ResourceStr
    }
    this.isLoading = false
  }

  build() {
    Column() {
      // 顶栏
      Row() {
        BackButton({ fontSize: 24, fontColor: COLORS.PRIMARY })
          .onClick(() => { safeBack() })
          .accessibilityText('返回')
          .accessibilityLevel('yes')
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
          .accessibilityText('发布食谱')
          .accessibilityLevel('yes')
      }
      .width('100%')
      .padding(16)

      // 分类导航
      Scroll() {
        Row({ space: 8 }) {
          this.categoryChip($r('app.string.recipe_community_all'), '')
          ForEach(this.categoryKeys, (key: string) => {
            this.categoryChip(getCategoryLabel(key), key)
          }, (key: string) => key)
        }
        .padding({ left: 16, right: 16, bottom: 8 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .width('100%')
      .height(44)

      // AI推荐Tab + 排序Tab
      Row({ space: 8 }) {
        this.sortTab($r('app.string.recipe_community_ai_recommend'), 'ai')
        this.sortTab($r('app.string.recipe_community_latest'), 'latest')
        this.sortTab($r('app.string.recipe_community_popular'), 'popular')
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
      } else if (this.errorMessage) {
        ErrorFallback({
          message: this.errorMessage,
          icon: '🍽️',
          onRetry: () => this.loadRecipes()
        })
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
  categoryChip(label: ResourceStr, value: string) {
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
      .accessibilityText(label as Resource)
      .accessibilityLevel('yes')
  }

  @Builder
  sortTab(label: ResourceStr, value: string) {
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
      .accessibilityText(label as Resource)
      .accessibilityLevel('yes')
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
      Button($r('app.string.recipe_community_publish_first'))
        .height(BUTTON.HEIGHT_SECONDARY)
        .backgroundColor(COLORS.PRIMARY)
        .borderRadius(BUTTON.RADIUS_SECONDARY)
        .fontColor(COLORS.WHITE)
        .fontSize(14)
        .onClick(() => {
          safePushUrl('pages/RecipeCreatePage')
        })
        .accessibilityText('发布第一个食谱')
        .accessibilityLevel('yes')
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
          const navParams = new Map<string, Object>();
          navParams.set('recipeId', rec.recipe.recipeId);
          safePushUrl('pages/RecipeDetailPage', navParams)
        })
        .accessibilityText(rec.recipe.title)
        .accessibilityLevel('yes')
      }, (rec: AiRecipeRecommendation, i: number) => `rec_${i}`)
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
          Image(ImageCache.has(recipe.coverImageUrl) ? ImageCache.get(recipe.coverImageUrl)! : recipe.coverImageUrl)
            .width('100%')
            .height(160)
            .objectFit(ImageFit.Cover)
            .autoResize(true)
            .borderRadius({ topLeft: RADIUS.LG, topRight: RADIUS.LG })
            .onComplete(() => { ImageCache.set(recipe.coverImageUrl, recipe.coverImageUrl); })
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
            }, (tag: DietTag) => tag)
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
      const navParams = new Map<string, Object>();
      navParams.set('recipeId', recipe.recipeId);
      safePushUrl('pages/RecipeDetailPage', navParams)
    })
    .accessibilityText(recipe.title)
    .accessibilityLevel('yes')
  }

  // 使用全局函数 getDietTagLabel，避免栈溢出

  pageTransition() {
    PageTransitionEnter({ duration: 300, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 200, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
  }
}