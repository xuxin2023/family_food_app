export enum ShareTarget {
  FAMILY = 'family',
  WECHAT = 'wechat'
}

export class ShareActionResult {
  success: boolean = false;
  message: string = '';
}

export abstract class ShareProvider {
  abstract getCopyHint(): string;
  abstract shareText(target: ShareTarget, text: string): Promise<ShareActionResult>;
  abstract saveAsImage(componentId: string): Promise<ShareActionResult>;
  abstract saveToAlbum(imageUri: string): Promise<ShareActionResult>;
}
