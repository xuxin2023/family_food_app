// AiChatPage.ets
// AI 钀ュ吇甯堝璇濋〉闈?鈥?鏀寔澶氳疆瀵硅瘽銆佹垚鍛樼粦瀹氥€佸揩鎹锋彁闂?
import {
  safeBack, FamilyProfile, COLORS, FONT_SIZE, SPACING, RADIUS, FONT_WEIGHT, HILOG_DOMAIN_DEFAULT, ChatRole, ChatMessage, MessageStatus, QUICK_QUESTIONS, generateDynamicQuickQuestions, generateMessageId, PerformanceMonitor, PageResourceTracker, createPageTracker
} from 'hsp_core';
import { promptAction } from '@kit.ArkUI';
import { BackButton } from '../components/BackButton';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppState } from '../AppState';
import { ErrorBoundary } from '../components/ErrorBoundary';
import { LlmChatProxy, LlmSource, MemberHealthContext } from 'hsp_service';

import { ChatHistoryPrefsService } from 'hsp_service';

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
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

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
  @Local isOfflineMode: boolean = false
  @Local hasPageError: boolean = false;

  private appState: AppState = AppState.getInstance();
  private llmProxy: LlmChatProxy = LlmChatProxy.getInstance();
  private scrollController: Scroller = new Scroller();
  private componentActive: boolean = true;
  private pendingTimers: number[] = [];

  private chatHistoryService: ChatHistoryPrefsService = ChatHistoryPrefsService.getInstance();

  private tracker: PageResourceTracker = createPageTracker('AiChatPage')

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

      // 浠庢寔涔呭寲瀛樺偍鍔犺浇璇ユ垚鍛樼殑鍘嗗彶娑堟伅
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
    // 鎸佷箙鍖栦繚瀛樺綋鍓嶆垚鍛樼殑瀵硅瘽
    if (this.selectedMemberId.length > 0 && this.messages.length > 0) {
      this.chatHistoryService.saveMessages(this.selectedMemberId, JSON.stringify(this.messages));
    }
    for (const tid of this.pendingTimers) {
      clearTimeout(tid);
    }
    this.pendingTimers = [];
  }

  build() {
    ErrorBoundary({
      fallbackMessage: $r('app.string.ai_chat_page_load_failed'),
      onRetry: () => { this.aboutToAppear() },
      hasError: this.hasPageError,
      boundaryName: 'AiChatPage'
    }) {
      Column() {
      // ===== 椤堕儴瀵艰埅鏍?=====
      Row() {
        // 杩斿洖鎸夐挳
        BackButton({ fontSize: 28, fontColor: COLORS.TEXT_PRIMARY })
          .onClick(() => safeBack())
          .accessibilityText($r('app.string.back_arrow'))
          .accessibilityLevel('yes')

        // 鏍囬 + 褰撳墠鎴愬憳
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

        // 鍒囨崲鎴愬憳鎸夐挳
        if (this.familyMembers.length > 1) {
          Text($r('app.string.ai_chat_switch'))
            .fontSize(FONT_SIZE.BODY)
            .fontColor(COLORS.ACCENT_BLUE)
            .onClick(() => this.showMemberPicker())
            .accessibilityText($r('app.string.ai_chat_switch_member'))
            .accessibilityLevel('yes')
        }
      }
      .width('100%')
      .padding({ left: SPACING.LG, right: SPACING.LG, top: SPACING.MD, bottom: SPACING.SM })
      .backgroundColor(COLORS.WHITE)
      .shadow({ radius: 2, color: COLORS.SHADOW, offsetY: 2 })

      // ===== 娑堟伅鍒楄〃 =====
      Scroll(this.scrollController) {
        Column() {
          // 蹇嵎鎻愰棶锛堜粎棣栨鏄剧ず锛?          if (this.showQuickQuestions && this.messages.length <= 2) {
            this.QuickQuestionsPanel()
          }

          // 娑堟伅鍒楄〃
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

      // ===== 搴曢儴杈撳叆鍖?=====
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
          ? COLORS.ACCENT_PURPLE : COLORS.TEXT_TERTIARY)
        .borderRadius(RADIUS.FULL)
        .margin({ left: SPACING.SM })
        .enabled(this.inputText.length > 0 && !this.isLoading)
        .onClick(() => this.sendMessage())
        .accessibilityText($r('app.string.ai_chat_send_accessibility'))
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
  }

  // ========== 蹇嵎鎻愰棶闈㈡澘 ==========
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

  // ========== 娑堟伅姘旀场 ==========
  @Builder
  MessageBubble(msg: ChatMessage) {
    Row() {
      if (msg.role === ChatRole.USER) {
        // 鍙充晶锛氱敤鎴锋秷鎭?        Blank()
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
        // 宸︿晶锛欰I 娑堟伅
        // AI 澶村儚
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

  // ========== 鍙戦€佹秷鎭?==========

  private async sendMessage(): Promise<void> {
    const text = this.inputText.trim()
    if (text.length === 0 || this.isLoading) return

    PerformanceMonitor.getInstance().startSpan('ai_response:chat');

    this.showQuickQuestions = false

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

    const tid1 = setTimeout(() => {
      const idx = this.pendingTimers.indexOf(tid1);
      if (idx >= 0) { this.pendingTimers.splice(idx, 1); this.pendingTimers = [...this.pendingTimers]; }
      if (!this.componentActive) return;
      this.scrollController.scrollEdge(Edge.End)
    }, 100)
    this.pendingTimers.push(tid1)

    try {
      const context: string[] = this.messages
        .filter(m => m.role === ChatRole.ASSISTANT && m.content.length > 0)
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
      const sourceLabel = response.source === LlmSource.ON_DEVICE
        ? ' [端侧]' : response.source === LlmSource.CLOUD_PANGU
        ? ' [AI]' : '';
      const aiMsg = new ChatMessage(
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
      const errorMsg = new ChatMessage(
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
    return {
      age: member?.age ?? 30,
      gender: member?.gender ?? 'other',
      allergens: member?.allergens ?? [],
      healthGoal: (member?.healthGoals?.join(',') ?? '维持体重'),
      conditions: member?.conditions ?? [],
      dietPreference: member?.dietPreference ?? '',
    };
  }

  // ========== 鍒囨崲鎴愬憳 ==========
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
      buttons: [btn0, btn1, btn2, btn3, btn4, btn5].filter(
        (b: promptAction.Button | undefined): b is promptAction.Button => b !== undefined
      )
    }, async (err: Error, data: promptAction.ActionMenuSuccessResponse) => {
      if (err) {
        hilog.warn(0x0000, 'AiChatPage', 'showActionMenu err: %{public}s', JSON.stringify(err));
        return;
      }
      const index: number = data.index ?? 0
      if (index >= 0 && index < this.familyMembers.length) {
        const member = this.familyMembers[index]

        // 淇濆瓨褰撳墠鎴愬憳鐨勫璇?        await this.saveCurrentMessages()

        this.selectedMemberId = member.memberId
        this.selectedMemberName = member.nickname
        this.dynamicQuickQuestions = generateDynamicQuickQuestions(member?.healthGoals?.join(',') ?? '')
        this.messages = []
        this.showQuickQuestions = true

        // 鍔犺浇鏂版垚鍛樼殑鍘嗗彶娑堟伅
        try {
          const savedJson = await this.chatHistoryService.getMessages(member.memberId);
          const savedMessages: ChatMessage[] = JSON.parse(savedJson);
          if (savedMessages.length > 0) {
            this.messages = savedMessages;
          } else {
            const switchMsg = new ChatMessage(
              generateMessageId(),
              $r('app.string.ai_chat_switched_member', member.nickname) as ResourceStr,
              ChatRole.ASSISTANT,
              Date.now()
            )
            this.messages.push(switchMsg)
          }
        } catch (e) {
          const switchMsg = new ChatMessage(
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

  // ========== 宸ュ叿鏂规硶 ==========
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