export interface DietRecordInput {
  memberId: string;
  scenario: string;
  mealType: string;
  foodId: string;
  amount: number;
  sodiumIntake: number;
  sugarIntake: number;
  calorieIntake: number;
  fatIntake: number;
  scannedAt: string;
}

export interface IDietRecordProvider {
  getDietRecordsByDateRange(memberId: string, startDate: string, endDate: string): Promise<DietRecordInput[]>;
}
