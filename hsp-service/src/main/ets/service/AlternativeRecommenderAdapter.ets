import { AlternativeFood, FoodLabel, FamilyProfile, IAlternativeRecommender } from 'hsp_core';

export class AlternativeRecommenderAdapter implements IAlternativeRecommender {
  private delegate: IAlternativeRecommender | null = null;

  setDelegate(recommender: IAlternativeRecommender): void {
    this.delegate = recommender;
  }

  async recommendAlternatives(foodLabel: FoodLabel, members: FamilyProfile[], topN: number): Promise<AlternativeFood[]> {
    if (this.delegate !== null) {
      return this.delegate.recommendAlternatives(foodLabel, members, topN);
    }
    return [];
  }
}
