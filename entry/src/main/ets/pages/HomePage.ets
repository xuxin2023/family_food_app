// HomePage.ets
// 首页 - 家庭饮食平衡助手 V5
// V5增强：今日家庭状态条、各成员预算剩余

import { router, promptAction } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { FamilyProfile } from '../model/FamilyProfile';
import { MemberCard } from '../components/MemberCard';
import { AppState } from '../AppState';
import { SubscriptionTier } from '../model/PricingModel';
import { MilestoneService, Milestone } from '../service/MilestoneService';
import { OnlineShoppingParser } from '../service/OnlineShoppingParser';

@Entry
@Component
struct HomePage {
  @State familyMembers: FamilyProfile[] = []
  @State selectedMemberId: string = ''
  @State currentSloganIndex: number = 0
  @State refreshToggle: boolean = false
  @State milestones: Milestone[] = []
  @State showLinkInput: boolean = false
  @State linkInputText: string = ''
  @State isParsingLink: boolean = false

  private appState: AppState = AppState.getInstance()
  private milestoneService: MilestoneService = MilestoneService.getInstance()
  private shoppingParser: OnlineShoppingParser = OnlineShoppingParser.getInstance()

  private slogans: string[] = [
    '给爸妈买食品前，先拍一下。',
    '孩子零食会不会影响正餐，一拍就知道。',
    '吃完烧烤火锅，下一餐怎么搭。',
    '同一款食品，爸爸、妈妈、孩子建议都不同。',
    '不是不让你吃，而是帮你吃得更有数。'
  ]

  async aboutToAppear() {
    this.currentSloganIndex = Math.floor(Math.random() * this.slogans.length)
    await this.loadFamilyMembers()
    await this.refreshMilestones()
  }

  private async refreshMilestones() {
    try {
      this.milestones = await this.milestoneService.checkMilestones()
    } catch (_error) {
      // 静默失败
    }
  }

  async loadFamilyMembers() {
    this.familyMembers = await this.appState.getAllMembers()
    if (this.familyMembers.length > 0 && this.selectedMemberId.length === 0) {
      this.selectedMemberId = this.familyMembers[0].memberId
    }
  }

  /**
   * 解析粘贴的电商链接
   */
  private async handleParseLink(url: string): Promise<void> {
    if (url.trim().length === 0) {
      promptAction.showToast({ message: '请输入或粘贴商品链接' })
      return
    }

    this.isParsingLink = true
    this.showLinkInput = false

    try {
      const result = await this.shoppingParser.parseUrl(url.trim())

      if (!result.parseSuccess) {
        // 解析失败
        promptAction.showToast({ message: result.errorMessage || '解析失败，请尝试拍照识别' })
        this.isParsingLink = false
        return
      }

      // 解析成功 → 构造简洁FoodLabel跳转到报告页
      promptAction.showToast({ message: `识别到 ${result.platform}：${result.productName}` })

      // 构造FoodLabel跳转到ReportPage
      const parser = OnlineShoppingParser.getInstance()
      const parseResult = await parser.parseUrlToLabel(url.trim())

      router.pushUrl({
        url: 'pages/ReportPage',
        params: {
          foodLabel: parseResult.label,
          recommendations: [],
          members: this.familyMembers,
          alternatives: [],
          nutriScore: 50,
          credibilityResult: {
            overallScore: 60,
            dataSource: result.platform,
            reliability: 'medium',
            warnings: ['数据来自电商平台，营养成分仅供参考']
          },
          childProtection: []
        }
      })
    } catch (error) {
      promptAction.showToast({ message: '链接解析异常，请重试或使用拍照识别' })
      hilog.error(0x0000, 'HomePage', 'parseLink error: ' + JSON.stringify(error))
    } finally {
      this.isParsingLink = false
    }
  }

  /**
   * 打开链接输入弹窗
   */
  private openLinkInput(): void {
    this.linkInputText = ''
    this.showLinkInput = true
  }

