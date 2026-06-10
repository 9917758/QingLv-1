/**
 * AI 健康顾问对话页面
 * 支持会话列表、多轮对话、新建/切换/删除会话
 */
import { window } from '@kit.ArkUI';
import { HttpUtil, AuthToken, ThemeUtil } from 'common';
import type { ThemeColors } from 'common';
import type {
  ApiResponse, ApiChatSession, ApiChatSessionList,
  ApiChatMessage, ApiChatMessageList, ApiChatSendResponse
} from 'common';
import { phoneRouterControl } from 'oh_router';

interface DisplayMessage {
  role: string;
  content: string;
  time: string;
}

interface SessionCreateBody {
  title: string;
}

interface ChatSendBody {
  message: string;
}

@Builder
export function AiAgentPageBuilder() {
  AiAgentPage()
}

@ComponentV2
export struct AiAgentPage {
  @Local messages: DisplayMessage[] = [];
  @Local inputText: string = '';
  @Local isLoading: boolean = false;
  @Local sessionId: number = -1;
  @Local sessions: ApiChatSession[] = [];
  @Local showSessionList: boolean = false;
  @Local statusBarHeight: number = 48;
  @Computed get themeColors(): ThemeColors {
    return ThemeUtil.instance.currentColors;
  }

  async aboutToAppear(): Promise<void> {
    this.getStatusBarHeight();
    await this.loadSessions();
    await this.initSession();
  }

  private getStatusBarHeight(): void {
    try {
      const stage = window.getLastWindow(getContext(this));
      stage.then((win: window.Window) => {
        const avoidArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
        this.statusBarHeight = avoidArea.topRect.height > 0 ? avoidArea.topRect.height : 48;
      });
    } catch {
      this.statusBarHeight = 48;
    }
  }

  /** 加载会话列表 */
  private async loadSessions(): Promise<void> {
    const resp: ApiResponse<ApiChatSessionList> = await HttpUtil.get<ApiChatSessionList>('/api/chat/sessions');
    if (resp.data) {
      this.sessions = resp.data.sessions;
    }
  }

  /** 初始化：加载最近会话或创建新会话 */
  private async initSession(): Promise<void> {
    if (this.sessions.length > 0) {
      this.sessionId = this.sessions[0].id;
      await this.loadMessages();
    } else {
      await this.createSession();
    }
  }

  /** 创建新会话 */
  private async createSession(): Promise<void> {
    const body: SessionCreateBody = { title: '新对话' };
    const resp: ApiResponse<ApiChatSession> = await HttpUtil.post<ApiChatSession>('/api/chat/sessions', body);
    if (resp.data) {
      this.sessionId = resp.data.id;
      this.messages = [{
        role: 'assistant',
        content: '你好！我是清律健康顾问 🏥\n\n我可以根据你的健康数据和收藏的知识文章，为你提供个性化的健康建议。\n\n你可以问我：\n• 我最近的身体状况怎么样？\n• 根据我的数据，有什么需要注意的？\n• 怎样改善我的睡眠质量？\n• 推荐适合我的运动方式',
        time: this.getTimeStr()
      }];
      await this.loadSessions();
    }
  }

  /** 切换到指定会话 */
  private async switchSession(sessionId: number): Promise<void> {
    this.sessionId = sessionId;
    this.showSessionList = false;
    await this.loadMessages();
  }

  /** 删除会话 */
  private async deleteSession(sessionId: number): Promise<void> {
    await HttpUtil.del<object>(`/api/chat/sessions/${sessionId}`);
    await this.loadSessions();
    // 如果删除的是当前会话，切换到最近的会话或创建新的
    if (this.sessionId === sessionId) {
      if (this.sessions.length > 0) {
        await this.switchSession(this.sessions[0].id);
      } else {
        await this.createSession();
      }
    }
  }

  /** 加载当前会话的历史消息 */
  private async loadMessages(): Promise<void> {
    if (this.sessionId < 0) return;
    const resp: ApiResponse<ApiChatMessageList> = await HttpUtil.get<ApiChatMessageList>(`/api/chat/sessions/${this.sessionId}/messages`);
    if (resp.data && resp.data.messages.length > 0) {
      const loaded: DisplayMessage[] = [];
      for (let i = 0; i < resp.data.messages.length; i++) {
        const m = resp.data.messages[i];
        loaded.push({ role: m.role, content: m.content, time: this.formatTime(m.created_at) });
      }
      this.messages = loaded;
    } else {
      this.messages = [{
        role: 'assistant',
        content: '你好！我是清律健康顾问 🏥\n\n请输入你的健康问题。',
        time: this.getTimeStr()
      }];
    }
  }

