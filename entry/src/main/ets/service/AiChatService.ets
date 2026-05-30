import { ChatMessage, FamilyProfile, HealthSignal, DailyBudget, NutritionTarget } from 'hsp_core';
import { AiChatServiceImpl, createAiChatService, IAiStateProvider } from 'hsp_service';
import { AppState } from '../AppState';

class AppStateProvider implements IAiStateProvider {
  async getAllMembers(): Promise<FamilyProfile[]> {
    return AppState.getInstance().getAllMembers();
  }
  getHealthSignal(memberId: string): HealthSignal {
    return AppState.getInstance().getHealthSignal(memberId);
  }
  getDailyBudget(memberId: string): DailyBudget {
    return AppState.getInstance().getDailyBudgetSync(memberId);
  }
  getCurrentMemberId(): string {
    return AppState.getInstance().member.getCurrentMemberId();
  }
  getNutritionTarget(memberId: string): NutritionTarget | null {
    return AppState.getInstance().getNutritionTargetFromCache(memberId);
  }
}

let _impl: AiChatServiceImpl | null = null;

function getImpl(): AiChatServiceImpl {
  if (_impl === null) {
    _impl = createAiChatService(new AppStateProvider());
  }
  return _impl;
}

export class AiChatService {
  bindMember(memberId: string): void { getImpl().bindMember(memberId); }
  getBoundMemberId(): string { return getImpl().getBoundMemberId(); }
  clearHistory(): void { getImpl().clearHistory(); }
  async sendMessage(message: string): Promise<ChatMessage> { return getImpl().sendMessage(message); }
  isAvailable(): boolean { return getImpl().isAvailable(); }
}
