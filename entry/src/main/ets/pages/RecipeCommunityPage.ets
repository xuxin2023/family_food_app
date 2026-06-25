// RecipeCommunityPage.ets
// 食谱社区页面 — 浏览热门/最新食谱、分类筛选

import {
  safeBack, safePushUrl, getPageParams, Recipe, RecipeCategory, RecipeDifficulty, DietTag, RecipeQueryParams, safeParseRecipeCategory, COLORS, RADIUS, SPACING, FONT_SIZE, SHADOWS, BUTTON, BLUR, BasicDataSource, PAGE_SIZE_CONFIG, HILOG_DOMAIN_DEFAULT, AiRecipeRecommendation, AiRecipeRecommendationResult, AiRecipeRequest, getCategoryLabel, getCategoryEmoji, getDietTagLabel, getDifficultyLabel, ImageCache,
  HapticHelper, PageResourceTracker, createPageTracker, ThemeReactive, themeReactive, ThemeColors, ThemeMode, NavigationManager, DeviceAdapter, Breakpoint
} from 'hsp_core';
import { BackButton } from '../components/BackButton';
import { GradientHeader } from '../components/GradientHeader';
import { GlassCard, GlassDepth } from '../components/GlassCard';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppState } from '../AppState';
import { ErrorFallback } from '../components/ErrorFallback';
import { LoadingSkeleton } from '../components/SkeletonScreen';


const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

const PAGE_SIZE = PAGE_SIZE_CONFIG.RECIPE_COMMUNITY_PAGE_SIZE;

@Entry
@ComponentV2
export struct RecipeCommunityPage {
  @Local isLoading: boolean = true
  @Local selectedCategory: string = ''
  @Local sortBy: string = 'latest'
  @Local aiRecommendations: AiRecipeRecommendation[] = []
  @Local isLoadingAi: boolean = false
  @Local showAiRecommend: boolean = false
  @Local aiSummary: string = ''
  @Local errorMessage: ResourceStr = ''
  @Local isRefreshing: boolean = false
  @Local searchText: string = ''
  private componentActive: boolean = true
  private tracker: PageResourceTracker = createPageTracker('RecipeCommunityPage')

  private appState: AppState = AppState.getInstance()
  private recipes: Recipe[] = []
  private recipeDS = new BasicDataSource<Recipe>()
  private readonly categoryKeys: string[] = ['breakfast', 'lunch', 'dinner', 'snack', 'beverage', 'dessert', 'soup', 'staple']

  private themeRef: ThemeReactive = themeReactive

  private get isDark(): boolean {
    if (this.themeRef.key >= 0) { /* trigger reactive */ }
    return ThemeColors.getTheme() === ThemeMode.DARK
  }

  private get pageBgGradient(): LinearGradient {
    if (this.isDark) {
      return { angle: 180, colors: [['#0D1B0E', 0.0], ['#1A2F1C', 0.5], ['#0A1A0D', 1.0]] }
    }
    return { angle: 180, colors: [['#E0F2F1', 0.0], ['#E8EAF6', 0.3], ['#E8F5E9', 0.7], ['#FFF8E1', 1.0]] }
  }

  async aboutToAppear() {
    this.tracker.onAppear()
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
    this.tracker.onDisappear()
    this.componentActive = false
  }

