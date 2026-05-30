// FoodTagFilter.ets
// 食品标签筛选组件 — 横向可滚动 Chip 样式标签，支持多选

import { COLORS, FONT_SIZE, FONT_WEIGHT, RADIUS, SPACING, SCORE_COLORS } from 'hsp_core';
import { ElderModeManager } from 'hsp_service';

export class FilterTag {
  key: string = '';
  label: ResourceStr = '';
  color: string = '';
  selected: boolean = false;
}

function buildNutriScoreTags(): FilterTag[] {
  const grades: [string, string, string][] = [
    ['nutri_a', 'A', SCORE_COLORS.GRADE_A],
    ['nutri_b', 'B', SCORE_COLORS.GRADE_B],
    ['nutri_c', 'C', SCORE_COLORS.GRADE_C],
    ['nutri_d', 'D', SCORE_COLORS.GRADE_D],
    ['nutri_e', 'E', SCORE_COLORS.GRADE_E]
  ];
  return grades.map((g: [string, string, string]) => {
    const tag = new FilterTag();
    tag.key = g[0];
    tag.label = g[1];
    tag.color = g[2];
    tag.selected = false;
    return tag;
  });
}

function buildNovaGroupTags(): FilterTag[] {
  const groups: [string, string, string][] = [
    ['nova_1', 'NOVA 1', SCORE_COLORS.NOVA_1],
    ['nova_2', 'NOVA 2', SCORE_COLORS.NOVA_2],
    ['nova_3', 'NOVA 3', SCORE_COLORS.NOVA_3],
    ['nova_4', 'NOVA 4', SCORE_COLORS.NOVA_4]
  ];
  return groups.map((g: [string, string, string]) => {
    const tag = new FilterTag();
    tag.key = g[0];
    tag.label = g[1];
    tag.color = g[2];
    tag.selected = false;
    return tag;
  });
}

function buildSpecialTags(): FilterTag[] {
  const specials: [string, ResourceStr, string][] = [
    ['low_sodium', $r('app.string.tag_low_sodium'), SCORE_COLORS.GRADE_A],
    ['low_sugar', $r('app.string.tag_low_sugar'), '#66BB6A'],
    ['high_protein', $r('app.string.tag_high_protein'), '#2196F3'],
    ['high_fiber', $r('app.string.tag_high_fiber'), '#009688'],
    ['organic', $r('app.string.tag_organic'), '#7B1FA2'],
    ['no_added_sugar', $r('app.string.tag_no_added_sugar'), '#43A047']
  ];
  return specials.map((s: [string, ResourceStr, string]) => {
    const tag = new FilterTag();
    tag.key = s[0];
    tag.label = s[1];
    tag.color = s[2];
    tag.selected = false;
    return tag;
  });
}

export function createAllFilterTags(): FilterTag[] {
  return [...buildNutriScoreTags(), ...buildNovaGroupTags(), ...buildSpecialTags()];
}

@ComponentV2
export struct FoodTagFilter {
  @Param tags: FilterTag[] = [];
  @Event onFilterChange?: (selectedTags: string[]) => void;
  private touchTarget: number = ElderModeManager.getInstance().getTouchTarget()

  private toggleTag(tag: FilterTag): void {
    tag.selected = !tag.selected;
    const selectedKeys: string[] = this.tags
      .filter((t: FilterTag) => t.selected)
      .map((t: FilterTag) => t.key);
    if (this.onFilterChange) {
      this.onFilterChange?.(selectedKeys);
    }
  }

  build() {
    Scroll() {
      Row({ space: SPACING.SM }) {
        ForEach(this.tags, (tag: FilterTag) => {
          Text(tag.label)
            .fontSize(FONT_SIZE.SMALL)
            .fontWeight(tag.selected ? FONT_WEIGHT.BOLD : FONT_WEIGHT.REGULAR)
            .fontColor(tag.selected ? COLORS.WHITE : tag.color)
            .backgroundColor(tag.selected ? tag.color : COLORS.BG_LIGHT)
            .borderRadius(RADIUS.SM)
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .responseRegion({ x: 0, y: 0, width: this.touchTarget, height: this.touchTarget })
            .borderWidth(1)
            .borderColor(tag.selected ? tag.color : COLORS.BORDER)
            .accessibilityText(tag.selected ? $r('app.string.tag_selected') : $r('app.string.tag_unselected'))
            .onClick(() => { this.toggleTag(tag) })
        }, (tag: FilterTag) => tag.key)
      }
      .padding({ left: SPACING.LG, right: SPACING.LG })
    }
    .scrollBar(BarState.Off)
    .width('100%')
    .height(this.touchTarget)
    .align(Alignment.Start)
  }
}
