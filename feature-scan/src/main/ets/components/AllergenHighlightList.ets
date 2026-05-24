// AllergenHighlightList.ets
// 配料表过敏原高亮展示 — 将配料中与过敏原匹配的项标红

import { COLORS, FONT_SIZE, FONT_WEIGHT } from 'hsp_core';
import { IngredientSemanticEngine } from '../engine/IngredientSemanticEngine';

@ComponentV2
export struct AllergenHighlightList {
  @Param ingredients: string[] = [];
  @Param allergenHints: string[] = [];
  @Param intolerances: string[] = [];

  private isAllergen(ingredient: string): boolean {
    for (const hint of this.allergenHints) {
      if (IngredientSemanticEngine.containsAllergen(ingredient, hint)) return true;
    }
    for (const intolerance of this.intolerances) {
      if (IngredientSemanticEngine.containsAllergen(ingredient, intolerance)) return true;
    }
    return false;
  }

  build() {
    if (this.ingredients.length > 0) {
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.ingredients, (item: string, idx: number) => {
          Text(item)
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(this.isAllergen(item) ? COLORS.ACCENT_RED_EF53 : COLORS.TEXT_SECONDARY)
            .fontWeight(this.isAllergen(item) ? FONT_WEIGHT.BOLD : FONT_WEIGHT.REGULAR)
            .backgroundColor(this.isAllergen(item) ? '#FFEBEE' : 'transparent')
            .borderRadius(4)
            .padding({ left: 4, right: 4, top: 2, bottom: 2 })
            .margin({ right: 4, bottom: 4 })
        }, (item: string, idx: number) => `${idx}`)
      }
      .width('100%')
      .accessibilityText(`配料表，共${this.ingredients.length}项，其中${this.ingredients.filter((i: string) => this.isAllergen(i)).length}项含过敏原`)
      .accessibilityLevel('yes')
    }
  }
}
