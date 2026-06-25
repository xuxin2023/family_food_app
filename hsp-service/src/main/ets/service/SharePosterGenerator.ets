import { common } from '@kit.AbilityKit';
import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';

const TAG = 'SharePosterGenerator';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

const POSTER_WIDTH = 750;
const POSTER_HEIGHT = 1334;
const PADDING = 48;
const PRIMARY_COLOR = '#1976D2';
const TEXT_COLOR = '#333333';
const SUBTITLE_COLOR = '#757575';
const BG_COLOR = '#FFFFFF';

export class PosterNutritionItem {
  name: string = '';
  value: string = '';
  unit: string = ''
}

export class PosterData {
  foodName: string = ''
  brand: string = ''
  nutritionScore: number = 50
  novaGroup: number = 2
  nutritionItems: PosterNutritionItem[] = []
  qrCodeUri: string = ''
  shareLink: string = ''
  appLogoUri: string = ''
}

export class SharePosterGenerator {
  private context: common.Context

  constructor(context: common.Context) {
    this.context = context;
  }

  async generatePoster(data: PosterData): Promise<string> {
    try {
      const tempDir = this.context.tempDir;
      const posterPath = `${tempDir}/share_poster_${Date.now()}.png`;

      const pixelMap = await this.renderPosterToPixelMap(data);
      await this.savePixelMapToFile(pixelMap, posterPath);
      pixelMap.release();

      hilog.info(DOMAIN_ZERO, TAG, 'Poster generated: %{public}s', posterPath);
      return posterPath;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'generatePoster failed: %{public}s', JSON.stringify(error));
      throw new Error('海报生成失败');
    }
  }

  private async renderPosterToPixelMap(data: PosterData): Promise<image.PixelMap> {
    const bufferSize = POSTER_WIDTH * POSTER_HEIGHT * 4;
    const buffer: ArrayBuffer = new ArrayBuffer(bufferSize);

    const opts: image.InitializationOptions = {
      size: { width: POSTER_WIDTH, height: POSTER_HEIGHT },
      pixelFormat: image.PixelMapFormat.RGBA_8888,
      editable: true
    };
    let pixelMap: image.PixelMap;
    try {
      pixelMap = await image.createPixelMap(buffer, opts);
    } catch (err) {
      hilog.error(DOMAIN_ZERO, TAG, 'createPixelMap failed: %{public}s', JSON.stringify(err));
      throw new Error('createPixelMap failed');
    }

    const canvas: CanvasRenderingContext2D = new CanvasRenderingContext2D()
    // Canvas size is determined by the pixel map, not settable directly

    this.drawBackground(canvas);
    this.drawHeader(canvas, data);
    this.drawScoreRing(canvas, data);
    this.drawNutritionItems(canvas, data);
    this.drawNovaGroup(canvas, data);
    this.drawQrCode(canvas, data);
    this.drawWatermark(canvas, data);

    return pixelMap;
  }

  private drawBackground(canvas: CanvasRenderingContext2D): void {
    canvas.fillStyle = BG_COLOR;
    canvas.fillRect(0, 0, POSTER_WIDTH, POSTER_HEIGHT);
    canvas.fillStyle = PRIMARY_COLOR;
    canvas.fillRect(0, 0, POSTER_WIDTH, 8);
  }

  private drawHeader(canvas: CanvasRenderingContext2D, data: PosterData): void {
    canvas.fillStyle = PRIMARY_COLOR;
    canvas.font = 'bold 40px sans-serif';
    canvas.fillText(data.foodName, PADDING, 100);

    if (data.brand.length > 0) {
      canvas.fillStyle = SUBTITLE_COLOR;
      canvas.font = '24px sans-serif';
      canvas.fillText(data.brand, PADDING, 140);
    }
  }

  private drawScoreRing(canvas: CanvasRenderingContext2D, data: PosterData): void {
    const centerX = POSTER_WIDTH / 2;
    const centerY = 280;
    const radius = 80;
    const lineWidth = 16;
    const startAngle = -Math.PI / 2;
    const endAngle = startAngle + (2 * Math.PI * data.nutritionScore / 100);

    canvas.lineWidth = lineWidth;
    canvas.lineCap = 'round';

    canvas.strokeStyle = '#E0E0E0';
    canvas.beginPath();
    canvas.arc(centerX, centerY, radius, 0, 2 * Math.PI);
    canvas.stroke();

    const scoreColor = data.nutritionScore >= 70 ? '#4CAF50'
      : data.nutritionScore >= 40 ? '#FF9800' : '#F44336';
    canvas.strokeStyle = scoreColor;
    canvas.beginPath();
    canvas.arc(centerX, centerY, radius, startAngle, endAngle);
    canvas.stroke();

    canvas.fillStyle = TEXT_COLOR;
    canvas.font = 'bold 48px sans-serif';
    canvas.textAlign = 'center';
    canvas.fillText(`${data.nutritionScore}`, centerX, centerY + 16);
    canvas.font = '18px sans-serif';
    canvas.fillText('营养评分', centerX, centerY + 44);
    canvas.textAlign = 'left';
  }

  private drawNutritionItems(canvas: CanvasRenderingContext2D, data: PosterData): void {
    const startY = 420;
    canvas.fillStyle = TEXT_COLOR;
    canvas.font = 'bold 28px sans-serif';
    canvas.fillText('关键营养指标', PADDING, startY);

    let y = startY + 48;
    for (const item of data.nutritionItems) {
      canvas.fillStyle = SUBTITLE_COLOR;
      canvas.font = '22px sans-serif';
      canvas.fillText(item.name, PADDING, y);
      canvas.fillStyle = TEXT_COLOR;
      canvas.font = 'bold 22px sans-serif';
      const valueText = `${item.value}${item.unit}`;
      canvas.fillText(valueText, POSTER_WIDTH - PADDING - canvas.measureText(valueText).width, y);
      y += 44;
    }
  }

  private drawNovaGroup(canvas: CanvasRenderingContext2D, data: PosterData): void {
    const y = 420 + 48 + data.nutritionItems.length * 44 + 40;
    const novaLabels = ['未加工', '加工烹饪', '加工食品', '超加工食品'];
    const label = novaLabels[data.novaGroup - 1] || '未知';

    canvas.fillStyle = TEXT_COLOR;
    canvas.font = 'bold 28px sans-serif';
    canvas.fillText('NOVA 加工等级', PADDING, y);

    canvas.fillStyle = data.novaGroup <= 2 ? '#4CAF50' : '#FF9800';
    canvas.font = 'bold 32px sans-serif';
    canvas.fillText(`第${data.novaGroup}级 · ${label}`, PADDING, y + 44);
  }

  private drawQrCode(canvas: CanvasRenderingContext2D, data: PosterData): void {
    const y = POSTER_HEIGHT - 260;
    canvas.fillStyle = '#F5F5F5';
    canvas.fillRect(0, y - 20, POSTER_WIDTH, POSTER_HEIGHT - y + 20);

    if (data.shareLink.length > 0) {
      canvas.fillStyle = SUBTITLE_COLOR;
      canvas.font = '20px sans-serif';
      canvas.textAlign = 'center';
      canvas.fillText('扫码查看详细报告', POSTER_WIDTH / 2, y + 20);
      canvas.textAlign = 'left';
    }

    if (data.qrCodeUri.length > 0) {
      hilog.info(DOMAIN_ZERO, TAG, 'QR code URI provided, rendering placeholder');
    }
  }

  private drawWatermark(canvas: CanvasRenderingContext2D, data: PosterData): void {
    const y = POSTER_HEIGHT - 60;
    canvas.fillStyle = '#BDBDBD';
    canvas.font = '18px sans-serif';
    canvas.textAlign = 'center';
    canvas.fillText('家庭食品适配助手', POSTER_WIDTH / 2, y);
    canvas.textAlign = 'left';
  }

  private async savePixelMapToFile(pixelMap: image.PixelMap, filePath: string): Promise<void> {
    const packingOpts: image.PackingOption = { format: 'image/png', quality: 95 };
    let imagePackerApi: image.ImagePacker;
    try {
      imagePackerApi = image.createImagePacker();
    } catch (err) {
      hilog.error(DOMAIN_ZERO, TAG, 'createImagePacker failed: %{public}s', JSON.stringify(err));
      throw new Error('createImagePacker failed');
    }
    let packedData: ArrayBuffer;
    try {
      packedData = await imagePackerApi.packing(pixelMap, packingOpts);
    } catch (err) {
      hilog.error(DOMAIN_ZERO, TAG, 'packing failed: %{public}s', JSON.stringify(err));
      try { imagePackerApi.release(); } catch (_) {}
      throw new Error('Image packing failed');
    }
    const file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY);
    fileIo.writeSync(file.fd, packedData);
    fileIo.closeSync(file.fd);
    try { imagePackerApi.release(); } catch (_) {}
  }
}
