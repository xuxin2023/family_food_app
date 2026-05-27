import { AlternativeFood, FoodLabel, FamilyProfile, IAlternativeRecommender } from 'hsp_core';

export class AlternativeFoodRecommender implements IAlternativeRecommender {
  async recommend(_food: FoodLabel): Promise<AlternativeFood[]> {
    return [];
  }
  async recommendAlternatives(_foodLabel: FoodLabel, _members: FamilyProfile[], _topN: number): Promise<AlternativeFood[]> {
    return [];
  }
}
