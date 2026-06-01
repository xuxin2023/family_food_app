// AuditLogger.ets
// 结构化审计日志 — 记录关键业务操作的时间、用户ID、操作类型、操作结果

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
  SHARE_REPORT = 'share_report'
}

export class AuditEntry {
  timestamp: number = 0;
  memberId: string = '';
  action: string = '';
  result: string = '';
  detail: string = '';
  clientIp: string = '';
}

const MAX_AUDIT_ENTRIES = 200;
let auditLog: AuditEntry[] = [];

export class AuditLogger {
  static log(
    action: AuditAction | string,
    result: 'success' | 'failure' | 'denied',
    memberId: string = '',
    detail: string = ''
  ): void {
    const entry: AuditEntry = {
      timestamp: Date.now(),
      memberId: memberId,
      action: typeof action === 'string' ? action : action,
      result: result,
      detail: detail.substring(0, 200),
      clientIp: ''
    };

    auditLog.push(entry);
    if (auditLog.length > MAX_AUDIT_ENTRIES) {
      auditLog = auditLog.slice(-MAX_AUDIT_ENTRIES);
    }

    hilog.info(DOMAIN_ZERO, TAG,
      '[AUDIT] %{public}s | member=%{public}s | action=%{public}s | result=%{public}s | detail=%{public}s',
      new Date(entry.timestamp).toISOString(),
      memberId,
      entry.action,
      result,
      detail.substring(0, 100)
    );
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

  static clear(): void {
    auditLog = [];
  }
}