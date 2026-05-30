import { FamilyProfile, HealthSignal, DailyBudget, NutritionTarget } from 'hsp_core';
import { IAiStateProvider } from 'hsp_service';
import { AppState } from '../AppState';

export class CommonStateProvider implements IAiStateProvider {
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

let _provider: CommonStateProvider | null = null;

export function getCommonStateProvider(): CommonStateProvider {
  if (_provider === null) { _provider = new CommonStateProvider(); }
  return _provider;
}