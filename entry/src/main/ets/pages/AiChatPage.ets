// AiChatPage.ets
// AI 营养师对话页面 — 支持多轮对话、成员绑定、快捷提问

import {
  safeBack, FamilyProfile, COLORS, FONT_SIZE, SPACING, RADIUS, FONT_WEIGHT, HILOG_DOMAIN, ChatRole, ChatMessage, MessageStatus, QUICK_QUESTIONS, generateDynamicQuickQuestions, generateMessageId
} from 'hsp_core';
import { promptAction } from '@kit.ArkUI';
import { BackButton } from '../components/BackButton';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppState } from '../AppState';
import { AiChatService } from '../service/AiChatService';

import { ChatHistoryPrefsService } from '../service/ChatHistoryPrefsService';

class ActionMenuButton {
  text: string = '';
  color: string = '';
}

function makeActionMenuButton(text: string, color: string): ActionMenuButton {
  const btn = new ActionMenuButton();
  btn.text = text;
  btn.color = color;
  return btn;
}

const TAG = 'AiChatPage';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

@Entry
@ComponentV2
struct AiChatPage {
  @Local messages: ChatMessage[] = [];
  @Local inputText: string = '';
  @Local isLoading: boolean = false;
  @Local showQuickQuestions: boolean = true;
  @Local familyMembers: FamilyProfile[] = [];
  @Local selectedMemberId: string = '';
  @Local selectedMemberName: ResourceStr = $r('app.string.ai_chat_all_members');
  @Local dynamicQuickQuestions: string[] = [];

  private appState: AppState = AppState.getInstance();
  private aiChatService: AiChatService = new AiChatService();
  private scrollController: Scroller = new Scroller();
  private componentActive: boolean = true;
  private pendingTimers: number[] = [];

  private chatHistoryService: ChatHistoryPrefsService = ChatHistoryPrefsService.getInstance();

