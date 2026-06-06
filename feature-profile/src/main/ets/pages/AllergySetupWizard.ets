// AllergySetupWizard.ets
// 过敏原档案设置向导 — 对标Yuka/Olive过敏原配置
// 引导用户完成常见过敏原、不耐受、严重度配置

import { router } from '@kit.ArkUI';
import {
  COLORS, FONT_SIZE, FONT_WEIGHT, SPACING, RADIUS,
  safeBack, AllergyProfile, AllergyItem, IntoleranceItem,
  Severity, createDefaultAllergyProfile, severityToLabel, severityToColor,
  HILOG_DOMAIN_DEFAULT
} from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'AllergySetupWizard';

class AllergyOption {
  name: string = '';
  category: 'allergy' | 'intolerance' = 'allergy';
  selected: boolean = false;
  severity: Severity = Severity.MODERATE;
}

const COMMON_ALLERGENS: string[] = [
  '花生', '牛奶', '鸡蛋', '大豆', '小麦', '坚果', '鱼类', '虾/蟹', '芝麻', '芒果'
];

const COMMON_INTOLERANCES: string[] = [
  '乳糖不耐受', '麸质不耐受', '果糖不耐受', '组胺不耐受', 'FODMAP不耐受'
];

@Entry
@ComponentV2
struct AllergySetupWizard {
  @Local step: number = 0;
  @Local profile: AllergyProfile = createDefaultAllergyProfile('');
  @Local allergyOptions: AllergyOption[] = [];
  @Local intoleranceOptions: AllergyOption[] = [];
  @Local selectedMemberName: string = '';

