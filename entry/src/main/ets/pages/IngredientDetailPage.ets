// IngredientDetailPage.ets
// 成分深度解读页 — 对标Yuka添加剂详情
// 展示添加剂名称、E号/CNS号、用途、风险等级(红绿灯)、GB 2760、ADI值、儿童/孕妇限制

import { router } from '@kit.ArkUI';
import {
  COLORS, FONT_SIZE, FONT_WEIGHT, SPACING, RADIUS, SHADOWS,
  safeBack, FoodLabel, HILOG_DOMAIN_DEFAULT, ThemeReactive, themeReactive
} from 'hsp_core';
import { AdditiveSafetyEngine, AdditiveAssessment, AdditiveRiskLevel, FoodAdditiveReport } from 'feature_scan';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BackButton } from '../components/BackButton';
import { GradientHeader } from '../components/GradientHeader';
import { LoadingSkeleton } from '../components/SkeletonScreen';

const TAG = 'IngredientDetailPage';

class IngredientDetailVM {
  ingredientName: string = '';
  eNumber: string = '';
  cnsCode: string = '';
  additiveName: string = '';
  category: string = '';
  riskLevel: string = '';
  riskColor: string = '';
  riskLabel: string = '';
  description: string = '';
  euStatus: string = '';
  gbRef: string = '';
  adi: string = '';
  childRestriction: string = '';
  pregnancyRestriction: string = '';
  cnMaxUsage: string = '';
  allergyPotential: boolean = false;
  intoleranceRisk: string = '';
  isAdditive: boolean = false;
}

@Entry
@ComponentV2
export struct IngredientDetailPage {
  @Local vm: IngredientDetailVM = new IngredientDetailVM()
  @Local isLoading: boolean = true

  private themeRef: ThemeReactive = themeReactive

  aboutToAppear(): void {
    try {
      const params = router.getParams() as Record<string, Object> | null;
      if (params) {
        const name = params['ingredientName'] as string;
        const foodLabel = params['foodLabel'] as FoodLabel;
        this.vm.ingredientName = name;
        if (foodLabel) {
          this.lookupAdditive(name, foodLabel);
        }
      }
    } catch (e) {
      hilog.warn(HILOG_DOMAIN_DEFAULT, TAG, 'load failed: %{public}s', JSON.stringify(e));
    }
    this.isLoading = false;
  }

  private lookupAdditive(name: string, foodLabel: FoodLabel): void {
    const engine: AdditiveSafetyEngine = new AdditiveSafetyEngine();
    const report: FoodAdditiveReport = engine.assessFood(foodLabel);

    for (let i = 0; i < report.assessments.length; i++) {
      const a = report.assessments[i];
      if (a.name.includes(name) || name.includes(a.name) || name.toUpperCase().includes(a.eNumber.toUpperCase())) {
        this.fillVM(a);
        return;
      }
    }

    this.vm.additiveName = name;
    this.vm.riskLevel = '未知';
    this.vm.riskColor = COLORS.TEXT_GRAY_9E9E;
    this.vm.riskLabel = '未在添加剂数据库中找到，可能为普通食材';
    this.vm.isAdditive = false;
  }

  private fillVM(a: AdditiveAssessment): void {
    this.vm.isAdditive = true;
    this.vm.eNumber = a.eNumber;
    this.vm.cnsCode = a.cnsCode ?? '';
    this.vm.additiveName = a.name;
    this.vm.category = a.category;
    this.vm.description = a.description;
    this.vm.euStatus = a.euStatus;
    this.vm.gbRef = a.gbRef ?? '';
    this.vm.adi = a.adi ?? '';
    this.vm.childRestriction = a.childRestriction ?? '';
    this.vm.pregnancyRestriction = a.pregnancyRestriction ?? '';
    this.vm.cnMaxUsage = a.cnMaxUsage ?? '';
    this.vm.allergyPotential = a.allergyPotential ?? false;
    this.vm.intoleranceRisk = a.intoleranceRisk ?? '';

    if (a.riskLevel === AdditiveRiskLevel.SAFE) {
      this.vm.riskLevel = 'SAFE';
      this.vm.riskColor = COLORS.ACCENT_GREEN_4CAF;
      this.vm.riskLabel = '安全';
    } else if (a.riskLevel === AdditiveRiskLevel.CAUTION) {
      this.vm.riskLevel = 'CAUTION';
      this.vm.riskColor = COLORS.ACCENT_ORANGE_FFA7;
      this.vm.riskLabel = '注意';
    } else if (a.riskLevel === AdditiveRiskLevel.AVOID) {
      this.vm.riskLevel = 'AVOID';
      this.vm.riskColor = COLORS.LEVEL_RED;
      this.vm.riskLabel = '避免';
    } else {
      this.vm.riskLevel = 'UNKNOWN';
      this.vm.riskColor = COLORS.TEXT_GRAY_9E9E;
      this.vm.riskLabel = '未知';
    }
  }

