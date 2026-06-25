// RecipeCreatePage.ets
// 创建食谱页面 — 发布新食谱到社区

import {
  ToastHelper, safeBack, getPageParams, RecipeCategory, RecipeDifficulty, DietTag, RecipeIngredient, RecipeStep, COLORS, SHADOWS, RADIUS, safeParseDietTag,
  HapticHelper, PageResourceTracker, createPageTracker, ThemeReactive, themeReactive, ThemeColors, ThemeMode, HILOG_DOMAIN_DEFAULT
} from 'hsp_core';
import { BackButton } from '../components/BackButton';
import { GradientHeader } from '../components/GradientHeader';
import { AppState } from '../AppState';
import { LoadingSkeleton } from '../components/SkeletonScreen';
import { picker } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { CommunityImageService, ImageUploadResult } from 'feature_community';

const RCP_TAG = 'RecipeCreatePage';
const RCP_DOMAIN = HILOG_DOMAIN_DEFAULT;

class OptionItem {
  label: ResourceStr = '';
  value: string = '';
  constructor(label: ResourceStr, value: string) {
    this.label = label;
    this.value = value;
  }
}

const CATEGORY_OPTIONS: OptionItem[] = [
  new OptionItem($r('app.string.recipe_create_cat_breakfast'), RecipeCategory.BREAKFAST),
  new OptionItem($r('app.string.recipe_create_cat_lunch'), RecipeCategory.LUNCH),
  new OptionItem($r('app.string.recipe_create_cat_dinner'), RecipeCategory.DINNER),
  new OptionItem($r('app.string.recipe_create_cat_snack'), RecipeCategory.SNACK),
  new OptionItem($r('app.string.recipe_create_cat_beverage'), RecipeCategory.BEVERAGE),
  new OptionItem($r('app.string.recipe_create_cat_dessert'), RecipeCategory.DESSERT),
  new OptionItem($r('app.string.recipe_create_cat_soup'), RecipeCategory.SOUP),
  new OptionItem($r('app.string.recipe_create_cat_staple'), RecipeCategory.STAPLE)
];

const DIFFICULTY_LABEL_MAP: Map<string, ResourceStr> = new Map();
DIFFICULTY_LABEL_MAP.set('easy', $r('app.string.recipe_create_diff_easy'));
DIFFICULTY_LABEL_MAP.set('medium', $r('app.string.recipe_create_diff_medium'));
DIFFICULTY_LABEL_MAP.set('hard', $r('app.string.recipe_create_diff_hard'));

const DIFFICULTY_OPTIONS: OptionItem[] = [
  new OptionItem($r('app.string.recipe_create_diff_easy'), 'easy'),
  new OptionItem($r('app.string.recipe_create_diff_medium'), 'medium'),
  new OptionItem($r('app.string.recipe_create_diff_hard'), 'hard')
];

const DIET_TAG_OPTIONS: OptionItem[] = [
  new OptionItem($r('app.string.recipe_create_tag_child_friendly'), DietTag.CHILD_FRIENDLY),
  new OptionItem($r('app.string.recipe_create_tag_elder_friendly'), DietTag.ELDER_FRIENDLY),
  new OptionItem($r('app.string.recipe_create_tag_low_sodium'), DietTag.LOW_SODIUM),
  new OptionItem($r('app.string.recipe_create_tag_low_sugar'), DietTag.LOW_SUGAR),
  new OptionItem($r('app.string.recipe_create_tag_low_fat'), DietTag.LOW_FAT),
  new OptionItem($r('app.string.recipe_create_tag_high_protein'), DietTag.HIGH_PROTEIN),
];

@Entry
@ComponentV2
export struct RecipeCreatePage {
  @Local title: string = ''
  @Local description: string = ''
  @Local category: RecipeCategory = RecipeCategory.SNACK
  @Local difficulty: RecipeDifficulty = RecipeDifficulty.EASY
  @Local totalMinutes: number = 30
  @Local servings: number = 2
  @Local ingredients: RecipeIngredient[] = (() => { const i = new RecipeIngredient(); return [i]; })()
  @Local steps: RecipeStep[] = (() => { const s = new RecipeStep(); s.stepNumber = 1; return [s]; })()
  @Local selectedDietTags: DietTag[] = []
  @Local showCategoryPicker: boolean = false
  @Local showDifficultyPicker: boolean = false
  @Local isLoading: boolean = false
  @Local coverImageUrl: string = ''
  @Local isUploadingImage: boolean = false