  async aboutToAppear() {
    this.componentActive = true;
    this.isLoading = true;
    try {
      this.familyMembers = await this.appState.getAllMembers();
      if (this.familyMembers.length > 0) {
        this.selectedMemberId = this.familyMembers[0].memberId;
        this.selectedMemberName = this.familyMembers[0].nickname;
        this.dynamicQuickQuestions = generateDynamicQuickQuestions(
          this.familyMembers[0].healthGoals.join(',')
        );
      } else {
        this.dynamicQuickQuestions = QUICK_QUESTIONS;
      }

      // 从持久化存储加载该成员的历史消息
      const savedJson = await this.chatHistoryService.getMessages(this.selectedMemberId);
      let savedMessages: ChatMessage[] = [];
      try {
        savedMessages = JSON.parse(savedJson) as ChatMessage[];
      } catch (_e) {
        hilog.warn(DOMAIN_ZERO, TAG, 'Parse chat history failed, starting fresh');
      }
      if (savedMessages.length > 0) {
        this.messages = savedMessages;
      } else {
        const welcomeText = this.selectedMemberId.length > 0
          ? $r('app.string.ai_chat_welcome_with_member', this.selectedMemberName)
          : $r('app.string.ai_chat_welcome');
        const welcomeMsg = new ChatMessage(
          generateMessageId(),
          welcomeText,
          ChatRole.ASSISTANT,
          Date.now()
        );
        this.messages.push(welcomeMsg);
      }

      if (this.selectedMemberId.length > 0) {
        this.aiChatService.bindMember(this.selectedMemberId);
      }
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'aboutToAppear failed: %{public}s', JSON.stringify(error));
    } finally {
      this.isLoading = false;
    }
  }

  aboutToDisappear(): void {
    this.componentActive = false
    // 持久化保存当前成员的对话
    if (this.selectedMemberId.length > 0 && this.messages.length > 0) {
      this.chatHistoryService.saveMessages(this.selectedMemberId, JSON.stringify(this.messages));
    }
    for (const tid of this.pendingTimers) {
      clearTimeout(tid);
    }
    this.pendingTimers = [];
  }

  build() {
    Column() {
      // ===== 顶部导航栏 =====
      Row() {
        // 返回按钮
        BackButton({ fontSize: 28, fontColor: COLORS.TEXT_PRIMARY })
          .onClick(() => safeBack())
          .accessibilityText('返回')
          .accessibilityLevel('yes')

        // 标题 + 当前成员
        Column({ space: 2 }) {
          Text($r('app.string.ai_chat_title'))
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
          Text($r('app.string.ai_chat_switch'))
            .fontSize(FONT_SIZE.BODY)
            .fontColor(COLORS.ACCENT_BLUE)
            .onClick(() => this.showMemberPicker())
            .accessibilityText('切换成员')
            .accessibilityLevel('yes')
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
        TextInput({ placeholder: $r('app.string.ai_chat_input_placeholder') as ResourceStr, text: this.inputText })
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
          .accessibilityText('输入消息')
          .accessibilityLevel('yes')

        Button() {
          if (this.isLoading) {
            LoadingProgress()
              .width(20)
              .height(20)
              .color(COLORS.WHITE)
          } else {
            Text($r('app.string.ai_chat_send'))
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
        .accessibilityText('发送消息')
        .accessibilityLevel('yes')
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
      Text($r('app.string.ai_chat_try_these'))
        .fontSize(FONT_SIZE.SMALL)
        .fontColor(COLORS.TEXT_TERTIARY)
        .width('100%')
        .textAlign(TextAlign.Start)

      ForEach(this.dynamicQuickQuestions, (question: string) => {
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
          .accessibilityText(question)
          .accessibilityLevel('yes')
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
            Text($r('app.string.ai_chat_sending'))
              .fontSize(FONT_SIZE.TINY)
              .fontColor(COLORS.WHITE)
              .margin({ top: 4 })
          } else if (msg.status === MessageStatus.FAILED) {
            Text($r('app.string.ai_chat_send_failed'))
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
    const tid1 = setTimeout(() => {
      const idx = this.pendingTimers.indexOf(tid1);
      if (idx >= 0) this.pendingTimers.splice(idx, 1);
      if (!this.componentActive) return;
      this.scrollController.scrollEdge(Edge.End)
    }, 100)
    this.pendingTimers.push(tid1)

    try {
      // 调用 AI 服务
      const aiMsg = await this.aiChatService.sendMessage(text)

      if (!this.componentActive) return;

      // 替换为已发送状态
      userMsg.status = MessageStatus.SENT

      // 添加 AI 回复
      this.messages.push(aiMsg)
      this.saveCurrentMessages()
    } catch (error) {
      userMsg.status = MessageStatus.FAILED
      hilog.error(DOMAIN_ZERO, TAG, 'sendMessage failed: %{public}s', JSON.stringify(error))

      const errorMsg = new ChatMessage(
        generateMessageId(),
        $r('app.string.ai_chat_error_reply') as string,
        ChatRole.ASSISTANT,
        Date.now()
      )
      this.messages.push(errorMsg)
      this.saveCurrentMessages()
    }

    this.isLoading = false

    // 滚动到底部
    const tid2 = setTimeout(() => {
      const idx2 = this.pendingTimers.indexOf(tid2);
      if (idx2 >= 0) this.pendingTimers.splice(idx2, 1);
      if (!this.componentActive) return;
      this.scrollController.scrollEdge(Edge.End)
    }, 100)
    this.pendingTimers.push(tid2)
  }

  // ========== 切换成员 ==========
  private showMemberPicker(): void {
    const items: string[] = this.familyMembers.map(m => m.nickname)
    const maxButtons = Math.min(items.length, 6)
    const buttons: promptAction.ButtonInfo[] = []
    for (let i = 0; i < maxButtons; i++) {
      buttons.push(makeActionMenuButton(items[i], COLORS.TEXT_PRIMARY))
    }

    promptAction.showActionMenu({
      title: $r('app.string.ai_chat_switch_member') as string,
      buttons: buttons
    }, async (err: Error, data: promptAction.ActionMenuSuccessResponse) => {
      if (err) {
        hilog.warn(0x0000, 'AiChatPage', 'showActionMenu err: %{public}s', JSON.stringify(err));
        return;
      }
      const index = data.index
      if (index >= 0 && index < this.familyMembers.length) {
        const member = this.familyMembers[index]

        // 保存当前成员的对话
        await this.saveCurrentMessages()

        this.selectedMemberId = member.memberId
        this.selectedMemberName = member.nickname
        this.aiChatService.bindMember(member.memberId)
        this.dynamicQuickQuestions = generateDynamicQuickQuestions(member.healthGoals.join(','))

        this.aiChatService.clearHistory()
        this.messages = []
        this.showQuickQuestions = true

        // 加载新成员的历史消息
        try {
          const savedJson = await this.chatHistoryService.getMessages(member.memberId);
          const savedMessages: ChatMessage[] = JSON.parse(savedJson);
          if (savedMessages.length > 0) {
            this.messages = savedMessages;
          } else {
            const switchMsg = new ChatMessage(
              generateMessageId(),
              $r('app.string.ai_chat_switched_member', member.nickname) as string,
              ChatRole.ASSISTANT,
              Date.now()
            )
            this.messages.push(switchMsg)
          }
        } catch (e) {
          const switchMsg = new ChatMessage(
            generateMessageId(),
            $r('app.string.ai_chat_switched_member', member.nickname) as string,
            ChatRole.ASSISTANT,
            Date.now()
          )
          this.messages.push(switchMsg)
        }
      }
    })
  }

  // ========== 工具方法 ==========
  private async saveCurrentMessages(): Promise<void> {
    if (this.selectedMemberId.length > 0 && this.messages.length > 0) {
      await this.chatHistoryService.saveMessages(this.selectedMemberId, JSON.stringify(this.messages));
    }
  }

  private formatTime(timestamp: number): string {
    const d = new Date(timestamp)
    const h = d.getHours().toString().padStart(2, '0')
    const m = d.getMinutes().toString().padStart(2, '0')
    return `${h}:${m}`
  }

  pageTransition() {
    PageTransitionEnter({ duration: 350, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 250, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
  }
}