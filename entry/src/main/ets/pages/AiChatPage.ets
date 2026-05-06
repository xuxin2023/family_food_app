// AiChatPage.ets
// AI 营养师对话页面 — 支持多轮对话、成员绑定、快捷提问

import { promptAction } from '@kit.ArkUI';
import { BackButton } from '../components/BackButton';
import { safeBack } from '../utils/RouterUtil';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppState } from '../AppState';
import { AiChatService } from '../service/AiChatService';
import {
  ChatRole, ChatMessage, MessageStatus, QUICK_QUESTIONS, generateMessageId
} from '../model/AiChat';
import { FamilyProfile } from '../model/FamilyProfile';
import { COLORS, FONT_SIZE, SPACING, RADIUS, FONT_WEIGHT, BUTTON } from '../constants/AppTheme';

interface ActionMenuButton {
  text: string;
  color: string;
}

class ActionMenuButtonItem implements ActionMenuButton {
  text: string = '';
  color: string = '';
  constructor(text: string, color: string) {
    this.text = text;
    this.color = color;
  }
}

const TAG = 'AiChatPage';
const DOMAIN_ZERO = 0;

@Entry
@Component
struct AiChatPage {
  @State messages: ChatMessage[] = [];
  @State inputText: string = '';
  @State isLoading: boolean = false;
  @State showQuickQuestions: boolean = true;
  @State familyMembers: FamilyProfile[] = [];
  @State selectedMemberId: string = '';
  @State selectedMemberName: string = '全部成员';

  private appState: AppState = AppState.getInstance();
  private aiChatService: AiChatService = new AiChatService();
  private scrollController: Scroller = new Scroller();

