import { safeBack, COLORS, HILOG_DOMAIN_DEFAULT, PageResourceTracker, createPageTracker } from 'hsp_core';
import { BackButton } from '../components/BackButton';
import { AppState } from '../AppState';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'AllergenSetupWizard';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

const COMMON_ALLERGENS: string[] = [
  '牛奶', '鸡蛋', '花生', '坚果', '大豆', '小麦', '鱼', '甲壳类',
  '芝麻', '芹菜', '芥末', '羽扇豆', '软体动物', '二氧化硫'
];

const COMMON_INTOLERANCES: string[] = [
  '乳糖不耐受', '麸质不耐受', '组胺不耐受', '果糖不耐受',
  '水杨酸敏感', '亚硫酸盐敏感', '味精敏感'
];

const AGE_GROUP_OPTIONS: string[] = [
  '婴幼儿(0-3岁)', '儿童(4-12岁)', '青少年(13-17岁)',
  '成人(18-59岁)', '老年人(60+岁)', '孕期', '哺乳期'
];

const HEALTH_GOAL_OPTIONS: string[] = [
  '控盐', '控糖', '低脂', '减重', '增肌',
  '儿童营养', '孕期安全', '老年保健', '慢性病管理'
];

@Entry
@ComponentV2
export struct AllergenSetupWizard {
  @Local currentStep: number = 0
  @Local selectedAgeGroup: string = ''
  @Local selectedGoals: string[] = []
  @Local selectedAllergens: string[] = []
  @Local selectedIntolerances: string[] = []
  @Local customAllergen: string = ''
  @Local customIntolerance: string = ''
  @Local isLoading: boolean = false
  @Local isComplete: boolean = false

  private appState: AppState = AppState.getInstance()
  private readonly TOTAL_STEPS: number = 4

  private tracker: PageResourceTracker = createPageTracker('AllergenSetupWizard')

  aboutToAppear(): void {
    this.tracker.onAppear()
  }


