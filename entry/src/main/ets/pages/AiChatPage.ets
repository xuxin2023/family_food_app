// AiChatPage.ets
// AI 营养师对话页面 - V4: 端侧推理 + 云端增强双通道
import {
  safeBack, FamilyProfile, AgeGroup, COLORS, FONT_SIZE, SPACING, RADIUS, FONT_WEIGHT, SHADOWS, HILOG_DOMAIN_DEFAULT, ChatRole, ChatMessage, MessageStatus, QUICK_QUESTIONS, generateDynamicQuickQuestions, generateMessageId,   PerformanceMonitor, PageResourceTracker, createPageTracker, ThemeReactive, themeReactive, ThemeColors, ThemeMode
} from 'hsp_core';
import { promptAction } from '@kit.ArkUI';
import { BackButton } from '../components/BackButton';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppState } from '../AppState';
import { ErrorFallback } from '../components/ErrorFallback';
import { LlmChatProxy, LlmSource, MemberHealthContext } from 'hsp_service';

import { ChatHistoryPrefsService } from 'hsp_service';

class ActionMenuButton {
  text: string = '';
  color: string = '';
}

function makeActionMenuButton(text: string, color: string): ActionMenuButton {
  const btn: ActionMenuButton = new ActionMenuButton()
  btn.text = text;
  btn.color = color;
  return btn;
}

const TAG = 'AiChatPage';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

@Entry
@ComponentV2
export struct AiChatPage {
  @Local messages: ChatMessage[] = [];
  @Local inputText: string = '';
  @Local isLoading: boolean = false;
  @Local showQuickQuestions: boolean = true;
  @Local familyMembers: FamilyProfile[] = [];
  @Local selectedMemberId: string = '';
  @Local selectedMemberName: ResourceStr = $r('app.string.ai_chat_all_members');
  @Local dynamicQuickQuestions: string[] = [];
  @Local isOfflineMode: boolean = false
  @Local hasPageError: boolean = false;
  // 当前 AI 对话模式（本地/云端/离线），由最近一次响应更新，用于显示模式徽标
  @Local activeMode: LlmSource = LlmSource.CLOUD_PANGU;

  private appState: AppState = AppState.getInstance();
  private llmProxy: LlmChatProxy = LlmChatProxy.getInstance();
  private scrollController: Scroller = new Scroller();
  private componentActive: boolean = true;
  private pendingTimers: number[] = [];

  private chatHistoryService: ChatHistoryPrefsService = ChatHistoryPrefsService.getInstance();

  private tracker: PageResourceTracker = createPageTracker('AiChatPage')

  private themeRef: ThemeReactive = themeReactive

  private get isDark(): boolean {
    if (this.themeRef.key >= 0) { /* trigger reactive */ }
    return ThemeColors.getTheme() === ThemeMode.DARK;
  }

  private get pageBgGradient(): LinearGradient {
    if (this.isDark) {
      return { angle: 180, colors: [['#1A1410', 0.0], ['#231C16', 0.5], ['#0F0C0A', 1.0]] };
    }
    return { angle: 180, colors: [['#FBF9F6', 0.0], ['#F7F4F0', 1.0]] };
  }

  async aboutToAppear() {
    this.tracker.onAppear()
    PerformanceMonitor.getInstance().pageEnter('AiChatPage');
    this.componentActive = true;
    this.isLoading = true;
    try {
      this.familyMembers = await this.appState.getAllMembers();
      if (this.familyMembers.length > 0) {
        this.selectedMemberId = this.familyMembers[0].memberId;
        this.selectedMemberName = this.familyMembers[0].nickname;
        this.dynamicQuickQuestions = generateDynamicQuickQuestions(
          this.familyMembers[0]?.healthGoals?.join(',') ?? ''
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
        const welcomeMsg: ChatMessage = new ChatMessage(
          generateMessageId(),
          welcomeText,
          ChatRole.ASSISTANT,
          Date.now()
        );
        this.messages.push(welcomeMsg);
      }

      if (this.selectedMemberId.length > 0) {
        // V5: LlmChatProxy 按请求传入 memberId，无需 bindMember
      }
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'aboutToAppear failed: %{public}s', JSON.stringify(error));
    } finally {
      this.isLoading = false;
    }
  }

