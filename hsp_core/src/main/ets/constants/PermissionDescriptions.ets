// PermissionDescriptions.ets
// 权限使用说明常量 - 供 PermissionGuideDialog 展示
// 每个权限对应的用户友好说明

export class PermissionDescriptions {
  static readonly CAMERA: string = '用于扫码识别食品条码';
  static readonly INTERNET: string = '用于查询全球食品数据库';
  static readonly ACTIVITY_RECOGNITION: string = '用于联动运动数据优化营养建议';
  static readonly KEEP_BACKGROUND_RUNNING: string = '用于定时提醒饮食记录';
  static readonly READ_HEALTH_DATA: string = '用于读取华为健康数据（步数、睡眠等）';
  static readonly LOCATION: string = '用于获取本地食品推荐';
  static readonly NOTIFICATION: string = '用于发送用餐提醒和健康预警通知';

  static getDescription(permission: string): string {
    switch (permission) {
      case 'CAMERA':
        return PermissionDescriptions.CAMERA;
      case 'INTERNET':
        return PermissionDescriptions.INTERNET;
      case 'ACTIVITY_RECOGNITION':
        return PermissionDescriptions.ACTIVITY_RECOGNITION;
      case 'KEEP_BACKGROUND_RUNNING':
        return PermissionDescriptions.KEEP_BACKGROUND_RUNNING;
      case 'READ_HEALTH_DATA':
        return PermissionDescriptions.READ_HEALTH_DATA;
      case 'LOCATION':
        return PermissionDescriptions.LOCATION;
      case 'NOTIFICATION':
        return PermissionDescriptions.NOTIFICATION;
      default:
        return '用于提供应用核心功能';
    }
  }

  static getAllDescriptions(): Map<string, string> {
    const map = new Map<string, string>();
    map.set('CAMERA', PermissionDescriptions.CAMERA);
    map.set('INTERNET', PermissionDescriptions.INTERNET);
    map.set('ACTIVITY_RECOGNITION', PermissionDescriptions.ACTIVITY_RECOGNITION);
    map.set('KEEP_BACKGROUND_RUNNING', PermissionDescriptions.KEEP_BACKGROUND_RUNNING);
    map.set('READ_HEALTH_DATA', PermissionDescriptions.READ_HEALTH_DATA);
    map.set('LOCATION', PermissionDescriptions.LOCATION);
    map.set('NOTIFICATION', PermissionDescriptions.NOTIFICATION);
    return map;
  }
}