  build() {
    Column() {
      Row() {
        if (this.currentStep > 0 && !this.isComplete) {
          BackButton({ fontSize: 24, fontColor: COLORS.PRIMARY })
            .onClick(() => { this.currentStep-- })
            .accessibilityText('上一步')
            .accessibilityLevel('yes')
        }
        Blank()
        Text('健康档案配置')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 8 })

      if (!this.isComplete) {
        Row() {
          ForEach(Array.from({ length: this.TOTAL_STEPS }, (_, i: number) => i), (step: number) => {
            Row()
              .width(step <= this.currentStep ? '25%' : '25%')
              .height(4)
              .backgroundColor(step <= this.currentStep ? COLORS.PRIMARY : '#E0E0E0')
              .borderRadius(2)
          }, (step: number) => `${step}`)
        }
        .width('92%')
        .margin({ bottom: 16 })

        Text(this.stepTitle())
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .width('92%')
          .margin({ bottom: 8 })

        Text(this.stepDescription())
          .fontSize(13)
          .fontColor(COLORS.TEXT_GRAY_7575)
          .width('92%')
          .margin({ bottom: 16 })
      }

      Scroll() {
        Column() {
          if (this.isComplete) {
            this.buildCompleteStep()
          } else if (this.currentStep === 0) {
            this.buildAgeStep()
          } else if (this.currentStep === 1) {
            this.buildGoalStep()
          } else if (this.currentStep === 2) {
            this.buildAllergenStep()
          } else if (this.currentStep === 3) {
            this.buildIntoleranceStep()
          }
        }
        .width('92%')
      }
      .layoutWeight(1)

      if (!this.isComplete) {
        Row() {
          if (this.currentStep > 0) {
            Button('上一步')
              .layoutWeight(1)
              .height(44)
              .backgroundColor('#F0F0F0')
              .fontColor(COLORS.TEXT_GRAY_3333)
              .borderRadius(22)
              .margin({ right: 8 })
              .onClick(() => { this.currentStep-- })
          }
          Button(this.currentStep === this.TOTAL_STEPS - 1 ? '完成配置' : '下一步')
            .layoutWeight(1)
            .height(44)
            .backgroundColor(COLORS.PRIMARY)
            .fontColor(COLORS.WHITE)
            .borderRadius(22)
            .margin({ left: this.currentStep > 0 ? 8 : 0 })
            .enabled(this.canProceed())
            .onClick(() => {
              if (this.currentStep === this.TOTAL_STEPS - 1) {
                this.completeWizard()
              } else {
                this.currentStep++
              }
            })
            .accessibilityText(this.currentStep === this.TOTAL_STEPS - 1 ? '完成配置' : '下一步')
            .accessibilityLevel('yes')
        }
        .width('92%')
        .margin({ top: 16, bottom: 24 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_PAGE)
  }

  @Builder
  buildAgeStep() {
    Text('选择年龄段（影响安全阈值）')
      .fontSize(14)
      .fontColor(COLORS.TEXT_GRAY_7575)
      .margin({ bottom: 12 })

    Column() {
      ForEach(AGE_GROUP_OPTIONS, (option: string) => {
        Row() {
          Radio({ value: option, group: 'ageGroup' })
            .checked(this.selectedAgeGroup === option)
            .onChange((isChecked: boolean) => {
              if (isChecked) { this.selectedAgeGroup = option }
            })
            .accessibilityText(option)
            .accessibilityLevel('yes')
          Text(option)
            .fontSize(15)
            .margin({ left: 8 })
        }
        .width('100%')
        .padding({ top: 12, bottom: 12 })
        .borderWidth({ bottom: 0.5 })
        .borderColor('#E0E0E0')
      }, (option: string) => option)
    }
    .width('100%')
    .backgroundColor(COLORS.WHITE)
    .borderRadius(12)
    .padding({ left: 16, right: 16 })
  }

  @Builder
  buildGoalStep() {
    Text('选择健康目标（可多选，影响推荐策略）')
      .fontSize(14)
      .fontColor(COLORS.TEXT_GRAY_7575)
      .margin({ bottom: 12 })

    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(HEALTH_GOAL_OPTIONS, (goal: string) => {
        Text(goal)
          .fontSize(14)
          .padding({ left: 14, right: 14, top: 10, bottom: 10 })
          .borderRadius(20)
          .backgroundColor(this.selectedGoals.includes(goal) ? COLORS.PRIMARY : '#F0F0F0')
          .fontColor(this.selectedGoals.includes(goal) ? COLORS.WHITE : COLORS.TEXT_GRAY_3333)
          .margin({ right: 8, bottom: 8 })
          .onClick(() => { this.toggleGoal(goal) })
          .accessibilityText(goal)
          .accessibilityLevel('yes')
      }, (goal: string) => goal)
    }
    .width('100%')
  }

  @Builder
  buildAllergenStep() {
    Text('选择需要避免的过敏原')
      .fontSize(14)
      .fontColor(COLORS.TEXT_GRAY_7575)
      .margin({ bottom: 12 })

    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(COMMON_ALLERGENS, (allergen: string) => {
        Text(allergen)
          .fontSize(14)
          .padding({ left: 14, right: 14, top: 10, bottom: 10 })
          .borderRadius(20)
          .backgroundColor(this.selectedAllergens.includes(allergen) ? '#FF4444' : '#F0F0F0')
          .fontColor(this.selectedAllergens.includes(allergen) ? COLORS.WHITE : COLORS.TEXT_GRAY_3333)
          .margin({ right: 8, bottom: 8 })
          .onClick(() => { this.toggleAllergen(allergen) })
          .accessibilityText(allergen)
          .accessibilityLevel('yes')
      }, (allergen: string) => allergen)
    }
    .width('100%')
    .margin({ bottom: 16 })

    Row() {
      TextInput({ placeholder: '添加自定义过敏原' })
        .width('65%')
        .height(40)
        .onChange((value: string) => { this.customAllergen = value })
        .accessibilityText('自定义过敏原')
        .accessibilityLevel('yes')
      Button('添加')
        .height(40)
        .backgroundColor('#FF4444')
        .fontColor(COLORS.WHITE)
        .borderRadius(20)
        .margin({ left: 8 })
        .onClick(() => { this.addCustomAllergen() })
    }
    .width('100%')

    if (this.selectedAllergens.filter((a: string) => !COMMON_ALLERGENS.includes(a)).length > 0) {
      Column() {
        ForEach(this.selectedAllergens.filter((a: string) => !COMMON_ALLERGENS.includes(a)),
          (allergen: string) => {
            Row() {
              Text(allergen).fontSize(14).layoutWeight(1)
              Text('✕').fontSize(16).fontColor('#FF4444')
                .onClick(() => { this.toggleAllergen(allergen) })
            }
            .width('100%')
            .padding({ top: 8, bottom: 8 })
          }, (allergen: string) => allergen)
      }
      .width('100%')
      .margin({ top: 8 })
    }
  }

  @Builder
  buildIntoleranceStep() {
    Text('选择食物不耐受/敏感')
      .fontSize(14)
      .fontColor(COLORS.TEXT_GRAY_7575)
      .margin({ bottom: 12 })

    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(COMMON_INTOLERANCES, (item: string) => {
        Text(item)
          .fontSize(14)
          .padding({ left: 14, right: 14, top: 10, bottom: 10 })
          .borderRadius(20)
          .backgroundColor(this.selectedIntolerances.includes(item) ? '#FF8800' : '#F0F0F0')
          .fontColor(this.selectedIntolerances.includes(item) ? COLORS.WHITE : COLORS.TEXT_GRAY_3333)
          .margin({ right: 8, bottom: 8 })
          .onClick(() => { this.toggleIntolerance(item) })
          .accessibilityText(item)
          .accessibilityLevel('yes')
      }, (item: string) => item)
    }
    .width('100%')
    .margin({ bottom: 16 })

