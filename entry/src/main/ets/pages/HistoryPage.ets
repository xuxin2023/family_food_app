import { router } from '@kit.ArkUI';
import { AppState } from '../AppState';
import { FamilyProfile } from '../model/FamilyProfile';
import { ScanHistoryRecord } from '../repository/HistoryRepository';
import { DateUtil } from '../utils/DateUtil';

@Entry
@Component
struct HistoryPage {
  @State familyMembers: FamilyProfile[] = []
  @State historyRecords: ScanHistoryRecord[] = []
  @State selectedMemberId: string = 'all'

  private appState: AppState = AppState.getInstance()

  async aboutToAppear() {
    this.familyMembers = await this.appState.getAllMembers()
    this.historyRecords = await this.appState.getRecentScanHistory(100)
  }

  build() {
    Column() {
      Row() {
        Text('<')
          .fontSize(24)
          .fontColor('#1976D2')
          .onClick(() => { try { router.back() } catch (_e) { /* ignore */ } })
        Text('历史记录')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })

      Scroll() {
        Row() {
          Text('全部')
            .fontSize(13)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .borderRadius(16)
            .backgroundColor(this.selectedMemberId === 'all' ? '#1976D2' : '#FFFFFF')
            .fontColor(this.selectedMemberId === 'all' ? '#FFFFFF' : '#212121')
            .margin({ right: 8 })
            .onClick(() => { this.selectedMemberId = 'all' })

          ForEach(this.familyMembers, (member: FamilyProfile) => {
            Text(member.nickname)
              .fontSize(13)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .borderRadius(16)
              .backgroundColor(this.selectedMemberId === member.memberId ? '#1976D2' : '#FFFFFF')
              .fontColor(this.selectedMemberId === member.memberId ? '#FFFFFF' : '#212121')
              .margin({ right: 8 })
              .onClick(() => { this.selectedMemberId = member.memberId })
          }, (member: FamilyProfile) => member.memberId)
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .width('100%')
      .padding({ left: 16, right: 16 })
      .margin({ bottom: 14 })

      if (this.getVisibleRecords().length === 0) {
        Column() {
          Text('还没有历史记录')
            .fontSize(16)
            .fontColor('#616161')
          Text('先去拍标签或扫码，再回来查看')
            .fontSize(12)
            .fontColor('#9E9E9E')
            .margin({ top: 8 })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        List() {
          ForEach(this.getVisibleRecords(), (record: ScanHistoryRecord) => {
            ListItem() {
              this.HistoryCard(record)
            }
          }, (record: ScanHistoryRecord) => `${record.id}`)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')
  }

  @Builder
  HistoryCard(record: ScanHistoryRecord) {
    Column() {
      Row() {
        Column() {
          Text(record.foodName)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
          Text(this.getMemberName(record.memberId))
            .fontSize(12)
            .fontColor('#757575')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(DateUtil.formatTimestamp(record.scannedAt))
          .fontSize(11)
          .fontColor('#9E9E9E')
      }
      .width('100%')

      Row() {
        Text(record.level)
          .fontSize(12)
          .fontColor(this.getLevelColor(record.level))
        if (record.maxAmount > 0) {
          Text(` · 建议上限 ${Math.round(record.maxAmount)} g`)
            .fontSize(12)
            .fontColor('#616161')
            .margin({ left: 6 })
        }
      }
      .width('100%')
      .margin({ top: 8 })

      if (record.reasons.length > 0) {
        Text(record.reasons[0])
          .fontSize(12)
          .fontColor('#616161')
          .margin({ top: 8 })
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .margin({ bottom: 8 })
    .alignItems(HorizontalAlign.Start)
  }

  private getVisibleRecords(): ScanHistoryRecord[] {
    if (this.selectedMemberId === 'all') {
      return this.historyRecords
    }
    return this.historyRecords.filter(record => record.memberId === this.selectedMemberId)
  }

  private getMemberName(memberId: string): string {
    const member = this.familyMembers.find(item => item.memberId === memberId)
    return member ? member.nickname : memberId
  }

  private getLevelColor(level: string): string {
    if (level === '适合') return '#43A047'
    if (level === '少量可以') return '#FB8C00'
    if (level === '今天谨慎') return '#F4511E'
    if (level === '建议避免') return '#D32F2F'
    return '#757575'
  }
}
