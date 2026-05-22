import { FoodLabel, NutritionPer100g } from './FoodLabel';

export interface IOfflineFoodProvider {
  getAllEntries(): OfflineFoodEntry[];
  getByBarcode(barcode: string): OfflineFoodEntry | null;
}

export class OfflineFoodEntry {
  barcode: string = '';
  foodName: string = '';
  manufacturer: string = '';
  category: string = '';
  nutrition: NutritionPer100g = new NutritionPer100g();
  ingredients: string[] = [];
  allergenHints: string[] = [];
}
