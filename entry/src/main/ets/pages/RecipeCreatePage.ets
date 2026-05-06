// RecipeCreatePage.ets
// 创建食谱页面 — 发布新食谱到社区

import { router, promptAction } from '@kit.ArkUI';
import { BackButton } from '../components/BackButton';
import { safeBack } from '../utils/RouterUtil';
import { AppState } from '../AppState';
import { RecipeCategory, RecipeDifficulty, DietTag, RecipeIngredient, RecipeStep } from '../model/Recipe';
import { COLORS, RADIUS, BUTTON } from '../constants/AppTheme';

class OptionItem {
  label: string = '';
  value: string = '';
  constructor(label: string, value: string) {
    this.label = label;
    this.value = value;
  }
}

const CATEGORY_OPTIONS: OptionItem[] = [
  new OptionItem('早餐', RecipeCategory.BREAKFAST),
  new OptionItem('午餐', RecipeCategory.LUNCH),
  new OptionItem('晚餐', RecipeCategory.DINNER),
  new OptionItem('零食', RecipeCategory.SNACK),
  new OptionItem('饮品', RecipeCategory.BEVERAGE),
  new OptionItem('甜品', RecipeCategory.DESSERT),
  new OptionItem('汤羹', RecipeCategory.SOUP),
  new OptionItem('主食', RecipeCategory.STAPLE)
];

const DIET_TAG_OPTIONS: OptionItem[] = [
  new OptionItem('儿童友好', DietTag.CHILD_FRIENDLY),
  new OptionItem('老人友好', DietTag.ELDER_FRIENDLY),
  new OptionItem('低钠', DietTag.LOW_SODIUM),
  new OptionItem('低糖', DietTag.LOW_SUGAR),
  new OptionItem('低脂', DietTag.LOW_FAT),
  new OptionItem('高蛋白', DietTag.HIGH_PROTEIN),
];

@Entry
@Component
struct RecipeCreatePage {
  @State title: string = ''
  @State description: string = ''
  @State category: RecipeCategory = RecipeCategory.SNACK
  @State difficulty: RecipeDifficulty = RecipeDifficulty.EASY
  @State totalMinutes: number = 30
  @State servings: number = 2
  @State ingredients: RecipeIngredient[] = [{ name: '', amount: '', alternative: '' }]
  @State steps: RecipeStep[] = [{ stepNumber: 1, description: '', imageUrl: '', durationMinutes: 0 }]
  @State selectedDietTags: DietTag[] = []
  @State showCategoryPicker: boolean = false
  @State showDifficultyPicker: boolean = false

  private appState: AppState = AppState.getInstance()
  private relatedFoodId: string = ''

  async aboutToAppear() {
    const params = router.getParams() as Record<string, Object>
    if (params && (params.relatedFoodId as string)) {
      this.relatedFoodId = params.relatedFoodId as string
    }
  }

