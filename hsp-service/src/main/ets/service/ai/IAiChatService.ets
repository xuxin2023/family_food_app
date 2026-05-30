import { ChatMessage } from 'hsp_core';

export interface IAiChatService {
  sendMessage(message: string): Promise<ChatMessage>;
  bindMember(memberId: string): void;
  getBoundMemberId(): string;
  clearHistory(): void;
  isAvailable(): boolean;
  getRemainingQuota(): number;
}