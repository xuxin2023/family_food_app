import { COLORS } from 'hsp_core';

class IconDef {
  symbolName: string = '';
  fallback: string = '';
}

const ICON_MAP: Record<string, IconDef> = {
  'home': { symbolName: 'sys.symbol.ohos_home', fallback: '\u{1F3E0}' },
  'diary': { symbolName: 'sys.symbol.ohos_message', fallback: '\u{1F4D3}' },
  'ai': { symbolName: 'sys.symbol.ohos_emoji_symbol', fallback: '\u{1F916}' },
  'community': { symbolName: 'sys.symbol.ohos_user_group', fallback: '\u{1F465}' },
  'profile': { symbolName: 'sys.symbol.ohos_me', fallback: '\u{1F464}' },
  'back': { symbolName: 'sys.symbol.ohos_less', fallback: '\u2190' },
  'settings': { symbolName: 'sys.symbol.ohos_settings', fallback: '\u2699' },
  'camera': { symbolName: 'sys.symbol.ohos_camera', fallback: '\u{1F4F7}' },
  'plus': { symbolName: 'sys.symbol.ohos_add', fallback: '\u2795' },
  'search': { symbolName: 'sys.symbol.ohos_search', fallback: '\u{1F50D}' },
  'heart': { symbolName: 'sys.symbol.ohos_heart', fallback: '\u2764' },
  'check': { symbolName: 'sys.symbol.ohos_check_circle', fallback: '\u2705' },
  'warning': { symbolName: 'sys.symbol.ohos_notice', fallback: '\u26A0' },
  'close': { symbolName: 'sys.symbol.ohos_cross', fallback: '\u2716' },
  'share': { symbolName: 'sys.symbol.ohos_share', fallback: '\u{1F4E4}' },
  'mic': { symbolName: 'sys.symbol.ohos_microphone', fallback: '\u{1F3A4}' },
  'scan': { symbolName: 'sys.symbol.ohos_scan', fallback: '\u{1F4F7}' },
  'calendar': { symbolName: 'sys.symbol.ohos_calendar', fallback: '\u{1F4C5}' },
  'chart': { symbolName: 'sys.symbol.ohos_bar_chart', fallback: '\u{1F4CA}' },
  'list': { symbolName: 'sys.symbol.ohos_list', fallback: '\u{1F4CB}' },
  'edit': { symbolName: 'sys.symbol.ohos_pen', fallback: '\u270F' },
  'trash': { symbolName: 'sys.symbol.ohos_trash', fallback: '\u{1F5D1}' },
  'refresh': { symbolName: 'sys.symbol.ohos_refresh', fallback: '\u{1F504}' },
  'chevron_right': { symbolName: 'sys.symbol.ohos_arrow_right', fallback: '\u203A' },
  'chevron_down': { symbolName: 'sys.symbol.ohos_down', fallback: '\u2304' },
  'info': { symbolName: 'sys.symbol.ohos_info', fallback: '\u2139' },
  'star': { symbolName: 'sys.symbol.ohos_star', fallback: '\u2B50' },
  'clock': { symbolName: 'sys.symbol.ohos_clock', fallback: '\u{1F551}' },
  'cart': { symbolName: 'sys.symbol.ohos_shopping_cart', fallback: '\u{1F6D2}' },
  'fork_knife': { symbolName: 'sys.symbol.ohos_eat', fallback: '\u{1F37D}' },
  'drop': { symbolName: 'sys.symbol.ohos_water', fallback: '\u{1F4A7}' },
  'flame': { symbolName: 'sys.symbol.ohos_fire', fallback: '\u{1F525}' },
  'shield': { symbolName: 'sys.symbol.ohos_shield', fallback: '\u{1F6E1}' },
  'doc': { symbolName: 'sys.symbol.ohos_doc', fallback: '\u{1F4C4}' },
  'bell': { symbolName: 'sys.symbol.ohos_ring', fallback: '\u{1F514}' },
  'location': { symbolName: 'sys.symbol.ohos_location', fallback: '\u{1F4CD}' },
  'lock': { symbolName: 'sys.symbol.ohos_lock', fallback: '\u{1F512}' },
  'eye': { symbolName: 'sys.symbol.ohos_view', fallback: '\u{1F441}' },
  'thumbsup': { symbolName: 'sys.symbol.ohos_hand', fallback: '\u{1F44D}' },
  'chat': { symbolName: 'sys.symbol.ohos_message', fallback: '\u{1F4AC}' },
  'leaf': { symbolName: 'sys.symbol.ohos_leaf', fallback: '\u{1F33F}' },
  'photo': { symbolName: 'sys.symbol.ohos_image', fallback: '\u{1F5FC}' },
  'report': { symbolName: 'sys.symbol.ohos_doc', fallback: '\u{1F4DD}' },
  'target': { symbolName: 'sys.symbol.ohos_star', fallback: '\u{1F3AF}' },
  'book': { symbolName: 'sys.symbol.ohos_book', fallback: '\u{1F4DA}' },
  'family': { symbolName: 'sys.symbol.ohos_user_group', fallback: '\u{1F46A}' },
  'cloud': { symbolName: 'sys.symbol.ohos_cloud', fallback: '\u2601' },
  'feedback': { symbolName: 'sys.symbol.ohos_message', fallback: '\u{1F4AC}' },
  'fitness': { symbolName: 'sys.symbol.ohos_fire', fallback: '\u{1F3CB}' },
  'device': { symbolName: 'sys.symbol.ohos_phone', fallback: '\u{1F4F1}' },
  'save': { symbolName: 'sys.symbol.ohos_save', fallback: '\u{1F4BE}' },
} as Record<string, IconDef>;

let _useSymbol: boolean = false;

export function setSymbolAvailable(available: boolean): void {
  _useSymbol = available;
}

export function isSymbolAvailable(): boolean {
  return _useSymbol;
}

export function getIconFallback(name: string): string {
  const def: IconDef | undefined = ICON_MAP[name];
  if (def) {
    return def.fallback;
  }
  return '?';
}

export function getIconSymbolName(name: string): string {
  const def: IconDef | undefined = ICON_MAP[name];
  if (def) {
    return def.symbolName;
  }
  return '';
}

@ComponentV2
export struct AppIcon {
  @Param name: string = 'home';
  @Param iconSize: number = 24;
  @Param color: ResourceColor = COLORS.TEXT_PRIMARY;
  @Param useSymbol: boolean = true;
  @Param effectStrategy: SymbolEffectStrategy = SymbolEffectStrategy.NONE;
  @Param renderingStrategy: SymbolRenderingStrategy = SymbolRenderingStrategy.SINGLE;

  build() {
    if (this.useSymbol && getIconSymbolName(this.name).length > 0) {
      SymbolGlyph($r(getIconSymbolName(this.name)))
        .fontSize(this.iconSize)
        .fontColor([this.color])
        .fontWeight(FontWeight.Normal)
        .renderingStrategy(this.renderingStrategy)
        .effectStrategy(this.effectStrategy)
    } else {
      Text(getIconFallback(this.name))
        .fontSize(this.iconSize)
        .fontColor(this.color as string)
        .textAlign(TextAlign.Center)
    }
  }
}
