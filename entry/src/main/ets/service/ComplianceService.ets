// ComplianceService.ets
// 合规服务 — 未成年人模式 + 数据导出 + 隐私计算
// 满足华为应用商店 2025+ 合规要求

import { HILOG_DOMAIN, AgeGroup } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'ComplianceService';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export class MinorRestrictions {
  disableCommunity: boolean = true;
  disableAIShare: boolean = true;
  disableThirdPartyLogin: boolean = true;
  maxDailyScanCount: number = 20;
  dataRetentionDays: number = 30;
  disableGroupCreation: boolean = true;
  contentFilterLevel: string = 'strict';
}

export class DataExportPackage {
  memberProfiles: string = '';
  scanHistory: string = '';
  dietRecords: string = '';
  favoriteItems: string = '';
  settings: string = '';
  exportedAt: number = 0;
  format: string = 'json';
}

export class ComplianceService {
  private static readonly MINOR_AGE_GROUPS: Set<string> = new Set([
    AgeGroup.INFANT, AgeGroup.TODDLER, AgeGroup.CHILD, AgeGroup.TEEN
  ]);

  static isMinorMode(ageGroup: string): boolean {
    return ComplianceService.MINOR_AGE_GROUPS.has(ageGroup);
  }

  static getMinorRestrictions(): MinorRestrictions {
    const restrictions = new MinorRestrictions();
    restrictions.disableCommunity = true;
    restrictions.disableAIShare = true;
    restrictions.disableThirdPartyLogin = true;
    restrictions.maxDailyScanCount = 20;
    restrictions.dataRetentionDays = 30;
    restrictions.disableGroupCreation = true;
    restrictions.contentFilterLevel = 'strict';
    return restrictions;
  }

  static getAdultRestrictions(): MinorRestrictions {
    const restrictions = new MinorRestrictions();
    restrictions.disableCommunity = false;
    restrictions.disableAIShare = false;
    restrictions.disableThirdPartyLogin = false;
    restrictions.maxDailyScanCount = 999;
    restrictions.dataRetentionDays = 365;
    restrictions.disableGroupCreation = false;
    restrictions.contentFilterLevel = 'standard';
    return restrictions;
  }

  static checkScanLimit(ageGroup: string, todayScanCount: number): boolean {
    const restrictions = ComplianceService.isMinorMode(ageGroup)
      ? ComplianceService.getMinorRestrictions()
      : ComplianceService.getAdultRestrictions();
    const allowed = todayScanCount < restrictions.maxDailyScanCount;
    if (!allowed) {
      hilog.warn(DOMAIN_ZERO, TAG,
        'Scan limit reached for ageGroup=%{public}s: %{public}d/%{public}d',
        ageGroup, todayScanCount, restrictions.maxDailyScanCount);
    }
    return allowed;
  }

  static isFeatureAllowedForAge(feature: string, ageGroup: string): boolean {
    if (!ComplianceService.isMinorMode(ageGroup)) return true;
    const minorFeatures: Set<string> = new Set([
      'scan', 'report', 'history', 'nutrition_knowledge',
      'favorite', 'shopping_list', 'meal_plan'
    ]);
    return minorFeatures.has(feature);
  }

  static buildDataExportPackage(
    memberProfiles: string,
    scanHistory: string,
    dietRecords: string,
    favoriteItems: string,
    settings: string
  ): DataExportPackage {
    const pkg = new DataExportPackage();
    pkg.memberProfiles = memberProfiles;
    pkg.scanHistory = scanHistory;
    pkg.dietRecords = dietRecords;
    pkg.favoriteItems = favoriteItems;
    pkg.settings = settings;
    pkg.exportedAt = Date.now();
    pkg.format = 'json';
    hilog.info(DOMAIN_ZERO, TAG, 'Data export package built at %{public}d', pkg.exportedAt);
    return pkg;
  }

  static getDataRetentionDays(ageGroup: string): number {
    return ComplianceService.isMinorMode(ageGroup)
      ? ComplianceService.getMinorRestrictions().dataRetentionDays
      : ComplianceService.getAdultRestrictions().dataRetentionDays;
  }
}
