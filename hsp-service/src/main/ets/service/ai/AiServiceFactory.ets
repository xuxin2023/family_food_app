import { IAiStateProvider } from '../IAiStateProvider';
import { AiNutritionistServiceImpl } from './AiNutritionistServiceImpl';
import { AiChatServiceImpl } from './AiChatServiceImpl';

export function createAiNutritionistService(provider: IAiStateProvider): AiNutritionistServiceImpl {
  return new AiNutritionistServiceImpl(provider);
}

export function createAiChatService(provider: IAiStateProvider): AiChatServiceImpl {
  return new AiChatServiceImpl(provider);
}