  build() {
    Column() {
      // 顶栏
      Row() {
        BackButton({ fontSize: 24, fontColor: COLORS.PRIMARY })
          .onClick(() => { safeBack() })
        Text($r('app.string.create_recipe'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 12 })
        Blank()
        Text($r('app.string.save'))
          .fontSize(15)
          .fontColor(COLORS.PRIMARY)
          .fontWeight(FontWeight.Bold)
          .onClick(() => { this.handlePublish() })
      }
      .width('100%')
      .padding(16)

      Scroll() {
        Column() {
          // 基本信息
          this.sectionHeader('基本信息')
          this.formCard()

          // 食材
          this.sectionHeader('食材清单')
          this.ingredientsCard()

          // 步骤
          this.sectionHeader('烹饪步骤')
          this.stepsCard()

          // 适配标签
          this.sectionHeader('适合人群（可多选）')
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
    .backgroundColor(COLORS.BG_PAGE)
  }

  @Builder
  sectionHeader(title: string) {
    Text(title)
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .width('100%')
      .margin({ top: 16, bottom: 8 })
  }

  @Builder
  formCard() {
    Column() {
      TextInput({ placeholder: '食谱名称', text: this.title })
        .width('100%')
        .height(48)
        .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
        .borderRadius(12)
        .padding({ left: 16 })
        .onChange((v: string) => { this.title = v })

      TextArea({ placeholder: '简单描述一下这个食谱（可选）', text: this.description })
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
        }
        .layoutWeight(1)
        .padding(10)
        .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
        .borderRadius(10)
        .alignItems(HorizontalAlign.Center)

        Column() {
          Text($r('app.string.difficulty_label')).fontSize(12).fontColor(COLORS.TEXT_GRAY_9E9E)
          Text(this.getDifficultyLabel(this.difficulty))
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .onClick(() => { this.showDifficultyPicker = true })
        }
        .layoutWeight(1)
        .padding(10)
        .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
        .borderRadius(10)
        .alignItems(HorizontalAlign.Center)

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
  }

  @Builder
  ingredientsCard() {
    Column() {
      ForEach(this.ingredients, (ing: RecipeIngredient, index: number) => {
        Row({ space: 8 }) {
          TextInput({ placeholder: '食材名', text: ing.name })
            .layoutWeight(3)
            .height(40)
            .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
            .borderRadius(10)
            .padding({ left: 12 })
            .onChange((v: string) => { this.ingredients[index].name = v })
          TextInput({ placeholder: '用量', text: ing.amount })
            .layoutWeight(2)
            .height(40)
            .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
            .borderRadius(10)
            .padding({ left: 12 })
            .onChange((v: string) => { this.ingredients[index].amount = v })
          if (this.ingredients.length > 1) {
            Text('✕')
              .fontSize(18)
              .fontColor(COLORS.ERROR)
              .onClick(() => {
                this.ingredients.splice(index, 1)
                this.ingredients = [...this.ingredients]
              })
          }
        }
        .width('100%')
        .margin({ bottom: 8 })
      })

      Text('+ 添加食材')
        .fontSize(13)
        .fontColor(COLORS.PRIMARY)
        .margin({ top: 4 })
        .onClick(() => {
          this.ingredients.push({ name: '', amount: '', alternative: '' })
          this.ingredients = [...this.ingredients]
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.LG)
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
            Text(`步骤 ${index + 1}`)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .margin({ left: 8 })
            Blank()
            if (this.steps.length > 1) {
              Text('删除')
                .fontSize(12)
                .fontColor(COLORS.ERROR)
                .onClick(() => {
                  this.steps.splice(index, 1)
                  this.steps = [...this.steps]
                })
            }
          }
          .width('100%')

          TextArea({
            placeholder: '描述这一步的操作...',
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
              placeholder: '预计用时(分钟)',
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
          }
          .width('100%')
          .margin({ top: 8 })
        }
        .width('100%')
        .padding(12)
        .backgroundColor(COLORS.BG_PAGE_LIGHT)
        .borderRadius(12)
        .margin({ bottom: 10 })
      })

      Text('+ 添加步骤')
        .fontSize(13)
        .fontColor(COLORS.PRIMARY)
        .margin({ top: 4 })
        .onClick(() => {
          this.steps.push({
            stepNumber: this.steps.length + 1,
            description: '',
            imageUrl: '',
            durationMinutes: 0
          })
          this.steps = [...this.steps]
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.LG)
  }

  @Builder
  dietTagsCard() {
    Column() {
      Row({ space: 8 }) {
        ForEach(DIET_TAG_OPTIONS, (option: OptionItem) => {
          Text(option.label)
            .fontSize(13)
            .fontColor(this.selectedDietTags.includes(option.value as DietTag) ? COLORS.WHITE : COLORS.ACCENT_GREEN_4CAF)
            .backgroundColor(this.selectedDietTags.includes(option.value as DietTag) ? COLORS.ACCENT_GREEN : COLORS.BG_LIGHT_GREEN)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .borderRadius(16)
            .onClick(() => {
              const tag = option.value as DietTag
              const idx = this.selectedDietTags.indexOf(tag)
              if (idx >= 0) {
                this.selectedDietTags.splice(idx, 1)
              } else {
                this.selectedDietTags.push(tag)
              }
              this.selectedDietTags = [...this.selectedDietTags]
            })
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.LG)
  }

  private getCategoryLabel(value: RecipeCategory): string {
    for (const opt of CATEGORY_OPTIONS) {
      if (opt.value === value) {
        return opt.label
      }
    }
    return value
  }

  private getDifficultyLabel(value: RecipeDifficulty): string {
    const difficultyMap: Map<string, string> = new Map()
    difficultyMap.set('easy', '简单')
    difficultyMap.set('medium', '中等')
    difficultyMap.set('hard', '困难')
    return difficultyMap.get(value) || value
  }

  private async handlePublish() {
    if (this.title.trim().length === 0) {
      promptAction.showToast({ message: '请输入食谱名称' })
      return
    }
    if (this.ingredients.length === 0 || this.ingredients.every(i => i.name.length === 0)) {
      promptAction.showToast({ message: '请至少添加一个食材' })
      return
    }
    if (this.steps.length === 0 || this.steps.every(s => s.description.length === 0)) {
      promptAction.showToast({ message: '请至少添加一个步骤' })
      return
    }

    try {
      const validIngredients = this.ingredients.filter(i => i.name.length > 0)
      const validSteps: RecipeStep[] = this.steps
        .filter(s => s.description.length > 0)
        .map((s, idx) => {
          const step: RecipeStep = {
            stepNumber: idx + 1,
            description: s.description,
            imageUrl: s.imageUrl,
            durationMinutes: s.durationMinutes
          }
          return step
        })

      await this.appState.publishRecipe({
        title: this.title.trim(),
        description: this.description.trim(),
        coverImageUrl: '',
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

      promptAction.showToast({ message: '食谱发布成功！' })
      safeBack()
    } catch (e) {
      promptAction.showToast({ message: `发布失败：${(e as Error).message}` })
    }
  }
}
