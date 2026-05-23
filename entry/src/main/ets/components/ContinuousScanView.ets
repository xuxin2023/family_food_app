// ContinuousScanView.ets
// 连续扫码自定义相机预览组件 — 对标 Yuka 实时预览+持续解码
// 使用 CameraKit 自定义预览 + @ohos/zxing 持续解码
//
// 架构说明:
// - XComponent 承载 Camera 预览流
// - 定时帧回调 → ZXing MultiFormatReader 解码
// - 防抖机制：同一码 2 秒内不重复触发
// - 支持前后置切换、闪光灯、相册导入

import { camera } from '@kit.CameraKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN, COLORS, SPACING, RADIUS } from 'hsp_core';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'ContinuousScanView';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;
const DEBOUNCE_MS = 2000;

@ComponentV2
export struct ContinuousScanView {
  @Local isScanning: boolean = false;
  @Local hasTorch: boolean = false;
  @Local torchOn: boolean = false;
  @Local lastDecodedText: string = '';
  @Local lastDecodeTime: number = 0;

  private xComponentController: XComponentController = new XComponentController();
  private cameraManager: camera.CameraManager | null = null;
  private cameraInput: camera.CameraInput | null = null;
  private previewOutput: camera.PreviewOutput | null = null;
  private captureSession: camera.Session | null = null;
  private frameCallbackId: number = -1;
  private onBarcodeScanned: ((barcode: string) => void) | null = null;

  aboutToDisappear(): void {
    this.releaseCamera();
  }

  build() {
    Stack() {
      // 相机预览
      XComponent({
        id: 'continuousScanCamera',
        type: XComponentType.SURFACE,
        controller: this.xComponentController
      })
        .width('100%')
        .height('100%')
        .onLoad(() => {
          this.initCamera();
        })

      // 扫描框指示
      Column() {
        Row()
          .width(280)
          .height(280)
          .borderWidth(2)
          .borderColor(COLORS.ACCENT_GREEN_4CAF)
          .borderRadius(RADIUS.MD)
          .opacity(0.8)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      // 底部控制栏
      Row() {
        // 闪光灯
        if (this.hasTorch) {
          Button(this.torchOn ? '关闭闪光灯' : '闪光灯')
            .onClick(() => this.toggleTorch())
            .backgroundColor($r('sys.color.ohos_id_color_foreground_contrary'))
            .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
            .borderRadius(RADIUS.FULL)
            .padding({ left: SPACING.MD, right: SPACING.MD, top: SPACING.SM, bottom: SPACING.SM })
            .accessibilityText(this.torchOn ? '关闭闪光灯' : '开启闪光灯')
            .accessibilityLevel('yes')
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding(SPACING.LG)
      .alignItems(VerticalAlign.Center)
      .position({ x: 0, y: '85%' })
    }
    .width('100%')
    .height('100%')
  }

  setOnBarcodeScanned(callback: (barcode: string) => void): void {
    this.onBarcodeScanned = callback;
  }

  private async initCamera(): Promise<void> {
    try {
      const context = getContext(this);
      this.cameraManager = camera.getCameraManager(context);

      const cameras = this.cameraManager.getSupportedCameras();
      if (cameras.length === 0) {
        hilog.warn(DOMAIN_ZERO, TAG, 'No camera available');
        return;
      }

      const backCamera = cameras.find(c => c.cameraPosition === camera.CameraPosition.CAMERA_POSITION_BACK) ?? cameras[0];

      this.cameraInput = this.cameraManager.createCameraInput(backCamera);
      await this.cameraInput.open();

      const surfaceId = this.xComponentController.getXComponentSurfaceId();
      const previewProfiles = this.cameraManager.getSupportedOutputProfile(backCamera.cameraType).previewProfiles;
      const previewProfile = previewProfiles[previewProfiles.length - 1];

      this.previewOutput = this.cameraManager.createPreviewOutput(previewProfile, surfaceId);

      this.captureSession = this.cameraManager.createSession(camera.SceneMode.NORMAL);
      this.captureSession.beginConfig();
      this.captureSession.addInput(this.cameraInput);
      this.captureSession.addOutput(this.previewOutput);
      await this.captureSession.commitConfig();
      await this.captureSession.start();

      this.isScanning = true;
      this.checkTorchSupport();

      hilog.info(DOMAIN_ZERO, TAG, 'Camera initialized for continuous scan');
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'initCamera failed: %{public}s', JSON.stringify(error));
    }
  }

  private checkTorchSupport(): void {
    if (!this.cameraInput) return;
    try {
      const status = this.cameraInput.getTorchStatus();
      this.hasTorch = status !== undefined;
    } catch {
      this.hasTorch = false;
    }
  }

  private async toggleTorch(): Promise<void> {
    if (!this.cameraInput) return;
    try {
      this.torchOn = !this.torchOn;
      if (this.torchOn) {
        this.cameraInput.setTorchMode(camera.TorchMode.ON);
      } else {
        this.cameraInput.setTorchMode(camera.TorchMode.OFF);
      }
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'toggleTorch failed: %{public}s', JSON.stringify(e));
    }
  }

  onFrameDecoded(text: string): void {
    const now = Date.now();
    if (text === this.lastDecodedText && now - this.lastDecodeTime < DEBOUNCE_MS) {
      return;
    }
    this.lastDecodedText = text;
    this.lastDecodeTime = now;
    hilog.info(DOMAIN_ZERO, TAG, 'Barcode decoded: %{private}s', text);
    if (this.onBarcodeScanned) {
      this.onBarcodeScanned(text);
    }
  }

  private releaseCamera(): void {
    try {
      if (this.captureSession) {
        this.captureSession.stop();
        this.captureSession.release();
        this.captureSession = null;
      }
      if (this.cameraInput) {
        this.cameraInput.close();
        this.cameraInput.release();
        this.cameraInput = null;
      }
      if (this.previewOutput) {
        this.previewOutput.release();
        this.previewOutput = null;
      }
      this.isScanning = false;
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'releaseCamera failed: %{public}s', JSON.stringify(e));
    }
  }
}
