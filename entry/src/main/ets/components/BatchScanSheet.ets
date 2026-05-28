import { FoodLabel, COLORS, RADIUS, HILOG_DOMAIN } from 'hsp_core';
import { BatchScanService, BatchScanResult } from 'hsp_service';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'BatchScanSheet';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

@ComponentV2
export struct BatchScanSheet {
  @Local barcodeInput: string = ''
  @Local barcodes: string[] = []
  @Local results: BatchScanResult[] = []
  @Local isProcessing: boolean = false
  @Local totalScanned: number = 0
  @Local hitCount: number = 0

  private batchService: BatchScanService = new BatchScanService()
  private onResultSelected?: (food: FoodLabel) => void

  build() {
    Column() {
      Row() {
        Text('批量扫码')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text(`${this.hitCount}/${this.totalScanned} 命中`)
          .fontSize(13)
          .fontColor(COLORS.TEXT_TERTIARY)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 8 })

      Row() {
        TextInput({ placeholder: '输入条码后按回车添加', text: this.barcodeInput })
          .layoutWeight(1)
          .height(40)
          .fontSize(14)
          .borderRadius(8)
          .type(InputType.Number)
          .onChange((v: string) => { this.barcodeInput = v; })
          .onSubmit(() => { this.addBarcode(); })
          .accessibilityText('条码输入')
          .accessibilityLevel('yes')

        Button('添加')
          .height(40)
          .margin({ left: 8 })
          .backgroundColor(COLORS.PRIMARY)
          .fontColor(COLORS.WHITE)
          .borderRadius(8)
          .onClick(() => { this.addBarcode(); })
          .accessibilityText('添加条码')
          .accessibilityLevel('yes')
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 8 })

      if (this.barcodes.length > 0) {
        Column() {
          Text(`待扫描 (${this.barcodes.length} 个条码)`)
            .fontSize(12)
            .fontColor(COLORS.TEXT_TERTIARY)
            .margin({ bottom: 4 })

          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.barcodes, (barcode: string, index: number) => {
              Row() {
                Text(barcode)
                  .fontSize(11)
                  .fontColor(COLORS.TEXT_PRIMARY)
                Text('×')
                  .fontSize(10)
                  .fontColor(COLORS.TEXT_TERTIARY)
                  .margin({ left: 4 })
                  .onClick(() => {
                    this.barcodes = this.barcodes.filter((_, i) => i !== index);
                  })
              }
              .padding({ left: 8, right: 6, top: 4, bottom: 4 })
              .backgroundColor(COLORS.BG_LIGHT)
              .borderRadius(12)
              .margin({ right: 6, top: 4 })
            }, (barcode: string, index: number) => `${barcode}_${index}`)
          }
          .width('100%')
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 8 })
      }

      Button(this.isProcessing ? '扫描中...' : '开始批量扫描')
        .width('90%')
        .height(44)
        .backgroundColor(this.barcodes.length > 0 ? COLORS.PRIMARY : COLORS.TEXT_GRAY_9E9E)
        .fontColor(COLORS.WHITE)
        .borderRadius(22)
        .enabled(this.barcodes.length > 0 && !this.isProcessing)
        .onClick(() => { this.startBatchScan(); })
        .margin({ top: 8, bottom: 12 })
        .accessibilityText('开始批量扫描')
        .accessibilityLevel('yes')

      if (this.results.length > 0) {
        List() {
          ForEach(this.results, (result: BatchScanResult, index: number) => {
            ListItem() {
              Row() {
                Column() {
                  Text(result.foodLabel?.foodName ?? '未识别')
                    .fontSize(14)
                    .fontColor(result.foodLabel ? COLORS.TEXT_PRIMARY : COLORS.TEXT_TERTIARY)
                    .fontWeight(FontWeight.Medium)
                  Text(result.barcode)
                    .fontSize(10)
                    .fontColor(COLORS.TEXT_TERTIARY)
                    .margin({ top: 2 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Text(result.source === 'local_cache' ? '本地' : result.source === 'off_api' ? 'API' : '未命中')
                  .fontSize(11)
                  .fontColor(result.foodLabel ? COLORS.ACCENT_GREEN_4CAF : COLORS.TEXT_TERTIARY)
                  .backgroundColor(result.foodLabel ? '#E8F5E9' : '#F5F5F5')
                  .borderRadius(8)
                  .padding({ left: 8, right: 8, top: 3, bottom: 3 })

                if (result.foodLabel) {
                  Text(`${result.confidence}%`)
                    .fontSize(10)
                    .fontColor(COLORS.TEXT_TERTIARY)
                    .margin({ left: 4 })
                }
              }
              .width('100%')
              .padding({ top: 8, bottom: 8 })
              .onClick(() => {
                if (result.foodLabel && this.onResultSelected) {
                  this.onResultSelected(result.foodLabel);
                }
              })
              .accessibilityText(result.foodLabel?.foodName ?? result.barcode)
              .accessibilityLevel('yes')
            }
          }, (result: BatchScanResult, index: number) => `${result.barcode}_${index}`)
        }
        .width('100%')
        .layoutWeight(1)
        .divider({ strokeWidth: 0.5, color: COLORS.DIVIDER })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.WHITE)
    .borderRadius({ topLeft: RADIUS.XL, topRight: RADIUS.XL })
  }

  private addBarcode(): void {
    const trimmed = this.barcodeInput.trim();
    if (trimmed.length >= 4 && !this.barcodes.includes(trimmed)) {
      this.barcodes = [...this.barcodes, trimmed];
      this.barcodeInput = '';
    }
  }

  private async startBatchScan(): Promise<void> {
    if (this.barcodes.length === 0) return;
    this.isProcessing = true;
    try {
      this.results = await this.batchService.scanBatch([...this.barcodes]);
      const summary = this.batchService.getSummary();
      this.totalScanned = summary.total;
      this.hitCount = summary.hit;
      hilog.info(DOMAIN_ZERO, TAG, 'Batch: %{public}d/%{public}d, avg %{public}dms',
        summary.hit, summary.total, summary.avgTimeMs);
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Batch scan error: %{public}s', JSON.stringify(e));
    }
    this.isProcessing = false;
  }
}
