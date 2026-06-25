import { IAiStateProvider } from '../IAiStateProvider';
import { FamilyProfile, HealthSignal, DailyBudget, NutritionTarget } from 'hsp_core';
import { AiNutritionistServiceImpl } from './AiNutritionistServiceImpl';
import { AiChatServiceImpl } from './AiChatServiceImpl';

export function createAiNutritionistService(provider?: IAiStateProvider): AiNutritionistServiceImpl {
  return new AiNutritionistServiceImpl(provider ?? createDefaultAiStateProvider());
}

export function createAiChatService(provider?: IAiStateProvider): AiChatServiceImpl {
  return new AiChatServiceImpl(provider ?? createDefaultAiStateProvider());
}

class DefaultAiStateProvider implements IAiStateProvider {
  getAllMembers(): Promise<FamilyProfile[]> { return Promise.resolve([]); }
  getHealthSignal(_memberId: string): HealthSignal { return new Object() as HealthSignal; }
  getDailyBudget(_memberId: string): DailyBudget { return new Object() as DailyBudget; }
  getCurrentMemberId(): string { return ''; }
  getNutritionTarget(_memberId: string): NutritionTarget | null { return null; }
}

function createDefaultAiStateProvider(): IAiStateProvider {
  return new DefaultAiStateProvider();
}