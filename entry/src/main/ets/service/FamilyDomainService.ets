// FamilyDomainService.ets
// 家庭成员领域服务 - 封装家庭成员相关的业务逻辑
// 用途：从 AppState 中提取家庭成员管理职责，减轻上帝类负担

import { FamilyProfile, AgeGroup, HealthGoal, createDefaultMembers } from '../model/FamilyProfile';
import { FamilyRepository } from '../repository/FamilyRepository';

const TAG = 'FamilyDomainService';

export class FamilyDomainService {
  private familyRepo: FamilyRepository;
  private membersCache: FamilyProfile[] = [];
  private memberInitLock: boolean = false;

  constructor(familyRepo: FamilyRepository) {
    this.familyRepo = familyRepo;
  }

  /** 获取缓存中的成员列表（如无则从DB加载） */
  async getAllMembers(): Promise<FamilyProfile[]> {
    if (this.membersCache.length === 0) {
      this.membersCache = await this.familyRepo.getAllMembers();
      if (this.membersCache.length === 0 && !this.memberInitLock) {
        this.memberInitLock = true;
        try {
          this.membersCache = createDefaultMembers();
          for (const member of this.membersCache) {
            await this.familyRepo.saveMember(member);
          }
        } finally {
          this.memberInitLock = false;
        }
      }
    }
    return this.membersCache;
  }

  /** 刷新成员缓存 */
  async refreshCache(): Promise<FamilyProfile[]> {
    this.membersCache = await this.familyRepo.getAllMembers();
    return this.membersCache;
  }

  /** 获取缓存快照（不触发加载） */
  getCachedMembers(): FamilyProfile[] {
    return this.membersCache;
  }

  /** 保存家庭成员 */
  async saveMember(profile: FamilyProfile): Promise<void> {
    await this.familyRepo.saveMember(profile);
    const index = this.membersCache.findIndex(m => m.memberId === profile.memberId);
    if (index >= 0) {
      this.membersCache[index] = profile;
    } else {
      this.membersCache.push(profile);
    }
  }

  /** 删除家庭成员 */
  async deleteMember(memberId: string): Promise<void> {
    await this.familyRepo.deleteMember(memberId);
    this.membersCache = this.membersCache.filter(m => m.memberId !== memberId);
  }
}
