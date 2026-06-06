// hsp-core: AuditLogger PIA 个人信息保护影响评估审计增强
// 增加数据分级(PIA_LEVEL)、数据收集清单自动生成、保留期限标记

import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from '../constants/AppConfig';

const TAG = 'AuditLogger';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export enum AuditAction {
  LOGIN = 'login',
  LOGOUT = 'logout',
  SCAN_BARCODE = 'scan_barcode',
  SCAN_OCR = 'scan_ocr',
  VIEW_REPORT = 'view_report',
  EXPORT_DATA = 'export_data',
  DELETE_DATA = 'delete_data',
  MODIFY_ALLERGY_PROFILE = 'modify_allergy_profile',
  MODIFY_NUTRITION_TARGET = 'modify_nutrition_target',
  CLOUD_SYNC = 'cloud_sync',
  PRIVACY_AGREE = 'privacy_agree',
  PERMISSION_GRANT = 'permission_grant',
  PERMISSION_DENY = 'permission_deny',
  PURCHASE = 'purchase',
  SHARE_REPORT = 'share_report',
  DATA_ACCESS = 'data_access',
  DATA_RETENTION_CHECK = 'data_retention_check',
}

export enum PIASensitivity {
  SENSITIVE = 'SENSITIVE',
  CONFIDENTIAL = 'CONFIDENTIAL',
  INTERNAL = 'INTERNAL',
  PUBLIC = 'PUBLIC',
}

export class AuditEntry {
  timestamp: number = 0;
  memberId: string = '';
  action: string = '';
  result: string = '';
  detail: string = '';
  clientIp: string = '';
  piaLevel: PIASensitivity = PIASensitivity.INTERNAL;
  retentionDays: number = 365;
}

export interface DataInventoryItem {
  dataType: string;
  description: string;
  piaLevel: PIASensitivity;
  collectionPurpose: string;
  storageLocation: 'device' | 'cloud' | 'both';
  retentionDays: number;
  isMandatory: boolean;
}

const DATA_INVENTORY: DataInventoryItem[] = [
  { dataType: '家庭档案', description: '家庭成员基本信息(年龄/性别/关系)', piaLevel: PIASensitivity.SENSITIVE, collectionPurpose: '个性化食品适配推荐', storageLocation: 'both', retentionDays: 0, isMandatory: true },
  { dataType: '过敏原档案', description: '过敏原、不耐受类型列表', piaLevel: PIASensitivity.SENSITIVE, collectionPurpose: '过敏原/不耐受预警', storageLocation: 'both', retentionDays: 0, isMandatory: false },
  { dataType: '健康信号', description: '身高/体重/BMI/步数等健康数据', piaLevel: PIASensitivity.SENSITIVE, collectionPurpose: '营养目标动态调整', storageLocation: 'device', retentionDays: 90, isMandatory: false },
  { dataType: '扫描历史', description: '食品条码扫描记录', piaLevel: PIASensitivity.CONFIDENTIAL, collectionPurpose: '历史回溯与趋势分析', storageLocation: 'both', retentionDays: 365, isMandatory: false },
  { dataType: '饮食记录', description: '每日饮食摄入记录', piaLevel: PIASensitivity.CONFIDENTIAL, collectionPurpose: '营养摄入追踪', storageLocation: 'both', retentionDays: 365, isMandatory: false },
  { dataType: '营养目标', description: '个人营养目标设置', piaLevel: PIASensitivity.INTERNAL, collectionPurpose: '个性化推荐', storageLocation: 'both', retentionDays: 0, isMandatory: false },
  { dataType: '设备标识', description: '设备型号/系统版本/设备ID', piaLevel: PIASensitivity.INTERNAL, collectionPurpose: '适配与安全验证', storageLocation: 'cloud', retentionDays: 90, isMandatory: true },
  { dataType: '推送令牌', description: '华为Push Kit令牌', piaLevel: PIASensitivity.INTERNAL, collectionPurpose: '消息推送', storageLocation: 'cloud', retentionDays: 0, isMandatory: false },
  { dataType: '崩溃日志', description: '应用崩溃堆栈信息', piaLevel: PIASensitivity.INTERNAL, collectionPurpose: '稳定性改进', storageLocation: 'device', retentionDays: 30, isMandatory: true },
  { dataType: '审计日志', description: '关键操作审计记录', piaLevel: PIASensitivity.INTERNAL, collectionPurpose: '安全审计与合规', storageLocation: 'device', retentionDays: 200, isMandatory: true },
];

