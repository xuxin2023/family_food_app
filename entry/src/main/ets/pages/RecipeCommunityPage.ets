// RecipeCommunityPage.ets
// 食谱社区页面 — 浏览热门/最新食谱、分类筛选

import { router, promptAction } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppState } from '../AppState';
import { Recipe, RecipeCategory, RecipeDifficulty, DietTag, RecipeQueryParams } from '../model/Recipe';
import { COLORS, RADIUS, SPACING, BUTTON, FONT_SIZE, FONT_WEIGHT } from '../constants/AppTheme';

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
  @State recipes: Recipe[] = []
  @State isLoading: boolean = true
  @State selectedCategory: string = ''
  @State sortBy: string = 'latest'

  private appState: AppState = AppState.getInstance()

  async aboutToAppear() {
    await this.loadRecipes()
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
          .onClick(() => { router.back() })
        Text('食谱社区')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 12 })
        Blank()
        Text('发布')
          .fontSize(14)
          .fontColor(COLORS.PRIMARY)
          .onClick(() => {
            router.pushUrl({ url: 'pages/RecipeCreatePage' })
          })
      }
      .width('100%')
      .padding(16)

      // 分类导航
      this.categoryNav()

      // 排序Tab
      Row({ space: 8 }) {
        this.sortTab('最新', 'latest')
        this.sortTab('热门', 'popular')
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 8 })

      if (this.isLoading) {
        LoadingProgress()
          .width(32)
          .height(32)
          .margin({ top: 100 })
      } else if (this.recipes.length === 0) {
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
  categoryNav() {
    Scroll() {
      Row({ space: 8 }) {
        this.categoryChip('全部', '')
        const categoryKeys: string[] = ['breakfast', 'lunch', 'dinner', 'snack', 'beverage', 'dessert', 'soup', 'staple']
        ForEach(categoryKeys, (key: string) => {
          this.categoryChip(getCategoryLabel(key), key)
        })
      }
      .padding({ left: 16, right: 16, bottom: 8 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .width('100%')
    .height(44)
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
        this.loadRecipes()
      })
  }

  @Builder
  emptyState() {
    Column() {
      Text('🍳')
        .fontSize(60)
        .margin({ bottom: 16 })
      Text('还没有食谱分享')
        .fontSize(16)
        .fontColor(COLORS.TEXT_GRAY_6161)
        .margin({ bottom: 8 })
      Text('扫描食品后可以创建食谱分享给社区\n也可以看看别人怎么搭配')
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
      ForEach(this.recipes, (recipe: Recipe) => {
        ListItem() {
          this.recipeCard(recipe)
        }
      })
    }
    .width('100%')
    .layoutWeight(1)
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
              Text(this.getDietTagLabel(tag))
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
      router.pushUrl({
        url: 'pages/RecipeDetailPage',
        params: navParams
      })
    })
  }

  private getDietTagLabel(tag: DietTag): string {
    return getDietTagLabel(tag)
  }
}
