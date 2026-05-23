// FamilyComparisonItem.ets
// 家庭对比结果项 — 用于 calculateFamilyComparison 返回值

import { FamilyProfile } from './FamilyProfile';
import { Recommendation } from './Recommendation';

export class FamilyComparisonItem {
  member: FamilyProfile = new FamilyProfile();
  recommendation: Recommendation = new Recommendation();
}
