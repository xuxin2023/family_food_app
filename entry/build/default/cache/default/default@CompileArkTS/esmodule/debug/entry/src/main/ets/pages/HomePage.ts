if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface HomePage_Params {
    familyMembers?: FamilyProfile[];
    selectedMemberId?: string;
    currentSloganIndex?: number;
    refreshToggle?: boolean;
    appState?: AppState;
    slogans?: string[];
}
import router from "@ohos:router";
import type { FamilyProfile } from '../model/FamilyProfile';
import { MemberCard } from "@bundle:com.familyfood.helper/entry/ets/components/MemberCard";
import { AppState } from "@bundle:com.familyfood.helper/entry/ets/AppState";
import { SubscriptionTier } from "@bundle:com.familyfood.helper/entry/ets/model/PricingModel";
class HomePage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__familyMembers = new ObservedPropertyObjectPU([], this, "familyMembers");
        this.__selectedMemberId = new ObservedPropertySimplePU('', this, "selectedMemberId");
        this.__currentSloganIndex = new ObservedPropertySimplePU(0, this, "currentSloganIndex");
        this.__refreshToggle = new ObservedPropertySimplePU(false, this, "refreshToggle");
        this.appState = AppState.getInstance();
        this.slogans = [
            '给爸妈买食品前，先拍一下。',
            '孩子零食会不会影响正餐，一拍就知道。',
            '吃完烧烤火锅，下一餐怎么搭。',
            '同一款食品，爸爸、妈妈、孩子建议都不同。',
            '不是不让你吃，而是帮你吃得更有数。'
        ];
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: HomePage_Params) {
        if (params.familyMembers !== undefined) {
            this.familyMembers = params.familyMembers;
        }
        if (params.selectedMemberId !== undefined) {
            this.selectedMemberId = params.selectedMemberId;
        }
        if (params.currentSloganIndex !== undefined) {
            this.currentSloganIndex = params.currentSloganIndex;
        }
        if (params.refreshToggle !== undefined) {
            this.refreshToggle = params.refreshToggle;
        }
        if (params.appState !== undefined) {
            this.appState = params.appState;
        }
        if (params.slogans !== undefined) {
            this.slogans = params.slogans;
        }
    }
    updateStateVars(params: HomePage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__familyMembers.purgeDependencyOnElmtId(rmElmtId);
        this.__selectedMemberId.purgeDependencyOnElmtId(rmElmtId);
        this.__currentSloganIndex.purgeDependencyOnElmtId(rmElmtId);
        this.__refreshToggle.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__familyMembers.aboutToBeDeleted();
        this.__selectedMemberId.aboutToBeDeleted();
        this.__currentSloganIndex.aboutToBeDeleted();
        this.__refreshToggle.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __familyMembers: ObservedPropertyObjectPU<FamilyProfile[]>;
    get familyMembers() {
        return this.__familyMembers.get();
    }
    set familyMembers(newValue: FamilyProfile[]) {
        this.__familyMembers.set(newValue);
    }
    private __selectedMemberId: ObservedPropertySimplePU<string>;
    get selectedMemberId() {
        return this.__selectedMemberId.get();
    }
    set selectedMemberId(newValue: string) {
        this.__selectedMemberId.set(newValue);
    }
    private __currentSloganIndex: ObservedPropertySimplePU<number>;
    get currentSloganIndex() {
        return this.__currentSloganIndex.get();
    }
    set currentSloganIndex(newValue: number) {
        this.__currentSloganIndex.set(newValue);
    }
    private __refreshToggle: ObservedPropertySimplePU<boolean>;
    get refreshToggle() {
        return this.__refreshToggle.get();
    }
    set refreshToggle(newValue: boolean) {
        this.__refreshToggle.set(newValue);
    }
    private appState: AppState;
    private slogans: string[];
    async aboutToAppear() {
        this.currentSloganIndex = Math.floor(Math.random() * this.slogans.length);
        await this.loadFamilyMembers();
    }
    async loadFamilyMembers() {
        this.familyMembers = await this.appState.getAllMembers();
        if (this.familyMembers.length > 0 && this.selectedMemberId.length === 0) {
            this.selectedMemberId = this.familyMembers[0].memberId;
        }
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor('#FAFAFA');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 顶部品牌区
            Column.create();
            // 顶部品牌区
            Column.width('100%');
            // 顶部品牌区
            Column.alignItems(HorizontalAlign.Center);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('家庭饮食平衡助手');
            Text.fontSize(22);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor('#1976D2');
            Text.margin({ top: 20, bottom: 4 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.slogans[this.currentSloganIndex]);
            Text.fontSize(14);
            Text.fontColor('#757575');
            Text.margin({ bottom: 16 });
            Text.textAlign(TextAlign.Center);
            Text.maxLines(2);
        }, Text);
        Text.pop();
        // 顶部品牌区
        Column.pop();
        // V5增强：今日家庭状态条
        this.buildFamilyStatusBar.bind(this)();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 家庭成员选择
            Text.create('今天给谁看？');
            // 家庭成员选择
            Text.fontSize(18);
            // 家庭成员选择
            Text.fontWeight(FontWeight.Medium);
            // 家庭成员选择
            Text.fontColor('#212121');
            // 家庭成员选择
            Text.margin({ left: 16, bottom: 8 });
        }, Text);
        // 家庭成员选择
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Scroll.create();
            Scroll.scrollable(ScrollDirection.Vertical);
            Scroll.layoutWeight(1);
        }, Scroll);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Flex.create({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start, alignItems: ItemAlign.Start });
            Flex.width('100%');
            Flex.padding({ left: 16, right: 16 });
        }, Flex);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = _item => {
                const member = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Column.create();
                    Column.width('45%');
                    Column.margin(8);
                }, Column);
                {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        if (isInitialRender) {
                            let componentCall = new MemberCard(this, {
                                member: member,
                                isSelected: this.selectedMemberId === member.memberId,
                                onSelect: (id: string) => { this.selectedMemberId = id; }
                            }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/HomePage.ets", line: 75, col: 15 });
                            ViewPU.create(componentCall);
                            let paramsLambda = () => {
                                return {
                                    member: member,
                                    isSelected: this.selectedMemberId === member.memberId,
                                    onSelect: (id: string) => { this.selectedMemberId = id; }
                                };
                            };
                            componentCall.paramsGenerator_ = paramsLambda;
                        }
                        else {
                            this.updateStateVarsOfChildByElmtId(elmtId, {
                                member: member,
                                isSelected: this.selectedMemberId === member.memberId
                            });
                        }
                    }, { name: "MemberCard" });
                }
                Column.pop();
            };
            this.forEachUpdateFunction(elmtId, this.familyMembers, forEachItemGenFunction, (member: FamilyProfile) => member.memberId, false, false);
        }, ForEach);
        ForEach.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('45%');
            Column.height(100);
            Column.margin(8);
            Column.borderRadius(16);
            Column.justifyContent(FlexAlign.Center);
            Column.alignItems(HorizontalAlign.Center);
            Column.border({ width: 1, color: '#E0E0E0', style: BorderStyle.Dashed, radius: 16 });
            Column.onClick(() => {
                if (this.appState.canAddMember()) {
                    router.pushUrl({ url: 'pages/MemberEditPage' });
                }
                else {
                    router.pushUrl({ url: 'pages/SettingsPage' });
                }
            });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('+');
            Text.fontSize(28);
            Text.fontColor('#1976D2');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.appState.canAddMember() ? '添加成员' : '升级解锁');
            Text.fontSize(12);
            Text.fontColor(this.appState.canAddMember() ? '#1976D2' : '#FF9800');
            Text.margin({ top: 4 });
        }, Text);
        Text.pop();
        Column.pop();
        Flex.pop();
        Scroll.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 底部操作区
            Column.create();
            // 底部操作区
            Column.width('100%');
            // 底部操作区
            Column.alignItems(HorizontalAlign.Center);
            // 底部操作区
            Column.padding({ left: 16, right: 16 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithChild();
            Button.width('90%');
            Button.height(56);
            Button.backgroundColor('#1976D2');
            Button.borderRadius(28);
            Button.margin({ bottom: 12 });
            Button.onClick(() => {
                router.pushUrl({
                    url: 'pages/ScanPage',
                    params: { memberId: this.selectedMemberId }
                });
            });
        }, Button);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('📷');
            Text.fontSize(20);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('拍食品标签');
            Text.fontSize(18);
            Text.fontColor('#FFFFFF');
            Text.margin({ left: 8 });
        }, Text);
        Text.pop();
        Row.pop();
        Button.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithChild();
            Button.width('90%');
            Button.height(56);
            Button.backgroundColor('#E3F2FD');
            Button.borderRadius(28);
            Button.margin({ bottom: 12 });
            Button.onClick(() => {
                router.pushUrl({
                    url: 'pages/BalancePage',
                    params: { memberId: this.selectedMemberId }
                });
            });
        }, Button);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('🍽');
            Text.fontSize(20);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('记录美食');
            Text.fontSize(18);
            Text.fontColor('#1976D2');
            Text.margin({ left: 8 });
        }, Text);
        Text.pop();
        Row.pop();
        Button.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.appState.canAccess(SubscriptionTier.FAMILY_EARLY)) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Button.createWithChild();
                        Button.width('90%');
                        Button.height(48);
                        Button.backgroundColor('#FFF3E0');
                        Button.borderRadius(24);
                        Button.margin({ bottom: 12 });
                        Button.onClick(() => {
                            router.pushUrl({ url: 'pages/BasketCheckPage' });
                        });
                    }, Button);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('🛒');
                        Text.fontSize(20);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('购物篮检查');
                        Text.fontSize(18);
                        Text.fontColor('#FF9800');
                        Text.margin({ left: 8 });
                    }, Text);
                    Text.pop();
                    Row.pop();
                    Button.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.margin({ bottom: 16 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('历史');
            Text.fontSize(13);
            Text.fontColor('#757575');
            Text.onClick(() => { router.pushUrl({ url: 'pages/HistoryPage' }); });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('  |  ');
            Text.fontSize(13);
            Text.fontColor('#E0E0E0');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.appState.canAccess(SubscriptionTier.FAMILY_EARLY)) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('周报');
                        Text.fontSize(13);
                        Text.fontColor('#757575');
                        Text.onClick(() => { router.pushUrl({ url: 'pages/WeeklyReportPage' }); });
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('  |  ');
                        Text.fontSize(13);
                        Text.fontColor('#E0E0E0');
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
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('设置');
            Text.fontSize(13);
            Text.fontColor('#757575');
            Text.onClick(() => { router.pushUrl({ url: 'pages/SettingsPage' }); });
        }, Text);
        Text.pop();
        Row.pop();
        // 底部操作区
        Column.pop();
        Column.pop();
    }
    buildFamilyStatusBar(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.padding(12);
            Column.backgroundColor('#FFFFFF');
            Column.borderRadius(10);
            Column.margin({ left: 16, right: 16, bottom: 12 });
            Column.shadow({ radius: 2, color: '#1A000000', offsetY: 1 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width('100%');
            Row.margin({ bottom: 8 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('💡');
            Text.fontSize(16);
            Text.margin({ right: 4 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('今日家庭状态');
            Text.fontSize(14);
            Text.fontWeight(FontWeight.Medium);
            Text.fontColor('#1A1A1A');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('点击刷新');
            Text.fontSize(11);
            Text.fontColor('#007DFF');
            Text.onClick(() => {
                this.refreshToggle = !this.refreshToggle;
            });
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.familyMembers.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Flex.create({ wrap: FlexWrap.Wrap });
                        Flex.width('100%');
                    }, Flex);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = _item => {
                            const member = _item;
                            this.buildMemberStatusItem.bind(this)(member);
                        };
                        this.forEachUpdateFunction(elmtId, this.familyMembers, forEachItemGenFunction);
                    }, ForEach);
                    ForEach.pop();
                    Flex.pop();
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
    buildMemberStatusItem(member: FamilyProfile, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width('48%');
            Row.margin({ top: 4, bottom: 4 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.getMemberEmoji(member));
            Text.fontSize(14);
            Text.margin({ right: 4 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(member.nickname);
            Text.fontSize(12);
            Text.fontColor('#333333');
            Text.margin({ right: 4 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.getMemberStatusText(member));
            Text.fontSize(11);
            Text.fontColor(this.getMemberStatusColor(member));
        }, Text);
        Text.pop();
        Row.pop();
    }
    private getMemberEmoji(member: FamilyProfile): string {
        if (member.nickname === '爸爸')
            return '👨';
        if (member.nickname === '妈妈')
            return '👩';
        if (member.nickname === '孩子')
            return '👶';
        return '🧑';
    }
    private getMemberStatusText(member: FamilyProfile): string {
        const goal = member.healthGoals[0];
        if (goal === '控压')
            return '高盐额度剩余85%';
        if (goal === '控糖')
            return '糖预算剩余70%';
        if (goal === '减脂')
            return '热量预算剩余60%';
        if (goal === '儿童')
            return '今日零食0次/建议≤3次';
        return '预算充足';
    }
    private getMemberStatusColor(member: FamilyProfile): string {
        const goal = member.healthGoals[0];
        if (goal === '控压')
            return '#EF7D00';
        if (goal === '控糖')
            return '#00823F';
        if (goal === '减脂')
            return '#007DFF';
        if (goal === '儿童')
            return '#9C27B0';
        return '#00823F';
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "HomePage";
    }
}
registerNamedRoute(() => new HomePage(undefined, {}), "", { bundleName: "com.familyfood.helper", moduleName: "entry", pagePath: "pages/HomePage", pageFullPath: "entry/src/main/ets/pages/HomePage", integratedHsp: "false", moduleType: "followWithHap" });
