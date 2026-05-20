// model/NutritionSnapshot.ets
import { NutritionPer100g } from './FoodLabel';

export class NutritionSnapshot {
  id: string = '';
  memberId: string = '';
  date: string = '';
  foodName: string = '';
  brand: string = '';
  nutrition: NutritionPer100g = new NutritionPer100g();
  nutriGrade: string = '';
  capturedAt: number = 0;
  memo: string = '';
  sodium_mg: number = 0;
  sugar_g: number = 0;
  calories: number = 0;
  fat_g: number = 0;

  get sodium(): number { return this.sodium_mg; }
  set sodium(v: number) { this.sodium_mg = v; }
  get sugar(): number { return this.sugar_g; }
  set sugar(v: number) { this.sugar_g = v; }
  get calorie(): number { return this.calories; }
  set calorie(v: number) { this.calories = v; }
  get fat(): number { return this.fat_g; }
  set fat(v: number) { this.fat_g = v; }
}
