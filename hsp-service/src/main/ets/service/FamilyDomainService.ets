// FamilyDomainService.ets
// 家庭成员领域服务 - 封装家庭成员相关的业务逻辑
// 用途：从 AppState 中提取家庭成员管理职责，减轻上帝类负担
//
// V2: 统一缓存策略 — 不再维护独立缓存，由 AppState.CacheManager 统一管理
// 所有数据操作直接委托给 FamilyRepository，调用方负责缓存同步

import { FamilyProfile, createDefaultMembers } from 'hsp_core';
import { FamilyRepository } from '../repository/FamilyRepository';

const TAG = 'FamilyDomainService';

export class FamilyDomainService {
  private familyRepo: FamilyRepository;
  private memberInitLock: boolean = false;

  constructor(familyRepo: FamilyRepository) {
    this.familyRepo = familyRepo;
  }

  /** 从数据库获取所有成员（无缓存） */
  async getAllMembers(): Promise<FamilyProfile[]> {
    const members = await this.familyRepo.getAllMembers();
    if (members.length === 0 && !this.memberInitLock) {
      this.memberInitLock = true;
      try {
        const defaults = createDefaultMembers();
        for (const member of defaults) {
          await this.familyRepo.saveMember(member);
        }
        return await this.familyRepo.getAllMembers();
      } finally {
        this.memberInitLock = false;
      }
    }
    return members;
  }

  /** 保存家庭成员 */
  async saveMember(profile: FamilyProfile): Promise<void> {
    await this.familyRepo.saveMember(profile);
  }

  /** 删除家庭成员 */
  async deleteMember(memberId: string): Promise<void> {
    await this.familyRepo.deleteMember(memberId);
  }
}