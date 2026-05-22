// SecuritySaveButton.ets
// 安全保存按钮封装 — 使用 HarmonyOS 6.1 SaveButton 安全组件
// 点击后系统临时授予 WRITE_MEDIA 权限，无需在 module.json5 声明
// 适用于保存图片、导出文件等场景

import { COLORS, RADIUS } from 'hsp_core';

@ComponentV2
export struct SecuritySaveButton {
  @Param label: string = '保存';
  @Event onSave: () => void = () => {};
  @Param isWorking: boolean = false;
  @Param buttonColor: string = COLORS.PRIMARY;

  build() {
    SaveButton({ icon: SaveIconStyle.FULL_FILLED, text: SaveDescription.SAVE })
      .width('100%')
      .height(44)
      .borderRadius(RADIUS.LG)
      .enabled(!this.isWorking)
      .onClick(() => { this.onSave() })
  }
}