  aboutToDisappear(): void {
    this.tracker.onDisappear()
    PerformanceMonitor.getInstance().pageLeave('AiChatPage');
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
      if (this.hasPageError) {
        ErrorFallback({
          message: $r('app.string.ai_chat_page_load_failed'),
          onRetry: () => { this.aboutToAppear() }
        })
      } else {
        Column() {
      // ===== 顶部导航栏 — 渐变头部 =====
      Column() {
        Row() {
          // AI头像
          Column() {
            Text('智能助手')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(COLORS.WHITE)
          }
          .width(40)
          .height(40)
          .borderRadius(12)
          .backgroundColor('rgba(255,255,255,0.25)')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)

          // 标题 + 当前成员
          Column({ space: 2 }) {
            Text($r('app.string.ai_chat_title'))
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(COLORS.WHITE)

            if (this.selectedMemberId.length > 0) {
              Text(this.selectedMemberName)
                .fontSize(12)
                .fontColor('rgba(255,255,255,0.8)')
            }
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 12 })

          // 切换成员按钮
          if (this.familyMembers.length > 1) {
            Row() {
              Text($r('app.string.ai_chat_switch'))
                .fontSize(13)
                .fontColor(COLORS.WHITE)
            }
            .padding({ left: 14, right: 14, top: 6, bottom: 6 })
            .backgroundColor('rgba(255,255,255,0.2)')
            .borderRadius(20)
            .onClick(() => this.showMemberPicker())
          }
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 52, bottom: 16 })
      }
      .width('100%')
      .linearGradient({
        angle: 165,
        colors: [['#C56542', 0.0], ['#E07856', 0.5], ['#F2A78D', 1.0]]
      })
      .borderRadius({ topLeft: 0, topRight: 0, bottomLeft: 0, bottomRight: 0 })
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

