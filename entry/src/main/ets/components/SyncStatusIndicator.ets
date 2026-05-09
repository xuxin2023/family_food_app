// SyncStatusIndicator.ets
// 同步状态指示器组件 - 显示当前同步状态图标和待同步数量

import { SyncService, SyncEvent } from '../service/sync/SyncService';
import { NetworkState } from '../service/NetworkMonitorService';
import { AppState } from '../AppState';
import { HILOG_DOMAIN } from '../constants/AppConfig';

@ComponentV2
export struct SyncStatusIndicator {
  @Local private isSyncing: boolean = false;
  @Local private pendingCount: number = 0;
  @Local private isConnected: boolean = false;
  @Local private isCloudBound: boolean = false;
  @Local private syncEnabled: boolean = false;

  private syncService: SyncService = AppState.getInstance().services.syncService;

  aboutToAppear(): void {
    this.refreshState();
    // 监听同步事件
    this.syncService.onEvent(this.onSyncEvent);
  }

  aboutToDisappear(): void {
    this.syncService.offEvent(this.onSyncEvent);
  }

  build() {
    Row({ space: 4 }) {
      if (!this.isCloudBound) {
        // 未绑定云端 - 显示灰色云
        Image($r('app.media.app_icon'))
          .width(16)
          .height(16)
          .opacity(0.4)
      } else if (!this.syncEnabled) {
        // 同步已关闭
        Image($r('app.media.app_icon'))
          .width(16)
          .height(16)
          .opacity(0.5)
      } else if (this.isSyncing) {
        // 同步中 - 显示旋转动画
        LoadingProgress()
          .width(16)
          .height(16)
          .color(Color.Blue)
      } else if (!this.isConnected) {
        // 离线 - 显示离线云
        Image($r('app.media.app_icon'))
          .width(16)
          .height(16)
          .opacity(0.6)
          .colorFilter(
            new ColorFilter([0.5, 0, 0, 0, 0, 0.5, 0, 0, 0, 0.5, 0, 0, 0, 0, 0, 0, 0, 1, 0])
          )
      } else if (this.pendingCount > 0) {
        // 有待同步项
        Stack() {
          Image($r('app.media.app_icon'))
            .width(16)
            .height(16)
          Text(`${this.pendingCount}`)
            .fontSize(8)
            .fontColor(Color.White)
            .backgroundColor(Color.Red)
            .borderRadius(6)
            .width(12)
            .height(12)
            .textAlign(TextAlign.Center)
            .position({ x: 10, y: -4 })
        }
        .width(20)
        .height(20)
      } else {
        // 已同步
        Image($r('app.media.app_icon'))
          .width(16)
          .height(16)
          .opacity(0.8)
      }
    }
  }

  private refreshState(): void {
    const config = this.syncService.getConfig();
    this.syncEnabled = config.enabled;
    this.pendingCount = config.pendingCount;
    this.isConnected = this.syncService.getNetworkMonitor().isConnected();
    this.isCloudBound = AppState.getInstance().services.cloudAuthService.isCloudAccountBound();
  }

  private onSyncEvent = (event: SyncEvent): void => {
    switch (event.type) {
      case 'sync_started':
        this.isSyncing = true;
        break;
      case 'sync_completed':
      case 'sync_failed':
        this.isSyncing = false;
        this.refreshState();
        break;
      case 'queue_changed':
      case 'network_changed':
        this.refreshState();
        break;
    }
  };
}