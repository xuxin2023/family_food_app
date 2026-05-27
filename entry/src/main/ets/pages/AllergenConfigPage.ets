import { safeBack, COLORS, HILOG_DOMAIN } from 'hsp_core';
import { BackButton } from '../components/BackButton';
import { AppState } from '../AppState';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'AllergenConfigPage';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

const PRESET_ALLERGENS: string[] = [
  '牛奶', '鸡蛋', '花生', '坚果', '大豆', '小麦', '鱼', '甲壳类', '芝麻', '芹菜',
  '芥末', '羽扇豆', '软体动物', '二氧化硫'
];

@Entry
@ComponentV2
struct AllergenConfigPage {
  @Local customAllergens: string[] = []
  @Local newAllergen: string = ''
  @Local isLoading: boolean = true

  private appState: AppState = AppState.getInstance()

  async aboutToAppear() {
    const memberId = this.appState.member.getCurrentMemberId();
    const members = this.appState.getAllMembersSync();
    const member = members.find((m) => m.memberId === memberId);
    if (member) {
      this.customAllergens = [...member.allergens];
    }
    this.isLoading = false;
  }

  build() {
    Column() {
      Row() {
        BackButton({ fontSize: 24, fontColor: COLORS.PRIMARY })
          .onClick(() => { safeBack() })
          .accessibilityText('返回')
          .accessibilityLevel('yes')
        Text('过敏原配置')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })

      if (this.isLoading) {
        LoadingProgress().width(48).height(48).color(COLORS.PRIMARY)
      } else {
        Scroll() {
          Column() {
            Text('常见过敏原')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 12 })

            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(PRESET_ALLERGENS, (allergen: string) => {
                Text(allergen)
                  .fontSize(14)
                  .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                  .borderRadius(20)
                  .backgroundColor(this.customAllergens.includes(allergen) ? COLORS.PRIMARY : '#F0F0F0')
                  .fontColor(this.customAllergens.includes(allergen) ? COLORS.WHITE : COLORS.TEXT_GRAY_2121)
                  .margin({ right: 8, bottom: 8 })
                  .onClick(() => { this.toggleAllergen(allergen) })
                  .accessibilityText(allergen)
                  .accessibilityLevel('yes')
              }, (allergen: string) => allergen)
            }
            .width('100%')
            .margin({ bottom: 24 })

            Text('自定义过敏原')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 12 })

            Row() {
              TextInput({ placeholder: '输入过敏原名称' })
                .width('60%')
                .height(40)
                .onChange((value: string) => { this.newAllergen = value })
                .accessibilityText('自定义过敏原')
                .accessibilityLevel('yes')

              Button('添加')
                .height(40)
                .backgroundColor(COLORS.PRIMARY)
                .fontColor(COLORS.WHITE)
                .borderRadius(20)
                .margin({ left: 8 })
                .onClick(() => { this.addCustomAllergen() })
                .accessibilityText('添加过敏原')
                .accessibilityLevel('yes')
            }
            .width('100%')
            .margin({ bottom: 16 })

            if (this.customAllergens.filter((a: string) => !PRESET_ALLERGENS.includes(a)).length > 0) {
              Text('已添加的自定义过敏原')
                .fontSize(14)
                .fontColor(COLORS.TEXT_GRAY_7575)
                .margin({ bottom: 8 })

              ForEach(this.customAllergens.filter((a: string) => !PRESET_ALLERGENS.includes(a)),
                (allergen: string) => {
                  Row() {
                    Text(allergen)
                      .fontSize(14)
                      .layoutWeight(1)

                    Text('✕')
                      .fontSize(16)
                      .fontColor(COLORS.TEXT_GRAY_BDBD)
                      .onClick(() => { this.toggleAllergen(allergen) })
                      .accessibilityText('删除')
                      .accessibilityLevel('yes')
                  }
                  .width('100%')
                  .padding({ top: 8, bottom: 8 })
                }, (allergen: string) => allergen)
            }
          }
          .width('92%')
          .padding(16)
        }
        .layoutWeight(1)
      }

      Button('保存')
        .width('90%')
        .height(44)
        .backgroundColor(COLORS.PRIMARY)
        .fontColor(COLORS.WHITE)
        .borderRadius(22)
        .margin({ top: 16, bottom: 16 })
        .onClick(() => { this.saveAllergens() })
        .accessibilityText('保存过敏原配置')
        .accessibilityLevel('yes')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_PAGE)
  }

  private toggleAllergen(allergen: string): void {
    const idx = this.customAllergens.indexOf(allergen);
    if (idx >= 0) {
      this.customAllergens.splice(idx, 1);
      this.customAllergens = [...this.customAllergens];
    } else {
      this.customAllergens = [...this.customAllergens, allergen];
    }
  }

  private addCustomAllergen(): void {
    const trimmed = this.newAllergen.trim();
    if (trimmed.length > 0 && !this.customAllergens.includes(trimmed)) {
      this.customAllergens = [...this.customAllergens, trimmed];
      this.newAllergen = '';
    }
  }

  private async saveAllergens(): Promise<void> {
    const memberId = this.appState.member.getCurrentMemberId();
    const members = this.appState.getAllMembersSync();
    const member = members.find((m) => m.memberId === memberId);
    if (member) {
      member.allergens = [...this.customAllergens];
      await this.appState.saveMember(member);
      hilog.info(DOMAIN_ZERO, TAG, 'Allergens saved: %{public}d items', this.customAllergens.length);
    }
    safeBack();
  }
}
