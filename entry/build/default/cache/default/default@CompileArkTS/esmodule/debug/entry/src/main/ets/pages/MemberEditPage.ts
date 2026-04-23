if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface MemberEditPage_Params {
    nickname?: string;
    selectedAgeGroup?: number;
    selectedGoals?: boolean[];
    allergenInput?: string;
    stepLevelIndex?: number;
    sleepStatusIndex?: number;
    bpStatusIndex?: number;
    bsStatusIndex?: number;
    appState?: AppState;
    editingMemberId?: string;
    ageGroups?: string[];
    healthGoals?: string[];
    stepLevels?: string[];
    sleepStatuses?: string[];
    bpStatuses?: string[];
    bsStatuses?: string[];
    commonAllergens?: string[];
    selectedAllergens?: boolean[];
}
import router from "@ohos:router";
import { FamilyProfile, AgeGroup, HealthGoal } from "@bundle:com.familyfood.helper/entry/ets/model/FamilyProfile";
import { HealthSignal, StepLevel, SleepStatus, BpStatus, BsStatus } from "@bundle:com.familyfood.helper/entry/ets/model/HealthSignal";
import { AppState } from "@bundle:com.familyfood.helper/entry/ets/AppState";
import { DateUtil } from "@bundle:com.familyfood.helper/entry/ets/utils/DateUtil";
// AgeGroup 枚举值数组
const AGE_GROUP_VALUES: AgeGroup[] = [AgeGroup.CHILD, AgeGroup.TEEN, AgeGroup.ADULT, AgeGroup.MIDDLE_OLD, AgeGroup.OLD];
class MemberEditPage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__nickname = new ObservedPropertySimplePU('', this, "nickname");
        this.__selectedAgeGroup = new ObservedPropertySimplePU(2 // 默认成人
        , this, "selectedAgeGroup");
        this.__selectedGoals = new ObservedPropertyObjectPU([false, false, false, false, false, false], this, "selectedGoals");
        this.__allergenInput = new ObservedPropertySimplePU('', this, "allergenInput");
        this.__stepLevelIndex = new ObservedPropertySimplePU(1 // 默认正常
        , this, "stepLevelIndex");
        this.__sleepStatusIndex = new ObservedPropertySimplePU(0 // 默认好
        , this, "sleepStatusIndex");
        this.__bpStatusIndex = new ObservedPropertySimplePU(0 // 默认正常
        , this, "bpStatusIndex");
        this.__bsStatusIndex = new ObservedPropertySimplePU(0 // 默认正常
        , this, "bsStatusIndex");
        this.appState = AppState.getInstance();
        this.editingMemberId = '' // 空表示新建
        ;
        this.ageGroups = ['儿童', '青少年', '成人', '中老年', '老年'];
        this.healthGoals = ['控压', '控糖', '控脂', '减脂', '儿童', '无特殊'];
        this.stepLevels = ['低', '正常', '高'];
        this.sleepStatuses = ['好', '一般', '差'];
        this.bpStatuses = ['正常', '偏高', '高'];
        this.bsStatuses = ['正常', '偏高', '高'];
        this.commonAllergens = ['坚果', '乳制品', '麸质', '鸡蛋', '海鲜', '大豆', '芝麻', '花生'];
        this.__selectedAllergens = new ObservedPropertyObjectPU([false, false, false, false, false, false, false, false]
        // 将 AgeGroup 转换为索引
        , this, "selectedAllergens");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: MemberEditPage_Params) {
        if (params.nickname !== undefined) {
            this.nickname = params.nickname;
        }
        if (params.selectedAgeGroup !== undefined) {
            this.selectedAgeGroup = params.selectedAgeGroup;
        }
        if (params.selectedGoals !== undefined) {
            this.selectedGoals = params.selectedGoals;
        }
        if (params.allergenInput !== undefined) {
            this.allergenInput = params.allergenInput;
        }
        if (params.stepLevelIndex !== undefined) {
            this.stepLevelIndex = params.stepLevelIndex;
        }
        if (params.sleepStatusIndex !== undefined) {
            this.sleepStatusIndex = params.sleepStatusIndex;
        }
        if (params.bpStatusIndex !== undefined) {
            this.bpStatusIndex = params.bpStatusIndex;
        }
        if (params.bsStatusIndex !== undefined) {
            this.bsStatusIndex = params.bsStatusIndex;
        }
        if (params.appState !== undefined) {
            this.appState = params.appState;
        }
        if (params.editingMemberId !== undefined) {
            this.editingMemberId = params.editingMemberId;
        }
        if (params.ageGroups !== undefined) {
            this.ageGroups = params.ageGroups;
        }
        if (params.healthGoals !== undefined) {
            this.healthGoals = params.healthGoals;
        }
        if (params.stepLevels !== undefined) {
            this.stepLevels = params.stepLevels;
        }
        if (params.sleepStatuses !== undefined) {
            this.sleepStatuses = params.sleepStatuses;
        }
        if (params.bpStatuses !== undefined) {
            this.bpStatuses = params.bpStatuses;
        }
        if (params.bsStatuses !== undefined) {
            this.bsStatuses = params.bsStatuses;
        }
        if (params.commonAllergens !== undefined) {
            this.commonAllergens = params.commonAllergens;
        }
        if (params.selectedAllergens !== undefined) {
            this.selectedAllergens = params.selectedAllergens;
        }
    }
    updateStateVars(params: MemberEditPage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__nickname.purgeDependencyOnElmtId(rmElmtId);
        this.__selectedAgeGroup.purgeDependencyOnElmtId(rmElmtId);
        this.__selectedGoals.purgeDependencyOnElmtId(rmElmtId);
        this.__allergenInput.purgeDependencyOnElmtId(rmElmtId);
        this.__stepLevelIndex.purgeDependencyOnElmtId(rmElmtId);
        this.__sleepStatusIndex.purgeDependencyOnElmtId(rmElmtId);
        this.__bpStatusIndex.purgeDependencyOnElmtId(rmElmtId);
        this.__bsStatusIndex.purgeDependencyOnElmtId(rmElmtId);
        this.__selectedAllergens.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__nickname.aboutToBeDeleted();
        this.__selectedAgeGroup.aboutToBeDeleted();
        this.__selectedGoals.aboutToBeDeleted();
        this.__allergenInput.aboutToBeDeleted();
        this.__stepLevelIndex.aboutToBeDeleted();
        this.__sleepStatusIndex.aboutToBeDeleted();
        this.__bpStatusIndex.aboutToBeDeleted();
        this.__bsStatusIndex.aboutToBeDeleted();
        this.__selectedAllergens.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __nickname: ObservedPropertySimplePU<string>;
    get nickname() {
        return this.__nickname.get();
    }
    set nickname(newValue: string) {
        this.__nickname.set(newValue);
    }
    private __selectedAgeGroup: ObservedPropertySimplePU<number>; // 默认成人
    get selectedAgeGroup() {
        return this.__selectedAgeGroup.get();
    }
    set selectedAgeGroup(newValue: number) {
        this.__selectedAgeGroup.set(newValue);
    }
    private __selectedGoals: ObservedPropertyObjectPU<boolean[]>;
    get selectedGoals() {
        return this.__selectedGoals.get();
    }
    set selectedGoals(newValue: boolean[]) {
        this.__selectedGoals.set(newValue);
    }
    private __allergenInput: ObservedPropertySimplePU<string>;
    get allergenInput() {
        return this.__allergenInput.get();
    }
    set allergenInput(newValue: string) {
        this.__allergenInput.set(newValue);
    }
    private __stepLevelIndex: ObservedPropertySimplePU<number>; // 默认正常
    get stepLevelIndex() {
        return this.__stepLevelIndex.get();
    }
    set stepLevelIndex(newValue: number) {
        this.__stepLevelIndex.set(newValue);
    }
    private __sleepStatusIndex: ObservedPropertySimplePU<number>; // 默认好
    get sleepStatusIndex() {
        return this.__sleepStatusIndex.get();
    }
    set sleepStatusIndex(newValue: number) {
        this.__sleepStatusIndex.set(newValue);
    }
    private __bpStatusIndex: ObservedPropertySimplePU<number>; // 默认正常
    get bpStatusIndex() {
        return this.__bpStatusIndex.get();
    }
    set bpStatusIndex(newValue: number) {
        this.__bpStatusIndex.set(newValue);
    }
    private __bsStatusIndex: ObservedPropertySimplePU<number>; // 默认正常
    get bsStatusIndex() {
        return this.__bsStatusIndex.get();
    }
    set bsStatusIndex(newValue: number) {
        this.__bsStatusIndex.set(newValue);
    }
    private appState: AppState;
    private editingMemberId: string; // 空表示新建
    private ageGroups: string[];
    private healthGoals: string[];
    private stepLevels: string[];
    private sleepStatuses: string[];
    private bpStatuses: string[];
    private bsStatuses: string[];
    private commonAllergens: string[];
    private __selectedAllergens: ObservedPropertyObjectPU<boolean[]>;
    get selectedAllergens() {
        return this.__selectedAllergens.get();
    }
    set selectedAllergens(newValue: boolean[]) {
        this.__selectedAllergens.set(newValue);
    }
    // 将 AgeGroup 转换为索引
    private ageGroupToIndex(ageGroup: AgeGroup): number {
        for (let i = 0; i < AGE_GROUP_VALUES.length; i++) {
            if (AGE_GROUP_VALUES[i] === ageGroup) {
                return i;
            }
        }
        return 2; // 默认成人
    }
    // 将索引转换为 AgeGroup
    private indexToAgeGroup(index: number): AgeGroup {
        if (index >= 0 && index < AGE_GROUP_VALUES.length) {
            return AGE_GROUP_VALUES[index];
        }
        return AgeGroup.ADULT; // 默认成人
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Scroll.create();
            Scroll.width('100%');
            Scroll.height('100%');
            Scroll.backgroundColor('#FAFAFA');
            Scroll.scrollable(ScrollDirection.Vertical);
        }, Scroll);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 顶部导航
            Row.create();
            // 顶部导航
            Row.width('100%');
            // 顶部导航
            Row.padding({ left: 16, right: 16, top: 16, bottom: 16 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('←');
            Text.fontSize(24);
            Text.fontColor('#1976D2');
            Text.onClick(() => { router.back(); });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('编辑成员');
            Text.fontSize(20);
            Text.fontWeight(FontWeight.Bold);
            Text.margin({ left: 16 });
        }, Text);
        Text.pop();
        // 顶部导航
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 昵称
            Column.create();
            // 昵称
            Column.width('100%');
            // 昵称
            Column.padding({ left: 16, right: 16, bottom: 16 });
            // 昵称
            Column.alignItems(HorizontalAlign.Start);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('昵称');
            Text.fontSize(14);
            Text.fontColor('#757575');
            Text.margin({ bottom: 8 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TextInput.create({ placeholder: '如：爸爸、妈妈、孩子' });
            TextInput.width('100%');
            TextInput.height(48);
            TextInput.borderRadius(12);
            TextInput.backgroundColor('#FFFFFF');
            TextInput.onChange((value: string) => { this.nickname = value; });
        }, TextInput);
        // 昵称
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 年龄段
            Column.create();
            // 年龄段
            Column.width('100%');
            // 年龄段
            Column.padding({ left: 16, right: 16, bottom: 16 });
            // 年龄段
            Column.alignItems(HorizontalAlign.Start);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('年龄段');
            Text.fontSize(14);
            Text.fontColor('#757575');
            Text.margin({ bottom: 8 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Flex.create({ wrap: FlexWrap.Wrap });
        }, Flex);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = (_item, index: number) => {
                const group = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(group);
                    Text.fontSize(14);
                    Text.padding({ left: 16, right: 16, top: 8, bottom: 8 });
                    Text.borderRadius(20);
                    Text.backgroundColor(this.selectedAgeGroup === index ? '#1976D2' : '#F5F5F5');
                    Text.fontColor(this.selectedAgeGroup === index ? '#FFFFFF' : '#212121');
                    Text.margin({ right: 8, bottom: 8 });
                    Text.onClick(() => { this.selectedAgeGroup = index; });
                }, Text);
                Text.pop();
            };
            this.forEachUpdateFunction(elmtId, this.ageGroups, forEachItemGenFunction, (group: string, index: number) => `${index}`, true, true);
        }, ForEach);
        ForEach.pop();
        Flex.pop();
        // 年龄段
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 健康目标（多选）
            Column.create();
            // 健康目标（多选）
            Column.width('100%');
            // 健康目标（多选）
            Column.padding({ left: 16, right: 16, bottom: 16 });
            // 健康目标（多选）
            Column.alignItems(HorizontalAlign.Start);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('健康目标（可多选）');
            Text.fontSize(14);
            Text.fontColor('#757575');
            Text.margin({ bottom: 8 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Flex.create({ wrap: FlexWrap.Wrap });
        }, Flex);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = (_item, index: number) => {
                const goal = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(goal);
                    Text.fontSize(14);
                    Text.padding({ left: 16, right: 16, top: 8, bottom: 8 });
                    Text.borderRadius(20);
                    Text.backgroundColor(this.selectedGoals[index] ? '#1976D2' : '#F5F5F5');
                    Text.fontColor(this.selectedGoals[index] ? '#FFFFFF' : '#212121');
                    Text.margin({ right: 8, bottom: 8 });
                    Text.onClick(() => {
                        this.selectedGoals[index] = !this.selectedGoals[index];
                    });
                }, Text);
                Text.pop();
            };
            this.forEachUpdateFunction(elmtId, this.healthGoals, forEachItemGenFunction, (goal: string, index: number) => `${index}`, true, true);
        }, ForEach);
        ForEach.pop();
        Flex.pop();
        // 健康目标（多选）
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 过敏原
            Column.create();
            // 过敏原
            Column.width('100%');
            // 过敏原
            Column.padding({ left: 16, right: 16, bottom: 16 });
            // 过敏原
            Column.alignItems(HorizontalAlign.Start);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('过敏原');
            Text.fontSize(14);
            Text.fontColor('#757575');
            Text.margin({ bottom: 8 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Flex.create({ wrap: FlexWrap.Wrap });
        }, Flex);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = (_item, index: number) => {
                const allergen = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(allergen);
                    Text.fontSize(14);
                    Text.padding({ left: 12, right: 12, top: 6, bottom: 6 });
                    Text.borderRadius(16);
                    Text.backgroundColor(this.selectedAllergens[index] ? '#FF5722' : '#F5F5F5');
                    Text.fontColor(this.selectedAllergens[index] ? '#FFFFFF' : '#212121');
                    Text.margin({ right: 8, bottom: 8 });
                    Text.onClick(() => {
                        this.selectedAllergens[index] = !this.selectedAllergens[index];
                    });
                }, Text);
                Text.pop();
            };
            this.forEachUpdateFunction(elmtId, this.commonAllergens, forEachItemGenFunction, (allergen: string, index: number) => `${index}`, true, true);
        }, ForEach);
        ForEach.pop();
        Flex.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 自定义过敏原输入
            TextInput.create({ placeholder: '自定义过敏原' });
            // 自定义过敏原输入
            TextInput.width('100%');
            // 自定义过敏原输入
            TextInput.height(40);
            // 自定义过敏原输入
            TextInput.borderRadius(8);
            // 自定义过敏原输入
            TextInput.backgroundColor('#FFFFFF');
            // 自定义过敏原输入
            TextInput.margin({ top: 8 });
            // 自定义过敏原输入
            TextInput.onChange((value: string) => { this.allergenInput = value; });
        }, TextInput);
        // 过敏原
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 今日健康状态
            Column.create();
            // 今日健康状态
            Column.width('100%');
            // 今日健康状态
            Column.padding(16);
            // 今日健康状态
            Column.backgroundColor('#FFFFFF');
            // 今日健康状态
            Column.borderRadius(12);
            // 今日健康状态
            Column.margin({ left: 16, right: 16, bottom: 16 });
            // 今日健康状态
            Column.alignItems(HorizontalAlign.Start);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('今日健康状态');
            Text.fontSize(16);
            Text.fontWeight(FontWeight.Medium);
            Text.margin({ bottom: 12 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 活动量
            Row.create();
            // 活动量
            Row.margin({ bottom: 8 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('活动量：');
            Text.fontSize(14);
            Text.width(70);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = (_item, index: number) => {
                const level = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(level);
                    Text.fontSize(13);
                    Text.padding({ left: 12, right: 12, top: 6, bottom: 6 });
                    Text.borderRadius(16);
                    Text.backgroundColor(this.stepLevelIndex === index ? '#1976D2' : '#F5F5F5');
                    Text.fontColor(this.stepLevelIndex === index ? '#FFFFFF' : '#212121');
                    Text.margin({ right: 6 });
                    Text.onClick(() => { this.stepLevelIndex = index; });
                }, Text);
                Text.pop();
            };
            this.forEachUpdateFunction(elmtId, this.stepLevels, forEachItemGenFunction, (level: string, index: number) => `${index}`, true, true);
        }, ForEach);
        ForEach.pop();
        // 活动量
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 睡眠
            Row.create();
            // 睡眠
            Row.margin({ bottom: 8 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('睡眠：');
            Text.fontSize(14);
            Text.width(70);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = (_item, index: number) => {
                const status = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(status);
                    Text.fontSize(13);
                    Text.padding({ left: 12, right: 12, top: 6, bottom: 6 });
                    Text.borderRadius(16);
                    Text.backgroundColor(this.sleepStatusIndex === index ? '#1976D2' : '#F5F5F5');
                    Text.fontColor(this.sleepStatusIndex === index ? '#FFFFFF' : '#212121');
                    Text.margin({ right: 6 });
                    Text.onClick(() => { this.sleepStatusIndex = index; });
                }, Text);
                Text.pop();
            };
            this.forEachUpdateFunction(elmtId, this.sleepStatuses, forEachItemGenFunction, (status: string, index: number) => `${index}`, true, true);
        }, ForEach);
        ForEach.pop();
        // 睡眠
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 血压状态
            Row.create();
            // 血压状态
            Row.margin({ bottom: 8 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('血压：');
            Text.fontSize(14);
            Text.width(70);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = (_item, index: number) => {
                const status = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(status);
                    Text.fontSize(13);
                    Text.padding({ left: 12, right: 12, top: 6, bottom: 6 });
                    Text.borderRadius(16);
                    Text.backgroundColor(this.bpStatusIndex === index ? '#FF5722' : '#F5F5F5');
                    Text.fontColor(this.bpStatusIndex === index ? '#FFFFFF' : '#212121');
                    Text.margin({ right: 6 });
                    Text.onClick(() => { this.bpStatusIndex = index; });
                }, Text);
                Text.pop();
            };
            this.forEachUpdateFunction(elmtId, this.bpStatuses, forEachItemGenFunction, (status: string, index: number) => `${index}`, true, true);
        }, ForEach);
        ForEach.pop();
        // 血压状态
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 血糖状态
            Row.create();
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('血糖：');
            Text.fontSize(14);
            Text.width(70);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = (_item, index: number) => {
                const status = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(status);
                    Text.fontSize(13);
                    Text.padding({ left: 12, right: 12, top: 6, bottom: 6 });
                    Text.borderRadius(16);
                    Text.backgroundColor(this.bsStatusIndex === index ? '#FF5722' : '#F5F5F5');
                    Text.fontColor(this.bsStatusIndex === index ? '#FFFFFF' : '#212121');
                    Text.margin({ right: 6 });
                    Text.onClick(() => { this.bsStatusIndex = index; });
                }, Text);
                Text.pop();
            };
            this.forEachUpdateFunction(elmtId, this.bsStatuses, forEachItemGenFunction, (status: string, index: number) => `${index}`, true, true);
        }, ForEach);
        ForEach.pop();
        // 血糖状态
        Row.pop();
        // 今日健康状态
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 保存按钮
            Button.createWithLabel('保存');
            // 保存按钮
            Button.width('90%');
            // 保存按钮
            Button.height(48);
            // 保存按钮
            Button.backgroundColor('#1976D2');
            // 保存按钮
            Button.borderRadius(24);
            // 保存按钮
            Button.margin({ top: 16, bottom: 32 });
            // 保存按钮
            Button.onClick(() => {
                this.saveMember();
            });
        }, Button);
        // 保存按钮
        Button.pop();
        Column.pop();
        Scroll.pop();
    }
    async aboutToAppear() {
        const params = router.getParams() as Record<string, string>;
        if (params && params.memberId) {
            this.editingMemberId = params.memberId;
            // 加载已有成员数据
            const members = await this.appState.getAllMembers();
            const member = members.find(m => m.memberId === this.editingMemberId);
            if (member) {
                this.nickname = member.nickname;
                this.selectedAgeGroup = this.ageGroupToIndex(member.ageGroup);
                // 回填健康目标
                const goalValues = [HealthGoal.CONTROL_BP, HealthGoal.CONTROL_SUGAR, HealthGoal.CONTROL_FAT,
                    HealthGoal.LOSE_FAT, HealthGoal.CHILD, HealthGoal.NONE];
                for (let i = 0; i < goalValues.length; i++) {
                    this.selectedGoals[i] = member.healthGoals.includes(goalValues[i]);
                }
                // 回填过敏原
                for (let i = 0; i < this.commonAllergens.length; i++) {
                    this.selectedAllergens[i] = member.allergens.includes(this.commonAllergens[i]);
                }
            }
        }
    }
    private async saveMember() {
        const profile = new FamilyProfile();
        profile.memberId = this.editingMemberId.length > 0 ? this.editingMemberId : `member_${Date.now()}`;
        profile.nickname = this.nickname;
        profile.ageGroup = this.indexToAgeGroup(this.selectedAgeGroup);
        profile.createdAt = this.editingMemberId.length > 0 ? Date.now() : Date.now();
        profile.updatedAt = Date.now();
        // 健康目标
        const goalValues = [HealthGoal.CONTROL_BP, HealthGoal.CONTROL_SUGAR, HealthGoal.CONTROL_FAT,
            HealthGoal.LOSE_FAT, HealthGoal.CHILD, HealthGoal.NONE];
        profile.healthGoals = [];
        for (let i = 0; i < this.selectedGoals.length; i++) {
            if (this.selectedGoals[i]) {
                profile.healthGoals.push(goalValues[i]);
            }
        }
        // 过敏原
        profile.allergens = [];
        for (let i = 0; i < this.commonAllergens.length; i++) {
            if (this.selectedAllergens[i]) {
                profile.allergens.push(this.commonAllergens[i]);
            }
        }
        if (this.allergenInput.length > 0) {
            profile.allergens.push(this.allergenInput);
        }
        // 保存
        await this.appState.saveMember(profile);
        // 同步更新健康信号
        const signal = new HealthSignal();
        signal.memberId = profile.memberId;
        signal.date = DateUtil.getToday();
        signal.stepLevel = [StepLevel.LOW, StepLevel.NORMAL, StepLevel.HIGH][this.stepLevelIndex];
        signal.sleepStatus = [SleepStatus.GOOD, SleepStatus.FAIR, SleepStatus.POOR][this.sleepStatusIndex];
        signal.manualBpStatus = [BpStatus.NORMAL, BpStatus.ELEVATED, BpStatus.HIGH][this.bpStatusIndex];
        signal.manualBsStatus = [BsStatus.NORMAL, BsStatus.ELEVATED, BsStatus.HIGH][this.bsStatusIndex];
        this.appState.updateHealthSignal(signal);
        router.back();
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "MemberEditPage";
    }
}
registerNamedRoute(() => new MemberEditPage(undefined, {}), "", { bundleName: "com.familyfood.helper", moduleName: "entry", pagePath: "pages/MemberEditPage", pageFullPath: "entry/src/main/ets/pages/MemberEditPage", integratedHsp: "false", moduleType: "followWithHap" });
