export class DietRecordInput {
  memberId: string = '';
  scenario: string = '';
  mealType: string = '';
  foodId: string = '';
  amount: number = 0;
  sodiumIntake: number = 0;
  sugarIntake: number = 0;
  calorieIntake: number = 0;
  fatIntake: number = 0;
  scannedAt: string = '';
}

export class IDietRecordProvider {
  getDietRecordsByDateRange(memberId: string, startDate: string, endDate: string): Promise<DietRecordInput[]> {
    return Promise.resolve([] as DietRecordInput[]);
  }
}