      // ===== 消息列表 =====
      Scroll(this.scrollController) {
        Column() {
          // 快捷提问(仅首次显示)
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

      // ===== 底部输入区=====
      Column() {
        this.ModeBadge()
      }
      .width('100%')
      .padding({ left: SPACING.MD, right: SPACING.MD, top: SPACING.XS })
      .backgroundColor(COLORS.WHITE)

      Row() {
        TextInput({ placeholder: $r('app.string.ai_chat_input_placeholder'), text: this.inputText })
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
          .accessibilityText($r('app.string.ai_chat_input_accessibility'))
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
          ? '#E07856' : COLORS.TEXT_TERTIARY)
        .borderRadius(RADIUS.FULL)
        .margin({ left: SPACING.SM })
        .enabled(this.inputText.length > 0 && !this.isLoading)
        .onClick(() => this.sendMessage())
        .accessibilityText($r('app.string.ai_chat_send_accessibility'))
        .accessibilityLevel('yes')
      }
      .width('100%')
      .padding({ left: SPACING.MD, right: SPACING.MD, top: SPACING.SM, bottom: SPACING.LG + 52 })
      .backgroundColor(COLORS.WHITE)
      .shadow(SHADOWS.SM)
    }
    .width('100%')
    .height('100%')
    .linearGradient(this.pageBgGradient)
      }
    }
    .opacity(this.themeRef.key >= 0 ? 1 : 1)
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
        Row() {
          Text(question)
            .fontSize(FONT_SIZE.BODY)
            .fontColor(COLORS.PRIMARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .height(40)
        .borderRadius(20)
        .backgroundColor(COLORS.PRIMARY_LIGHT)
        .padding({ left: SPACING.MD, right: SPACING.MD })
        .alignItems(VerticalAlign.Center)
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
    .shadow(SHADOWS.SM)
  }

  // ========== 模式徽标（本地/云端/离线） ==========
  @Builder
  ModeBadge() {
    Row({ space: 4 }) {
      Column() {}
        .width(6)
        .height(6)
        .borderRadius(3)
        .backgroundColor(this.modeBadgeColor())
      Text(this.modeBadgeLabel())
        .fontSize(FONT_SIZE.TINY)
        .fontColor(this.modeBadgeTextColor())
    }
    .padding({ left: SPACING.SM, right: SPACING.SM, top: 2, bottom: 2 })
    .borderRadius(RADIUS.FULL)
    .backgroundColor(this.modeBadgeBgColor())
    .margin({ top: SPACING.XS, bottom: 0 })
  }

  private modeBadgeLabel(): string {
    if (this.activeMode === LlmSource.ON_DEVICE) return '本地模式';
    if (this.activeMode === LlmSource.FALLBACK_TEMPLATE) return '离线模式';
    return '云端模式';
  }

  private modeBadgeColor(): string {
    if (this.activeMode === LlmSource.ON_DEVICE) return '#7CB342';
    if (this.activeMode === LlmSource.FALLBACK_TEMPLATE) return '#F5A623';
    return '#E07856';
  }

  private modeBadgeTextColor(): string {
    if (this.activeMode === LlmSource.ON_DEVICE) return '#558B2F';
    if (this.activeMode === LlmSource.FALLBACK_TEMPLATE) return '#E8941A';
    return '#C56542';
  }

  private modeBadgeBgColor(): string {
    if (this.activeMode === LlmSource.ON_DEVICE) return '#EFF6E8';
    if (this.activeMode === LlmSource.FALLBACK_TEMPLATE) return '#FFF5E0';
    return '#FCF0EB';
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
        .linearGradient({ angle: 135, colors: [['#C56542', 0.0], ['#E07856', 1.0]] })
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
        Column() {
          Text('智能助手')
            .fontSize(FONT_SIZE.CAPTION)
            .fontWeight(FONT_WEIGHT.BOLD)
            .fontColor(COLORS.WHITE)
        }
        .width(32)
        .height(32)
        .borderRadius(RADIUS.LG)
        .linearGradient({ angle: 135, colors: [['#C56542', 0.0], ['#E07856', 1.0]] })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
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
        .backgroundColor(this.isDark ? '#1E1E1E' : '#FAFAFA')
        .borderRadius(RADIUS.LG)
        .borderRadius({
          topLeft: RADIUS.SM,
          topRight: RADIUS.LG,
          bottomLeft: RADIUS.LG,
          bottomRight: RADIUS.LG
        })
        .border({ width: { left: 3, top: 0, right: 0, bottom: 0 }, color: '#43A047' })
        .shadow(SHADOWS.XS)

        Blank()
          .layoutWeight(1)
      }
    }
    .width('100%')
    .margin({ top: SPACING.SM, bottom: SPACING.SM })
    .alignItems(VerticalAlign.Top)
    .transition(TransitionEffect.OPACITY.animation({ duration: 300, curve: Curve.FastOutSlowIn }).combine(TransitionEffect.move(TransitionEdge.BOTTOM)))
  }

  // ========== 发送消息==========

  private async sendMessage(): Promise<void> {
    const text = this.inputText.trim()
    if (text.length === 0 || this.isLoading) return

    PerformanceMonitor.getInstance().startSpan('ai_response:chat');

    this.showQuickQuestions = false

    const userMsg: ChatMessage = new ChatMessage(
      generateMessageId(),
      text,
      ChatRole.USER,
      Date.now()
    )
    userMsg.status = MessageStatus.SENDING
    this.messages.push(userMsg)
    this.inputText = ''
    this.isLoading = true

    const tid1 = setTimeout(() => {
      const idx = this.pendingTimers.indexOf(tid1);
      if (idx >= 0) { this.pendingTimers.splice(idx, 1); this.pendingTimers = [...this.pendingTimers]; }
      if (!this.componentActive) return;
      this.scrollController.scrollEdge(Edge.End)
    }, 100)
    this.pendingTimers.push(tid1)

    try {
      const context: string[] = this.messages
        .filter(m => m.role === ChatRole.ASSISTANT && (m.content as string).length > 0)
        .slice(-4)
        .map(m => typeof m.content === 'string' ? m.content : '');
      const healthCtx = this.buildMemberHealthContext();
      const preferOffline = this.isOfflineMode;

      const response = await this.llmProxy.chat({
        question: text,
        context: context,
        memberId: this.selectedMemberId,
        preferOffline: preferOffline,
      }, healthCtx);

      if (!this.componentActive) return;

      userMsg.status = MessageStatus.SENT;
      this.activeMode = response.source;
      const notice: string | undefined = response.degradeNotice;
      if (notice !== undefined && notice.length > 0) {
        promptAction.showToast({ message: notice, duration: 2500 });
      }
      const sourceLabel = response.source === LlmSource.ON_DEVICE
        ? ' [端侧]' : response.source === LlmSource.CLOUD_PANGU
        ? ' [AI]' : '';
      const aiMsg: ChatMessage = new ChatMessage(
        generateMessageId(),
        response.answer + sourceLabel,
        ChatRole.ASSISTANT,
        Date.now()
      );
      this.messages.push(aiMsg);
      this.saveCurrentMessages();
    } catch (error) {
      userMsg.status = MessageStatus.FAILED
      hilog.error(DOMAIN_ZERO, TAG, 'sendMessage failed: %{public}s', JSON.stringify(error))
      const errorMsg: ChatMessage = new ChatMessage(
        generateMessageId(),
        $r('app.string.ai_chat_error_reply') as ResourceStr,
        ChatRole.ASSISTANT,
        Date.now()
      )
      this.messages.push(errorMsg)
      this.saveCurrentMessages()
    }

    this.isLoading = false
    PerformanceMonitor.getInstance().endSpan('ai_response:chat');

    const tid2 = setTimeout(() => {
      const idx2 = this.pendingTimers.indexOf(tid2);
      if (idx2 >= 0) { this.pendingTimers.splice(idx2, 1); this.pendingTimers = [...this.pendingTimers]; }
      if (!this.componentActive) return;
      this.scrollController.scrollEdge(Edge.End)
    }, 100)
    this.pendingTimers.push(tid2)
  }

  private buildMemberHealthContext(): MemberHealthContext {
    const member = this.familyMembers.find(m => m.memberId === this.selectedMemberId);
    const ageGroupToAge = (ag: AgeGroup): number => {
      switch (ag) {
        case AgeGroup.INFANT: return 1;
        case AgeGroup.TODDLER: return 3;
        case AgeGroup.CHILD: return 8;
        case AgeGroup.TEEN: return 14;
        case AgeGroup.ADULT: return 30;
        case AgeGroup.MIDDLE_OLD: return 55;
        case AgeGroup.OLD: return 75;
        default: return 30;
      }
    };
    const ctx: MemberHealthContext = {
      age: member ? ageGroupToAge(member.ageGroup) : 30,
      gender: 'other',
      allergens: member?.allergens ?? [],
      healthGoal: (member?.healthGoals?.join(',') ?? '维持体重'),
      conditions: [],
      dietPreference: '',
    };
    return ctx;
  }

  // ========== 切换成员 ==========
  private showMemberPicker(): void {
    const items: string[] = this.familyMembers.map(m => m.nickname)
    const maxButtons = Math.min(items.length, 6)
    const btn0: promptAction.Button = maxButtons > 0 ? { text: items[0], color: COLORS.TEXT_PRIMARY } : { text: '', color: '' }
    const btn1: promptAction.Button | undefined = maxButtons > 1 ? { text: items[1], color: COLORS.TEXT_PRIMARY } : undefined
    const btn2: promptAction.Button | undefined = maxButtons > 2 ? { text: items[2], color: COLORS.TEXT_PRIMARY } : undefined
    const btn3: promptAction.Button | undefined = maxButtons > 3 ? { text: items[3], color: COLORS.TEXT_PRIMARY } : undefined
    const btn4: promptAction.Button | undefined = maxButtons > 4 ? { text: items[4], color: COLORS.TEXT_PRIMARY } : undefined
    const btn5: promptAction.Button | undefined = maxButtons > 5 ? { text: items[5], color: COLORS.TEXT_PRIMARY } : undefined

    promptAction.showActionMenu({
      title: $r('app.string.ai_chat_switch_member') as ResourceStr,
      buttons: [btn0, btn1, btn2, btn3, btn4, btn5] as [
        promptAction.Button,
        promptAction.Button?,
        promptAction.Button?,
        promptAction.Button?,
        promptAction.Button?,
        promptAction.Button?
      ]
    }, async (err: Error, data: promptAction.ActionMenuSuccessResponse) => {
      if (err) {
        hilog.warn(0x0000, 'AiChatPage', 'showActionMenu err: %{public}s', JSON.stringify(err));
        return;
      }
      const index: number = data.index ?? 0
      if (index >= 0 && index < this.familyMembers.length) {
        const member = this.familyMembers[index]

        // 保存当前成员的对话
        await this.saveCurrentMessages()

        this.selectedMemberId = member.memberId
        this.selectedMemberName = member.nickname
        this.dynamicQuickQuestions = generateDynamicQuickQuestions(member?.healthGoals?.join(',') ?? '')
        this.messages = []
        this.showQuickQuestions = true

        // 加载新成员的历史消息
        try {
          const savedJson = await this.chatHistoryService.getMessages(member.memberId);
          const savedMessages: ChatMessage[] = JSON.parse(savedJson);
          if (savedMessages.length > 0) {
            this.messages = savedMessages;
          } else {
            const switchMsg: ChatMessage = new ChatMessage(
              generateMessageId(),
              $r('app.string.ai_chat_switched_member', member.nickname) as ResourceStr,
              ChatRole.ASSISTANT,
              Date.now()
            )
            this.messages.push(switchMsg)
          }
        } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(e));
          const switchMsg: ChatMessage = new ChatMessage(
            generateMessageId(),
            $r('app.string.ai_chat_switched_member', member.nickname) as ResourceStr,
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