  build() {
    Column() {
      GradientHeader({ title: '成分解读' })

      if (this.isLoading) {
        Column() {
          LoadingSkeleton({ variant: 'detail' })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            this.headerCard()
            if (this.vm.isAdditive) {
              this.detailCard()
              this.safetyCard()
            }
          }
          .width('100%')
          .padding({ left: SPACING.MD, right: SPACING.MD, bottom: 80 })
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_LIGHT)
    .opacity(this.themeRef.key >= 0 ? 1 : 1)
  }

  @Builder
  headerCard() {
    Column() {
      Row() {
        Column() {
          Text(this.vm.riskLabel)
            .fontSize(FONT_SIZE.LG)
            .fontWeight(FONT_WEIGHT.BOLD)
            .fontColor(COLORS.WHITE)
        }
        .width(56)
        .height(56)
        .borderRadius(28)
        .backgroundColor(this.vm.riskColor)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        Column() {
          Text(this.vm.ingredientName)
            .fontSize(FONT_SIZE.MEDIUM)
            .fontColor(COLORS.TEXT_PRIMARY)
            .fontWeight(FONT_WEIGHT.BOLD)
          if (this.vm.eNumber.length > 0) {
            Text(this.vm.eNumber)
              .fontSize(FONT_SIZE.SMALL)
              .fontColor(COLORS.TEXT_TERTIARY)
              .margin({ top: 2 })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ left: 12 })
      }
      .width('100%')

      if (this.vm.category.length > 0) {
        Text(this.vm.category)
          .fontSize(FONT_SIZE.TINY)
          .fontColor(COLORS.PRIMARY)
          .backgroundColor(COLORS.BG_WARM_BLUE)
          .borderRadius(4)
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .margin({ top: 8 })
      }
    }
    .width('100%')
    .padding(SPACING.MD)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.MD)
    .margin({ top: SPACING.SM })
    .shadow(SHADOWS.SM)
  }

  @Builder
  detailCard() {
    Column() {
      Text('基本信息')
        .fontSize(FONT_SIZE.SMALL)
        .fontColor(COLORS.TEXT_SECONDARY)
        .fontWeight(FONT_WEIGHT.MEDIUM)
        .margin({ bottom: 8 })

      if (this.vm.description.length > 0) {
        this.infoRow('说明', this.vm.description)
      }
      if (this.vm.cnsCode.length > 0) {
        this.infoRow('CNS编号', this.vm.cnsCode)
      }
      if (this.vm.euStatus.length > 0) {
        this.infoRow('欧盟状态', this.vm.euStatus)
      }
      if (this.vm.gbRef.length > 0) {
        this.infoRow('GB标准', this.vm.gbRef)
      }
      if (this.vm.cnMaxUsage.length > 0) {
        this.infoRow('最大使用量', this.vm.cnMaxUsage)
      }
      if (this.vm.adi.length > 0) {
        this.infoRow('ADI值', this.vm.adi)
      }
    }
    .width('100%')
    .padding(SPACING.MD)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.MD)
    .margin({ top: SPACING.SM })
    .alignItems(HorizontalAlign.Start)
    .shadow(SHADOWS.SM)
  }

  @Builder
  safetyCard() {
    Column() {
      Text('安全提示')
        .fontSize(FONT_SIZE.SMALL)
        .fontColor(COLORS.TEXT_SECONDARY)
        .fontWeight(FONT_WEIGHT.MEDIUM)
        .margin({ bottom: 8 })

      if (this.vm.childRestriction.length > 0) {
        Row() {
          Text('👶 儿童')
            .fontSize(FONT_SIZE.TINY)
            .margin({ right: 8 })
          Text(this.vm.childRestriction)
            .fontSize(FONT_SIZE.TINY)
            .fontColor(COLORS.TEXT_SECONDARY)
            .layoutWeight(1)
        }
        .width('100%')
        .margin({ top: 4 })
      }

      if (this.vm.pregnancyRestriction.length > 0) {
        Row() {
          Text('🤰 孕妇')
            .fontSize(FONT_SIZE.TINY)
            .margin({ right: 8 })
          Text(this.vm.pregnancyRestriction)
            .fontSize(FONT_SIZE.TINY)
            .fontColor(COLORS.TEXT_SECONDARY)
            .layoutWeight(1)
        }
        .width('100%')
        .margin({ top: 4 })
      }

      if (this.vm.allergyPotential) {
        Row() {
          Text('⚠️ 过敏')
            .fontSize(FONT_SIZE.TINY)
            .margin({ right: 8 })
          Text('可能引起过敏反应')
            .fontSize(FONT_SIZE.TINY)
            .fontColor(COLORS.ACCENT_ORANGE)
            .layoutWeight(1)
        }
        .width('100%')
        .margin({ top: 4 })
      }

      if (this.vm.intoleranceRisk.length > 0) {
        Row() {
          Text('消化不耐')
            .fontSize(FONT_SIZE.TINY)
            .margin({ right: 8 })
          Text(this.vm.intoleranceRisk)
            .fontSize(FONT_SIZE.TINY)
            .fontColor(COLORS.TEXT_SECONDARY)
            .layoutWeight(1)
        }
        .width('100%')
        .margin({ top: 4 })
      }

      if (this.vm.riskLevel === 'AVOID') {
        Text('⚠️ 该添加剂在部分国家/地区已限用或禁用，建议避免选择含此成分的食品')
          .fontSize(FONT_SIZE.TINY)
          .fontColor(COLORS.LEVEL_RED)
          .margin({ top: 8 })
      }
    }
    .width('100%')
    .padding(SPACING.MD)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.MD)
    .margin({ top: SPACING.SM })
    .alignItems(HorizontalAlign.Start)
    .shadow(SHADOWS.SM)
  }

  @Builder
  infoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(FONT_SIZE.TINY)
        .fontColor(COLORS.TEXT_TERTIARY)
        .width(72)
      Text(value)
        .fontSize(FONT_SIZE.TINY)
        .fontColor(COLORS.TEXT_SECONDARY)
        .layoutWeight(1)
    }
    .width('100%')
    .margin({ top: 4 })
  }
}
