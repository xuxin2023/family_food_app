// RecipeDetailPage.ets
// 食谱详情页面 — 详情、评论、点赞

import { router, promptAction } from '@kit.ArkUI';
import { BackButton } from '../components/BackButton';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppState } from '../AppState';
import { Recipe, RecipeComment, DietTag, RecipeIngredient, RecipeStep } from '../model/Recipe';
import { COLORS, RADIUS, BUTTON, FONT_SIZE, FONT_WEIGHT } from '../constants/AppTheme';
import { BasicDataSource } from '../utils/BasicDataSource';
import {
  getCategoryLabel,
  getCategoryEmoji,
  getDifficultyLabel,
  getDietTagLabel,
  formatTime
} from '../utils/RecipeUtil';
import { HILOG_DOMAIN } from '../constants/AppConfig';

const TAG = 'RecipeDetailPage';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

@Entry
@ComponentV2
struct RecipeDetailPage {
  @Local recipe: Recipe | null = null
  @Local hasLiked: boolean = false
  @Local hasBookmarked: boolean = false
  @Local isLoading: boolean = true
  @Local commentText: string = ''
  @Local selectedSection: string = 'detail'

  private appState: AppState = AppState.getInstance()
  private comments: RecipeComment[] = []
  private commentDS = new BasicDataSource<RecipeComment>()
  private recipeId: string = ''

  async aboutToAppear() {
    const params = router.getParams() as Record<string, Object>
    if (params) {
      this.recipeId = (params.recipeId as string) || ''
    }
    await this.loadRecipe()
  }

