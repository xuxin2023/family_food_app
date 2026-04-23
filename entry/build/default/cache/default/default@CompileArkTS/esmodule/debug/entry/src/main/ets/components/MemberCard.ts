if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface MemberCard_Params {
    member?: FamilyProfile;
    isSelected?: boolean;
    onSelect?: (memberId: string) => void;
}
import { FamilyProfile } from "@bundle:com.familyfood.helper/entry/ets/model/FamilyProfile";
export class MemberCard extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__member = new SynchedPropertyObjectOneWayPU(params.member, this, "member");
        this.__isSelected = new SynchedPropertySimpleOneWayPU(params.isSelected, this, "isSelected");
        this.onSelect = () => { };
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: MemberCard_Params) {
        if (params.member === undefined) {
            this.__member.set(new FamilyProfile());
        }
        if (params.isSelected === undefined) {
            this.__isSelected.set(false);
        }
        if (params.onSelect !== undefined) {
            this.onSelect = params.onSelect;
        }
    }
    updateStateVars(params: MemberCard_Params) {
        this.__member.reset(params.member);
        this.__isSelected.reset(params.isSelected);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__member.purgeDependencyOnElmtId(rmElmtId);
        this.__isSelected.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__member.aboutToBeDeleted();
        this.__isSelected.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __member: SynchedPropertySimpleOneWayPU<FamilyProfile>;
    get member() {
        return this.__member.get();
    }
    set member(newValue: FamilyProfile) {
        this.__member.set(newValue);
    }
    private __isSelected: SynchedPropertySimpleOneWayPU<boolean>;
    get isSelected() {
        return this.__isSelected.get();
    }
    set isSelected(newValue: boolean) {
        this.__isSelected.set(newValue);
    }
    private onSelect: (memberId: string) => void;
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.padding(16);
            Column.borderRadius(16);
            Column.backgroundColor(this.isSelected ? '#E3F2FD' : '#FFFFFF');
            Column.border({
                width: this.isSelected ? 2 : 1,
                color: this.isSelected ? '#1976D2' : '#E0E0E0',
                style: BorderStyle.Solid,
                radius: 16
            });
            Column.alignItems(HorizontalAlign.Center);
            Column.onClick(() => {
                this.onSelect(this.member.memberId);
            });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 成员头像emoji
            Text.create(this.getMemberEmoji());
            // 成员头像emoji
            Text.fontSize(36);
            // 成员头像emoji
            Text.margin({ bottom: 8 });
        }, Text);
        // 成员头像emoji
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 昵称
            Text.create(this.member.nickname);
            // 昵称
            Text.fontSize(16);
            // 昵称
            Text.fontWeight(FontWeight.Medium);
            // 昵称
            Text.fontColor('#212121');
        }, Text);
        // 昵称
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 健康目标标签
            Text.create(this.member.healthGoals.join('·'));
            // 健康目标标签
            Text.fontSize(12);
            // 健康目标标签
            Text.fontColor('#757575');
            // 健康目标标签
            Text.margin({ top: 4 });
            // 健康目标标签
            Text.maxLines(1);
            // 健康目标标签
            Text.textOverflow({ overflow: TextOverflow.Ellipsis });
        }, Text);
        // 健康目标标签
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 过敏原标签
            if (this.member.allergens.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(`过敏：${this.member.allergens.join('、')}`);
                        Text.fontSize(11);
                        Text.fontColor('#FF5722');
                        Text.margin({ top: 4 });
                        Text.maxLines(1);
                        Text.textOverflow({ overflow: TextOverflow.Ellipsis });
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
        Column.pop();
    }
    private getMemberEmoji(): string {
        if (this.member.nickname === '爸爸')
            return '👨';
        if (this.member.nickname === '妈妈')
            return '👩';
        if (this.member.nickname === '孩子')
            return '👶';
        return '🧑';
    }
    rerender() {
        this.updateDirtyElements();
    }
}
