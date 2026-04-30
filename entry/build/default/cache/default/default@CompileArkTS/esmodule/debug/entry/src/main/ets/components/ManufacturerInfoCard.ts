if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface ManufacturerInfoCard_Params {
    food?: FoodNutrition;
    isExpanded?: boolean;
}
import type { FoodNutrition } from '../model/FoodAdapterTypes';
import { RADIUS, SPACING, FONT_SIZE, FONT_WEIGHT, ANIMATION } from "@bundle:com.familyfood.helper/entry/ets/constants/AppTheme";
import pasteboard from "@ohos:pasteboard";
import type { BusinessError } from "@ohos:base";
import type common from "@ohos:app.ability.common";
// ==================== 常量定义 ====================
/** 中性色 - 生产信息卡专用，与报告页主卡片四级颜色体系拉开距离 */
class NEUTRAL {
    static readonly CARD_BG: string = '#FAFAFA';
    static readonly CARD_BORDER: string = '#E8E8E8';
    static readonly ICON_COLOR: string = '#9E9E9E';
    static readonly LABEL_COLOR: string = '#757575';
    static readonly VALUE_COLOR: string = '#424242';
    static readonly HINT_COLOR: string = '#BDBDBD';
    static readonly DISCLAIMER_COLOR: string = '#9E9E9E';
    static readonly WARNING_COLOR: string = '#FF9800';
    static readonly BUTTON_BG: string = '#F0F0F0';
    static readonly BUTTON_TEXT: string = '#616161';
    static readonly SC_VALID_COLOR: string = '#388E3C';
    static readonly SC_INVALID_COLOR: string = '#E53935';
    static readonly SC_VALID_BG: string = '#E8F5E9';
    static readonly SC_INVALID_BG: string = '#FFEBEE';
}
/** SC编号正则：SC + 14位阿拉伯数字 */
const SC_NUMBER_PATTERN: RegExp = /^SC\d{14}$/;
/** 国家市场监督管理总局食品生产许可查询平台URL */
const SAMR_QUERY_URL: string = 'https://spaqjg.e-cqs.cn/spscxk/';
/** 默认空食品营养数据 */
const DEFAULT_FOOD_NUTRITION: FoodNutrition = {
    productName: '',
    brand: '',
    netWeight_g: 0,
    energy_kj: 0,
    protein_g: 0,
    fat_g: 0,
    saturatedFat_g: 0,
    transFat_g: 0,
    carbs_g: 0,
    sugar_g: 0,
    sodium_mg: 0,
    allergens: [],
    isSugarFree: false,
    isSucroseFree: false,
    sweeteners: [],
    manufacturer: '',
    entrustInfo: '',
    scNumber: '',
    dataCompleteness: ''
};
/** 食品营养数据结构中所有字段名列表（用于统计完整度） */
const NUTRITION_FIELDS: string[] = [
    'productName', 'brand', 'netWeight_g', 'energy_kj', 'protein_g',
    'fat_g', 'saturatedFat_g', 'transFat_g', 'carbs_g', 'sugar_g',
    'sodium_mg', 'manufacturer', 'scNumber'
];
export class ManufacturerInfoCard extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__food = new SynchedPropertyObjectOneWayPU(params.food, this, "food");
        this.__isExpanded = new ObservedPropertySimplePU(true, this, "isExpanded");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: ManufacturerInfoCard_Params) {
        if (params.food === undefined) {
            this.__food.set(DEFAULT_FOOD_NUTRITION);
        }
        if (params.isExpanded !== undefined) {
            this.isExpanded = params.isExpanded;
        }
    }
    updateStateVars(params: ManufacturerInfoCard_Params) {
        this.__food.reset(params.food);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__food.purgeDependencyOnElmtId(rmElmtId);
        this.__isExpanded.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__food.aboutToBeDeleted();
        this.__isExpanded.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    /** 食品营养数据 */
    private __food: SynchedPropertySimpleOneWayPU<FoodNutrition>;
    get food() {
        return this.__food.get();
    }
    set food(newValue: FoodNutrition) {
        this.__food.set(newValue);
    }
    /** 折叠状态 */
    private __isExpanded: ObservedPropertySimplePU<boolean>;
    get isExpanded() {
        return this.__isExpanded.get();
    }
    set isExpanded(newValue: boolean) {
        this.__isExpanded.set(newValue);
    }
    // ==================== 构建 ====================
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.transition(TransitionEffect.opacity(ANIMATION.DURATION_NORMAL));
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 卡片容器
            Column.create();
            // 卡片容器
            Column.width('100%');
            // 卡片容器
            Column.padding(SPACING.LG);
            // 卡片容器
            Column.backgroundColor(NEUTRAL.CARD_BG);
            // 卡片容器
            Column.borderRadius(RADIUS.MD);
            // 卡片容器
            Column.border({ width: 1, color: NEUTRAL.CARD_BORDER });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 顶部免责声明
            Text.create('以下信息来自包装标识识别，未经官方核验。');
            // 顶部免责声明
            Text.fontSize(FONT_SIZE.TINY);
            // 顶部免责声明
            Text.fontColor(NEUTRAL.DISCLAIMER_COLOR);
            // 顶部免责声明
            Text.width('100%');
            // 顶部免责声明
            Text.margin({ bottom: SPACING.SM });
        }, Text);
        // 顶部免责声明
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 标题行（可点击折叠）
            Row.create();
            // 标题行（可点击折叠）
            Row.width('100%');
            // 标题行（可点击折叠）
            Row.padding({ top: SPACING.XS, bottom: SPACING.XS });
            // 标题行（可点击折叠）
            Row.onClick(() => {
                this.isExpanded = !this.isExpanded;
            });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 图标
            Text.create('🏭');
            // 图标
            Text.fontSize(FONT_SIZE.BODY);
            // 图标
            Text.margin({ right: SPACING.XS });
        }, Text);
        // 图标
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('生产主体信息');
            Text.fontSize(FONT_SIZE.BODY_LG);
            Text.fontColor(NEUTRAL.VALUE_COLOR);
            Text.fontWeight(FONT_WEIGHT.MEDIUM);
            Text.layoutWeight(1);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 折叠/展开箭头
            Text.create(this.isExpanded ? '▲' : '▼');
            // 折叠/展开箭头
            Text.fontSize(FONT_SIZE.SMALL);
            // 折叠/展开箭头
            Text.fontColor(NEUTRAL.ICON_COLOR);
        }, Text);
        // 折叠/展开箭头
        Text.pop();
        // 标题行（可点击折叠）
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 折叠内容区域
            if (this.isExpanded) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.width('100%');
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // 分割线
                        Divider.create();
                        // 分割线
                        Divider.width('100%');
                        // 分割线
                        Divider.color(NEUTRAL.CARD_BORDER);
                        // 分割线
                        Divider.margin({ top: SPACING.SM, bottom: SPACING.SM });
                    }, Divider);
                    // ---- 生产商信息 ----
                    this.InfoRow.bind(this)('🏢', '生产商', this.manufacturerDisplay, this.hasManufacturer);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        If.create();
                        // ---- SC编号信息 ----
                        if (this.hasScNumber) {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.ScNumberRow.bind(this)();
                            });
                        }
                        // ---- 委托生产信息 ----
                        else {
                            this.ifElseBranchUpdateFunction(1, () => {
                            });
                        }
                    }, If);
                    If.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        If.create();
                        // ---- 委托生产信息 ----
                        if (this.hasEntrustInfo) {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.InfoRow.bind(this)('📋', '委托生产', this.food.entrustInfo, true);
                            });
                        }
                        // ---- 包装标识完整度 ----
                        else {
                            this.ifElseBranchUpdateFunction(1, () => {
                            });
                        }
                    }, If);
                    If.pop();
                    // ---- 包装标识完整度 ----
                    this.CompletenessRow.bind(this)();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // 底部免责声明
                        Divider.create();
                        // 底部免责声明
                        Divider.width('100%');
                        // 底部免责声明
                        Divider.color(NEUTRAL.CARD_BORDER);
                        // 底部免责声明
                        Divider.margin({ top: SPACING.SM, bottom: SPACING.SM });
                    }, Divider);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('查询结果以国家市场监督管理总局官方平台为准，本App仅提供信息展示与查询入口。');
                        Text.fontSize(FONT_SIZE.TINY);
                        Text.fontColor(NEUTRAL.DISCLAIMER_COLOR);
                        Text.width('100%');
                    }, Text);
                    Text.pop();
                    Column.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        // 卡片容器
        Column.pop();
        Column.pop();
    }
    // ==================== 子组件 ====================
    /**
     * 信息行（通用）
     * @param icon - 图标
     * @param label - 标签
     * @param value - 值
     * @param hasValue - 是否有值
     */
    InfoRow(icon: string, label: string, value: string, hasValue: boolean, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width('100%');
            Row.padding({ top: SPACING.XS, bottom: SPACING.XS });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 图标
            Text.create(icon);
            // 图标
            Text.fontSize(FONT_SIZE.BODY);
            // 图标
            Text.margin({ right: SPACING.SM });
        }, Text);
        // 图标
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 标签
            Text.create(label);
            // 标签
            Text.fontSize(FONT_SIZE.SMALL);
            // 标签
            Text.fontColor(NEUTRAL.LABEL_COLOR);
            // 标签
            Text.margin({ right: SPACING.SM });
        }, Text);
        // 标签
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 值
            Text.create(value);
            // 值
            Text.fontSize(FONT_SIZE.BODY);
            // 值
            Text.fontColor(hasValue ? NEUTRAL.VALUE_COLOR : NEUTRAL.HINT_COLOR);
            // 值
            Text.layoutWeight(1);
        }, Text);
        // 值
        Text.pop();
        Row.pop();
    }
    /**
     * SC编号行（含格式验证、复制、官方查询）
     */
    ScNumberRow(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width('100%');
            Row.padding({ top: SPACING.XS, bottom: SPACING.XS });
            Row.alignItems(VerticalAlign.Top);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 图标
            Text.create('🔖');
            // 图标
            Text.fontSize(FONT_SIZE.BODY);
            // 图标
            Text.margin({ right: SPACING.SM });
        }, Text);
        // 图标
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.layoutWeight(1);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 标签
            Text.create('SC编号');
            // 标签
            Text.fontSize(FONT_SIZE.SMALL);
            // 标签
            Text.fontColor(NEUTRAL.LABEL_COLOR);
            // 标签
            Text.width('100%');
        }, Text);
        // 标签
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // SC编号值 + 格式状态
            Row.create();
            // SC编号值 + 格式状态
            Row.width('100%');
            // SC编号值 + 格式状态
            Row.margin({ top: SPACING.XS });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.food.scNumber);
            Text.fontSize(FONT_SIZE.BODY);
            Text.fontColor(NEUTRAL.VALUE_COLOR);
            Text.fontWeight(FONT_WEIGHT.MEDIUM);
            Text.margin({ right: SPACING.XS });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 格式验证标签
            Text.create(this.scValidationInfo);
            // 格式验证标签
            Text.fontSize(FONT_SIZE.TINY);
            // 格式验证标签
            Text.fontColor(this.isScNumberValid ? NEUTRAL.SC_VALID_COLOR : NEUTRAL.SC_INVALID_COLOR);
            // 格式验证标签
            Text.backgroundColor(this.isScNumberValid ? NEUTRAL.SC_VALID_BG : NEUTRAL.SC_INVALID_BG);
            // 格式验证标签
            Text.padding({ left: SPACING.XS, right: SPACING.XS, top: SPACING.XS, bottom: SPACING.XS });
            // 格式验证标签
            Text.borderRadius(RADIUS.SM);
        }, Text);
        // 格式验证标签
        Text.pop();
        // SC编号值 + 格式状态
        Row.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 操作按钮组
            Row.create();
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 复制按钮
            Button.createWithChild();
            // 复制按钮
            Button.type(ButtonType.Capsule);
            // 复制按钮
            Button.height(28);
            // 复制按钮
            Button.backgroundColor(NEUTRAL.BUTTON_BG);
            // 复制按钮
            Button.padding({ left: SPACING.SM, right: SPACING.SM });
            // 复制按钮
            Button.margin({ right: SPACING.XS });
            // 复制按钮
            Button.onClick(() => {
                this.copyScNumber();
            });
        }, Button);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('复制');
            Text.fontSize(FONT_SIZE.TINY);
            Text.fontColor(NEUTRAL.BUTTON_TEXT);
        }, Text);
        Text.pop();
        // 复制按钮
        Button.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 官方查询按钮
            Button.createWithChild();
            // 官方查询按钮
            Button.type(ButtonType.Capsule);
            // 官方查询按钮
            Button.height(28);
            // 官方查询按钮
            Button.backgroundColor(NEUTRAL.BUTTON_BG);
            // 官方查询按钮
            Button.padding({ left: SPACING.SM, right: SPACING.SM });
            // 官方查询按钮
            Button.onClick(() => {
                this.openSamrQuery();
            });
        }, Button);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('官方查询');
            Text.fontSize(FONT_SIZE.TINY);
            Text.fontColor(NEUTRAL.BUTTON_TEXT);
        }, Text);
        Text.pop();
        // 官方查询按钮
        Button.pop();
        // 操作按钮组
        Row.pop();
        Row.pop();
    }
    /**
     * 包装标识完整度行
     */
    CompletenessRow(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width('100%');
            Row.padding({ top: SPACING.XS, bottom: SPACING.XS });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 图标
            Text.create('📊');
            // 图标
            Text.fontSize(FONT_SIZE.BODY);
            // 图标
            Text.margin({ right: SPACING.SM });
        }, Text);
        // 图标
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('包装标识完整度');
            Text.fontSize(FONT_SIZE.SMALL);
            Text.fontColor(NEUTRAL.LABEL_COLOR);
            Text.margin({ right: SPACING.SM });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(`已识别${this.identifiedCount}项，未识别${this.unidentifiedCount}项`);
            Text.fontSize(FONT_SIZE.BODY);
            Text.fontColor(NEUTRAL.VALUE_COLOR);
            Text.layoutWeight(1);
        }, Text);
        Text.pop();
        Row.pop();
    }
    // ==================== 交互方法 ====================
    /**
     * 复制SC编号到剪贴板
     */
    private copyScNumber(): void {
        if (!this.hasScNumber) {
            return;
        }
        try {
            const pasteboardData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.food.scNumber);
            const pasteboardObj = pasteboard.getSystemPasteboard();
            pasteboardObj.setData(pasteboardData, (err: BusinessError) => {
                if (err !== null) {
                    console.error('复制SC编号失败：', JSON.stringify(err));
                }
            });
        }
        catch (error) {
            console.error('复制SC编号异常：', JSON.stringify(error));
        }
    }
    /**
     * 打开国家市场监督管理总局食品生产许可查询平台
     */
    private openSamrQuery(): void {
        try {
            const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
            context.openLink(SAMR_QUERY_URL);
        }
        catch (error) {
            console.error('打开官方查询页面失败：', JSON.stringify(error));
        }
    }
    rerender() {
        this.updateDirtyElements();
    }
}
