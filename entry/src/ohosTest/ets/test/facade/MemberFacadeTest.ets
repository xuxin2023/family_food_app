import { describe, it, expect } from '@ohos/hypium';
import { MemberFacade } from '../../../../../src/main/ets/facade/MemberFacade';
import { FamilyProfile, HealthSignal, DailyBudget, NutritionTarget } from 'hsp_core';
import { FamilyRepository } from '../../../../../src/main/ets/repository/FamilyRepository';
import { MemberManager } from 'hsp_service';
import { CacheManager } from 'hsp_core';
import { NutritionTargetRepository } from 'hsp_service';

class MockFamilyRepository extends FamilyRepository {
  private members: FamilyProfile[] = [];

  async getAllMembers(): Promise<FamilyProfile[]> {
    return this.members;
  }

  async saveMember(profile: FamilyProfile): Promise<void> {
    const idx = this.members.findIndex(m => m.memberId === profile.memberId);
    if (idx >= 0) {
      this.members[idx] = profile;
    } else {
      this.members.push(profile);
    }
  }

  async deleteMember(memberId: string): Promise<void> {
    this.members = this.members.filter(m => m.memberId !== memberId);
  }
}

class MockMemberManager extends MemberManager {
  syncMemberCount(count: number): void {}
}

class MockCacheManager extends CacheManager {
  private healthSignals: Map<string, HealthSignal> = new Map();
  private budgets: Map<string, DailyBudget> = new Map();

  getHealthSignalFromCache(mid: string): HealthSignal | undefined {
    return this.healthSignals.get(mid);
  }

  setHealthSignalToCache(mid: string, signal: HealthSignal): void {
    this.healthSignals.set(mid, signal);
  }

  clearHealthSignalsCache(): void {
    this.healthSignals.clear();
  }

  clearAllBudgets(): void {
    this.budgets.clear();
  }
}

class MockNutritionTargetRepository extends NutritionTargetRepository {
  async getForMember(memberId: string): Promise<NutritionTarget | null> {
    return null;
  }
}

export default function memberFacadeTest() {
  describe('MemberFacade', () => {
    it('saveMember_and_getAllMembersSync_should_work', 0, async () => {
      const familyRepo: MockFamilyRepository = new MockFamilyRepository()
      const facade: MemberFacade = new MemberFacade(
        familyRepo,
        new MockMemberManager(),
        new MockCacheManager(),
        new MockNutritionTargetRepository()
      );

      const profile: FamilyProfile = new FamilyProfile()
      profile.memberId = 'mem-001';
      profile.nickname = '爸爸';

      await facade.saveMember(profile);
      const members = facade.getAllMembersSync();
      expect(members.length).assertEqual(1);
      expect(members[0].nickname).assertEqual('爸爸');
    });

    it('deleteMember_should_remove_from_cache', 0, async () => {
      const familyRepo: MockFamilyRepository = new MockFamilyRepository()
      const facade: MemberFacade = new MemberFacade(
        familyRepo,
        new MockMemberManager(),
        new MockCacheManager(),
        new MockNutritionTargetRepository()
      );

      const profile: FamilyProfile = new FamilyProfile()
      profile.memberId = 'mem-002';
      profile.nickname = '妈妈';

      await facade.saveMember(profile);
      expect(facade.getAllMembersSync().length).assertEqual(1);

      await facade.deleteMember('mem-002');
      expect(facade.getAllMembersSync().length).assertEqual(0);
    });

    it('getHealthSignal_should_return_default_for_new_member', 0, () => {
      const familyRepo: MockFamilyRepository = new MockFamilyRepository()
      const facade: MemberFacade = new MemberFacade(
        familyRepo,
        new MockMemberManager(),
        new MockCacheManager(),
        new MockNutritionTargetRepository()
      );

      const signal = facade.getHealthSignal('mem-003');
      expect(signal !== undefined).assertTrue();
      expect(signal.memberId).assertEqual('mem-003');
    });

    it('getDailyBudgetSync_should_return_default_for_new_member', 0, () => {
      const familyRepo: MockFamilyRepository = new MockFamilyRepository()
      const facade: MemberFacade = new MemberFacade(
        familyRepo,
        new MockMemberManager(),
        new MockCacheManager(),
        new MockNutritionTargetRepository()
      );

      const budget = facade.getDailyBudgetSync('mem-004');
      expect(budget !== undefined).assertTrue();
      expect(budget.memberId).assertEqual('mem-004');
    });

    it('getAllMembersSync_should_return_empty_initially', 0, () => {
      const familyRepo: MockFamilyRepository = new MockFamilyRepository()
      const facade: MemberFacade = new MemberFacade(
        familyRepo,
        new MockMemberManager(),
        new MockCacheManager(),
        new MockNutritionTargetRepository()
      );

      const members = facade.getAllMembersSync();
      expect(members.length).assertEqual(0);
    });
  });
}
