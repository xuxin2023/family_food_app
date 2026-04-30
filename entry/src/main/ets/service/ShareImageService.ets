import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { Recommendation, RecommendLevel } from '../model/Recommendation';
import { FamilyProfile } from '../model/FamilyProfile';

const TAG = 'ShareImageService';
const DOMAIN_ZERO = 0;

export interface ShareCardParams {
  foodName: string;
  recommendations: Recommendation[];
  members: FamilyProfile[];
  appName: string;
}

export class ShareImageService {
  // P0版本：图片生成功能标记为后续实现
  async generateShareImage(context: common.Context, params: ShareCardParams): Promise<string> {
    hilog.info(DOMAIN_ZERO, TAG, 'Share image generation: P0 version returns empty');
    return '';
  }
}