  async loadAiRecommendations(): Promise<void> {
    this.isLoadingAi = true
    try {
      const members = await this.appState.getAllMembers()
      const request: AiRecipeRequest = new AiRecipeRequest()
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

  async loadRecipes(): Promise<void> {    this.isLoading = true
    this.errorMessage = ''
    try {
      const params: RecipeQueryParams = new RecipeQueryParams()
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

  private applySearchFilter(): void {
    if (this.searchText.length === 0) {
      this.recipeDS.reload(this.recipes)
      return
    }
    const keyword = this.searchText.toLowerCase()
    const filtered = this.recipes.filter((r: Recipe) => {
      return r.title.toLowerCase().includes(keyword) ||
        r.description.toLowerCase().includes(keyword) ||
        r.authorName.toLowerCase().includes(keyword)
    })
    this.recipeDS.reload(filtered)
  }

  build() {
    Column() {
      // 顶栏 — 渐变头部
      GradientHeader({
        title: $r('app.string.recipe_community'),
        showBack: false,
        rightText: '发布食谱',
        onRightClick: () => { safePushUrl('pages/RecipeCreatePage') }
      })

      // 搜索栏
      GlassCard({
        depth: GlassDepth.SURFACE,
        paddingVal: 8,
        radiusVal: RADIUS.LG,
        widthVal: '100%',
        marginVal: { left: 16, right: 16, top: 8, bottom: 4 }
      }) {
        Row({ space: 8 }) {
          Text('\u{1F50D}')
            .fontSize(16)
          TextInput({ text: this.searchText, placeholder: '搜索食谱...' })
            .layoutWeight(1)
            .height(36)
            .fontSize(14)
            .backgroundColor(this.isDark ? '#1FFFFFFF' : '#33FFFFFF')
            .borderRadius(18)
            .padding({ left: 12, right: 12 })
            .onChange((value: string) => {
              this.searchText = value
              this.applySearchFilter()
            })
        }
        .width('100%')
      }

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

      Refresh({ refreshing: $$this.isRefreshing }) {
        Column() {
          if (this.sortBy === 'ai') {
            if (this.isLoadingAi) {
              LoadingSkeleton({ variant: 'list' })
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
              icon: '\u{1F37D}',
              onRetry: () => this.loadRecipes()
            })
          } else if (this.isLoading) {
            LoadingSkeleton({ variant: 'list' })
              .margin({ top: 100 })
          } else if (this.recipeDS.totalCount() === 0) {
            this.emptyState()
          } else {
            this.recipeList()
          }
        }
        .width('100%')
        .layoutWeight(1)
      }
      .onRefreshing(async () => {
        HapticHelper.light()
        if (this.sortBy === 'ai') {
          await this.loadAiRecommendations()
        } else {
          await this.loadRecipes()
        }
        this.isRefreshing = false
      })
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .linearGradient(this.pageBgGradient)
    .opacity(this.themeRef.key >= 0 ? 1 : 1)
  }

  @Builder
  categoryChip(label: ResourceStr, value: string) {
    Text(label)
      .fontSize(FONT_SIZE.SMALL)
      .fontColor(this.selectedCategory === value ? COLORS.WHITE : COLORS.TEXT_SECONDARY)
      .backgroundColor(Color.Transparent)
      .linearGradient(this.selectedCategory === value
        ? { angle: 135, colors: [['#D66B5A', 0.0], ['#E8826C', 0.5], ['#F0A18C', 1.0]] }
        : { angle: 0, colors: [[this.isDark ? '#1FFFFFFF' : '#33FFFFFF', 0.0], [this.isDark ? '#1FFFFFFF' : '#33FFFFFF', 1.0]] })
      .padding({ left: 14, right: 14, top: 6, bottom: 6 })
      .borderRadius(RADIUS.LG)
      .onClick(() => {
        HapticHelper.light()
        this.selectedCategory = value
        this.loadRecipes()
      })
      .accessibilityText(typeof label === 'string' ? label : '')
      .accessibilityLevel('yes')
  }

  @Builder
  sortTab(label: ResourceStr, value: string) {
    Text(label)
      .fontSize(FONT_SIZE.BODY)
      .fontWeight(this.sortBy === value ? FontWeight.Bold : FontWeight.Regular)
      .fontColor(this.sortBy === value ? COLORS.PRIMARY : COLORS.TEXT_GRAY_9E9E)
      .onClick(() => {
        HapticHelper.light()
        this.sortBy = value
        if (value === 'ai') {
          this.loadAiRecommendations()
        } else {
          this.loadRecipes()
        }
      })
      .accessibilityText(typeof label === 'string' ? label : '')
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
          HapticHelper.light()
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
    WaterFlow() {
      LazyForEach(this.recipeDS, (recipe: Recipe) => {
        FlowItem() {
          this.recipeCard(recipe)
        }
      }, (recipe: Recipe) => `${recipe.recipeId}`)
    }
    .columnsTemplate(this.getRecipeColumns())
    .columnsGap(12)
    .rowsGap(12)
    .width('100%')
    .layoutWeight(1)
    .padding({ left: 16, right: 16 })
    .cachedCount(8)
  }

  private getRecipeColumns(): string {
    const bp: Breakpoint = DeviceAdapter.getBreakpoint()
    if (bp === Breakpoint.LG) {
      return '1fr 1fr 1fr'
    }
    return '1fr 1fr'
  }

  @Builder
  aiRecommendList() {
    Column() {
      // AI总评卡片
      GlassCard({
        depth: GlassDepth.HERO,
        paddingVal: 16,
        radiusVal: RADIUS.LG,
        glowColor: '#3369F0AE',
        widthVal: '100%',
        marginVal: { bottom: 12 }
      }) {
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
      }

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
        .backgroundColor(COLORS.GLASS_BG_ELEVATED)
        .backgroundBlurStyle(BLUR.CARD, { adaptiveColor: AdaptiveColor.DEFAULT, scale: 1.0 })
        .border({ width: 0.5, color: COLORS.GLASS_BORDER })
        .borderRadius(RADIUS.LG)
        .margin({ bottom: 12 })
        .shadow(this.isDark ? { radius: 12, color: '#3369F0AE', offsetX: 0, offsetY: 4 } : SHADOWS.MD)
        .onClick(() => {
          HapticHelper.light()
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
      Row()
        .width(4)
        .height('100%')
        .position({ x: 0, y: 0 })
        .backgroundColor(this.getCategoryAccentColor(recipe.category))
        .borderRadius({ topLeft: RADIUS.LG, bottomLeft: RADIUS.LG })

      Column() {
        if (recipe.coverImageUrl.length > 0) {
          Stack({ alignContent: Alignment.BottomStart }) {
            Image(ImageCache.has(recipe.coverImageUrl) ? (ImageCache.get(recipe.coverImageUrl) ?? recipe.coverImageUrl) : recipe.coverImageUrl)
              .width('100%')
              .height(160)
              .objectFit(ImageFit.Cover)
              .autoResize(true)
              .borderRadius({ topLeft: RADIUS.LG, topRight: RADIUS.LG })
              .geometryTransition('recipe_cover_' + recipe.recipeId)
              .onComplete(() => { ImageCache.set(recipe.coverImageUrl, recipe.coverImageUrl); })
            Column()
              .width('100%')
              .height(64)
              .linearGradient({ angle: 180, colors: [['#00000000', 0.0], ['#66000000', 1.0]] })
          }
          .width('100%')
        } else {
          Column() {
            Text(getCategoryEmoji(recipe.category))
              .fontSize(48)
          }
          .width('100%')
          .height(140)
          .linearGradient(this.isDark
            ? { angle: 135, colors: [['#1B3A1E', 0.0], ['#0D1B0E', 1.0]] }
            : { angle: 135, colors: [['#E8F5E9', 0.0], ['#C8E6C9', 1.0]] })
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
      }

      Column() {
        Row() {
          Text(recipe.title)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          Text(getDifficultyLabel(recipe.difficulty))
            .fontSize(10)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Medium)
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .borderRadius(10)
            .linearGradient(this.getDifficultyGradient(recipe.difficulty))
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

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
    .backgroundColor(COLORS.GLASS_BG_ELEVATED)
    .backgroundBlurStyle(BLUR.CARD, { adaptiveColor: AdaptiveColor.DEFAULT, scale: 1.0 })
    .border({ width: 0.5, color: COLORS.GLASS_BORDER })
    .borderRadius(RADIUS.LG)
    .shadow(this.isDark ? { radius: 12, color: '#3369F0AE', offsetX: 0, offsetY: 4 } : { radius: 16, color: '#20000000', offsetX: 0, offsetY: 6 })
    .margin({ bottom: 14 })
    .onClick(() => {
      HapticHelper.light()
      const navParams = new Map<string, Object>();
      navParams.set('recipeId', recipe.recipeId);
      this.getUIContext()?.animateTo({ duration: 350 }, () => {
        NavigationManager.pushPathForSharedElement('pages/RecipeDetailPage', navParams)
      })
    })
    .accessibilityText(recipe.title)
    .accessibilityLevel('yes')
  }

  private getCategoryAccentColor(category: string): string {
    if (category === 'breakfast') return '#FF9800';
    if (category === 'lunch') return '#43A047';
    if (category === 'dinner') return '#1976D2';
    if (category === 'snack') return '#7B1FA2';
    if (category === 'beverage') return '#00897B';
    if (category === 'dessert') return '#E91E63';
    if (category === 'soup') return '#FF5722';
    if (category === 'staple') return '#795548';
    return '#43A047';
  }

  private getDifficultyGradient(difficulty: string): LinearGradient {
    if (difficulty === RecipeDifficulty.EASY) {
      return { angle: 135, colors: [['#E8826C', 0.0], ['#F0A18C', 1.0]] };
    }
    if (difficulty === RecipeDifficulty.HARD) {
      return { angle: 135, colors: [['#D32F2F', 0.0], ['#F44336', 1.0]] };
    }
    return { angle: 135, colors: [['#F57C00', 0.0], ['#FF9800', 1.0]] };
  }

  // 使用全局函数 getDietTagLabel，避免栈溢出

  pageTransition() {
    PageTransitionEnter({ duration: 300, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 200, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
  }
}