    Row() {
      TextInput({ placeholder: '添加自定义不耐受' })
        .width('65%')
        .height(40)
        .onChange((value: string) => { this.customIntolerance = value })
        .accessibilityText('自定义不耐受')
        .accessibilityLevel('yes')
      Button('添加')
        .height(40)
        .backgroundColor('#FF8800')
        .fontColor(COLORS.WHITE)
        .borderRadius(20)
        .margin({ left: 8 })
        .onClick(() => { this.addCustomIntolerance() })
    }
    .width('100%')
  }

  @Builder
  buildCompleteStep() {
    Column() {
      Text('✓')
        .fontSize(48)
        .fontColor(COLORS.PRIMARY)
        .margin({ bottom: 16 })

      Text('配置完成!')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 24 })

      if (this.selectedAgeGroup.length > 0) {
        this.buildSummaryRow('年龄段', this.selectedAgeGroup)
      }
      if (this.selectedGoals.length > 0) {
        this.buildSummaryRow('健康目标', this.selectedGoals.join('、'))
      }
      if (this.selectedAllergens.length > 0) {
        this.buildSummaryRow('过敏原', this.selectedAllergens.join('、'))
      }
      if (this.selectedIntolerances.length > 0) {
        this.buildSummaryRow('不耐受', this.selectedIntolerances.join('、'))
      }

      Button('完成')
        .width('100%')
        .height(44)
        .backgroundColor(COLORS.PRIMARY)
        .fontColor(COLORS.WHITE)
        .borderRadius(22)
        .margin({ top: 24 })
        .onClick(() => { safeBack() })
        .accessibilityText('完成')
        .accessibilityLevel('yes')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .padding(16)
  }

  @Builder
  buildSummaryRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(13)
        .fontColor(COLORS.TEXT_GRAY_7575)
        .width(70)
      Text(value)
        .fontSize(14)
        .fontColor(COLORS.TEXT_GRAY_3333)
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
    .borderWidth({ bottom: 0.5 })
    .borderColor('#E0E0E0')
  }

  private stepTitle(): string {
    const titles: string[] = ['年龄段', '健康目标', '过敏原', '食物不耐受'];
    return titles[this.currentStep] || '';
  }

  private stepDescription(): string {
    const descs: string[] = [
      '不同年龄段的安全阈值不同，如儿童钠摄入上限更低',
      '选择您关注的健康方向，系统将优化推荐策略',
      '选中的过敏原将在扫描时触发红色警报',
      '不耐受不同于过敏，但同样需要控制摄入'
    ];
    return descs[this.currentStep] || '';
  }

  private canProceed(): boolean {
    if (this.currentStep === 0) {
      return this.selectedAgeGroup.length > 0;
    }
    return true;
  }

  private toggleGoal(goal: string): void {
    const idx = this.selectedGoals.indexOf(goal);
    if (idx >= 0) {
      this.selectedGoals.splice(idx, 1);
      this.selectedGoals = [...this.selectedGoals];
    } else {
      this.selectedGoals = [...this.selectedGoals, goal];
    }
  }

  private toggleAllergen(allergen: string): void {
    const idx = this.selectedAllergens.indexOf(allergen);
    if (idx >= 0) {
      this.selectedAllergens.splice(idx, 1);
      this.selectedAllergens = [...this.selectedAllergens];
    } else {
      this.selectedAllergens = [...this.selectedAllergens, allergen];
    }
  }

  private toggleIntolerance(item: string): void {
    const idx = this.selectedIntolerances.indexOf(item);
    if (idx >= 0) {
      this.selectedIntolerances.splice(idx, 1);
      this.selectedIntolerances = [...this.selectedIntolerances];
    } else {
      this.selectedIntolerances = [...this.selectedIntolerances, item];
    }
  }

  private addCustomAllergen(): void {
    const trimmed = this.customAllergen.trim();
    if (trimmed.length > 0 && !this.selectedAllergens.includes(trimmed)) {
      this.selectedAllergens = [...this.selectedAllergens, trimmed];
      this.customAllergen = '';
    }
  }

  private addCustomIntolerance(): void {
    const trimmed = this.customIntolerance.trim();
    if (trimmed.length > 0 && !this.selectedIntolerances.includes(trimmed)) {
      this.selectedIntolerances = [...this.selectedIntolerances, trimmed];
      this.customIntolerance = '';
    }
  }

  private async completeWizard(): Promise<void> {
    this.isLoading = true;
    try {
      const memberId = this.appState.member.getCurrentMemberId();
      const members = this.appState.getAllMembersSync();
      const member = members.find((m) => m.memberId === memberId);
      if (member) {
        member.allergens = [...this.selectedAllergens, ...this.selectedIntolerances];
        await this.appState.saveMember(member);
        hilog.info(DOMAIN_ZERO, TAG, 'Wizard complete: %{public}d allergens, %{public}d goals',
          this.selectedAllergens.length, this.selectedGoals.length);
      }
      this.isComplete = true;
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Complete wizard failed: %{public}s', JSON.stringify(e));
    }
    this.isLoading = false;
  }

  aboutToDisappear(): void {
    this.tracker.onDisappear()
  }

}