const MAX_AUDIT_ENTRIES = 500;
const ACTION_PIA_MAP: Map<string, PIASensitivity> = new Map([
  [AuditAction.SCAN_BARCODE, PIASensitivity.CONFIDENTIAL],
  [AuditAction.MODIFY_ALLERGY_PROFILE, PIASensitivity.SENSITIVE],
  [AuditAction.VIEW_REPORT, PIASensitivity.CONFIDENTIAL],
  [AuditAction.DELETE_DATA, PIASensitivity.SENSITIVE],
  [AuditAction.EXPORT_DATA, PIASensitivity.SENSITIVE],
  [AuditAction.PURCHASE, PIASensitivity.SENSITIVE],
  [AuditAction.SHARE_REPORT, PIASensitivity.CONFIDENTIAL],
  [AuditAction.CLOUD_SYNC, PIASensitivity.CONFIDENTIAL],
]);

let auditLog: AuditEntry[] = [];

export class AuditLogger {
  static log(
    action: AuditAction | string,
    result: 'success' | 'failure' | 'denied',
    memberId: string = '',
    detail: string = ''
  ): void {
    const actionStr = typeof action === 'string' ? action : action;
    const piaLevel = ACTION_PIA_MAP.get(actionStr) ?? PIASensitivity.INTERNAL;

    const entry: AuditEntry = {
      timestamp: Date.now(),
      memberId: memberId,
      action: actionStr,
      result: result,
      detail: detail.substring(0, 200),
      clientIp: '',
      piaLevel: piaLevel,
      retentionDays: piaLevel === PIASensitivity.SENSITIVE ? 90 : 365,
    };

    auditLog.push(entry);
    if (auditLog.length > MAX_AUDIT_ENTRIES) {
      auditLog = auditLog.slice(-MAX_AUDIT_ENTRIES);
    }

    hilog.info(DOMAIN_ZERO, TAG,
      '[AUDIT][%{public}s] %{public}s | member=%{public}s | action=%{public}s | result=%{public}s',
      piaLevel,
      new Date(entry.timestamp).toISOString(),
      memberId,
      entry.action,
      result
    );
  }

  static logSensitive(
    action: AuditAction | string,
    result: 'success' | 'failure' | 'denied',
    memberId: string = '',
    detail: string = ''
  ): void {
    AuditLogger.log(action, result, memberId, detail);
  }

  static generateDataInventory(): DataInventoryItem[] {
    return [...DATA_INVENTORY];
  }

  static getPIALevelSummary(): { level: string; count: number }[] {
    const summary = new Map<string, number>();
    for (const item of DATA_INVENTORY) {
      summary.set(item.piaLevel, (summary.get(item.piaLevel) ?? 0) + 1);
    }
    return Array.from(summary.entries()).map(([level, count]) => ({ level, count }));
  }

  static getRecentEntries(limit: number = 50): AuditEntry[] {
    return auditLog.slice(-limit);
  }

  static getEntriesByAction(action: string): AuditEntry[] {
    return auditLog.filter((e: AuditEntry) => e.action === action);
  }

  static getEntriesByMember(memberId: string): AuditEntry[] {
    return auditLog.filter((e: AuditEntry) => e.memberId === memberId);
  }

  static getEntriesByPIALevel(level: PIASensitivity): AuditEntry[] {
    return auditLog.filter((e: AuditEntry) => e.piaLevel === level);
  }

  static getSensitiveAccessLog(memberId: string): AuditEntry[] {
    return auditLog.filter(
      (e: AuditEntry) =>
        e.memberId === memberId &&
        e.piaLevel === PIASensitivity.SENSITIVE &&
        (Date.now() - e.timestamp) < 90 * 24 * 60 * 60 * 1000
    );
  }

  static clear(): void {
    auditLog = [];
  }

  static exportAuditReport(): string {
    const inventory = AuditLogger.generateDataInventory();
    const summary = AuditLogger.getPIALevelSummary();
    const lines: string[] = [
      '# 个人信息保护影响评估 (PIA) 审计报告',
      `生成时间: ${new Date().toISOString()}`,
      `审计条目总数: ${auditLog.length}`,
      '',
      '## 数据收集清单',
    ];
    for (const item of inventory) {
      lines.push(
        `- [${item.piaLevel}] ${item.dataType}: ${item.description} (存储:${item.storageLocation}, 保留:${item.retentionDays}天)`
      );
    }
    lines.push('', '## PIA 分级汇总');
    for (const s of summary) {
      lines.push(`- ${s.level}: ${s.count}项`);
    }
    return lines.join('\n');
  }
}
