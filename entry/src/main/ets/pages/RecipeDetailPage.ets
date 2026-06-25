// RecipeDetailPage.ets
// 食谱详情页面 — 详情、评论、点赞

import {
  ToastHelper, getPageParams, Recipe, RecipeComment, DietTag, RecipeIngredient, RecipeStep, COLORS, RADIUS, FONT_SIZE, SPACING, SHADOWS, BasicDataSource, HILOG_DOMAIN_DEFAULT, getCategoryLabel, getCategoryEmoji, getDifficultyLabel, getDietTagLabel, formatTime, ShoppingItem,
  PageResourceTracker, createPageTracker, ThemeReactive, themeReactive, ThemeColors, ThemeMode
} from 'hsp_core';
import { BackButton } from '../components/BackButton';
import { GradientHeader } from '../components/GradientHeader';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppState } from '../AppState';
import { LikeButton } from 'feature_community';
import { LoadingSkeleton } from '../components/SkeletonScreen';
import { ShoppingListRepository } from '../repository/ShoppingListRepository';
import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { DB_NAME } from 'hsp_core';


const TAG = 'RecipeDetailPage';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

@Entry
@ComponentV2
export struct RecipeDetailPage {
  @Local recipe: Recipe | null = null
  @Local hasLiked: boolean = false
  @Local hasBookmarked: boolean = false
  @Local isLoading: boolean = true
  @Local commentText: string = ''
  @Local selectedSection: string = 'detail'
  @Local currentBreakpoint: string = 'md'

  private appState: AppState = AppState.getInstance()
  private shoppingRepo: ShoppingListRepository = new ShoppingListRepository()
  private comments: RecipeComment[] = []
  private commentDS = new BasicDataSource<RecipeComment>()
  private recipeId: string = ''
  private tracker: PageResourceTracker = createPageTracker('RecipeDetailPage')

  private themeRef: ThemeReactive = themeReactive

  private get isDark(): boolean {
    if (this.themeRef.key >= 0) { /* trigger reactive */ }
    return ThemeColors.getTheme() === ThemeMode.DARK;
  }

  private get pageBgGradient(): LinearGradient {
    if (this.isDark) {
      return { angle: 180, colors: [['#0D1B0E', 0.0], ['#1A2F1C', 0.5], ['#0A1A0D', 1.0]] };
    }
    return { angle: 180, colors: [['#F3E5F5', 0.0], ['#FFF3E0', 0.3], ['#FFF8E1', 0.7], ['#E8F5E9', 1.0]] };
  }

  async aboutToAppear() {
    this.tracker.onAppear()
    const params = getPageParams()
    const raw = params !== undefined ? params.get('recipeId') : undefined;
    this.recipeId = (typeof raw === 'string' ? raw : '');
    const ctx = AppStorage.get<common.Context>('appContext')
    if (ctx) {
      try {
        const rdbConfig: relationalStore.StoreConfig = { name: DB_NAME, securityLevel: relationalStore.SecurityLevel.S3 };
        const rdbStore = await relationalStore.getRdbStore(ctx, rdbConfig);
        await this.shoppingRepo.init(rdbStore);
      } catch (e) {
        hilog.warn(DOMAIN_ZERO, TAG, 'Init shopping repo failed: %{public}s', JSON.stringify(e));
      }
    }
    await this.loadRecipe()
  }

