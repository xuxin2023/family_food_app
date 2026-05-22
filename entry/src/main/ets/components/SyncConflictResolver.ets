// SyncConflictResolver.ets
// 同步冲突解决组件 - 当冲突策略为MANUAL时展示UI供用户选择
// 符合HarmonyOS 6.1 V2状态管理规范

@ComponentV2
export struct SyncConflictResolver {
  @Param entityType: string = '';
  @Param entityId: string = '';
  @Param localSummary: string = '';
  @Param remoteSummary: string = '';
  @Event onResolve: (useLocal: boolean) => void = (_useLocal: boolean) => {};

  build() {
    Column() {
      Text($r('app.string.sync_conflict_title'))
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 12 })

      Text(`${$r('app.string.sync_conflict_type_prefix')}${this.entityType}  ID: ${this.entityId}`)
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))
        .margin({ bottom: 12 })

      Row() {
        Column() {
          Text($r('app.string.sync_conflict_local_version'))
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 4 })
          Text(this.localSummary || $r('app.string.sync_conflict_local_default') as string)
            .fontSize(11)
            .fontColor('#999999')
            .maxLines(2)
        }
        .layoutWeight(1)
        .padding(8)
        .borderRadius(8)
        .backgroundColor($r('app.color.bg_light_green'))
        .onClick(() => {
          this.onResolve(true);
        })
        .accessibilityText($r('app.string.sync_conflict_use_local_acc'))

        Column() {
          Text($r('app.string.sync_conflict_cloud_version'))
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 4 })
          Text(this.remoteSummary || $r('app.string.sync_conflict_cloud_default') as string)
            .fontSize(11)
            .fontColor('#999999')
            .maxLines(2)
        }
        .layoutWeight(1)
        .padding(8)
        .borderRadius(8)
        .backgroundColor($r('app.color.bg_warm_blue'))
        .margin({ left: 8 })
        .onClick(() => {
          this.onResolve(false);
        })
        .accessibilityText($r('app.string.sync_conflict_use_cloud_acc'))
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
  }
}
