import { UIAbility, Want, AbilityConstant } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT, ROUTE_SCAN_PAGE, ROUTE_HOME_PAGE } from 'hsp_core';
import { window } from '@kit.ArkUI';

const TAG = 'ScanDirectAbility';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export default class ScanDirectAbility extends UIAbility {
  private scanMode: string = 'barcode';

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN_ZERO, TAG, 'ScanDirectAbility onCreate');

    if (want.parameters) {
      const scanType = want.parameters['scanType'] as string;
      if (scanType === 'qrcode' || scanType === 'ocr' || scanType === 'barcode') {
        this.scanMode = scanType;
      }
    }

    hilog.info(DOMAIN_ZERO, TAG, 'Scan mode: %{public}s', this.scanMode);
  }

  onDestroy(): void {
    hilog.info(DOMAIN_ZERO, TAG, 'ScanDirectAbility onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN_ZERO, TAG, 'ScanDirectAbility onWindowStageCreate');

    windowStage.loadContent(ROUTE_SCAN_PAGE, (err, data) => {
      if (err.code) {
        hilog.error(DOMAIN_ZERO, TAG, 'Failed to load ScanPage: %{public}s', err.message);
        windowStage.loadContent(ROUTE_HOME_PAGE, (fallbackErr) => {
          if (fallbackErr.code) {
            hilog.error(DOMAIN_ZERO, TAG, 'Failed to load HomePage fallback: %{public}s', fallbackErr.message);
          }
        });
        return;
      }
      hilog.info(DOMAIN_ZERO, TAG, 'ScanPage loaded successfully with mode: %{public}s', this.scanMode);
    });
  }

  onForeground(): void {
    hilog.info(DOMAIN_ZERO, TAG, 'ScanDirectAbility onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN_ZERO, TAG, 'ScanDirectAbility onBackground');
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    if (want.parameters) {
      const scanType = want.parameters['scanType'] as string;
      if (scanType === 'qrcode' || scanType === 'ocr' || scanType === 'barcode') {
        this.scanMode = scanType;
        hilog.info(DOMAIN_ZERO, TAG, 'Scan mode updated: %{public}s', this.scanMode);
      }
    }
  }
}