  async loadRecipe() {
    if (this.recipeId.length === 0) return
    this.isLoading = true
    try {
      this.recipe = await this.appState.getRecipeDetail(this.recipeId)
      if (this.recipe) {
        const allResults = await Promise.all([
          this.appState.getRecipeComments(this.recipeId),
          this.appState.hasLikedRecipe(this.recipeId)
        ])
        const comments = allResults[0] as RecipeComment[]
        const hasLiked = allResults[1] as boolean
        this.comments = comments
        this.commentDS.reload(this.comments)
        this.hasLiked = hasLiked
      }
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'load error: %{public}s', JSON.stringify(e))
    }
    this.isLoading = false
  }

  private async generateShoppingList(): Promise<void> {
    if (!this.recipe || this.recipe.ingredients.length === 0) {
      ToastHelper.show(this.getUIContext(), '该食谱没有食材信息')
      return
    }
    try {
      const memberId = this.appState.member.getCurrentMemberId()
      let addedCount = 0
      for (const ing of this.recipe.ingredients) {
        if (ing.name.trim().length === 0) continue
        const item: ShoppingItem = new ShoppingItem()
        item.id = 'shop_' + Date.now().toString() + '_' + addedCount.toString()
        item.name = ing.name.trim()
        item.category = '其他'
        item.quantity = ing.amount.trim().length > 0 ? ing.amount.trim() : '1'
        item.isPurchased = false
        item.addedBy = memberId
        item.addedAt = Date.now()
        item.relatedFoodBarcode = ''
        await this.shoppingRepo.addItem(item)
        addedCount++
      }
      if (addedCount > 0) {
        ToastHelper.show(this.getUIContext(), '已添加' + addedCount.toString() + '项到购物清单')
      } else {
        ToastHelper.show(this.getUIContext(), '没有有效的食材可添加')
      }
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'generateShoppingList failed: %{public}s', JSON.stringify(e))
      ToastHelper.show(this.getUIContext(), '生成购物清单失败')
    }
  }

  build() {
    Column() {
      // 顶栏 — 渐变
      GradientHeader({ title: $r('app.string.recipe_detail') })

      if (this.isLoading) {
        LoadingSkeleton({ variant: 'detail' })
      } else if (!this.recipe) {
        Text($r('app.string.recipe_not_found')).fontSize(16).fontColor(COLORS.TEXT_GRAY_6161).margin({ top: 100 })
      } else {
        GridRow({
          columns: { sm: 4, md: 8, lg: 12 },
          breakpoints: { value: ['320vp', '600vp'], reference: BreakpointsReference.WindowSize }
        }) {
          GridCol({ span: { sm: 4, md: 8, lg: 10 }, offset: { sm: 0, md: 0, lg: 1 } }) {
            Scroll() {
              Column() {
                // 封面
                this.coverSection()

                // 基本信息
                this.infoSection()

                // Tab切换: 详情 / 评论
                Row({ space: 0 }) {
                  this.sectionTab($r('app.string.recipe_detail_tab_detail'), 'detail')
                  this.sectionTab($r('app.string.recipe_detail_tab_comment'), 'comment')
                }
                .width('100%')
                .padding({ left: 16, right: 16 })
                .margin({ top: 8 })

                if (this.selectedSection === 'detail') {
                  this.detailSection()
                } else {
                  this.commentSection()
                }
              }
              .width('100%')
              .padding({ bottom: 80 })
            }
            .width('100%')
            .layoutWeight(1)
          }
        }
        .width('100%')
        .layoutWeight(1)
        .onBreakpointChange((bp: string) => { this.currentBreakpoint = bp })
      }
    }
    .width('100%')
    .height('100%')
    .linearGradient(this.pageBgGradient)
    .opacity(this.themeRef.key >= 0 ? 1 : 1)
  }

  @Builder
  coverSection() {
    Stack() {
      Column() {
        Row()
          .width(180)
          .height(180)
          .borderRadius(90)
          .backgroundColor('rgba(255,255,255,0.06)')
          .position({ x: '60%', y: '-20%' })
      }
      .hitTestBehavior(HitTestMode.None)

      Column() {
        Text(getCategoryEmoji(this.recipe?.category ?? 'other'))
          .fontSize(64)
          .shadow(SHADOWS.MD)
          .geometryTransition('recipe_cover_' + (this.recipe?.recipeId ?? ''))
        Text(this.recipe?.title ?? '食谱详情')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLORS.WHITE)
          .margin({ top: 12 })
        Row({ space: 6 }) {
          Text(getCategoryLabel(this.recipe?.category ?? 'other'))
            .fontSize(FONT_SIZE.BODY)
            .fontColor(COLORS.WHITE)
            .opacity(0.9)
          Text('·')
            .fontSize(FONT_SIZE.BODY)
            .fontColor(COLORS.WHITE)
            .opacity(0.6)
          Text(getDifficultyLabel(this.recipe?.difficulty ?? 'medium'))
            .fontSize(FONT_SIZE.BODY)
            .fontColor(COLORS.WHITE)
            .opacity(0.9)
        }
        .margin({ top: 8 })
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height(240)
    .linearGradient({
      angle: 135,
      colors: [['#4A148C', 0.0], ['#6A1B9A', 0.3], ['#8E24AA', 0.7], ['#AB47BC', 1.0]]
    })
    .borderRadius({ topLeft: 0, topRight: 0, bottomLeft: 24, bottomRight: 24 })
  }

  @Builder
  infoSection() {
    Column() {
      Row({ space: 0 }) {
        this.infoItem('⏱️', `${this.recipe?.totalMinutes ?? 0}分钟`)
        this.infoItem('🍽️', `${this.recipe?.servings ?? 1}人份`)
        this.infoItem('📝', `${this.recipe?.steps?.length ?? 0}步`)
      }
      .width('100%')
      .padding(16)
      .backgroundColor(COLORS.WHITE)
      .borderRadius(RADIUS.LG)
      .shadow(SHADOWS.SM)
      .margin({ bottom: 8 })

      Row({ space: 16 }) {
        LikeButton({
          isLiked: this.hasLiked,
          likeCount: this.recipe?.likeCount ?? 0,
          onToggle: () => {
            this.appState.toggleRecipeLike(this.recipeId).then((newState: boolean) => {
              if (this.recipe) {
                if (newState !== this.hasLiked) {
                  this.recipe.likeCount += newState ? 1 : -1
                }
              }
              this.hasLiked = newState
            })
          }
        })

        Row({ space: 6 }) {
          Text(this.hasBookmarked ? '🔖' : '🏷️').fontSize(20)
          Text($r('app.string.favorite')).fontSize(14).fontColor(COLORS.TEXT_SECONDARY)
        }
        .onClick(() => {
          this.appState.toggleRecipeBookmark(this.recipeId, '').then((result: boolean) => {
            this.hasBookmarked = result
            ToastHelper.show(this.getUIContext(), result ? $r('app.string.recipe_detail_favorited') : $r('app.string.recipe_detail_unfavorited'))
          })
        })
        .accessibilityText('收藏')
        .accessibilityLevel('yes')
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
        .borderRadius(20)
      }
      .width('100%')
      .padding(16)
      .backgroundColor(COLORS.WHITE)
    }
    .width('100%')
    .padding({ left: SPACING.LG, right: SPACING.LG, top: SPACING.MD, bottom: SPACING.MD })
  }

  @Builder
  infoItem(emoji: string, label: string) {
    Row({ space: 4 }) {
      Text(emoji).fontSize(16)
      Text(label).fontSize(13).fontColor(COLORS.TEXT_SECONDARY)
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  sectionTab(label: ResourceStr, value: string) {
    Column() {
      Text(label)
        .fontSize(15)
        .fontWeight(this.selectedSection === value ? FontWeight.Bold : FontWeight.Regular)
        .fontColor(this.selectedSection === value ? COLORS.PRIMARY : COLORS.TEXT_GRAY_9E9E)
        .padding({ bottom: 8 })
      if (this.selectedSection === value) {
        Divider()
          .width(24)
          .color(COLORS.PRIMARY)
          .strokeWidth(2)
      }
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => { this.selectedSection = value })
    .accessibilityText(label as string)
    .accessibilityLevel('yes')
  }

  @Builder
  detailSection() {
    Column() {
      if ((this.recipe?.description?.length ?? 0) > 0) {
        Column() {
          Text($r('app.string.intro_label')).fontSize(16).fontWeight(FontWeight.Bold).margin({ bottom: 8 })
          Text(this.recipe?.description ?? '').fontSize(14).fontColor(COLORS.TEXT_SECONDARY).lineHeight(22)
        }
        .width('100%')
        .padding(16)
        .backgroundColor(COLORS.WHITE)
        .borderRadius(RADIUS.LG)
        .margin({ bottom: 12 })
      }

      if (this.currentBreakpoint === 'lg') {
        Row({ space: 12 }) {
          this.ingredientsColumn()
          if (this.recipe?.nutrition) {
            this.nutritionColumn()
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
      } else {
        this.ingredientsColumn()
        if (this.recipe?.nutrition) {
          this.nutritionColumn()
        }
      }

      Column() {
        Text($r('app.string.cook_steps')).fontSize(16).fontWeight(FontWeight.Bold).margin({ bottom: 12 })
        ForEach(this.recipe?.steps ?? [], (step: RecipeStep) => {
          Row() {
            Stack() {
              Circle()
                .width(28)
                .height(28)
                .fill(COLORS.PRIMARY)
              Text(step.stepNumber.toString())
                .fontSize(14)
                .fontColor(COLORS.WHITE)
            }
            .width(28)
            .height(28)
            Text(step.description)
              .fontSize(14)
              .fontColor(COLORS.TEXT_PRIMARY)
              .lineHeight(22)
              .margin({ left: 10 })
              .layoutWeight(1)
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)
          .margin({ bottom: 12 })
        }, (step: RecipeStep, i: number) => `step_${i}`)
      }
      .width('100%')
      .padding(16)
      .backgroundColor(COLORS.WHITE)
      .borderRadius(RADIUS.LG)
      .margin({ bottom: 12 })

      if ((this.recipe?.dietTags?.length ?? 0) > 0) {
        Column() {
          Text($r('app.string.suitable_persons')).fontSize(16).fontWeight(FontWeight.Bold).margin({ bottom: 8 })
          Row({ space: 8 }) {
            ForEach(this.recipe?.dietTags ?? [], (tag: DietTag) => {
              Text(getDietTagLabel(tag))
                .fontSize(12)
                .fontColor(COLORS.ACCENT_GREEN_4CAF)
                .backgroundColor(COLORS.BG_LIGHT_GREEN)
                .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                .borderRadius(12)
            }, (tag: DietTag) => tag)
          }
        }
        .width('100%')
        .padding(16)
        .backgroundColor(COLORS.WHITE)
        .borderRadius(RADIUS.LG)
        .margin({ bottom: 12 })
      }

      Row() {
        Text(`👩‍🍳 发布者：${this.recipe?.authorName ?? '未知作者'}`)
          .fontSize(13)
          .fontColor(COLORS.TEXT_GRAY_9E9E)
      }
      .width('100%')
      .padding(16)
    }
    .width('100%')
    .padding(16)
  }

  @Builder
  ingredientsColumn() {
    Column() {
      Row() {
        Text($r('app.string.ingredient_list')).fontSize(16).fontWeight(FontWeight.Bold).layoutWeight(1)
        Button('🛒 生成购物清单')
          .fontSize(12)
          .fontColor(COLORS.WHITE)
          .backgroundColor(COLORS.PRIMARY)
          .borderRadius(RADIUS.MD)
          .height(32)
          .padding({ left: 12, right: 12 })
          .onClick(() => { this.generateShoppingList() })
          .accessibilityText('生成购物清单')
          .accessibilityLevel('yes')
      }
      .width('100%')
      .margin({ bottom: 12 })
      ForEach(this.recipe?.ingredients ?? [], (ing: RecipeIngredient) => {
        Row() {
          Text('•').fontSize(14).fontColor(COLORS.PRIMARY).margin({ right: 8 })
          Text(ing.name).fontSize(14).fontWeight(FontWeight.Medium)
          Blank()
          Text(ing.amount).fontSize(13).fontColor(COLORS.TEXT_GRAY_6161)
        }
        .width('100%')
        .margin({ bottom: 6 })
        if (ing.alternative.length > 0) {
          Text(`可选替代：${ing.alternative}`)
            .fontSize(12)
            .fontColor(COLORS.TEXT_GRAY_9E9E)
            .margin({ left: 16, bottom: 6 })
        }
      }, (ing: RecipeIngredient, i: number) => `ing_${i}`)
    }
    .layoutWeight(1)
    .padding(16)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.LG)
    .margin({ bottom: 12 })
  }

  @Builder
  nutritionColumn() {
    Column() {
      Text($r('app.string.nutrition_per_serving')).fontSize(16).fontWeight(FontWeight.Bold).margin({ bottom: 12 })
      this.nutritionRow($r('app.string.recipe_detail_calories'), (this.recipe?.nutrition?.calories ?? 0).toString() + ' kcal')
      this.nutritionRow($r('app.string.recipe_detail_protein'), (this.recipe?.nutrition?.protein ?? 0).toString())
      this.nutritionRow($r('app.string.recipe_detail_fat'), (this.recipe?.nutrition?.fat ?? 0).toString())
      this.nutritionRow($r('app.string.recipe_detail_carbohydrate'), (this.recipe?.nutrition?.carbohydrate ?? 0).toString())
      this.nutritionRow($r('app.string.recipe_detail_sodium'), (this.recipe?.nutrition?.sodium ?? 0).toString())
      this.nutritionRow($r('app.string.recipe_detail_sugar'), (this.recipe?.nutrition?.sugar ?? 0).toString())
    }
    .layoutWeight(1)
    .padding(16)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.LG)
    .margin({ bottom: 12 })
  }

  @Builder
  nutritionRow(label: ResourceStr, value: string) {
    Row() {
      Text(label).fontSize(14).fontColor(COLORS.TEXT_SECONDARY)
      Blank()
      Text(value).fontSize(14).fontWeight(FontWeight.Medium)
    }
    .width('100%')
    .margin({ bottom: 6 })
  }

  @Builder
  commentSection() {
    Column() {
      // 评论输入区
      Row({ space: 8 }) {
        TextInput({ placeholder: $r('app.string.recipe_detail_comment_placeholder'), text: this.commentText })
          .layoutWeight(1)
          .height(40)
          .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
          .borderRadius(20)
          .padding({ left: 16 })
          .onChange((v: string) => { this.commentText = v })
          .accessibilityText('评论输入')
          .accessibilityLevel('yes')
        Button($r('app.string.recipe_detail_send'))
          .height(36)
          .backgroundColor(COLORS.PRIMARY)
          .borderRadius(18)
          .fontSize(13)
          .fontColor(COLORS.WHITE)
          .onClick(() => {
            if (this.commentText.trim().length === 0) return
            this.appState.addRecipeComment(this.recipeId, this.commentText.trim(), '').then(() => {
              this.commentText = ''
              this.appState.getRecipeComments(this.recipeId).then((comments: RecipeComment[]) => {
                this.comments = comments
                this.commentDS.reload(this.comments)
                ToastHelper.show(this.getUIContext(), $r('app.string.recipe_detail_comment_sent'))
              })
            })
          })
          .accessibilityText('发送评论')
          .accessibilityLevel('yes')
      }
      .width('100%')
      .padding(12)
      .backgroundColor(COLORS.WHITE)

      // 评论列表
      if (this.commentDS.totalCount() === 0) {
        Column() {
          Text($r('app.string.no_comments_yet'))
            .fontSize(14)
            .fontColor(COLORS.TEXT_GRAY_9E9E)
            .margin({ top: 40 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      } else {
        List() {
          LazyForEach(this.commentDS, (comment: RecipeComment) => {
            ListItem() {
              Column() {
                Row() {
                  Stack() {
                    Circle()
                      .width(32)
                      .height(32)
                      .fill(COLORS.BG_WARM_BLUE)
                    Text(comment.authorName.substring(0, 1))
                      .fontSize(14)
                      .fontColor(COLORS.PRIMARY)
                  }
                  .width(32)
                  .height(32)
                  Column() {
                    Text(comment.authorName)
                      .fontSize(13)
                      .fontWeight(FontWeight.Medium)
                    Text(formatTime(comment.createdAt))
                      .fontSize(11)
                      .fontColor(COLORS.TEXT_GRAY_9E9E)
                  }
                  .margin({ left: 10 })
                }
                .alignItems(VerticalAlign.Center)
                Text(comment.content)
                  .fontSize(14)
                  .fontColor(COLORS.TEXT_PRIMARY)
                  .lineHeight(22)
                  .margin({ top: 8, left: 42 })
              }
              .width('100%')
              .padding(12)
              .backgroundColor(COLORS.WHITE)
              .borderRadius(RADIUS.MD)
              .margin({ bottom: 8 })
            }
          }, (comment: RecipeComment) => `${comment.commentId}`)
        }
        .width('100%')
        .layoutWeight(1)
        .cachedCount(5)
      }
    }
    .width('100%')
  }

  aboutToDisappear(): void {
    this.tracker.onDisappear()
  }
}