  build() {
    Stack() {
      Column() {
      // 顶部品牌区
      Column() {
        Text('家庭饮食平衡助手')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1976D2')
          .margin({ top: 20, bottom: 4 })

        Text(this.slogans[this.currentSloganIndex])
          .fontSize(14)
          .fontColor('#757575')
          .margin({ bottom: 16 })
          .textAlign(TextAlign.Center)
          .maxLines(2)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      // 快速操作区：扫描 + 粘贴链接
      Row({ space: 12 }) {
        Button() {
          Row({ space: 6 }) {
            Text('📷').fontSize(16)
            Text('扫码识别').fontSize(14).fontColor('#FFFFFF')
          }
        }
        .width('45%')
        .height(44)
        .borderRadius(22)
        .backgroundColor('#1976D2')
        .onClick(() => {
          router.pushUrl({ url: 'pages/ScanPage' })
        })

        Button() {
          Row({ space: 6 }) {
            Text('🔗').fontSize(16)
            Text('粘贴链接').fontSize(14).fontColor('#FFFFFF')
          }
        }
        .width('45%')
        .height(44)
        .borderRadius(22)
        .backgroundColor('#7B1FA2')
        .onClick(() => {
          this.showLinkInput = true
        })
      }
      .margin({ bottom: 16 })

      // V5增强：今日家庭状态条
      this.buildFamilyStatusBar()

      // 里程碑横向滑动卡片
      if (this.milestones.length > 0) {
        this.buildMilestoneCarousel()
      }

      // 家庭成员选择
      Text('今天给谁看？')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#212121')
        .margin({ left: 16, bottom: 8 })

      Scroll() {
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start, alignItems: ItemAlign.Start }) {
          ForEach(this.familyMembers, (member: FamilyProfile) => {
            Column() {
              MemberCard({
                member: member,
                isSelected: this.selectedMemberId === member.memberId,
                onSelect: (id: string) => { this.selectedMemberId = id }
              })
            }
            .width('45%')
            .margin(8)
          }, (member: FamilyProfile) => member.memberId)

          Column() {
            Text('+').fontSize(28).fontColor('#1976D2')
            Text(this.appState.canAddMember() ? '添加成员' : '升级解锁')
              .fontSize(12)
              .fontColor(this.appState.canAddMember() ? '#1976D2' : '#FF9800')
              .margin({ top: 4 })
          }
          .width('45%')
          .height(100)
          .margin(8)
          .borderRadius(16)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .border({ width: 1, color: '#E0E0E0', style: BorderStyle.Dashed, radius: 16 })
          .onClick(() => {
            if (this.appState.canAddMember()) {
              router.pushUrl({ url: 'pages/MemberEditPage' })
            } else {
              router.pushUrl({ url: 'pages/SettingsPage' })
            }
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
      }
      .scrollable(ScrollDirection.Vertical)
      .layoutWeight(1)

      // 底部操作区
      Column() {
        // 粘贴电商链接按钮
        Button() {
          Row() {
            Text('🔗').fontSize(20)
            Text('粘贴链接').fontSize(18).fontColor('#FFFFFF').margin({ left: 8 })
          }
        }
        .width('90%')
        .height(48)
        .backgroundColor('#7B1FA2')
        .borderRadius(24)
        .margin({ bottom: 10 })
        .onClick(() => { this.openLinkInput() })
        Button() {
          Row() {
            Text('📷').fontSize(20)
            Text('拍食品标签').fontSize(18).fontColor('#FFFFFF').margin({ left: 8 })
          }
        }
        .width('90%')
        .height(56)
        .backgroundColor('#1976D2')
        .borderRadius(28)
        .margin({ bottom: 12 })
        .onClick(() => {
          router.pushUrl({
            url: 'pages/ScanPage',
            params: { memberId: this.selectedMemberId }
          })
        })

        Button() {
          Row() {
            Text('🍽').fontSize(20)
            Text('记录美食').fontSize(18).fontColor('#1976D2').margin({ left: 8 })
          }
        }
        .width('90%')
        .height(56)
        .backgroundColor('#E3F2FD')
        .borderRadius(28)
        .margin({ bottom: 12 })
        .onClick(() => {
          router.pushUrl({
            url: 'pages/BalancePage',
            params: { memberId: this.selectedMemberId }
          })
        })

        if (this.appState.canAccess(SubscriptionTier.FAMILY_EARLY)) {
          Button() {
            Row() {
              Text('🛒').fontSize(20)
              Text('购物篮检查').fontSize(18).fontColor('#FF9800').margin({ left: 8 })
            }
          }
          .width('90%')
          .height(48)
          .backgroundColor('#FFF3E0')
          .borderRadius(24)
          .margin({ bottom: 12 })
          .onClick(() => {
            router.pushUrl({ url: 'pages/BasketCheckPage' })
          })
        }

        // 🛡️ 查品牌/商家透明度（无门控，所有用户可用）
        Button() {
          Row() {
            Text('🛡️').fontSize(20)
            Text('查品牌/商家透明度').fontSize(18).fontColor('#7B1FA2').margin({ left: 8 })
          }
        }
        .width('90%')
        .height(48)
        .backgroundColor('#F3E5F5')
        .borderRadius(24)
        .margin({ bottom: 12 })
        .onClick(() => {
          router.pushUrl({ url: 'pages/SettingsPage' })
        })

        Row() {
          Text('历史').fontSize(13).fontColor('#757575')
            .onClick(() => { router.pushUrl({ url: 'pages/HistoryPage' }) })
          Text('  |  ').fontSize(13).fontColor('#E0E0E0')
          if (this.appState.canAccess(SubscriptionTier.FAMILY_EARLY)) {
            Text('周报').fontSize(13).fontColor('#757575')
              .onClick(() => { router.pushUrl({ url: 'pages/WeeklyReportPage' }) })
            Text('  |  ').fontSize(13).fontColor('#E0E0E0')
          }
          Text('设置').fontSize(13).fontColor('#757575')
            .onClick(() => { router.pushUrl({ url: 'pages/SettingsPage' }) })
        }
        .margin({ bottom: 16 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')

    // 链接输入浮层
    if (this.showLinkInput) {
      Column() {
        Column() {
          Text('粘贴商品链接')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
            .margin({ bottom: 16 })

          TextInput({ placeholder: '粘贴京东/淘宝/天猫商品链接...', text: this.linkInputText })
            .width('100%')
            .height(44)
            .borderRadius(8)
            .backgroundColor('#F5F5F5')
            .padding({ left: 12, right: 12 })
            .placeholderColor('#999999')
            .onChange((value: string) => { this.linkInputText = value })

          Row({ space: 12 }) {
            Button('取消')
              .width('45%')
              .height(44)
              .borderRadius(22)
              .backgroundColor('#E0E0E0')
              .fontColor('#666666')
              .onClick(() => {
                this.showLinkInput = false
                this.linkInputText = ''
              })

            Button() {
              if (this.isParsingLink) {
                LoadingProgress()
                  .width(20)
                  .height(20)
                  .color('#FFFFFF')
              } else {
                Text('解析链接').fontColor('#FFFFFF').fontSize(16)
              }
            }
            .width('45%')
            .height(44)
            .borderRadius(22)
            .backgroundColor('#7B1FA2')
            .enabled(!this.isParsingLink)
            .onClick(() => { this.handleParseLink(this.linkInputText) })
          }
          .margin({ top: 16 })
        }
        .width('85%')
        .padding(24)
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .shadow({ radius: 12, color: '#33000000', offsetY: 4 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#66000000')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        this.showLinkInput = false
        this.linkInputText = ''
      })
      .position({ x: 0, y: 0 })
      .zIndex(999)
    }
  }
}

@Builder
  buildMilestoneCarousel() {
    Column() {
      Row() {
        Text('🏆 成就里程碑')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A1A')
        Blank()
        Text('查看全部')
          .fontSize(11)
          .fontColor('#007DFF')
          .onClick(() => {
            router.pushUrl({ url: 'pages/SettingsPage' })
          })
      }
      .width('100%')
      .margin({ bottom: 8 })

      Scroll() {
        Row({ space: 12 }) {
          ForEach(this.milestones, (milestone: Milestone) => {
            this.MilestoneCard(milestone)
          })
        }
        .padding({ left: 0, right: 0 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .width('100%')
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(10)
    .margin({ left: 16, right: 16, bottom: 12 })
    .shadow({ radius: 2, color: '#1A000000', offsetY: 1 })
  }

  @Builder
  MilestoneCard(milestone: Milestone) {
    Column() {
      // Emoji 图标
      Text(milestone.icon)
        .fontSize(28)
        .margin({ bottom: 6 })

      // 标题
      Text(milestone.title)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor('#212121')
        .lineHeight(18)
        .maxLines(1)
        .margin({ bottom: 8 })

      // 进度条
      Row() {
        Column() {
          // 进度条背景
          Row() {
            Column() {
              // 进度条填充
              Row()
                .width(`${milestone.progress}%`)
                .height(6)
                .backgroundColor(milestone.achieved && !milestone.acknowledged ? '#FFD700' : '#1976D2')
                .borderRadius(3)
            }
            .width('100%')
            .height(6)
            .backgroundColor('#E0E0E0')
            .borderRadius(3)
          }
          .width('100%')
          .margin({ bottom: 4 })

          // 百分比文字
          if (milestone.achieved) {
            Text('✅ 已完成')
              .fontSize(11)
              .fontColor('#2E7D32')
          } else {
            Text(`${milestone.progress}% (${milestone.current}/${milestone.target})`)
              .fontSize(10)
              .fontColor('#9E9E9E')
          }
        }
        .layoutWeight(1)
      }
    }
    .width(160)
    .height(120)
    .padding(12)
    .backgroundColor('#F5F5F5')
    .borderRadius(12)
    .border(milestone.achieved && !milestone.acknowledged ?
      { width: 2, color: '#FFD700' } : undefined)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      if (milestone.achieved) {
        promptAction.showToast({
          message: `🎉 恭喜达成「${milestone.title}」！解锁了新的饮食智慧`,
          duration: 3000
        })
        this.milestoneService.acknowledgeMilestone(milestone.name)
        // 刷新以去掉金色边框
        this.refreshMilestones()
      }
    })
  }

  @Builder
  buildFamilyStatusBar() {
    Column() {
      Row() {
        Text('💡')
          .fontSize(16)
          .margin({ right: 4 })
        Text('今日家庭状态')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A1A')
        Blank()
        Text('点击刷新')
          .fontSize(11)
          .fontColor('#007DFF')
          .onClick(() => {
            this.refreshToggle = !this.refreshToggle
          })
      }
      .width('100%')
      .margin({ bottom: 8 })

      if (this.familyMembers.length > 0) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.familyMembers, (member: FamilyProfile) => {
            this.buildMemberStatusItem(member)
          })
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(10)
    .margin({ left: 16, right: 16, bottom: 12 })
    .shadow({ radius: 2, color: '#1A000000', offsetY: 1 })
  }

  @Builder
  buildMemberStatusItem(member: FamilyProfile) {
    Row() {
      Text(this.getMemberEmoji(member))
        .fontSize(14)
        .margin({ right: 4 })
      Text(member.nickname)
        .fontSize(12)
        .fontColor('#333333')
        .margin({ right: 4 })
      Text(this.getMemberStatusText(member))
        .fontSize(11)
        .fontColor(this.getMemberStatusColor(member))
    }
    .width('48%')
    .margin({ top: 4, bottom: 4 })
  }

  private getMemberEmoji(member: FamilyProfile): string {
    if (member.nickname === '爸爸') return '👨'
    if (member.nickname === '妈妈') return '👩'
    if (member.nickname === '孩子') return '👶'
    return '🧑'
  }

  private getMemberStatusText(member: FamilyProfile): string {
    const goal = member.healthGoals[0]
    if (goal === '控压') return '高盐额度剩余85%'
    if (goal === '控糖') return '糖预算剩余70%'
    if (goal === '减脂') return '热量预算剩余60%'
    if (goal === '儿童') return '今日零食0次/建议≤3次'
    return '预算充足'
  }

  private getMemberStatusColor(member: FamilyProfile): string {
    const goal = member.healthGoals[0]
    if (goal === '控压') return '#EF7D00'
    if (goal === '控糖') return '#00823F'
    if (goal === '减脂') return '#007DFF'
    if (goal === '儿童') return '#9C27B0'
    return '#00823F'
  }
}