  async loadRecipe() {
    if (this.recipeId.length === 0) return
    this.isLoading = true
    try {
      this.recipe = await this.appState.getRecipeDetail(this.recipeId)
      if (this.recipe) {
        this.comments = await this.appState.getRecipeComments(this.recipeId)
        this.commentDS.reload(this.comments)
        this.hasLiked = await this.appState.hasLikedRecipe(this.recipeId)
      }
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'load error: %{public}s', JSON.stringify(e))
    }
    this.isLoading = false
  }

  build() {
    Column() {
      // 顶栏
      Row() {
        BackButton()
        Text($r('app.string.recipe_detail'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 12 })
      }
      .width('100%')
      .padding(16)

      if (this.isLoading) {
        LoadingProgress().width(32).height(32).margin({ top: 100 })
      } else if (!this.recipe) {
        Text($r('app.string.recipe_not_found')).fontSize(16).fontColor(COLORS.TEXT_GRAY_6161).margin({ top: 100 })
      } else {
        Scroll() {
          Column() {
            // 封面
            this.coverSection()

            // 基本信息
            this.infoSection()

            // Tab切换: 详情 / 评论
            Row({ space: 0 }) {
              this.sectionTab('食谱详情', 'detail')
              this.sectionTab('评论', 'comment')
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
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_PAGE)
  }

  @Builder
  coverSection() {
    Column() {
      Text(getCategoryEmoji(this.recipe!.category))
        .fontSize(72)
      Text(this.recipe!.title)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLORS.WHITE)
        .margin({ top: 16 })
      Text(getCategoryLabel(this.recipe!.category) + ' · ' + getDifficultyLabel(this.recipe!.difficulty))
        .fontSize(14)
        .fontColor(COLORS.WHITE)
        .opacity(0.8)
        .margin({ top: 8 })
    }
    .width('100%')
    .height(240)
    .backgroundColor(COLORS.PRIMARY)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  infoSection() {
    Row({ space: 0 }) {
      this.infoItem('⏱️', this.recipe!.totalMinutes.toString() + '分钟')
      this.infoItem('🍽️', this.recipe!.servings.toString() + '人份')
      this.infoItem('📝', this.recipe!.steps.length.toString() + '步')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(COLORS.WHITE)
    .margin({ bottom: 8 })

    // 互动按钮组
    Row({ space: 16 }) {
      Row({ space: 6 }) {
        Text(this.hasLiked ? '❤️' : '🤍').fontSize(20)
        Text(this.recipe!.likeCount.toString()).fontSize(14).fontColor(COLORS.TEXT_SECONDARY)
      }
      .onClick(() => {
        this.appState.toggleRecipeLike(this.recipeId).then((newState: boolean) => {
          // 本地乐观更新点赞数，避免全量刷新
          if (this.recipe) {
            if (newState !== this.hasLiked) {
              this.recipe.likeCount += newState ? 1 : -1
            }
          }
          this.hasLiked = newState
        })
      })
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
      .borderRadius(20)

      Row({ space: 6 }) {
        Text(this.hasBookmarked ? '🔖' : '🏷️').fontSize(20)
        Text($r('app.string.favorite')).fontSize(14).fontColor(COLORS.TEXT_SECONDARY)
      }
      .onClick(() => {
        this.appState.toggleRecipeBookmark(this.recipeId, '').then((result: boolean) => {
          this.hasBookmarked = result
          promptAction.showToast({ message: result ? '已收藏' : '已取消收藏' })
        })
      })
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
      .borderRadius(20)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(COLORS.WHITE)
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
  sectionTab(label: string, value: string) {
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
  }

  @Builder
  detailSection() {
    Column() {
      // 描述
      if (this.recipe!.description.length > 0) {
        Column() {
          Text($r('app.string.intro_label')).fontSize(16).fontWeight(FontWeight.Bold).margin({ bottom: 8 })
          Text(this.recipe!.description).fontSize(14).fontColor(COLORS.TEXT_SECONDARY).lineHeight(22)
        }
        .width('100%')
        .padding(16)
        .backgroundColor(COLORS.WHITE)
        .borderRadius(RADIUS.LG)
        .margin({ bottom: 12 })
      }

      // 食材
      Column() {
        Text($r('app.string.ingredient_list')).fontSize(16).fontWeight(FontWeight.Bold).margin({ bottom: 12 })
        ForEach(this.recipe!.ingredients, (ing: RecipeIngredient) => {
          Row() {
            Text('•').fontSize(14).fontColor(COLORS.PRIMARY).margin({ right: 8 })
            Text(ing.name).fontSize(14).fontWeight(FontWeight.Medium)
            Blank()
            Text(ing.amount).fontSize(13).fontColor(COLORS.TEXT_GRAY_6161)
          }
          .width('100%')
          .margin({ bottom: 6 })
          if (ing.alternative.length > 0) {
            Text('可选替代：' + ing.alternative)
              .fontSize(12)
              .fontColor(COLORS.TEXT_GRAY_9E9E)
              .margin({ left: 16, bottom: 6 })
          }
        })
      }
      .width('100%')
      .padding(16)
      .backgroundColor(COLORS.WHITE)
      .borderRadius(RADIUS.LG)
      .margin({ bottom: 12 })

      // 步骤
      Column() {
        Text($r('app.string.cook_steps')).fontSize(16).fontWeight(FontWeight.Bold).margin({ bottom: 12 })
        ForEach(this.recipe!.steps, (step: RecipeStep) => {
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
        })
      }
      .width('100%')
      .padding(16)
      .backgroundColor(COLORS.WHITE)
      .borderRadius(RADIUS.LG)
      .margin({ bottom: 12 })

      // 营养信息
      if (this.recipe!.nutrition) {
        Column() {
          Text($r('app.string.nutrition_per_serving')).fontSize(16).fontWeight(FontWeight.Bold).margin({ bottom: 12 })
          this.nutritionRow('热量', this.recipe!.nutrition!.calories.toString() + ' kcal')
          this.nutritionRow('蛋白质', this.recipe!.nutrition!.protein)
          this.nutritionRow('脂肪', this.recipe!.nutrition!.fat)
          this.nutritionRow('碳水化合物', this.recipe!.nutrition!.carbohydrate)
          this.nutritionRow('钠', this.recipe!.nutrition!.sodium)
          this.nutritionRow('糖', this.recipe!.nutrition!.sugar)
        }
        .width('100%')
        .padding(16)
        .backgroundColor(COLORS.WHITE)
        .borderRadius(RADIUS.LG)
        .margin({ bottom: 12 })
      }

      // 适配标签
      if (this.recipe!.dietTags.length > 0) {
        Column() {
          Text($r('app.string.suitable_persons')).fontSize(16).fontWeight(FontWeight.Bold).margin({ bottom: 8 })
          Row({ space: 8 }) {
            ForEach(this.recipe!.dietTags, (tag: DietTag) => {
              Text(getDietTagLabel(tag))
                .fontSize(12)
                .fontColor(COLORS.ACCENT_GREEN_4CAF)
                .backgroundColor(COLORS.BG_LIGHT_GREEN)
                .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                .borderRadius(12)
            })
          }
        }
        .width('100%')
        .padding(16)
        .backgroundColor(COLORS.WHITE)
        .borderRadius(RADIUS.LG)
        .margin({ bottom: 12 })
      }

      // 作者
      Row() {
        Text('👩‍🍳 发布者：' + this.recipe!.authorName)
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
  nutritionRow(label: string, value: string) {
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
        TextInput({ placeholder: '写下你的评论...', text: this.commentText })
          .layoutWeight(1)
          .height(40)
          .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
          .borderRadius(20)
          .padding({ left: 16 })
          .onChange((v: string) => { this.commentText = v })
        Button('发送')
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
                promptAction.showToast({ message: '评论已发送' })
              })
            })
          })
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
}