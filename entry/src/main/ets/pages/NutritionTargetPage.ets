import {
  ToastHelper, FamilyProfile, NutritionTarget, NutritionPreset, NUTRITION_PRESETS, applyPresetToTarget, createDefaultNutritionTarget, COLORS, safeBack, HILOG_DOMAIN_DEFAULT, PageResourceTracker, createPageTracker
} from 'hsp_core';
import { BackButton } from '../components/BackButton';
import { AppState } from '../AppState';
import { hilog } from '@kit.PerformanceAnalysisKit';

const NUTRI_TAG = 'NutritionTargetPage';
const NUTRI_DOMAIN = HILOG_DOMAIN_DEFAULT;

@Entry
@ComponentV2
struct NutritionTargetPage {
  @Local familyMembers: FamilyProfile[] = []
  @Local selectedMemberId: string = ''
  @Local target: NutritionTarget = new NutritionTarget()
  @Local activePresetIndex: number = 0
  @Local isSaving: boolean = false
  @Local isLoading: boolean = true

  private componentActive: boolean = true
  private appState: AppState = AppState.getInstance()
  private sliderDebounceTimer: number = -1
  private tracker: PageResourceTracker = createPageTracker('NutritionTargetPage')

  async aboutToAppear() {
    this.tracker.onAppear()
    this.componentActive = true
    try {
      this.isLoading = true
      this.familyMembers = await this.appState.getAllMembers()
      if (this.familyMembers.length > 0) {
        this.selectedMemberId = this.familyMembers[0].memberId
      }
      await this.loadTarget()
      this.isLoading = false
    } catch (e) {
      hilog.error(NUTRI_DOMAIN, NUTRI_TAG, 'aboutToAppear failed: %{public}s', JSON.stringify(e));
      this.isLoading = false
    }
  }

  aboutToDisappear(): void {
    this.tracker.onDisappear()
    this.componentActive = false
    if (this.sliderDebounceTimer !== -1) {
      clearTimeout(this.sliderDebounceTimer)
      this.sliderDebounceTimer = -1
    }
  }

  private async loadTarget(): Promise<void> {
    if (this.selectedMemberId.length === 0) return
    const saved = await this.appState.getNutritionTarget(this.selectedMemberId)
    if (saved) {
      this.target = saved
      const idx = NUTRITION_PRESETS.findIndex(p => p.name === saved.presetName)
      this.activePresetIndex = idx >= 0 ? idx : -1
    } else {
      this.target = createDefaultNutritionTarget(this.selectedMemberId)
      this.activePresetIndex = 0
    }
  }

  private onPresetSelected(index: number): void {
    this.activePresetIndex = index
    const preset = NUTRITION_PRESETS[index]
    applyPresetToTarget(this.target, preset)
  }

  private async onSave(): Promise<void> {
    if (this.selectedMemberId.length === 0) return
    this.isSaving = true
    this.target.memberId = this.selectedMemberId
    try {
      await this.appState.saveNutritionTarget(this.target)
      this.isSaving = false
      ToastHelper.show(this.getUIContext(), $r('app.string.nutrition_target_saved'))
    } catch (error) {
      this.isSaving = false
      hilog.error(NUTRI_DOMAIN, NUTRI_TAG, 'Save nutrition target failed: %{public}s', JSON.stringify(error))
      ToastHelper.show(this.getUIContext(), $r('app.string.nutrition_target_save_failed'))
    }
  }

  private async onReset(): Promise<void> {
    this.target = createDefaultNutritionTarget(this.selectedMemberId)
    this.activePresetIndex = 0
    await this.appState.saveNutritionTarget(this.target)
    ToastHelper.show(this.getUIContext(), $r('app.string.nutrition_target_reset_toast'))
  }

  build() {
    Scroll() {
      Column() {
        Row() {
          BackButton({ fontSize: 24, fontColor: COLORS.PRIMARY })
            .onClick(() => { safeBack() })
            .accessibilityText('杩斿洖')
            .accessibilityLevel('yes')
          Text($r('app.string.nutrition_target_title'))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 16 })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 16 })

        if (this.familyMembers.length > 1) {
          this.MemberSelector()
        }

        this.PresetSelector()

        this.CustomSliders()

