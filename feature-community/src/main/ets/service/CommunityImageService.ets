import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { SecureHttpHelper, SecureJsonResponse } from 'hsp_service';
import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { http } from '@kit.NetworkKit';

const TAG = 'CommunityImageService';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
const MAX_IMAGE_SIZE_BYTES = 5 * 1024 * 1024;
const COMPRESSION_QUALITY = 80;

export class ImageUploadResult {
  url: string = '';
  thumbnailUrl: string = '';
  width: number = 0;
  height: number = 0;
  sizeKB: number = 0;
}

export class CommunityImageService {
  private static instance: CommunityImageService | null = null;
  private context: common.Context | null = null;

  static getInstance(): CommunityImageService {
    if (!CommunityImageService.instance) {
      CommunityImageService.instance = new CommunityImageService();
    }
    return CommunityImageService.instance;
  }

  init(context: common.Context): void {
    this.context = context;
  }

  async uploadImage(localPath: string, category: string = 'recipe'): Promise<ImageUploadResult> {
    const result: ImageUploadResult = new ImageUploadResult();

    try {
      const stat = await fileIo.stat(localPath);
      if (stat.size > MAX_IMAGE_SIZE_BYTES) {
        hilog.warn(DOMAIN_ZERO, TAG, 'Image too large: %{public}d bytes', stat.size);
        throw new Error('图片大小超过5MB限制');
      }

      result.sizeKB = Math.round(stat.size / 1024);

      const fileName = `${category}_${Date.now()}_${Math.random().toString(36).substring(2, 8)}.jpg`;
      const uploadUrl = `/upload/image?category=${category}&fileName=${fileName}`;

      const header = new Map<string, string>();
      header.set('Content-Type', 'multipart/form-data');
      const uploadBody = new Map<string, Object>();
      uploadBody.set('localPath', localPath as Object);
      uploadBody.set('field', 'image' as Object);
      const response: SecureJsonResponse = await SecureHttpHelper.post(uploadUrl, uploadBody as Object, header, 30000);

      if (response.responseCode === 200 && response.data) {
        const data = response.data;
        result.url = (data.get('url') as string) ?? '';
        result.thumbnailUrl = (data.get('thumbnailUrl') as string) ?? result.url;
        result.width = (data.get('width') as number) ?? 0;
        result.height = (data.get('height') as number) ?? 0;

        hilog.info(DOMAIN_ZERO, TAG, 'Image uploaded: %{public}s (%{public}dKB)',
          result.url, result.sizeKB);
      } else {
        result.url = await this.saveToLocal(localPath, fileName);
        result.thumbnailUrl = result.url;
        hilog.info(DOMAIN_ZERO, TAG, 'Cloud upload failed, saved locally: %{public}s', result.url);
      }
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Image upload failed: %{public}s', JSON.stringify(error));
      throw new Error(JSON.stringify(error));
    }

    return result;
  }

  async uploadMultipleImages(paths: string[], category: string = 'recipe'): Promise<ImageUploadResult[]> {
    const results: ImageUploadResult[] = [];
    for (const path of paths) {
      try {
        const result = await this.uploadImage(path, category);
        results.push(result);
      } catch (_) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_));
        continue;
      }
    }
    return results;
  }

  private async saveToLocal(srcPath: string, fileName: string): Promise<string> {
    if (!this.context) return '';
    const filesDir = this.context.filesDir + '/community_images';
    try {
      await fileIo.access(filesDir);
    } catch (_) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_));
      await fileIo.mkdir(filesDir);
    }
    const destPath = filesDir + '/' + fileName;
    await fileIo.copyFile(srcPath, destPath);
    return destPath;
  }
}
