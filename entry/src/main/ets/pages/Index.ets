// Index.ets
// 应用入口页面 - 判断引导状态后进入主导航
// V2增强：三屏引导内容具体化

import { AppState } from '../AppState';
import { MainNavigation } from './MainNavigation';

@Entry
@Component
struct Index {
  @State showGuide: boolean = false;

  aboutToAppear(): void {
    const state = AppState.getInstance();
    this.showGuide = !state.hasShownGuide;
  }

  build() {
    Stack() {
      if (this.showGuide) {
        GuidePage({ onComplete: () => this.onGuideComplete() })
      } else {
        MainNavigation()
      }
    }
    .width('100%')
    .height('100%')
  }

  private onGuideComplete(): void {
    const state = AppState.getInstance();
    state.hasShownGuide = true;
    this.showGuide = false;
  }
}

@Component
struct GuidePage {
  @State currentPage: number = 0;
  onComplete?: () => void;

  build() {
    Column() {
      Row() {
        Blank()
        Text('跳过')
          .fontSize(14)
          .fontColor('#999999')
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .onClick(() => {
            this.onComplete?.();
          })
      }
      .width('100%')
      .padding({ top: 8, right: 8 })

      if (this.currentPage === 0) {
        this.buildPage1()
      } else if (this.currentPage === 1) {
        this.buildPage2()
      } else {
        this.buildPage3()
      }

      Column() {
        Row() {
          Circle({ width: 8, height: 8 })
            .fill(this.currentPage === 0 ? '#007DFF' : '#D0D0D0')
            .margin({ left: 4, right: 4 })
          Circle({ width: 8, height: 8 })
            .fill(this.currentPage === 1 ? '#007DFF' : '#D0D0D0')
            .margin({ left: 4, right: 4 })
          Circle({ width: 8, height: 8 })
            .fill(this.currentPage === 2 ? '#007DFF' : '#D0D0D0')
            .margin({ left: 4, right: 4 })
        }
        .margin({ bottom: 24 })

        Button(this.currentPage < 2 ? '下一步' : '开始使用')
          .width('80%')
          .height(48)
          .backgroundColor('#007DFF')
          .borderRadius(24)
          .fontColor('#FFFFFF')
          .fontSize(16)
          .onClick(() => {
            if (this.currentPage < 2) {
              this.currentPage++;
            } else {
              this.onComplete?.();
            }
          })
      }
      .width('100%')
      .padding({ bottom: 48 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  buildPage1() {
    Column() {
      Text('👨‍👩‍👧‍👦')
        .fontSize(80)
        .margin({ bottom: 24 })

      Text('为全家建立健康档案')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A1A')
        .margin({ bottom: 16 })

      // 四个成员头像
      Row() {
        this.buildMemberAvatar('👨', '爸爸', '控压')
        this.buildMemberAvatar('👩', '妈妈', '减脂')
        this.buildMemberAvatar('👶', '孩子', '儿童')
        this.buildMemberAvatar('🧑', '我', '控糖')
      }
      .width('100%')
      .padding({ left: 24, right: 24 })
      .margin({ bottom: 16 })

      Text('为每位家庭成员设置健康目标，\n后续扫码就能看到「同一食品，不同建议」')
        .fontSize(14)
        .fontColor('#666666')
        .textAlign(TextAlign.Center)
        .lineHeight(22)
        .padding({ left: 32, right: 32 })
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  buildMemberAvatar(emoji: string, name: string, goal: string) {
    Column() {
      Text(emoji)
        .fontSize(32)
      Text(name)
        .fontSize(12)
        .fontColor('#333333')
        .margin({ top: 4 })
      Text(goal)
        .fontSize(10)
        .fontColor('#888888')
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildPage2() {
    Column() {
      Image($r('sys.media.ohos_ic_public_scan'))
        .width(100)
        .height(100)
        .margin({ bottom: 24 })

      Text('三种方式，快速识别')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A1A')
        .margin({ bottom: 16 })

      Column() {
        this.buildMethodRow('📷', '拍照识别', '拍食品包装或配料表，自动提取营养信息')
        this.buildMethodRow('📱', '扫码查询', '扫描条形码，从全球数据库获取食品数据')
        this.buildMethodRow('🔗', '粘贴链接', '从电商App复制商品链接，自动解析分析')
      }
      .width('100%')
      .padding({ left: 32, right: 32 })

      Text('无论哪种方式，结果都一样精准')
        .fontSize(13)
        .fontColor('#999999')
        .margin({ top: 16 })
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  buildMethodRow(icon: string, title: string, desc: string) {
    Row() {
      Text(icon)
        .fontSize(24)
        .margin({ right: 12 })
      Column() {
        Text(title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A1A')
        Text(desc)
          .fontSize(12)
          .fontColor('#888888')
          .margin({ top: 2 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#F5F5F5')
    .borderRadius(10)
    .margin({ bottom: 8 })
  }

  @Builder
  buildPage3() {
    Column() {
      Text('✅')
        .fontSize(80)
        .margin({ bottom: 24 })

      Text('全家报告，一目了然')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A1A')
        .margin({ bottom: 16 })

      // 示例报告卡片
      Column() {
        Text('辣味牛肉干')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
          .margin({ bottom: 12 })

        this.buildExampleRow('👨', '爸爸', '今天谨慎', '#EF7D00', '最多50g')
        this.buildExampleRow('👩', '妈妈', '少量可以', '#FFCC00', '最多30g')
        this.buildExampleRow('👶', '孩子', '建议避免', '#E03C31', '')
        this.buildExampleRow('🧑', '我', '适合食用', '#00823F', '最多80g')
      }
      .width('85%')
      .padding(16)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .shadow({ radius: 8, color: '#1A000000', offsetY: 4 })
      .margin({ bottom: 16 })

      Text('同一款食品，全家建议都不同')
        .fontSize(14)
        .fontColor('#666666')
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  buildExampleRow(emoji: string, name: string, level: string, color: string, amount: string) {
    Row() {
      Text(emoji)
        .fontSize(16)
        .margin({ right: 6 })
      Text(name)
        .fontSize(14)
        .width(36)
      Text(level)
        .fontSize(12)
        .fontColor('#FFFFFF')
        .backgroundColor(color)
        .borderRadius(8)
        .padding({ left: 8, right: 8, top: 2, bottom: 2 })
        .margin({ left: 8 })
      if (amount.length > 0) {
        Text(amount)
          .fontSize(13)
          .fontColor('#666666')
          .margin({ left: 8 })
      }
    }
    .width('100%')
    .margin({ top: 6, bottom: 6 })
  }
}