        Row() {
          Button($r('app.string.save'))
            .width('45%')
            .height(48)
            .backgroundColor(COLORS.PRIMARY)
            .borderRadius(24)
            .enabled(!this.isSaving)
            .onClick(() => { this.onSave() })
            .accessibilityText('重置为默认')
            .accessibilityLevel('yes')
          Button($r('app.string.reset_to_default'))
            .width('45%')
            .height(48)
            .backgroundColor(COLORS.TEXT_GRAY_9E9E)
            .fontColor(COLORS.WHITE)
            .borderRadius(24)
            .onClick(() => { this.onReset() })
            .accessibilityText('閲嶇疆涓洪粯璁?)
            .accessibilityLevel('yes')
        }
        .width('92%')
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ top: 24, bottom: 32 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_PAGE)
  }

  @Builder
  MemberSelector() {
    Column() {
      Text($r('app.string.select_member'))
        .fontSize(13)
        .fontColor(COLORS.TEXT_GRAY_7575)
        .margin({ bottom: 8 })
      Row() {
        Scroll() {
          Row() {
            ForEach(this.familyMembers, (member: FamilyProfile) => {
              Text(member.nickname)
                .fontSize(13)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .borderRadius(16)
                .backgroundColor(this.selectedMemberId === member.memberId ? COLORS.PRIMARY : COLORS.WHITE)
                .fontColor(this.selectedMemberId === member.memberId ? COLORS.WHITE : COLORS.TEXT_GRAY_2121)
                .margin({ right: 8 })
                .onClick(async () => {
                  this.selectedMemberId = member.memberId
                  await this.loadTarget()
                })
                .accessibilityText(member.nickname)
                .accessibilityLevel('yes')
            }, (member: FamilyProfile) => member.memberId)
          }
        }
        .scrollBar(BarState.Off)
      }
    }
    .width('92%')
    .padding(16)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(16)
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 14 })
  }

  @Builder
  PresetSelector() {
    Column() {
      Text($r('app.string.preset_scheme'))
        .fontSize(14)
        .fontColor(COLORS.TEXT_GRAY_7575)
        .margin({ bottom: 8 })
      Scroll() {
        Row() {
          ForEach(NUTRITION_PRESETS, (preset: NutritionPreset, index?: number) => {
            Column() {
              Text(preset.name)
                .fontSize(14)
                .fontWeight(this.activePresetIndex === index ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.activePresetIndex === index ? COLORS.WHITE : COLORS.TEXT_PRIMARY)
            }
            .padding({ left: 16, right: 16, top: 10, bottom: 10 })
            .borderRadius(20)
            .backgroundColor(this.activePresetIndex === index ? COLORS.PRIMARY : '#F0F0F0')
            .margin({ right: 8 })
            .onClick(() => {
              if (index !== undefined) {
                this.onPresetSelected(index)
              }
            })
            .accessibilityText(preset.name)
            .accessibilityLevel('yes')
          }, (preset: NutritionPreset, index?: number) => `${preset.name}_${index}`)
        }
      }
      .scrollBar(BarState.Off)
    }
    .width('92%')
    .padding(16)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(16)
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 14 })
  }

  @Builder
  CustomSliders() {
    Column() {
      Text($r('app.string.custom_adjust'))
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 12 })

      this.SliderRow($r('app.string.sodium_max'), this.target.sodiumMax_mg, 'mg', 500, 5000, 100, (v: number) => { this.target.sodiumMax_mg = v; this.activePresetIndex = -1 })
      this.SliderRow($r('app.string.sugar_max'), this.target.sugarMax_g, 'g', 10, 100, 5, (v: number) => { this.target.sugarMax_g = v; this.activePresetIndex = -1 })
      this.SliderRow($r('app.string.calories_target'), this.target.caloriesTarget, 'kcal', 1000, 4000, 100, (v: number) => { this.target.caloriesTarget = v; this.activePresetIndex = -1 })
      this.SliderRow($r('app.string.fat_max'), this.target.fatMax_g, 'g', 20, 150, 5, (v: number) => { this.target.fatMax_g = v; this.activePresetIndex = -1 })
      this.SliderRow($r('app.string.protein_target'), this.target.proteinTarget_g, 'g', 20, 200, 5, (v: number) => { this.target.proteinTarget_g = v; this.activePresetIndex = -1 })
      this.SliderRow($r('app.string.fiber_min'), this.target.fiberMin_g, 'g', 10, 50, 5, (v: number) => { this.target.fiberMin_g = v; this.activePresetIndex = -1 })
    }
    .width('92%')
    .padding(16)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(16)
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 14 })
  }

  @Builder
  SliderRow(label: ResourceStr, value: number, unit: string, min: number, max: number, step: number, onChange: (v: number) => void) {
    Column() {
      Row() {
        Text(label)
          .fontSize(14)
          .fontColor(COLORS.TEXT_PRIMARY)
          .layoutWeight(1)
        Text(`${value}${unit}`)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLORS.PRIMARY)
      }
      .width('100%')
      .margin({ bottom: 4 })

      Slider({
        value: value,
        min: min,
        max: max,
        step: step,
        style: SliderStyle.InSet
      })
        .width('100%')
        .trackColor('#E0E0E0')
        .selectedColor(COLORS.PRIMARY)
        .blockColor(COLORS.PRIMARY)
        .onChange((val: number) => {
          const clamped = Math.max(min, Math.min(max, val))
          if (this.sliderDebounceTimer !== -1) {
            clearTimeout(this.sliderDebounceTimer)
          }
          this.sliderDebounceTimer = setTimeout(() => {
            onChange(clamped)
            this.sliderDebounceTimer = -1
          }, 100)
        })
    }
    .width('100%')
    .margin({ bottom: 16 })
  }

  pageTransition() {
    PageTransitionEnter({ duration: 350, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 250, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
  }
}
