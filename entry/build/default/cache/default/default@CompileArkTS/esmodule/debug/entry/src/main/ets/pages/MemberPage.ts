if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface MemberPage_Params {
    members?: FamilyProfile[];
}
import router from "@ohos:router";
import type { FamilyProfile } from '../model/FamilyProfile';
class MemberPage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__members = new ObservedPropertyObjectPU([], this, "members");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: MemberPage_Params) {
        if (params.members !== undefined) {
            this.members = params.members;
        }
    }
    updateStateVars(params: MemberPage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__members.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__members.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __members: ObservedPropertyObjectPU<FamilyProfile[]>;
    get members() {
        return this.__members.get();
    }
    set members(newValue: FamilyProfile[]) {
        this.__members.set(newValue);
    }
    aboutToAppear() {
        // TODO: 从本地数据库加载
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor('#FAFAFA');
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
            Text.create('家庭成员管理');
            Text.fontSize(20);
            Text.fontWeight(FontWeight.Bold);
            Text.margin({ left: 16 });
        }, Text);
        Text.pop();
        // 顶部导航
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 成员列表
            List.create();
            // 成员列表
            List.width('100%');
            // 成员列表
            List.layoutWeight(1);
            // 成员列表
            List.padding({ left: 16, right: 16 });
        }, List);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = _item => {
                const member = _item;
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
                        this.MemberListItem.bind(this)(member);
                        ListItem.pop();
                    };
                    this.observeComponentCreation2(itemCreation2, ListItem);
                    ListItem.pop();
                }
            };
            this.forEachUpdateFunction(elmtId, this.members, forEachItemGenFunction, (member: FamilyProfile) => member.memberId, false, false);
        }, ForEach);
        ForEach.pop();
        {
            const itemCreation = (elmtId, isInitialRender) => {
                ViewStackProcessor.StartGetAccessRecordingFor(elmtId);
                ListItem.create(deepRenderFunction, true);
                if (!isInitialRender) {
                    // 添加成员按钮
                    ListItem.pop();
                }
                ViewStackProcessor.StopGetAccessRecording();
            };
            const itemCreation2 = (elmtId, isInitialRender) => {
                ListItem.create(deepRenderFunction, true);
            };
            const deepRenderFunction = (elmtId, isInitialRender) => {
                itemCreation(elmtId, isInitialRender);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Row.create();
                    Row.width('100%');
                    Row.height(56);
                    Row.justifyContent(FlexAlign.Center);
                    Row.backgroundColor('#E3F2FD');
                    Row.borderRadius(12);
                    Row.margin({ top: 8 });
                    Row.onClick(() => {
                        router.pushUrl({ url: 'pages/MemberEditPage' });
                    });
                }, Row);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create('+ 添加家庭成员');
                    Text.fontSize(16);
                    Text.fontColor('#1976D2');
                }, Text);
                Text.pop();
                Row.pop();
                // 添加成员按钮
                ListItem.pop();
            };
            this.observeComponentCreation2(itemCreation2, ListItem);
            // 添加成员按钮
            ListItem.pop();
        }
        // 成员列表
        List.pop();
        Column.pop();
    }
    MemberListItem(member: FamilyProfile, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width('100%');
            Row.padding(16);
            Row.backgroundColor('#FFFFFF');
            Row.borderRadius(12);
            Row.margin({ top: 8 });
            Row.onClick(() => {
                router.pushUrl({
                    url: 'pages/MemberEditPage',
                    params: { memberId: member.memberId }
                });
            });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.alignItems(HorizontalAlign.Start);
            Column.layoutWeight(1);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(member.nickname);
            Text.fontSize(16);
            Text.fontWeight(FontWeight.Medium);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(member.healthGoals.join('·'));
            Text.fontSize(12);
            Text.fontColor('#757575');
            Text.margin({ top: 4 });
        }, Text);
        Text.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('编辑');
            Text.fontSize(14);
            Text.fontColor('#1976D2');
        }, Text);
        Text.pop();
        Row.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "MemberPage";
    }
}
registerNamedRoute(() => new MemberPage(undefined, {}), "", { bundleName: "com.familyfood.helper", moduleName: "entry", pagePath: "pages/MemberPage", pageFullPath: "entry/src/main/ets/pages/MemberPage", integratedHsp: "false", moduleType: "followWithHap" });