  private getTimeStr(): string {
    const now = new Date();
    return `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;
  }

  private formatTime(isoStr: string): string {
    try {
      const d = new Date(isoStr);
      return `${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}`;
    } catch {
      return '';
    }
  }

  private formatSessionTime(isoStr: string): string {
    try {
      const d = new Date(isoStr);
      const month = (d.getMonth() + 1).toString().padStart(2, '0');
      const day = d.getDate().toString().padStart(2, '0');
      const hour = d.getHours().toString().padStart(2, '0');
      const min = d.getMinutes().toString().padStart(2, '0');
      return `${month}-${day} ${hour}:${min}`;
    } catch {
      return '';
    }
  }

  private async sendMessage(): Promise<void> {
    const text = this.inputText.trim();
    if (text.length === 0 || this.isLoading || this.sessionId < 0) return;

    const userDisplay: DisplayMessage = { role: 'user', content: text, time: this.getTimeStr() };
    this.messages = [...this.messages, userDisplay];
    this.inputText = '';
    this.isLoading = true;

    const sendBody: ChatSendBody = { message: text };
    const resp: ApiResponse<ApiChatSendResponse> = await HttpUtil.post<ApiChatSendResponse>(
      `/api/chat/sessions/${this.sessionId}/send`, sendBody
    );

    this.isLoading = false;

    if (resp.data) {
      const aiDisplay: DisplayMessage = {
        role: 'assistant',
        content: resp.data.ai_message.content,
        time: this.formatTime(resp.data.ai_message.created_at)
      };
      this.messages = [...this.messages, aiDisplay];
      this.loadSessions(); // 刷新会话列表（标题可能更新）
    } else {
      const errMsg: DisplayMessage = {
        role: 'assistant',
        content: `抱歉，暂时无法回答：${resp.error}`,
        time: this.getTimeStr()
      };
      this.messages = [...this.messages, errMsg];
    }
  }

  // ─── 会话列表侧边栏 ───

  @Builder
  sessionListDrawer() {
    Column() {
      // 侧边栏头部
      Row() {
        Text($r('app.string.health_ai_history_title'))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeColors.textPrimary)
        Blank()
        Text('✕')
          .fontSize(18)
          .fontColor(this.themeColors.textTertiary)
          .padding(8)
          .onClick(() => this.showSessionList = false)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 12 })

      // 新建对话按钮
      Row() {
        Text('+')
          .fontSize(18)
          .fontColor(this.themeColors.accent)
          .fontWeight(FontWeight.Bold)
          .margin({ right: 8 })
        Text($r('app.string.health_ai_new_chat_btn'))
          .fontSize(15)
          .fontColor(this.themeColors.accent)
      }
      .width('100%')
      .height(48)
      .padding({ left: 16, right: 16 })
      .backgroundColor(this.themeColors.accentLight)
      .borderRadius(10)
      .margin({ left: 12, right: 12, bottom: 12 })
      .onClick(() => {
        this.showSessionList = false;
        this.createSession();
      })

      // 会话列表
      List() {
        ForEach(this.sessions, (session: ApiChatSession) => {
          ListItem() {
            Row() {
              Column() {
                Text(session.title)
                  .fontSize(15)
                  .fontColor(this.sessionId === session.id ? this.themeColors.accent : this.themeColors.textPrimary)
                  .fontWeight(this.sessionId === session.id ? FontWeight.Medium : FontWeight.Normal)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(this.formatSessionTime(session.updated_at))
                  .fontSize(12)
                  .fontColor(this.themeColors.textTertiary)
                  .margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Text('🗑')
                .fontSize(16)
                .padding(8)
                .onClick(() => this.deleteSession(session.id))
            }
            .width('100%')
            .height(60)
            .padding({ left: 16, right: 12 })
            .backgroundColor(this.sessionId === session.id ? this.themeColors.accentLight : this.themeColors.backgroundCard)
            .borderRadius(8)
            .margin({ left: 8, right: 8, bottom: 4 })
            .onClick(() => this.switchSession(session.id))
          }
        })
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeColors.backgroundPrimary)
  }

  // ─── 消息气泡 ───

  @Builder
  messageBubble(msg: DisplayMessage) {
    Row() {
      if (msg.role === 'user') {
        Blank()
      }

      Column() {
        Text(msg.content)
          .fontSize(15)
          .fontColor(msg.role === 'user' ? this.themeColors.textOnAccent : this.themeColors.textPrimary)
          .padding(12)
          .borderRadius(16)
          .backgroundColor(msg.role === 'user' ? this.themeColors.accent : this.themeColors.backgroundInput)
          .constraintSize({ maxWidth: '85%' })

        Text(msg.time)
          .fontSize(11)
          .fontColor(this.themeColors.textTertiary)
          .margin({ top: 4 })
      }
      .alignItems(msg.role === 'user' ? HorizontalAlign.End : HorizontalAlign.Start)

      if (msg.role === 'assistant') {
        Blank()
      }
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
  }

  @Builder
  loadingIndicator() {
    Row({ space: 4 }) {
      Text($r('app.string.health_thinking'))
        .fontSize(14)
        .fontColor(this.themeColors.textTertiary)
      LoadingProgress()
        .width(20)
        .height(20)
        .color(this.themeColors.accent)
    }
    .padding(12)
    .margin({ left: 12, top: 6 })
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        Column() {
          // 顶部导航栏（加了 statusBarHeight 的 padding）
          Row() {
            Text('←')
              .fontSize(22)
              .fontColor(this.themeColors.textPrimary)
              .padding(8)
              .onClick(() => phoneRouterControl.popPage())
            Text($r('app.string.health_ai_agent_title'))
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.themeColors.textPrimary)
              .margin({ left: 8 })
            Blank()
            Text($r('app.string.health_ai_history'))
              .fontSize(14)
              .fontColor(this.themeColors.accent)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .borderRadius(14)
              .backgroundColor(this.themeColors.accentLight)
              .onClick(() => this.showSessionList = !this.showSessionList)
            Text($r('app.string.health_ai_new_chat'))
              .fontSize(14)
              .fontColor(this.themeColors.textOnAccent)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .borderRadius(14)
              .backgroundColor(this.themeColors.accent)
              .margin({ left: 8 })
              .onClick(() => this.createSession())
          }
          .width('100%')
          .height(56)
          .padding({ left: 12, right: 16 })
          .backgroundColor(this.themeColors.backgroundPrimary)
          .borderWidth({ bottom: 1 })
          .borderColor(this.themeColors.divider)

          // 消息列表
          List() {
            ForEach(this.messages, (msg: DisplayMessage) => {
              ListItem() {
                this.messageBubble(msg)
              }
            })

            if (this.isLoading) {
              ListItem() {
                this.loadingIndicator()
              }
            }
          }
          .layoutWeight(1)
          .width('100%')
          .backgroundColor(this.themeColors.backgroundSecondary)
          .edgeEffect(EdgeEffect.Spring)
          .scrollBar(BarState.Off)

          // 输入区域
          Row({ space: 8 }) {
            TextInput({ text: $$this.inputText, placeholder: '输入你的健康问题...' })
              .layoutWeight(1)
              .height(44)
              .borderRadius(22)
              .backgroundColor(this.themeColors.backgroundInput)
              .padding({ left: 16, right: 16 })
              .fontSize(15)
              .fontColor(this.themeColors.textPrimary)
              .onSubmit(() => this.sendMessage())

            Button(this.isLoading ? '...' : $r('app.string.health_ai_send'))
              .height(44)
              .borderRadius(22)
              .backgroundColor(this.isLoading ? this.themeColors.textTertiary : this.themeColors.accent)
              .fontColor(this.themeColors.textOnAccent)
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .enabled(!this.isLoading)
              .onClick(() => this.sendMessage())
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 8, bottom: 12 })
          .backgroundColor(this.themeColors.backgroundPrimary)
          .borderWidth({ top: 1 })
          .borderColor(this.themeColors.divider)
        }
        .width('100%')
        .height('100%')
        .padding({ top: this.statusBarHeight })

        // 会话列表侧边栏（覆盖在左侧）
        if (this.showSessionList) {
          Row() {
            this.sessionListDrawer()
          }
          .width('75%')
          .height('100%')
          .backgroundColor(this.themeColors.backgroundPrimary)
          .shadow({ radius: 16, color: '#33000000', offsetX: 4, offsetY: 0 })

          // 点击遮罩关闭
          Column()
            .width('25%')
            .height('100%')
            .backgroundColor('rgba(0,0,0,0.3)')
            .onClick(() => this.showSessionList = false)
        }
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
  }
}
