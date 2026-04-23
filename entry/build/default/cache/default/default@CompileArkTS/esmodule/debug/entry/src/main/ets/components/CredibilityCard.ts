if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface CredibilityCard_Params {
    result?: CredibilityResult;
    radarLabels?: string[];
}
import { CredibilityResult, DataGrade } from "@bundle:com.familyfood.helper/entry/ets/model/CredibilityResult";
import type { RadarDimension, PublicQueryEntry } from "@bundle:com.familyfood.helper/entry/ets/model/CredibilityResult";
export class CredibilityCard extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__result = new SynchedPropertyObjectOneWayPU(params.result, this, "result");
        this.radarLabels = ['身份清晰', '许可信息', '追溯入口', '公开查询', '表达边界'];
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: CredibilityCard_Params) {
        if (params.result === undefined) {
            this.__result.set(new CredibilityResult());
        }
        if (params.radarLabels !== undefined) {
            this.radarLabels = params.radarLabels;
        }
    }
    updateStateVars(params: CredibilityCard_Params) {
        this.__result.reset(params.result);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__result.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__result.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __result: SynchedPropertySimpleOneWayPU<CredibilityResult>;
    get result() {
        return this.__result.get();
    }
    set result(newValue: CredibilityResult) {
        this.__result.set(newValue);
    }
    // 雷达图5个维度名称
    private radarLabels: string[];
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.padding(16);
            Column.backgroundColor('#FFFFFF');
            Column.borderRadius(12);
            Column.alignItems(HorizontalAlign.Start);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 标题行 + 数据等级
            Row.create();
            // 标题行 + 数据等级
            Row.width('100%');
            // 标题行 + 数据等级
            Row.margin({ bottom: 8 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('生产主体信息');
            Text.fontSize(16);
            Text.fontWeight(FontWeight.Medium);
            Text.layoutWeight(1);
        }, Text);
        Text.pop();
        // A-E数据等级标识
        this.GradeBadge.bind(this)(this.result.overallGrade);
        // 标题行 + 数据等级
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 数据等级说明
            Text.create(this.result.getGradeDesc());
            // 数据等级说明
            Text.fontSize(12);
            // 数据等级说明
            Text.fontColor('#757575');
            // 数据等级说明
            Text.margin({ bottom: 12 });
        }, Text);
        // 数据等级说明
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 5维雷达图
            if (this.result.radarDimensions.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.RadarChart.bind(this)();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // 降级：旧版进度条
                        Row.create();
                        // 降级：旧版进度条
                        Row.margin({ bottom: 4 });
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('透明度');
                        Text.fontSize(12);
                        Text.fontColor('#757575');
                        Text.margin({ right: 4 });
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(`${this.result.score}`);
                        Text.fontSize(20);
                        Text.fontWeight(FontWeight.Bold);
                        Text.fontColor(this.result.score >= 60 ? '#4CAF50' : '#FF5722');
                    }, Text);
                    Text.pop();
                    // 降级：旧版进度条
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Progress.create({ value: this.result.score, total: 100, type: ProgressType.Linear });
                        Progress.width('100%');
                        Progress.color(this.result.score >= 60 ? '#4CAF50' : '#FF5722');
                        Progress.backgroundColor('#E0E0E0');
                        Progress.margin({ bottom: 12 });
                    }, Progress);
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 各维度详情
            if (this.result.radarDimensions.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = _item => {
                            const dim = _item;
                            this.DimensionRow.bind(this)(dim);
                        };
                        this.forEachUpdateFunction(elmtId, this.result.radarDimensions, forEachItemGenFunction, (dim: RadarDimension, index: number) => `${index}`, false, true);
                    }, ForEach);
                    ForEach.pop();
                });
            }
            // 提示信息列表
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 提示信息列表
            if (this.result.tips.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.margin({ top: 8 });
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = _item => {
                            const tip = _item;
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Row.create();
                                Row.margin({ bottom: 4 });
                                Row.width('100%');
                            }, Row);
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create('•');
                                Text.fontSize(12);
                                Text.fontColor('#757575');
                                Text.margin({ right: 6 });
                            }, Text);
                            Text.pop();
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create(tip);
                                Text.fontSize(12);
                                Text.fontColor('#616161');
                            }, Text);
                            Text.pop();
                            Row.pop();
                        };
                        this.forEachUpdateFunction(elmtId, this.result.tips, forEachItemGenFunction, (tip: string, index: number) => `${index}`, false, true);
                    }, ForEach);
                    ForEach.pop();
                    Column.pop();
                });
            }
            // 公开查询入口
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 公开查询入口
            if (this.result.publicQueryEntries.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.PublicQuerySection.bind(this)();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        Column.pop();
    }
    // A-E数据等级标识
    GradeBadge(grade: DataGrade, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width(28);
            Row.height(28);
            Row.borderRadius(14);
            Row.backgroundColor(this.getGradeColor(grade));
            Row.justifyContent(FlexAlign.Center);
            Row.alignItems(VerticalAlign.Center);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(grade);
            Text.fontSize(16);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor('#FFFFFF');
        }, Text);
        Text.pop();
        Row.pop();
    }
    // 雷达图（用Canvas模拟五边形）
    RadarChart(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.padding({ top: 8, bottom: 8 });
            Column.alignItems(HorizontalAlign.Center);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 中心评分
            Text.create(`${this.result.score}`);
            // 中心评分
            Text.fontSize(32);
            // 中心评分
            Text.fontWeight(FontWeight.Bold);
            // 中心评分
            Text.fontColor(this.result.score >= 60 ? '#4CAF50' : '#FF5722');
        }, Text);
        // 中心评分
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('信息透明度');
            Text.fontSize(11);
            Text.fontColor('#757575');
            Text.margin({ top: 2, bottom: 8 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 5维条形图（替代Canvas雷达图，ArkUI Canvas在组件中受限）
            ForEach.create();
            const forEachItemGenFunction = (_item, index: number) => {
                const dim = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Row.create();
                    Row.width('100%');
                    Row.margin({ bottom: 6 });
                    Row.alignItems(VerticalAlign.Center);
                }, Row);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(this.radarLabels[index] || dim.name);
                    Text.fontSize(11);
                    Text.fontColor('#757575');
                    Text.width(60);
                }, Text);
                Text.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    // 进度条表示维度得分
                    Progress.create({ value: this.getDimensionScore(dim), total: 100, type: ProgressType.Linear });
                    // 进度条表示维度得分
                    Progress.layoutWeight(1);
                    // 进度条表示维度得分
                    Progress.height(6);
                    // 进度条表示维度得分
                    Progress.color(this.getDimensionColor(dim));
                    // 进度条表示维度得分
                    Progress.backgroundColor('#E0E0E0');
                }, Progress);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(dim.status);
                    Text.fontSize(10);
                    Text.fontColor(this.getDimensionColor(dim));
                    Text.width(50);
                    Text.textAlign(TextAlign.End);
                }, Text);
                Text.pop();
                Row.pop();
            };
            this.forEachUpdateFunction(elmtId, this.result.radarDimensions, forEachItemGenFunction, (dim: RadarDimension, index: number) => `${index}`, true, true);
        }, ForEach);
        // 5维条形图（替代Canvas雷达图，ArkUI Canvas在组件中受限）
        ForEach.pop();
        Column.pop();
    }
    // 维度详情行
    DimensionRow(dim: RadarDimension, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width('100%');
            Row.margin({ bottom: 4 });
            Row.alignItems(VerticalAlign.Center);
        }, Row);
        this.GradeBadge.bind(this)(dim.grade);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(dim.name);
            Text.fontSize(13);
            Text.fontWeight(FontWeight.Medium);
            Text.margin({ left: 8 });
            Text.layoutWeight(1);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(dim.status);
            Text.fontSize(12);
            Text.fontColor(this.getDimensionColor(dim));
        }, Text);
        Text.pop();
        Row.pop();
    }
    // 公开查询入口
    PublicQuerySection(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.alignItems(HorizontalAlign.Start);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('公开查询入口');
            Text.fontSize(14);
            Text.fontWeight(FontWeight.Medium);
            Text.margin({ top: 12, bottom: 8 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = _item => {
                const entry = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Row.create();
                    Row.width('100%');
                    Row.padding(8);
                    Row.backgroundColor('#F5F5F5');
                    Row.borderRadius(8);
                    Row.margin({ bottom: 6 });
                    Row.alignItems(VerticalAlign.Center);
                }, Row);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Column.create();
                    Column.alignItems(HorizontalAlign.Start);
                    Column.layoutWeight(1);
                }, Column);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(entry.name);
                    Text.fontSize(13);
                    Text.fontWeight(FontWeight.Medium);
                }, Text);
                Text.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(`查询关键词：${entry.keyword}`);
                    Text.fontSize(11);
                    Text.fontColor('#757575');
                    Text.margin({ top: 2 });
                }, Text);
                Text.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(entry.description);
                    Text.fontSize(11);
                    Text.fontColor('#9E9E9E');
                    Text.margin({ top: 2 });
                }, Text);
                Text.pop();
                Column.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create('复制');
                    Text.fontSize(12);
                    Text.fontColor('#1976D2');
                    Text.padding({ left: 8, right: 8, top: 4, bottom: 4 });
                    Text.borderRadius(8);
                    Text.backgroundColor('#E3F2FD');
                    Text.onClick(() => {
                        // TODO: 复制到剪贴板
                    });
                }, Text);
                Text.pop();
                Row.pop();
            };
            this.forEachUpdateFunction(elmtId, this.result.publicQueryEntries, forEachItemGenFunction, (entry: PublicQueryEntry, index: number) => `${index}`, false, true);
        }, ForEach);
        ForEach.pop();
        Column.pop();
    }
    // 辅助方法
    private getGradeColor(grade: DataGrade): string {
        switch (grade) {
            case DataGrade.A: return '#4CAF50'; // 绿
            case DataGrade.B: return '#8BC34A'; // 浅绿
            case DataGrade.C: return '#FF9800'; // 橙
            case DataGrade.D: return '#FF5722'; // 深橙
            case DataGrade.E: return '#9E9E9E'; // 灰
            default: return '#9E9E9E';
        }
    }
    private getDimensionScore(dim: RadarDimension): number {
        if (dim.status === '清晰')
            return 90;
        if (dim.status === '部分清晰')
            return 50;
        if (dim.status === '未识别')
            return 10;
        return 30;
    }
    private getDimensionColor(dim: RadarDimension): string {
        return this.getGradeColor(dim.grade);
    }
    rerender() {
        this.updateDirtyElements();
    }
}
