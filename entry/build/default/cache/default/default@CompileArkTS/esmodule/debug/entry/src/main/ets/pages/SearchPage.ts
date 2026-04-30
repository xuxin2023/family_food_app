if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface SearchPage_Params {
    searchKeyword?: string;
    searchResults?: SearchResultItem[];
    recentSearches?: string[];
    frequentBrands?: string[];
    isSearching?: boolean;
    hasSearched?: boolean;
    showClearButton?: boolean;
    appState?: AppState;
}
import router from "@ohos:router";
import promptAction from "@ohos:promptAction";
import { AppState } from "@bundle:com.familyfood.helper/entry/ets/AppState";
import type { FoodLabel } from '../model/FoodLabel';
import { NutriScoreEngine } from "@bundle:com.familyfood.helper/entry/ets/engine/NutriScoreEngine";
import { ShanghaiGradeEngine } from "@bundle:com.familyfood.helper/entry/ets/engine/ShanghaiGradeEngine";
import { SmartChoiceEngine } from "@bundle:com.familyfood.helper/entry/ets/engine/SmartChoiceEngine";
import type { FoodNutrition } from '../model/FoodAdapterTypes';
import { COLORS, RADIUS, SPACING, FONT_SIZE, FONT_WEIGHT } from "@bundle:com.familyfood.helper/entry/ets/constants/AppTheme";
// 搜索结果展示项
class SearchResultItem {
    foodId: string = '';
    foodName: string = '';
    brand: string = '';
    barcode: string = '';
    nutriScore: number = 0;
    nutriGrade: string = '';
    nutriColor: string = '';
    shanghaiGrade: string = ''; // 上海营养选择分级：A/B/C/D，非饮料类为空
    smartChoiceEligible: boolean = false; // 智慧选择是否达标
    tags: string[] = []; // 适配标签，如 "控糖友好" "高钠慎选"
    identifiedAt: number = 0;
}
class SearchPage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__searchKeyword = new ObservedPropertySimplePU('', this, "searchKeyword");
        this.__searchResults = new ObservedPropertyObjectPU([], this, "searchResults");
        this.__recentSearches = new ObservedPropertyObjectPU([], this, "recentSearches");
        this.__frequentBrands = new ObservedPropertyObjectPU([], this, "frequentBrands");
        this.__isSearching = new ObservedPropertySimplePU(false, this, "isSearching");
        this.__hasSearched = new ObservedPropertySimplePU(false, this, "hasSearched");
        this.__showClearButton = new ObservedPropertySimplePU(false, this, "showClearButton");
        this.appState = AppState.getInstance();
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: SearchPage_Params) {
        if (params.searchKeyword !== undefined) {
            this.searchKeyword = params.searchKeyword;
        }
        if (params.searchResults !== undefined) {
            this.searchResults = params.searchResults;
        }
        if (params.recentSearches !== undefined) {
            this.recentSearches = params.recentSearches;
        }
        if (params.frequentBrands !== undefined) {
            this.frequentBrands = params.frequentBrands;
        }
        if (params.isSearching !== undefined) {
            this.isSearching = params.isSearching;
        }
        if (params.hasSearched !== undefined) {
            this.hasSearched = params.hasSearched;
        }
        if (params.showClearButton !== undefined) {
            this.showClearButton = params.showClearButton;
        }
        if (params.appState !== undefined) {
            this.appState = params.appState;
        }
    }
    updateStateVars(params: SearchPage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__searchKeyword.purgeDependencyOnElmtId(rmElmtId);
        this.__searchResults.purgeDependencyOnElmtId(rmElmtId);
        this.__recentSearches.purgeDependencyOnElmtId(rmElmtId);
        this.__frequentBrands.purgeDependencyOnElmtId(rmElmtId);
        this.__isSearching.purgeDependencyOnElmtId(rmElmtId);
        this.__hasSearched.purgeDependencyOnElmtId(rmElmtId);
        this.__showClearButton.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__searchKeyword.aboutToBeDeleted();
        this.__searchResults.aboutToBeDeleted();
        this.__recentSearches.aboutToBeDeleted();
        this.__frequentBrands.aboutToBeDeleted();
        this.__isSearching.aboutToBeDeleted();
        this.__hasSearched.aboutToBeDeleted();
        this.__showClearButton.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __searchKeyword: ObservedPropertySimplePU<string>;
    get searchKeyword() {
        return this.__searchKeyword.get();
    }
    set searchKeyword(newValue: string) {
        this.__searchKeyword.set(newValue);
    }
    private __searchResults: ObservedPropertyObjectPU<SearchResultItem[]>;
    get searchResults() {
        return this.__searchResults.get();
    }
    set searchResults(newValue: SearchResultItem[]) {
        this.__searchResults.set(newValue);
    }
    private __recentSearches: ObservedPropertyObjectPU<string[]>;
    get recentSearches() {
        return this.__recentSearches.get();
    }
    set recentSearches(newValue: string[]) {
        this.__recentSearches.set(newValue);
    }
    private __frequentBrands: ObservedPropertyObjectPU<string[]>;
    get frequentBrands() {
        return this.__frequentBrands.get();
    }
    set frequentBrands(newValue: string[]) {
        this.__frequentBrands.set(newValue);
    }
    private __isSearching: ObservedPropertySimplePU<boolean>;
    get isSearching() {
        return this.__isSearching.get();
    }
    set isSearching(newValue: boolean) {
        this.__isSearching.set(newValue);
    }
    private __hasSearched: ObservedPropertySimplePU<boolean>;
    get hasSearched() {
        return this.__hasSearched.get();
    }
    set hasSearched(newValue: boolean) {
        this.__hasSearched.set(newValue);
    }
    private __showClearButton: ObservedPropertySimplePU<boolean>;
    get showClearButton() {
        return this.__showClearButton.get();
    }
    set showClearButton(newValue: boolean) {
        this.__showClearButton.set(newValue);
    }
    private appState: AppState;
    async aboutToAppear() {
        this.recentSearches = this.appState.getRecentSearches();
        this.frequentBrands = await this.appState.getFrequentBrands(5);
    }
    // 执行搜索
    private async doSearch(keyword: string) {
        const trimmed = keyword.trim();
        if (trimmed.length === 0)
            return;
        this.isSearching = true;
        this.hasSearched = true;
        this.searchKeyword = trimmed;
        // 保存到最近搜索
        this.appState.saveRecentSearch(trimmed);
        this.recentSearches = this.appState.getRecentSearches();
        // 从数据库搜索
        const labels = await this.appState.searchFoodLabels(trimmed);
        this.searchResults = labels.map(label => this.toSearchResult(label));
        this.isSearching = false;
    }
    // 将 FoodLabel 转换为搜索结果项
    private toSearchResult(label: FoodLabel): SearchResultItem {
        const item = new SearchResultItem();
        item.foodId = label.foodId;
        item.foodName = label.foodName;
        item.brand = label.manufacturer;
        item.barcode = label.barcode;
        item.identifiedAt = label.identifiedAt;
        // 计算 Nutri-Score
        const nutrition = this.foodLabelToNutrition(label);
        const nutriResult = NutriScoreEngine.calculateFromFoodNutrition(nutrition);
        item.nutriScore = nutriResult.score;
        item.nutriGrade = nutriResult.gradeLabel;
        item.nutriColor = nutriResult.gradeColor;
        // 计算上海营养选择分级（仅饮料类）
        const shanghaiResult = ShanghaiGradeEngine.calculateShanghaiGrade(nutrition);
        if (shanghaiResult.isApplicable) {
            item.shanghaiGrade = shanghaiResult.grade;
        }
        // 计算智慧选择标准
        const smartResult = SmartChoiceEngine.checkSmartChoice(nutrition);
        item.smartChoiceEligible = smartResult.isApplicable && smartResult.eligible;
        // 生成适配标签
        const tags: string[] = [];
        if (label.isHighSodium()) {
            tags.push('高钠慎选');
        }
        if (label.isHighSugar()) {
            tags.push('高糖注意');
        }
        if (label.isHighFat()) {
            tags.push('高脂留意');
        }
        if (label.isHighCalorie()) {
            tags.push('热量密集');
        }
        if (!label.isHighSodium() && !label.isHighSugar() && !label.isHighFat() && !label.isHighCalorie()) {
            tags.push('控糖友好');
        }
        item.tags = tags;
        return item;
    }
    // 将 FoodLabel 转换为 FoodNutrition
    private foodLabelToNutrition(label: FoodLabel): FoodNutrition {
        return {
            productName: label.foodName,
            brand: label.manufacturer,
            netWeight_g: 100,
            energy_kj: Math.round(label.nutrition.calories * 4.184),
            protein_g: label.nutrition.protein,
            fat_g: label.nutrition.fat,
            saturatedFat_g: label.nutrition.saturatedFat,
            transFat_g: 0,
            carbs_g: label.nutrition.carbohydrate,
            sugar_g: label.nutrition.sugar,
            sodium_mg: label.nutrition.sodium,
            allergens: label.allergenHints,
            isSugarFree: label.nutrition.sugar <= 0.5,
            isSucroseFree: false,
            sweeteners: [],
            manufacturer: label.manufacturer,
            entrustInfo: label.principal,
            scNumber: label.scNumber,
            dataCompleteness: label.hasManufacturer() ? 'complete' : 'partial'
        };
    }
    // 检查文本是否包含关键词（用于高亮判断）
    private containsKeyword(text: string, keyword: string): boolean {
        return text.toLowerCase().includes(keyword.toLowerCase());
    }
    // 渲染高亮文本
    HighlightedText(text: string, keyword: string, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (keyword.length === 0 || !this.containsKeyword(text, keyword)) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(text);
                        Text.fontSize(FONT_SIZE.BODY);
                        Text.fontColor(COLORS.TEXT_PRIMARY);
                    }, Text);
                    Text.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create();
                    }, Text);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Span.create(this.getTextBeforeKeyword(text, keyword));
                        Span.fontSize(FONT_SIZE.BODY);
                        Span.fontColor(COLORS.TEXT_PRIMARY);
                    }, Span);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Span.create(keyword);
                        Span.fontSize(FONT_SIZE.BODY);
                        Span.fontColor(COLORS.PRIMARY_DARK);
                        Span.fontWeight(FONT_WEIGHT.BOLD);
                    }, Span);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Span.create(this.getTextAfterKeyword(text, keyword));
                        Span.fontSize(FONT_SIZE.BODY);
                        Span.fontColor(COLORS.TEXT_PRIMARY);
                    }, Span);
                    Text.pop();
                });
            }
        }, If);
        If.pop();
    }
    private getTextBeforeKeyword(text: string, keyword: string): string {
        const idx = text.toLowerCase().indexOf(keyword.toLowerCase());
        return idx > 0 ? text.substring(0, idx) : '';
    }
    private getTextAfterKeyword(text: string, keyword: string): string {
        const idx = text.toLowerCase().indexOf(keyword.toLowerCase());
        return idx >= 0 ? text.substring(idx + keyword.length) : text;
    }
    // 清除搜索
    private clearSearch() {
        this.searchKeyword = '';
        this.searchResults = [];
        this.hasSearched = false;
    }
    // 点击最近搜索
    private onRecentSearchTap(keyword: string) {
        this.searchKeyword = keyword;
        this.doSearch(keyword);
    }
    // 点击搜索结果进入报告页
    private navigateToReport(foodId: string) {
        router.pushUrl({
            url: 'pages/ReportPage',
            params: { foodId: foodId }
        });
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor(COLORS.BG_PAGE);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // ===== 顶部搜索栏 =====
            Row.create();
            // ===== 顶部搜索栏 =====
            Row.width('100%');
            // ===== 顶部搜索栏 =====
            Row.padding({ top: SPACING.MD, bottom: SPACING.MD, right: SPACING.MD });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('←');
            Text.fontSize(FONT_SIZE.LARGE);
            Text.fontColor(COLORS.PRIMARY);
            Text.onClick(() => { router.back(); });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Search.create({ placeholder: '搜索商品名、品牌或条码...' });
            Search.width('80%');
            Search.height(40);
            Search.backgroundColor(COLORS.BG_CARD);
            Search.borderRadius(RADIUS.FULL);
            Search.placeholderColor(COLORS.TEXT_HINT);
            Search.placeholderFont({ size: FONT_SIZE.BODY });
            Search.onSubmit((value: string) => {
                this.doSearch(value);
            });
            Search.onChange((value: string) => {
                this.searchKeyword = value;
                this.showClearButton = value.length > 0;
            });
            Search.margin({ left: SPACING.MD, right: SPACING.SM });
        }, Search);
        Search.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.showClearButton) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('取消');
                        Text.fontSize(FONT_SIZE.BODY);
                        Text.fontColor(COLORS.PRIMARY);
                        Text.onClick(() => { this.clearSearch(); });
                    }, Text);
                    Text.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        // ===== 顶部搜索栏 =====
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // ===== 搜索结果 / 初始状态 =====
            if (this.isSearching) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.width('100%');
                        Column.layoutWeight(1);
                        Column.justifyContent(FlexAlign.Center);
                        Column.alignItems(HorizontalAlign.Center);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('🔍 搜索中...');
                        Text.fontSize(FONT_SIZE.BODY);
                        Text.fontColor(COLORS.TEXT_HINT);
                    }, Text);
                    Text.pop();
                    Column.pop();
                });
            }
            else if (this.hasSearched) {
                this.ifElseBranchUpdateFunction(1, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        If.create();
                        // 搜索结果
                        if (this.searchResults.length === 0) {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Column.create();
                                    Column.width('100%');
                                    Column.layoutWeight(1);
                                    Column.justifyContent(FlexAlign.Center);
                                    Column.alignItems(HorizontalAlign.Center);
                                }, Column);
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create('😕 未找到相关商品');
                                    Text.fontSize(FONT_SIZE.SUBTITLE);
                                    Text.fontColor(COLORS.TEXT_PRIMARY);
                                    Text.margin({ bottom: SPACING.SM });
                                }, Text);
                                Text.pop();
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create('试试其他关键词，或扫描食品标签添加');
                                    Text.fontSize(FONT_SIZE.SMALL);
                                    Text.fontColor(COLORS.TEXT_HINT);
                                }, Text);
                                Text.pop();
                                Column.pop();
                            });
                        }
                        else {
                            this.ifElseBranchUpdateFunction(1, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create(`找到 ${this.searchResults.length} 个结果`);
                                    Text.fontSize(FONT_SIZE.SMALL);
                                    Text.fontColor(COLORS.TEXT_HINT);
                                    Text.width('92%');
                                    Text.margin({ bottom: SPACING.SM });
                                }, Text);
                                Text.pop();
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    List.create();
                                    List.width('100%');
                                    List.layoutWeight(1);
                                    List.padding({ left: SPACING.MD, right: SPACING.MD });
                                }, List);
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    ForEach.create();
                                    const forEachItemGenFunction = _item => {
                                        const item = _item;
                                        {
                                            const itemCreation = (elmtId, isInitialRender) => {
                                                ViewStackProcessor.StartGetAccessRecordingFor(elmtId);
                                                ListItem.create(deepRenderFunction, true);
                                                if (!isInitialRender) {
                                                    ListItem.pop();
                                                }
                                                ViewStackProcessor.StopGetAccessRecording();
                                            };
                                            const itemCreation2 = (elmtId, isInitialRender) => {
                                                ListItem.create(deepRenderFunction, true);
                                            };
                                            const deepRenderFunction = (elmtId, isInitialRender) => {
                                                itemCreation(elmtId, isInitialRender);
                                                this.SearchResultCard.bind(this)(item);
                                                ListItem.pop();
                                            };
                                            this.observeComponentCreation2(itemCreation2, ListItem);
                                            ListItem.pop();
                                        }
                                    };
                                    this.forEachUpdateFunction(elmtId, this.searchResults, forEachItemGenFunction, (item: SearchResultItem) => item.foodId, false, false);
                                }, ForEach);
                                ForEach.pop();
                                List.pop();
                            });
                        }
                    }, If);
                    If.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(2, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // 初始状态：最近搜索 + 常搜品牌
                        Scroll.create();
                        // 初始状态：最近搜索 + 常搜品牌
                        Scroll.layoutWeight(1);
                    }, Scroll);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.width('100%');
                        Column.alignItems(HorizontalAlign.Center);
                        Column.margin({ top: SPACING.LG });
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        If.create();
                        // 最近搜索
                        if (this.recentSearches.length > 0) {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Column.create();
                                    Column.width('92%');
                                    Column.alignItems(HorizontalAlign.Start);
                                    Column.margin({ bottom: SPACING.XL });
                                }, Column);
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Row.create();
                                    Row.width('100%');
                                    Row.margin({ bottom: SPACING.SM });
                                }, Row);
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create('🕐 最近搜索');
                                    Text.fontSize(FONT_SIZE.SUBTITLE);
                                    Text.fontWeight(FONT_WEIGHT.BOLD);
                                    Text.fontColor(COLORS.TEXT_PRIMARY);
                                }, Text);
                                Text.pop();
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Blank.create();
                                }, Blank);
                                Blank.pop();
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create('清空');
                                    Text.fontSize(FONT_SIZE.SMALL);
                                    Text.fontColor(COLORS.TEXT_HINT);
                                    Text.onClick(() => {
                                        this.recentSearches = [];
                                        promptAction.showToast({ message: '已清空搜索历史' });
                                    });
                                }, Text);
                                Text.pop();
                                Row.pop();
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    // 搜索关键词标签（使用Flex换行）
                                    Flex.create({
                                        direction: FlexDirection.Row,
                                        wrap: FlexWrap.Wrap,
                                        justifyContent: FlexAlign.Start
                                    });
                                    // 搜索关键词标签（使用Flex换行）
                                    Flex.width('100%');
                                }, Flex);
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    ForEach.create();
                                    const forEachItemGenFunction = _item => {
                                        const keyword = _item;
                                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                                            Text.create(keyword);
                                            Text.fontSize(FONT_SIZE.SMALL);
                                            Text.fontColor(COLORS.TEXT_PRIMARY);
                                            Text.padding({ left: SPACING.MD, right: SPACING.MD, top: SPACING.SM, bottom: SPACING.SM });
                                            Text.backgroundColor(COLORS.BG_CARD);
                                            Text.borderRadius(RADIUS.FULL);
                                            Text.margin({ right: SPACING.SM, bottom: SPACING.SM });
                                            Text.onClick(() => { this.onRecentSearchTap(keyword); });
                                        }, Text);
                                        Text.pop();
                                    };
                                    this.forEachUpdateFunction(elmtId, this.recentSearches, forEachItemGenFunction, (keyword: string) => keyword, false, false);
                                }, ForEach);
                                ForEach.pop();
                                // 搜索关键词标签（使用Flex换行）
                                Flex.pop();
                                Column.pop();
                            });
                        }
                        // 常搜品牌
                        else {
                            this.ifElseBranchUpdateFunction(1, () => {
                            });
                        }
                    }, If);
                    If.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        If.create();
                        // 常搜品牌
                        if (this.frequentBrands.length > 0) {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Column.create();
                                    Column.width('92%');
                                    Column.alignItems(HorizontalAlign.Start);
                                    Column.margin({ bottom: SPACING.XL });
                                }, Column);
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Row.create();
                                    Row.width('100%');
                                    Row.margin({ bottom: SPACING.SM });
                                }, Row);
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create('🏷️ 常搜品牌');
                                    Text.fontSize(FONT_SIZE.SUBTITLE);
                                    Text.fontWeight(FONT_WEIGHT.BOLD);
                                    Text.fontColor(COLORS.TEXT_PRIMARY);
                                }, Text);
                                Text.pop();
                                Row.pop();
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Flex.create({
                                        direction: FlexDirection.Row,
                                        wrap: FlexWrap.Wrap,
                                        justifyContent: FlexAlign.Start
                                    });
                                    Flex.width('100%');
                                }, Flex);
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    ForEach.create();
                                    const forEachItemGenFunction = _item => {
                                        const brand = _item;
                                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                                            Text.create(brand);
                                            Text.fontSize(FONT_SIZE.SMALL);
                                            Text.fontColor(COLORS.PRIMARY_DARK);
                                            Text.padding({ left: SPACING.MD, right: SPACING.MD, top: SPACING.SM, bottom: SPACING.SM });
                                            Text.backgroundColor(COLORS.PRIMARY_LIGHT);
                                            Text.borderRadius(RADIUS.FULL);
                                            Text.margin({ right: SPACING.SM, bottom: SPACING.SM });
                                            Text.onClick(() => { this.onRecentSearchTap(brand); });
                                        }, Text);
                                        Text.pop();
                                    };
                                    this.forEachUpdateFunction(elmtId, this.frequentBrands, forEachItemGenFunction, (brand: string) => brand, false, false);
                                }, ForEach);
                                ForEach.pop();
                                Flex.pop();
                                Column.pop();
                            });
                        }
                        // 引导提示
                        else {
                            this.ifElseBranchUpdateFunction(1, () => {
                            });
                        }
                    }, If);
                    If.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // 引导提示
                        Column.create();
                        // 引导提示
                        Column.width('100%');
                        // 引导提示
                        Column.alignItems(HorizontalAlign.Center);
                        // 引导提示
                        Column.margin({ top: SPACING.XXXL });
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('🔍');
                        Text.fontSize(FONT_SIZE.HUGE);
                        Text.margin({ bottom: SPACING.MD });
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('搜索已扫描过的食品');
                        Text.fontSize(FONT_SIZE.BODY);
                        Text.fontColor(COLORS.TEXT_HINT);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('输入商品名、品牌名或条码，快速查看适配报告');
                        Text.fontSize(FONT_SIZE.SMALL);
                        Text.fontColor(COLORS.TEXT_HINT);
                        Text.margin({ top: SPACING.XS });
                    }, Text);
                    Text.pop();
                    // 引导提示
                    Column.pop();
                    Column.pop();
                    // 初始状态：最近搜索 + 常搜品牌
                    Scroll.pop();
                });
            }
        }, If);
        If.pop();
        Column.pop();
    }
    // ===== 搜索结果卡片 =====
    SearchResultCard(item: SearchResultItem, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.padding(SPACING.MD);
            Column.backgroundColor(COLORS.BG_CARD);
            Column.borderRadius(RADIUS.LG);
            Column.margin({ bottom: SPACING.SM });
            Column.shadow({
                radius: 4,
                color: COLORS.SHADOW_LIGHT,
                offsetX: 0,
                offsetY: 1
            });
            Column.onClick(() => { this.navigateToReport(item.foodId); });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width('100%');
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 左侧：商品信息
            Column.create();
            // 左侧：商品信息
            Column.layoutWeight(1);
            // 左侧：商品信息
            Column.alignItems(HorizontalAlign.Start);
        }, Column);
        // 商品名（高亮关键词）
        this.HighlightedText.bind(this)(item.foodName, this.searchKeyword);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 品牌
            if (item.brand.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(item.brand);
                        Text.fontSize(FONT_SIZE.TINY);
                        Text.fontColor(COLORS.TEXT_HINT);
                        Text.margin({ top: SPACING.XS });
                    }, Text);
                    Text.pop();
                });
            }
            // 条码
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 条码
            if (item.barcode.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(`条码: ${item.barcode}`);
                        Text.fontSize(FONT_SIZE.TINY);
                        Text.fontColor(COLORS.TEXT_HINT);
                        Text.margin({ top: 2 });
                    }, Text);
                    Text.pop();
                });
            }
            // 适配标签
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 适配标签
            if (item.tags.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.margin({ top: SPACING.XS });
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = _item => {
                            const tag = _item;
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create(tag);
                                Text.fontSize(FONT_SIZE.TINY);
                                Text.fontColor(COLORS.TEXT_WHITE);
                                Text.padding({ left: SPACING.SM, right: SPACING.SM, top: 2, bottom: 2 });
                                Text.borderRadius(RADIUS.FULL);
                                Text.backgroundColor(this.getTagColor(tag));
                                Text.margin({ right: SPACING.XS });
                            }, Text);
                            Text.pop();
                        };
                        this.forEachUpdateFunction(elmtId, item.tags, forEachItemGenFunction, (tag: string) => tag, false, false);
                    }, ForEach);
                    ForEach.pop();
                    Row.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        // 左侧：商品信息
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 右侧：Nutri-Score 等级徽章 + 国内分级徽章
            Column.create();
            // 右侧：Nutri-Score 等级徽章 + 国内分级徽章
            Column.alignItems(HorizontalAlign.Center);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // Nutri-Score 徽章
            Column.create();
            // Nutri-Score 徽章
            Column.width(52);
            // Nutri-Score 徽章
            Column.height(52);
            // Nutri-Score 徽章
            Column.borderRadius(RADIUS.MD);
            // Nutri-Score 徽章
            Column.backgroundColor(item.nutriColor);
            // Nutri-Score 徽章
            Column.justifyContent(FlexAlign.Center);
            // Nutri-Score 徽章
            Column.alignItems(HorizontalAlign.Center);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(item.nutriGrade.charAt(0));
            Text.fontSize(FONT_SIZE.TITLE_LG);
            Text.fontWeight(FONT_WEIGHT.BOLD);
            Text.fontColor(COLORS.TEXT_WHITE);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(`${item.nutriScore}分`);
            Text.fontSize(FONT_SIZE.TINY);
            Text.fontColor(COLORS.TEXT_WHITE);
            Text.margin({ top: 2 });
        }, Text);
        Text.pop();
        // Nutri-Score 徽章
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 上海营养选择分级徽章（仅饮料类）
            if (item.shanghaiGrade.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(`沪${item.shanghaiGrade}`);
                        Text.fontSize(FONT_SIZE.TINY);
                        Text.fontColor(COLORS.TEXT_WHITE);
                        Text.padding({ left: SPACING.XS, right: SPACING.XS, top: 2, bottom: 2 });
                        Text.borderRadius(RADIUS.SM);
                        Text.backgroundColor(ShanghaiGradeEngine.getGradeColor(item.shanghaiGrade));
                        Text.margin({ top: SPACING.XS });
                    }, Text);
                    Text.pop();
                });
            }
            // 智慧选择徽章
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 智慧选择徽章
            if (item.smartChoiceEligible) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('智选');
                        Text.fontSize(FONT_SIZE.TINY);
                        Text.fontColor(COLORS.TEXT_WHITE);
                        Text.padding({ left: SPACING.XS, right: SPACING.XS, top: 2, bottom: 2 });
                        Text.borderRadius(RADIUS.SM);
                        Text.backgroundColor(COLORS.ACCENT_GREEN);
                        Text.margin({ top: SPACING.XS });
                    }, Text);
                    Text.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        // 右侧：Nutri-Score 等级徽章 + 国内分级徽章
        Column.pop();
        Row.pop();
        Column.pop();
    }
    private getTagColor(tag: string): string {
        switch (tag) {
            case '控糖友好':
                return COLORS.SUCCESS;
            case '高钠慎选':
                return COLORS.DANGER;
            case '高糖注意':
                return COLORS.WARNING;
            case '高脂留意':
                return COLORS.WARNING;
            case '热量密集':
                return COLORS.DANGER;
            default:
                return COLORS.TEXT_HINT;
        }
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "SearchPage";
    }
}
registerNamedRoute(() => new SearchPage(undefined, {}), "", { bundleName: "com.familyfood.helper", moduleName: "entry", pagePath: "pages/SearchPage", pageFullPath: "entry/src/main/ets/pages/SearchPage", integratedHsp: "false", moduleType: "followWithHap" });
