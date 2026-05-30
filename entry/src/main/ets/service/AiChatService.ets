import { ChatMessage } from 'hsp_core';
import { AiChatServiceImpl, createAiChatService } from 'hsp_service';
import { getCommonStateProvider } from './CommonStateProvider';

let _impl: AiChatServiceImpl | null = null;
function getImpl(): AiChatServiceImpl {
  if (_impl === null) { _impl = createAiChatService(getCommonStateProvider()); }
  return _impl;
}

export class AiChatService {
  bindMember(memberId: string): void { getImpl().bindMember(memberId); }
  getBoundMemberId(): string { return getImpl().getBoundMemberId(); }
  clearHistory(): void { getImpl().clearHistory(); }
  async sendMessage(message: string): Promise<ChatMessage> { return getImpl().sendMessage(message); }
  isAvailable(): boolean { return getImpl().isAvailable(); }
}
