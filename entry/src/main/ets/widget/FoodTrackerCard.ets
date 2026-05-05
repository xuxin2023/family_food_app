// FoodTrackerCard.ets
// 营养追踪卡片 - 展示今日饮食概览、卡路里进度、饮水进度

let storage = new LocalStorage();

@Entry(storage)
@Component
struct FoodTrackerCard {
  // 卡片数据绑定
  @LocalStorageProp('formId') formId: string = '';
  @LocalStorageProp('todayMenu') todayMenu: string = '点击查看今日推荐';
  @LocalStorageProp('calorieTarget') calorieTarget: string = '---';
  @LocalStorageProp('calorieIntake') calorieIntake: string = '---';
  @LocalStorageProp('waterProgress') waterProgress: number = 0;
  @LocalStorageProp('healthScore') healthScore: string = '--';
  @LocalStorageProp('lastSyncTime') lastSyncTime: string = '-';

  build() {
    Column() {
      // 顶部：标题 + 健康评分
      Row() {
        Text('🥗 饮食追踪')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
        Blank()
        // 健康评分徽章
        Text(this.healthScore)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor('#4CAF50')
          .borderRadius(8)
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
      }
      .width('100%')
      .margin({ bottom: 4 })

      // 分隔线
      Divider()
        .height(1)
        .color('#E8E8E8')
        .margin({ bottom: 6 })

      // 今日推荐菜单
      Row() {
        Text('今日推荐')
          .fontSize(11)
          .fontColor('#888888')
        Blank()
        Image($r('app.media.app_icon'))
          .width(14)
          .height(14)
          .objectFit(ImageFit.Contain)
      }
      .width('100%')
      .margin({ bottom: 2 })
      Text(this.todayMenu)
        .fontSize(13)
        .fontColor('#333333')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ bottom: 6 })

      // 卡路里进度
      Row() {
        Text('🔥 卡路里')
          .fontSize(11)
          .fontColor('#888888')
        Text(`${this.calorieIntake} / ${this.calorieTarget} kcal`)
          .fontSize(11)
          .fontColor('#666666')
      }
      .width('100%')
      .margin({ bottom: 2 })
      Row() {
        // 进度条背景
        Stack() {
          Row()
            .width('100%')
            .height(6)
            .backgroundColor('#E0E0E0')
            .borderRadius(3)
          Row()
            .width(this.calcCaloriePercent())
            .height(6)
            .backgroundColor('#FF9800')
            .borderRadius(3)
        }
        .width('100%')
      }
      .width('100%')
      .margin({ bottom: 6 })

      // 饮水进度
      Row() {
        Text('💧 饮水')
          .fontSize(11)
          .fontColor('#888888')
        Text(`${this.waterProgress} 杯`)
          .fontSize(11)
          .fontColor('#666666')
      }
      .width('100%')
      .margin({ bottom: 2 })
      Row() {
        ForEach(this.getWaterCups(), (filled: boolean, index: number) => {
          Text(filled ? '🟦' : '⬜')
            .fontSize(12)
            .margin({ right: 2 })
        }, (item: boolean, index: number) => index.toString())
      }
      .width('100%')
      .margin({ bottom: 4 })

      // 底部：最后同步时间 + 刷新入口
      Row() {
        Text(`更新: ${this.lastSyncTime}`)
          .fontSize(9)
          .fontColor('#AAAAAA')
        Blank()
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .padding(10)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .onClick(() => {
      // 点击卡片跳转到应用首页
      postCardAction(this, {
        'action': 'router',
        'abilityName': 'EntryAbility',
        'params': {
          'target': 'main'
        }
      });
    })
  }

  /**
   * 计算卡路里百分比字符串
   */
  calcCaloriePercent(): string {
    const target = parseInt(this.calorieTarget) || 1;
    const intake = parseInt(this.calorieIntake) || 0;
    const pct = Math.min(100, Math.round((intake / target) * 100));
    return `${pct}%`;
  }

  /**
   * 生成8个饮水格子状态
   */
  getWaterCups(): boolean[] {
    const cups: boolean[] = [];
    const filled = Math.min(8, Math.max(0, this.waterProgress));
    for (let i = 0; i < 8; i++) {
      cups.push(i < filled);
    }
    return cups;
  }
}
