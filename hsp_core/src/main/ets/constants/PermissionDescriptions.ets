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
  static readonly READ_IMAGEVIDEO: string = '用于读取相册图片以进行配料表OCR识别';
  static readonly WRITE_IMAGEVIDEO: string = '用于保存扫描结果截图和分享图片到相册';
  static readonly VIBRATE: string = '用于扫码成功时振动反馈';
  static readonly PUBLISH_AGENT_REMINDER: string = '用于后台定时提醒用餐记录';
  static readonly DISTRIBUTED_DATASYNC: string = '用于跨设备同步家庭成员数据';

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
      case 'READ_IMAGEVIDEO':
        return PermissionDescriptions.READ_IMAGEVIDEO;
      case 'WRITE_IMAGEVIDEO':
        return PermissionDescriptions.WRITE_IMAGEVIDEO;
      case 'VIBRATE':
        return PermissionDescriptions.VIBRATE;
      case 'PUBLISH_AGENT_REMINDER':
        return PermissionDescriptions.PUBLISH_AGENT_REMINDER;
      case 'DISTRIBUTED_DATASYNC':
        return PermissionDescriptions.DISTRIBUTED_DATASYNC;
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
    map.set('READ_IMAGEVIDEO', PermissionDescriptions.READ_IMAGEVIDEO);
    map.set('WRITE_IMAGEVIDEO', PermissionDescriptions.WRITE_IMAGEVIDEO);
    map.set('VIBRATE', PermissionDescriptions.VIBRATE);
    map.set('PUBLISH_AGENT_REMINDER', PermissionDescriptions.PUBLISH_AGENT_REMINDER);
    map.set('DISTRIBUTED_DATASYNC', PermissionDescriptions.DISTRIBUTED_DATASYNC);
    return map;
  }
}
