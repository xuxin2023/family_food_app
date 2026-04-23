export type ShareTarget = 'family' | 'wechat';

export interface ShareActionResult {
  success: boolean;
  message: string;
}

export interface ShareProvider {
  getCopyHint(): string;
  shareText(target: ShareTarget, text: string): Promise<ShareActionResult>;
  saveAsImage(componentId: string): Promise<ShareActionResult>;
  saveToAlbum(imageUri: string): Promise<ShareActionResult>;
}
