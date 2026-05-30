import { FoodLabel } from './FoodLabel';

export class FoodInputResult {
  foodLabel: FoodLabel = new FoodLabel();
  recognizedText: string = '';
  hint: string = '';
  confidence: number = 0;
  requiresManualReview: boolean = false;
}