  aboutToAppear(): void {
    this.buildOptions();
    try {
      const params = router.getParams() as Record<string, Object> | null;
      if (params && params['memberId']) {
        this.profile.memberId = params['memberId'] as string;
      }
      if (params && params['memberName']) {
        this.selectedMemberName = params['memberName'] as string;
      }
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_e));
      // 从AppState获取
    }
  }

  private buildOptions(): void {
    this.allergyOptions = COMMON_ALLERGENS.map((name: string) => {
      const opt: AllergyOption = new AllergyOption()
      opt.name = name;
      opt.category = 'allergy';
      return opt;
    });

    this.intoleranceOptions = COMMON_INTOLERANCES.map((name: string) => {
      const opt: AllergyOption = new AllergyOption()
      opt.name = name;
      opt.category = 'intolerance';
      return opt;
    });
  }

  private saveProfile(): void {
    const selectedAllergies = this.allergyOptions
      .filter((o: AllergyOption) => o.selected)
      .map((o: AllergyOption) => {
        const item: AllergyItem = new AllergyItem()
        item.allergen = o.name;
        item.severity = o.severity;
        item.confirmedAt = Date.now();
        return item;
      });

    const selectedIntolerances = this.intoleranceOptions
      .filter((o: AllergyOption) => o.selected)
      .map((o: AllergyOption) => {
        const item: IntoleranceItem = new IntoleranceItem()
        item.substance = o.name;
        item.severity = o.severity;
        item.confirmedAt = Date.now();
        return item;
      });

    this.profile.allergies = selectedAllergies;
    this.profile.intolerances = selectedIntolerances;
    this.profile.updatedAt = Date.now();

    hilog.info(HILOG_DOMAIN_DEFAULT, TAG,
      'Profile saved: %{public}d allergies, %{public}d intolerances',
      selectedAllergies.length, selectedIntolerances.length);

    safeBack();
  }

  build() {
    Column() {
      this.headerBar()

      Column() {
        this.progressIndicator()

        if (this.step === 0) {
          this.welcomeStep()
        } else if (this.step === 1) {
          this.allergyStep()
        } else {
          this.intoleranceStep()
        }
      }
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)

      this.bottomBar()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  headerBar() {
    Row() {
      Button({ type: ButtonType.Normal }) {
        Text('← 返回').fontSize(FONT_SIZE.BODY)
      }
      .height(36)
      .onClick(() => safeBack())

      Blank()

      Text('过敏原档案设置')
        .fontSize(FONT_SIZE.MEDIUM)
        .fontColor(COLORS.TEXT_PRIMARY)
        .fontWeight(FONT_WEIGHT.BOLD)

      Blank()

      Row().width(60)
    }
    .width('100%')
    .height(48)
    .padding({ left: SPACING.MEDIUM, right: SPACING.MEDIUM })
    .backgroundColor(COLORS.WHITE)
  }

  @Builder
  progressIndicator() {
    Row() {
      ForEach(['开始', '过敏原', '不耐受'], (label: string, idx: number) => {
        Row() {
          Column() {
            Text(`${idx + 1}`)
              .fontSize(FONT_SIZE.TINY)
              .fontColor(this.step >= idx ? COLORS.WHITE : COLORS.TEXT_TERTIARY)
              .fontWeight(FONT_WEIGHT.BOLD)
          }
          .width(24)
          .height(24)
          .borderRadius(12)
          .backgroundColor(this.step >= idx ? COLORS.PRIMARY : '#E0E0E0')
          .justifyContent(FlexAlign.Center)

          Text(label)
            .fontSize(FONT_SIZE.TINY)
            .fontColor(this.step >= idx ? COLORS.PRIMARY : COLORS.TEXT_TERTIARY)
            .margin({ top: 4, left: 4 })

          if (idx < 2) {
            Divider()
              .width(40)
              .height(2)
              .color(this.step > idx ? COLORS.PRIMARY : '#E0E0E0')
              .margin({ left: 8, right: 8 })
          }
        }
      })
    }
    .width('100%')
    .padding(SPACING.MEDIUM)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(COLORS.WHITE)
  }

  @Builder
  welcomeStep() {
    Column() {
      Text('🛡️')
        .fontSize(48)
        .margin({ bottom: SPACING.MEDIUM })

      Text('设置过敏原档案')
        .fontSize(FONT_SIZE.LG)
        .fontColor(COLORS.TEXT_PRIMARY)
        .fontWeight(FONT_WEIGHT.BOLD)

      Text('帮助我们为您和家人提供精准的过敏原预警\n对标Yuka/Olive过敏原检测功能')
        .fontSize(FONT_SIZE.SMALL)
        .fontColor(COLORS.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)
        .margin({ top: SPACING.SMALL })
        .maxLines(3)

      Column() {
        this.infoRow('🔴', '过敏：免疫系统反应，可能危及生命，需严格避免')
        this.infoRow('🟡', '不耐受：消化系统反应，引起不适但非致命')
        this.infoRow('🟠', '交叉反应：与已知过敏原蛋白同源，谨慎注意')
      }
      .margin({ top: SPACING.LARGE })
      .width('100%')
    }
    .width('100%')
    .padding(SPACING.LARGE)
    .flexGrow(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  infoRow(icon: string, text: string) {
    Row() {
      Text(icon).fontSize(18)
      Text(text)
        .fontSize(FONT_SIZE.TINY)
        .fontColor(COLORS.TEXT_SECONDARY)
        .layoutWeight(1)
        .margin({ left: 8 })
    }
    .width('100%')
    .margin({ top: 8 })
  }

  @Builder
  allergyStep() {
    Scroll() {
      Column() {
        Text('选择过敏原')
          .fontSize(FONT_SIZE.MEDIUM)
          .fontColor(COLORS.TEXT_PRIMARY)
          .fontWeight(FONT_WEIGHT.BOLD)
          .width('100%')
          .margin({ bottom: SPACING.SMALL })

        Text('请为每位家庭成员选择已知的食物过敏原')
          .fontSize(FONT_SIZE.TINY)
          .fontColor(COLORS.TEXT_TERTIARY)
          .width('100%')
          .margin({ bottom: SPACING.SMALL })

        ForEach(this.allergyOptions, (opt: AllergyOption, idx: number) => {
          this.optionRow(opt, idx)
        })
      }
      .width('100%')
      .padding(SPACING.MEDIUM)
    }
  }

  @Builder
  intoleranceStep() {
    Scroll() {
      Column() {
        Text('选择不耐受')
          .fontSize(FONT_SIZE.MEDIUM)
          .fontColor(COLORS.TEXT_PRIMARY)
          .fontWeight(FONT_WEIGHT.BOLD)
          .width('100%')
          .margin({ bottom: SPACING.SMALL })

        Text('不耐受通常不会危及生命，但需注意饮食')
          .fontSize(FONT_SIZE.TINY)
          .fontColor(COLORS.TEXT_TERTIARY)
          .width('100%')
          .margin({ bottom: SPACING.SMALL })

        ForEach(this.intoleranceOptions, (opt: AllergyOption, idx: number) => {
          this.optionRow(opt, idx)
        })
      }
      .width('100%')
      .padding(SPACING.MEDIUM)
    }
  }

  @Builder
  optionRow(opt: AllergyOption, idx: number) {
    Row() {
      Toggle({ type: ToggleType.Checkbox, isOn: opt.selected })
        .onChange((isOn: boolean) => { opt.selected = isOn })

      Text(opt.name)
        .fontSize(FONT_SIZE.BODY)
        .fontColor(COLORS.TEXT_PRIMARY)
        .layoutWeight(1)
        .margin({ left: 8 })

      if (opt.selected) {
        Row() {
          Text(severityToLabel(opt.severity))
            .fontSize(FONT_SIZE.TINY)
            .fontColor(severityToColor(opt.severity))
        }
        .onClick(() => { this.cycleSeverity(opt) })
      }
    }
    .width('100%')
    .height(44)
    .padding({ left: 8, right: 8 })
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.SMALL)
    .margin({ top: 4 })
  }

  private cycleSeverity(opt: AllergyOption): void {
    const severities: Severity[] = [Severity.MILD, Severity.MODERATE,
      Severity.SEVERE, Severity.LIFE_THREATENING];
    const currentIdx = severities.indexOf(opt.severity);
    opt.severity = severities[(currentIdx + 1) % severities.length];
  }

  @Builder
  bottomBar() {
    Row() {
      if (this.step > 0) {
        Button('上一步')
          .fontSize(FONT_SIZE.SMALL)
          .onClick(() => { this.step-- })
          .margin({ right: 8 })
      }

      Blank()

      if (this.step < 2) {
        Button('下一步')
          .fontSize(FONT_SIZE.SMALL)
          .backgroundColor(COLORS.PRIMARY)
          .onClick(() => { this.step++ })
      } else {
        Button('完成设置')
          .fontSize(FONT_SIZE.SMALL)
          .backgroundColor(COLORS.SUCCESS)
          .onClick(() => { this.saveProfile() })
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: SPACING.MEDIUM, right: SPACING.MEDIUM })
    .backgroundColor(COLORS.WHITE)
  }
}