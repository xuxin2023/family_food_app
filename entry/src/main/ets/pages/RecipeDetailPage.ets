// RecipeDetailPage.ets
// 食谱详情页面 — 详情、评论、点赞

import {
  ToastHelper, getPageParams, Recipe, RecipeComment, DietTag, RecipeIngredient, RecipeStep, COLORS, RADIUS, BasicDataSource, HILOG_DOMAIN_DEFAULT, getCategoryLabel, getCategoryEmoji, getDifficultyLabel, getDietTagLabel, formatTime
} from 'hsp_core';
import { BackButton } from '../components/BackButton';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppState } from '../AppState';
import { LikeButton } from 'feature_community';


const TAG = 'RecipeDetailPage';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

@Entry
@ComponentV2
struct RecipeDetailPage {
  @Local recipe: Recipe | null = null
  @Local hasLiked: boolean = false
  @Local hasBookmarked: boolean = false
  @Local isLoading: boolean = true
  @Local commentText: string = ''
  @Local selectedSection: string = 'detail'
  @Local currentBreakpoint: string = 'md'

  private appState: AppState = AppState.getInstance()
  private comments: RecipeComment[] = []
  private commentDS = new BasicDataSource<RecipeComment>()
  private recipeId: string = ''

  async aboutToAppear() {
    const params = getPageParams()
    const raw = params !== undefined ? params.get('recipeId') : undefined;
    this.recipeId = (typeof raw === 'string' ? raw : '');
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

  build() {
    Column() {
      // 顶栏
      Row() {
        BackButton()
        .accessibilityText('返回')
        .accessibilityLevel('yes')
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
        GridRow({
          columns: { sm: 4, md: 8, lg: 12 },
          breakpoints: { reference: BreakpointsReference.WindowSize, breakpoints: ['320vp', '600vp'] } as BreakPoints
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
    Column() {
      Row({ space: 0 }) {
        this.infoItem('⏱️', `${this.recipe!.totalMinutes}分钟`)
        this.infoItem('🍽️', `${this.recipe!.servings}人份`)
        this.infoItem('📝', `${this.recipe!.steps.length}步`)
      }
      .width('100%')
      .padding(16)
      .backgroundColor(COLORS.WHITE)
      .margin({ bottom: 8 })

      Row({ space: 16 }) {
        LikeButton({
          isLiked: this.hasLiked,
          likeCount: this.recipe!.likeCount,
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
    .accessibilityText(label )
    .accessibilityLevel('yes')
  }

  @Builder
  detailSection() {
    Column() {
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

      if (this.currentBreakpoint === 'lg') {
        Row({ space: 12 }) {
          this.ingredientsColumn()
          if (this.recipe!.nutrition) {
            this.nutritionColumn()
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
      } else {
        this.ingredientsColumn()
        if (this.recipe!.nutrition) {
          this.nutritionColumn()
        }
      }

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
        }, (step: RecipeStep, i: number) => `step_${i}`)
      }
      .width('100%')
      .padding(16)
      .backgroundColor(COLORS.WHITE)
      .borderRadius(RADIUS.LG)
      .margin({ bottom: 12 })

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
        Text(`👩‍🍳 发布者：${this.recipe!.authorName}`)
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
      this.nutritionRow($r('app.string.recipe_detail_calories'), this.recipe!.nutrition!.calories.toString() + ' kcal')
      this.nutritionRow($r('app.string.recipe_detail_protein'), this.recipe!.nutrition!.protein.toString())
      this.nutritionRow($r('app.string.recipe_detail_fat'), this.recipe!.nutrition!.fat.toString())
      this.nutritionRow($r('app.string.recipe_detail_carbohydrate'), this.recipe!.nutrition!.carbohydrate.toString())
      this.nutritionRow($r('app.string.recipe_detail_sodium'), this.recipe!.nutrition!.sodium.toString())
      this.nutritionRow($r('app.string.recipe_detail_sugar'), this.recipe!.nutrition!.sugar.toString())
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

}