  async aboutToAppear() {
    try {
      this.familyMembers = await this.appState.getAllMembers();
      // 默认选中第一个成员
      if (this.familyMembers.length > 0) {
        this.selectedMemberId = this.familyMembers[0].memberId;
        this.selectedMemberName = this.familyMembers[0].nickname;
      }

      // 发送欢迎消息
      const welcomeMsg = new ChatMessage(
        generateMessageId(),
        `你好！我是你的家庭AI营养师助手${this.selectedMemberId.length > 0 ? `，当前正在为「${this.selectedMemberName}」提供健康建议` : ''}。\n\n你可以问我关于饮食营养的任何问题，比如下面这些：`,
        ChatRole.ASSISTANT,
        Date.now()
      );
      this.messages.push(welcomeMsg);

      // 绑定成员
      if (this.selectedMemberId.length > 0) {
        this.aiChatService.bindMember(this.selectedMemberId);
      }
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'aboutToAppear failed: %{public}s', JSON.stringify(error));
    }
  }

  build() {
    Column() {
      // ===== 顶部导航栏 =====
      Row() {
        // 返回按钮
        BackButton({ fontSize: 28, fontColor: COLORS.TEXT_PRIMARY })
          .onClick(() => safeBack())

        // 标题 + 当前成员
        Column({ space: 2 }) {
          Text('AI 营养师')
            .fontSize(FONT_SIZE.TITLE)
            .fontWeight(FONT_WEIGHT.BOLD)
            .fontColor(COLORS.TEXT_PRIMARY)

          if (this.selectedMemberId.length > 0) {
            Text(this.selectedMemberName)
              .fontSize(FONT_SIZE.SMALL)
              .fontColor(COLORS.TEXT_SECONDARY)
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        // 切换成员按钮
        if (this.familyMembers.length > 1) {
          Text('切换')
            .fontSize(FONT_SIZE.BODY)
            .fontColor(COLORS.ACCENT_BLUE)
            .onClick(() => this.showMemberPicker())
        }
      }
      .width('100%')
      .padding({ left: SPACING.LG, right: SPACING.LG, top: SPACING.MD, bottom: SPACING.SM })
      .backgroundColor(COLORS.WHITE)
      .shadow({ radius: 2, color: COLORS.SHADOW, offsetY: 2 })

      // ===== 消息列表 =====
      Scroll(this.scrollController) {
        Column() {
          // 快捷提问（仅首次显示）
          if (this.showQuickQuestions && this.messages.length <= 2) {
            this.QuickQuestionsPanel()
          }

          // 消息列表
          ForEach(this.messages, (msg: ChatMessage) => {
            this.MessageBubble(msg)
          }, (msg: ChatMessage) => msg.id)
        }
        .width('100%')
        .padding({ left: SPACING.MD, right: SPACING.MD, top: SPACING.MD, bottom: SPACING.LG })
      }
      .layoutWeight(1)
      .backgroundColor(COLORS.BG_PAGE)
      .scrollBar(BarState.Off)

      // ===== 底部输入区 =====
      Row() {
        TextInput({ placeholder: '输入你的问题...', text: this.inputText })
          .layoutWeight(1)
          .height(44)
          .backgroundColor(COLORS.BG_LIGHT)
          .borderRadius(RADIUS.FULL)
          .padding({ left: SPACING.LG, right: SPACING.LG })
          .onChange((val: string) => {
            this.inputText = val
          })
          .onSubmit(() => {
            this.sendMessage()
          })

        Button() {
          if (this.isLoading) {
            LoadingProgress()
              .width(20)
              .height(20)
              .color(COLORS.WHITE)
          } else {
            Text('发送')
              .fontSize(FONT_SIZE.BODY)
              .fontColor(COLORS.WHITE)
          }
        }
        .width(64)
        .height(44)
        .backgroundColor(this.inputText.length > 0 && !this.isLoading
          ? COLORS.ACCENT_PURPLE : COLORS.TEXT_TERTIARY)
        .borderRadius(RADIUS.FULL)
        .margin({ left: SPACING.SM })
        .enabled(this.inputText.length > 0 && !this.isLoading)
        .onClick(() => this.sendMessage())
      }
      .width('100%')
      .padding({ left: SPACING.MD, right: SPACING.MD, top: SPACING.SM, bottom: SPACING.LG })
      .backgroundColor(COLORS.WHITE)
      .shadow({ radius: 4, color: COLORS.SHADOW, offsetY: -2 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_PAGE)
  }

  // ========== 快捷提问面板 ==========
  @Builder
  QuickQuestionsPanel() {
    Column({ space: SPACING.SM }) {
      Text('💡 试试问这些问题')
        .fontSize(FONT_SIZE.SMALL)
        .fontColor(COLORS.TEXT_TERTIARY)
        .width('100%')
        .textAlign(TextAlign.Start)

      ForEach(QUICK_QUESTIONS, (question: string) => {
        Button(question)
          .width('100%')
          .height(40)
          .backgroundColor(COLORS.WHITE)
          .fontColor(COLORS.ACCENT_PURPLE)
          .fontSize(FONT_SIZE.BODY)
          .borderRadius(RADIUS.MD)
          .border({ width: 1, color: COLORS.BORDER })
          .onClick(() => {
            this.inputText = question
            this.sendMessage()
          })
      }, (question: string) => question)
    }
    .width('100%')
    .padding(SPACING.MD)
    .backgroundColor(COLORS.BG_CARD_HIGHLIGHT)
    .borderRadius(RADIUS.LG)
    .margin({ bottom: SPACING.MD })
  }

  // ========== 消息气泡 ==========
  @Builder
  MessageBubble(msg: ChatMessage) {
    Row() {
      if (msg.role === ChatRole.USER) {
        // 右侧：用户消息
        Blank()
          .layoutWeight(1)

        Column() {
          Text(msg.content)
            .fontSize(FONT_SIZE.BODY)
            .fontColor(COLORS.WHITE)
            .lineHeight(22)

          if (msg.status === MessageStatus.SENDING) {
            Text('发送中...')
              .fontSize(FONT_SIZE.TINY)
              .fontColor(COLORS.WHITE)
              .margin({ top: 4 })
          } else if (msg.status === MessageStatus.FAILED) {
            Text('发送失败')
              .fontSize(FONT_SIZE.TINY)
              .fontColor(COLORS.LEVEL_RED)
              .margin({ top: 4 })
          }
        }
        .constraintSize({ maxWidth: '75%' })
        .padding({ left: SPACING.MD, right: SPACING.MD, top: SPACING.SM, bottom: SPACING.SM })
        .backgroundColor(COLORS.ACCENT_PURPLE)
        .borderRadius(RADIUS.LG)
        .borderRadius({
          topLeft: RADIUS.LG,
          topRight: RADIUS.LG,
          bottomLeft: RADIUS.LG,
          bottomRight: RADIUS.SM
        })
      } else {
        // 左侧：AI 消息
        // AI 头像
        Circle()
          .width(32)
          .height(32)
          .fill(COLORS.BG_WARM_PURPLE)
          .margin({ right: SPACING.SM })

        Column() {
          Text(msg.content)
            .fontSize(FONT_SIZE.BODY)
            .fontColor(COLORS.TEXT_PRIMARY)
            .lineHeight(22)

          Text(this.formatTime(msg.timestamp))
            .fontSize(FONT_SIZE.TINY)
            .fontColor(COLORS.TEXT_TERTIARY)
            .margin({ top: 4 })
        }
        .constraintSize({ maxWidth: '70%' })
        .padding({ left: SPACING.MD, right: SPACING.MD, top: SPACING.SM, bottom: SPACING.SM })
        .backgroundColor(COLORS.WHITE)
        .borderRadius(RADIUS.LG)
        .borderRadius({
          topLeft: RADIUS.SM,
          topRight: RADIUS.LG,
          bottomLeft: RADIUS.LG,
          bottomRight: RADIUS.LG
        })
        .shadow({ radius: 1, color: COLORS.SHADOW, offsetY: 1 })

        Blank()
          .layoutWeight(1)
      }
    }
    .width('100%')
    .margin({ top: SPACING.SM, bottom: SPACING.SM })
    .alignItems(VerticalAlign.Top)
  }

  // ========== 发送消息 ==========
  private async sendMessage(): Promise<void> {
    const text = this.inputText.trim()
    if (text.length === 0 || this.isLoading) return

    // 隐藏快捷提问
    this.showQuickQuestions = false

    // 添加用户消息到列表
    const userMsg = new ChatMessage(
      generateMessageId(),
      text,
      ChatRole.USER,
      Date.now()
    )
    userMsg.status = MessageStatus.SENDING
    this.messages.push(userMsg)
    this.inputText = ''
    this.isLoading = true

    // 滚动到底部
    setTimeout(() => {
      this.scrollController.scrollEdge(Edge.End)
    }, 100)

    try {
      // 调用 AI 服务
      const aiMsg = await this.aiChatService.sendMessage(text)

      // 替换为已发送状态
      userMsg.status = MessageStatus.SENT

      // 添加 AI 回复
      this.messages.push(aiMsg)
    } catch (error) {
      userMsg.status = MessageStatus.FAILED
      hilog.error(DOMAIN_ZERO, TAG, 'sendMessage failed: %{public}s', JSON.stringify(error))

      const errorMsg = new ChatMessage(
        generateMessageId(),
        '抱歉，回复出错了，请稍后再试。',
        ChatRole.ASSISTANT,
        Date.now()
      )
      this.messages.push(errorMsg)
    }

    this.isLoading = false

    // 滚动到底部
    setTimeout(() => {
      this.scrollController.scrollEdge(Edge.End)
    }, 100)
  }

  // ========== 切换成员 ==========
  private showMemberPicker(): void {
    const items: string[] = this.familyMembers.map(m => m.nickname)
    const currentIndex = this.familyMembers.findIndex(
      m => m.memberId === this.selectedMemberId
    )

    const btn0 = new ActionMenuButtonItem(items[0], COLORS.TEXT_PRIMARY)
    const btn1 = items.length > 1 ? new ActionMenuButtonItem(items[1], COLORS.TEXT_PRIMARY) : null
    const btn2 = items.length > 2 ? new ActionMenuButtonItem(items[2], COLORS.TEXT_PRIMARY) : null
    const btn3 = items.length > 3 ? new ActionMenuButtonItem(items[3], COLORS.TEXT_PRIMARY) : null
    const btn4 = items.length > 4 ? new ActionMenuButtonItem(items[4], COLORS.TEXT_PRIMARY) : null
    const btn5 = items.length > 5 ? new ActionMenuButtonItem(items[5], COLORS.TEXT_PRIMARY) : null

    promptAction.showActionMenu({
      title: '切换家庭成员',
      buttons: [btn0, btn1, btn2, btn3, btn4, btn5]
    }, (err: Error, data: promptAction.ActionMenuSuccessResponse) => {
      if (err) {
        hilog.warn(0x0000, 'AiChatPage', 'showActionMenu err: %{public}s', JSON.stringify(err));
        return;
      }
      const index = data.index
      if (index >= 0 && index < this.familyMembers.length) {
        const member = this.familyMembers[index]
        this.selectedMemberId = member.memberId
        this.selectedMemberName = member.nickname
        this.aiChatService.bindMember(member.memberId)

        // 清除对话并重新开始
        this.aiChatService.clearHistory()
        this.messages = []
        this.showQuickQuestions = true

        const switchMsg = new ChatMessage(
          generateMessageId(),
          `已切换到「${member.nickname}」的健康咨询，有什么想问的吗？`,
          ChatRole.ASSISTANT,
          Date.now()
        )
        this.messages.push(switchMsg)
      }
    })
  }

  // ========== 工具方法 ==========
  private formatTime(timestamp: number): string {
    const d = new Date(timestamp)
    const h = d.getHours().toString().padStart(2, '0')
    const m = d.getMinutes().toString().padStart(2, '0')
    return `${h}:${m}`
  }
}
