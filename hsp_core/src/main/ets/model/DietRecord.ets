import { MealScenario } from './MealBalance';

export class DietRecord {
  id: number = 0;
  memberId: string = '';
  date: string = '';
  scenario: MealScenario | string = MealScenario.OTHER;
  mealType: string = 'breakfast';
  foodId: string = '';
  amountG: number = 0;
  sodiumIntake: number = 0;
  sugarIntake: number = 0;
  calorieIntake: number = 0;
  fatIntake: number = 0;
  recordedAt: number = 0;
}