  private appState: AppState = AppState.getInstance()
  private relatedFoodId: string = ''
  private tracker: PageResourceTracker = createPageTracker('RecipeCreatePage')

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
    this.isLoading = true;
    try {
    const params = getPageParams()
    const raw = params !== undefined ? params.get('relatedFoodId') : undefined;
    const relatedFoodId = typeof raw === 'string' ? raw : '';
    if (relatedFoodId) {
      this.relatedFoodId = relatedFoodId
    }
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    if (this.isLoading) {
      Column() {
        LoadingSkeleton({ variant: 'card' })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .opacity(this.themeRef.key >= 0 ? 1 : 1)
    } else {
    Column() {
      // 顶栏
      GradientHeader({
        title: $r('app.string.create_recipe'),
        rightText: '保存',
        onRightClick: () => { this.handlePublish() }
      })

      Scroll() {
        Column() {
          // 基本信息
          this.sectionHeader($r('app.string.recipe_create_section_basic_info'))
          this.formCard()

          // 食材
          this.sectionHeader($r('app.string.recipe_create_section_ingredients'))
          this.ingredientsCard()

          // 步骤
          this.sectionHeader($r('app.string.recipe_create_section_steps'))
          this.stepsCard()

          // 适配标签
          this.sectionHeader($r('app.string.recipe_create_section_diet_tags'))
          this.dietTagsCard()

          // 底部间距
          Blank().height(40)
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .linearGradient(this.pageBgGradient)
    .opacity(this.themeRef.key >= 0 ? 1 : 1)
    }
  }

  @Builder
  sectionHeader(title: ResourceStr) {
    Text(title)
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .width('100%')
      .margin({ top: 16, bottom: 8 })
  }

  @Builder
  formCard() {
    Column() {
      // 封面图片选择
      Row({ space: 12 }) {
        Stack() {
          if (this.coverImageUrl.length > 0) {
            Image(this.coverImageUrl)
              .width(80)
              .height(80)
              .borderRadius(12)
              .objectFit(ImageFit.Cover)
          } else {
            Column() {
              Text('📷')
                .fontSize(28)
              Text('添加封面')
                .fontSize(11)
                .fontColor(COLORS.TEXT_GRAY_9E9E)
                .margin({ top: 4 })
            }
            .width(80)
            .height(80)
            .borderRadius(12)
            .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          }
          if (this.isUploadingImage) {
            LoadingProgress()
              .width(24)
              .height(24)
              .color(COLORS.PRIMARY)
          }
        }
        .width(80)
        .height(80)
        .onClick(() => { this.pickCoverImage() })
        .accessibilityText('选择封面图片')
        .accessibilityLevel('yes')

        if (this.coverImageUrl.length > 0) {
          Text('更换封面')
            .fontSize(12)
            .fontColor(COLORS.PRIMARY)
            .onClick(() => { this.pickCoverImage() })
            .accessibilityText('更换封面图片')
            .accessibilityLevel('yes')
        }
        Blank()
        if (this.coverImageUrl.length > 0) {
          Text('✕')
            .fontSize(16)
            .fontColor(COLORS.TEXT_GRAY_9E9E)
            .onClick(() => { this.coverImageUrl = '' })
            .accessibilityText('移除封面图片')
            .accessibilityLevel('yes')
        }
      }
      .width('100%')
      .margin({ bottom: 12 })

      TextInput({ placeholder: $r('app.string.recipe_create_placeholder_recipe_name'), text: this.title })
        .width('100%')
        .height(48)
        .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
        .borderRadius(12)
        .padding({ left: 16 })
        .onChange((v: string) => { this.title = v })
        .accessibilityText('食谱名称')
        .accessibilityLevel('yes')

      TextArea({ placeholder: $r('app.string.recipe_create_placeholder_description'), text: this.description })
        .width('100%')
        .height(80)
        .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
        .borderRadius(12)
        .padding(16)
        .margin({ top: 10 })
        .onChange((v: string) => { this.description = v })

      Row({ space: 10 }) {
        Column() {
          Text($r('app.string.category_label')).fontSize(12).fontColor(COLORS.TEXT_GRAY_9E9E)
          Text(this.getCategoryLabel(this.category))
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .onClick(() => { this.showCategoryPicker = true })
            .accessibilityText('选择分类')
            .accessibilityLevel('yes')
        }
        .layoutWeight(1)
        .padding(10)
        .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
        .borderRadius(10)
        .alignItems(HorizontalAlign.Center)
        .bindSheet($$this.showCategoryPicker, this.categoryPickerContent(), {
          height: '50%',
          dragBar: true,
          backgroundColor: COLORS.BG_CARD
        })

        Column() {
          Text($r('app.string.difficulty_label')).fontSize(12).fontColor(COLORS.TEXT_GRAY_9E9E)
          Text(this.getDifficultyLabel(this.difficulty))
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .onClick(() => { this.showDifficultyPicker = true })
            .accessibilityText('选择难度')
            .accessibilityLevel('yes')
        }
        .layoutWeight(1)
        .padding(10)
        .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
        .borderRadius(10)
        .alignItems(HorizontalAlign.Center)
        .bindSheet($$this.showDifficultyPicker, this.difficultyPickerContent(), {
          height: '35%',
          dragBar: true,
          backgroundColor: COLORS.BG_CARD
        })

        Column() {
          Text($r('app.string.cook_time_label')).fontSize(12).fontColor(COLORS.TEXT_GRAY_9E9E)
          TextInput({ placeholder: '30', text: `${this.totalMinutes}` })
            .width('100%')
            .height(40)
            .backgroundColor(Color.Transparent)
            .textAlign(TextAlign.Center)
            .type(InputType.Number)
            .onChange((v: string) => {
              this.totalMinutes = parseInt(v) || 30
            })
            .accessibilityText('烹饪时间(分钟)')
            .accessibilityLevel('yes')
        }
        .layoutWeight(1)
        .padding(10)
        .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
        .borderRadius(10)
        .alignItems(HorizontalAlign.Center)

        Column() {
          Text($r('app.string.servings_label')).fontSize(12).fontColor(COLORS.TEXT_GRAY_9E9E)
          TextInput({ placeholder: '2', text: `${this.servings}` })
            .width('100%')
            .height(40)
            .backgroundColor(Color.Transparent)
            .textAlign(TextAlign.Center)
            .type(InputType.Number)
            .onChange((v: string) => {
              this.servings = parseInt(v) || 2
            })
            .accessibilityText('份数')
            .accessibilityLevel('yes')
        }
        .layoutWeight(1)
        .padding(10)
        .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
        .borderRadius(10)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .margin({ top: 10 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.LG)
    .shadow(SHADOWS.MD)
  }

  @Builder
  ingredientsCard() {
    Column() {
      ForEach(this.ingredients, (ing: RecipeIngredient, index: number) => {
        Row({ space: 8 }) {
          TextInput({ placeholder: $r('app.string.recipe_create_placeholder_ingredient_name'), text: ing.name })
            .layoutWeight(3)
            .height(40)
            .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
            .borderRadius(10)
            .padding({ left: 12 })
            .onChange((v: string) => { this.ingredients[index].name = v })
            .accessibilityText('食材名称')
            .accessibilityLevel('yes')
          TextInput({ placeholder: $r('app.string.recipe_create_placeholder_ingredient_amount'), text: ing.amount })
            .layoutWeight(2)
            .height(40)
            .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
            .borderRadius(10)
            .padding({ left: 12 })
            .onChange((v: string) => { this.ingredients[index].amount = v })
            .accessibilityText('食材用量')
            .accessibilityLevel('yes')
          if (this.ingredients.length > 1) {
            Text('✕')
              .fontSize(18)
              .fontColor(COLORS.ERROR)
              .onClick(() => {
                this.ingredients = this.ingredients.filter((_: RecipeIngredient, i: number) => i !== index)
              })
              .accessibilityText('删除食材')
              .accessibilityLevel('yes')
          }
        }
        .width('100%')
        .margin({ bottom: 8 })
      }, (ing: RecipeIngredient, index: number) => index.toString())

      Text($r('app.string.recipe_create_btn_add_ingredient'))
        .fontSize(13)
        .fontColor(COLORS.PRIMARY)
        .margin({ top: 4 })
        .onClick(() => {
          this.ingredients = [...this.ingredients, new RecipeIngredient()]
        })
        .accessibilityText('添加食材')
        .accessibilityLevel('yes')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.LG)
    .shadow(SHADOWS.MD)
  }

  @Builder
  stepsCard() {
    Column() {
      ForEach(this.steps, (step: RecipeStep, index: number) => {
        Column() {
          Row() {
            Stack() {
              Circle()
                .width(24)
                .height(24)
                .fill(COLORS.PRIMARY)
              Text(`${index + 1}`)
                .fontSize(12)
                .fontColor(COLORS.WHITE)
            }
            .width(24)
            .height(24)
            Text() { Span($r('app.string.recipe_create_label_step')); Span(` ${index + 1}`) }
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .margin({ left: 8 })
            Blank()
            if (this.steps.length > 1) {
              Text($r('app.string.recipe_create_btn_delete'))
                .fontSize(12)
                .fontColor(COLORS.ERROR)
                .onClick(() => {
                  this.steps.splice(index, 1)
                  this.steps = [...this.steps]
                })
                .accessibilityText('删除步骤')
                .accessibilityLevel('yes')
            }
          }
          .width('100%')

          TextArea({
            placeholder: $r('app.string.recipe_create_placeholder_step_desc'),
            text: step.description
          })
            .width('100%')
            .height(80)
            .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
            .borderRadius(10)
            .padding(12)
            .margin({ top: 8 })
            .onChange((v: string) => { this.steps[index].description = v })

          Row() {
            Text('⏱️').fontSize(14)
            TextInput({
              placeholder: $r('app.string.recipe_create_placeholder_duration'),
              text: step.durationMinutes > 0 ? `${step.durationMinutes}` : ''
            })
              .width(120)
              .height(36)
              .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
              .borderRadius(8)
              .padding({ left: 12 })
              .type(InputType.Number)
              .onChange((v: string) => {
                this.steps[index].durationMinutes = parseInt(v) || 0
              })
              .accessibilityText('步骤时长(分钟)')
              .accessibilityLevel('yes')
          }
          .width('100%')
          .margin({ top: 8 })
        }
        .width('100%')
        .padding(12)
        .backgroundColor(COLORS.BG_PAGE_LIGHT)
        .borderRadius(12)
        .margin({ bottom: 10 })
      }, (step: RecipeStep, index: number) => index.toString())

      Text($r('app.string.recipe_create_btn_add_step'))
        .fontSize(13)
        .fontColor(COLORS.PRIMARY)
        .margin({ top: 4 })
        .onClick(() => {
          const newStep: RecipeStep = new RecipeStep()
          newStep.stepNumber = this.steps.length + 1
          this.steps.push(newStep)
          this.steps = [...this.steps]
        })
        .accessibilityText('添加步骤')
        .accessibilityLevel('yes')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.LG)
    .shadow(SHADOWS.MD)
  }

  @Builder
  dietTagsCard() {
    Column() {
      Row({ space: 8 }) {
        ForEach(DIET_TAG_OPTIONS, (option: OptionItem) => {
          Text(option.label)
            .fontSize(13)
            .fontColor(this.selectedDietTags.includes(safeParseDietTag(option.value)) ? COLORS.WHITE : COLORS.ACCENT_GREEN_4CAF)
            .backgroundColor(this.selectedDietTags.includes(safeParseDietTag(option.value)) ? COLORS.ACCENT_GREEN : COLORS.BG_LIGHT_GREEN)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .borderRadius(RADIUS.LG)
            .onClick(() => {
              const tag = safeParseDietTag(option.value)
              const idx = this.selectedDietTags.indexOf(tag)
              if (idx >= 0) {
                this.selectedDietTags.splice(idx, 1)
              } else {
                this.selectedDietTags.push(tag)
              }
              this.selectedDietTags = [...this.selectedDietTags]
            })
            .accessibilityText(option.label as string)
            .accessibilityLevel('yes')
        }, (option: OptionItem, i: number) => `tag_${i}`)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.LG)
    .shadow(SHADOWS.MD)
  }

  private getCategoryLabel(value: RecipeCategory): ResourceStr {
    for (const opt of CATEGORY_OPTIONS) {
      if (opt.value === value) {
        return opt.label
      }
    }
    return value
  }

  private getDifficultyLabel(value: RecipeDifficulty): ResourceStr {
    return DIFFICULTY_LABEL_MAP.get(value) || value
  }

  @Builder
  categoryPickerContent() {
    Column() {
      Text('选择分类')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLORS.TEXT_PRIMARY)
        .padding({ top: 16, bottom: 8 })

      ForEach(CATEGORY_OPTIONS, (opt: OptionItem) => {
        Row() {
          Text(opt.label)
            .fontSize(15)
            .fontColor(this.category === opt.value ? COLORS.PRIMARY : COLORS.TEXT_PRIMARY)
          Blank()
          if (this.category === opt.value) {
            Text('\u2713')
              .fontSize(16)
              .fontColor(COLORS.PRIMARY)
          }
        }
        .width('100%')
        .padding({ left: 24, right: 24, top: 14, bottom: 14 })
        .onClick(() => {
          this.category = opt.value as RecipeCategory
          this.showCategoryPicker = false
        })
        .accessibilityText('选择' + (typeof opt.label === 'string' ? opt.label : ''))
        .accessibilityLevel('yes')
      }, (opt: OptionItem) => opt.value)
    }
    .width('100%')
    .backgroundColor(COLORS.BG_CARD)
    .padding({ bottom: 34 })
  }

  @Builder
  difficultyPickerContent() {
    Column() {
      Text('选择难度')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLORS.TEXT_PRIMARY)
        .padding({ top: 16, bottom: 8 })

      ForEach(DIFFICULTY_OPTIONS, (opt: OptionItem) => {
        Row() {
          Text(opt.label)
            .fontSize(15)
            .fontColor(this.difficulty === opt.value ? COLORS.PRIMARY : COLORS.TEXT_PRIMARY)
          Blank()
          if (this.difficulty === opt.value) {
            Text('\u2713')
              .fontSize(16)
              .fontColor(COLORS.PRIMARY)
          }
        }
        .width('100%')
        .padding({ left: 24, right: 24, top: 14, bottom: 14 })
        .onClick(() => {
          this.difficulty = opt.value as RecipeDifficulty
          this.showDifficultyPicker = false
        })
        .accessibilityText('选择' + (typeof opt.label === 'string' ? opt.label : ''))
        .accessibilityLevel('yes')
      }, (opt: OptionItem) => opt.value)
    }
    .width('100%')
    .backgroundColor(COLORS.BG_CARD)
    .padding({ bottom: 34 })
  }

  private async pickCoverImage(): Promise<void> {
    if (this.isUploadingImage) return
    HapticHelper.medium()
    try {
      const photoSelectOptions: picker.PhotoSelectOptions = new picker.PhotoSelectOptions()
      photoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE
      photoSelectOptions.maxSelectNumber = 1
      const photoViewPicker: picker.PhotoViewPicker = new picker.PhotoViewPicker()
      const photoSelectResult = await photoViewPicker.select(photoSelectOptions)
      if (!photoSelectResult.photoUris || photoSelectResult.photoUris.length === 0) {
        return
      }
      const localUri = photoSelectResult.photoUris[0]
      this.isUploadingImage = true

      const ctx = AppStorage.get<common.Context>('appContext')
      if (ctx) {
        CommunityImageService.getInstance().init(ctx)
      }

      try {
        const uploadResult: ImageUploadResult = await CommunityImageService.getInstance().uploadImage(localUri, 'recipe_cover')
        if (uploadResult.url.length > 0) {
          this.coverImageUrl = uploadResult.url
        } else {
          this.coverImageUrl = localUri
        }
      } catch (uploadErr) {
        hilog.warn(RCP_DOMAIN, RCP_TAG, 'Cover upload failed, using local URI: %{public}s', JSON.stringify(uploadErr))
        this.coverImageUrl = localUri
      }
    } catch (e) {
      hilog.warn(RCP_DOMAIN, RCP_TAG, 'pickCoverImage failed: %{public}s', JSON.stringify(e))
    }
    this.isUploadingImage = false
  }

  private async handlePublish() {
    HapticHelper.medium()
    if (this.title.trim().length === 0) {
      ToastHelper.show(this.getUIContext(), $r('app.string.recipe_create_toast_enter_name'))
      return
    }
    if (this.ingredients.length === 0 || this.ingredients.every(i => i.name.length === 0)) {
      ToastHelper.show(this.getUIContext(), $r('app.string.recipe_create_toast_add_ingredient'))
      return
    }
    if (this.steps.length === 0 || this.steps.every(s => s.description.length === 0)) {
      ToastHelper.show(this.getUIContext(), $r('app.string.recipe_create_toast_add_step'))
      return
    }

    try {
      const validIngredients = this.ingredients.filter(i => i.name.length > 0)
      const validSteps: RecipeStep[] = this.steps
        .filter(s => s.description.length > 0)
        .map((s, idx) => {
          const step: RecipeStep = new RecipeStep()
          step.stepNumber = idx + 1
          step.description = s.description
          step.imageUrl = s.imageUrl
          step.durationMinutes = s.durationMinutes
          return step
        })

      await this.appState.publishRecipe({
        title: this.title.trim(),
        description: this.description.trim(),
        coverImageUrl: this.coverImageUrl,
        category: this.category,
        difficulty: this.difficulty,
        totalMinutes: this.totalMinutes,
        servings: this.servings,
        ingredients: validIngredients,
        steps: validSteps,
        nutrition: null,
        dietTags: this.selectedDietTags,
        relatedFoodId: this.relatedFoodId,
        fromGroupId: '',
        isDraft: false
      })

      ToastHelper.show(this.getUIContext(), $r('app.string.recipe_create_toast_publish_success'))
      safeBack()
    } catch (e) {
      ToastHelper.show(this.getUIContext(), `发布失败：${(e as Error).message}`)
    }
  }

  aboutToDisappear(): void {
    this.tracker.onDisappear()
  }

  pageTransition() {
    PageTransitionEnter({ duration: 350, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 250, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
  }
}