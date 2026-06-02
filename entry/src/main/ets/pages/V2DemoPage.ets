// V2DemoPage.ets
// V2 闁绘鍩栭埀顑胯兌椤撴悂鎮堕崱妯煎窛缂佲偓濞差亗鈧妫?闁?閻庣懓鏈弳锝囦沪閺囩姰浠?@ComponentV2 闁汇垻鍠愰埀?//
// 閻忕偞娲滈妵姘舵嚄閽樺顫旈柨?// 1. @ObservedV2 + @Trace 闁?婵烇絽宕€瑰啿鐣电仦绛嬫閻庣數顢婇挅鍕喆閸屾氨妾柨娑樼墛濡倝妫侀埀?@ObjectLink 闁瑰嘲妫涚划宥嗙鐠佸湱纾奸柨?// 2. @Computed 闁?闁煎浜滄慨鈺冪磽閹惧磭鎽犻悹渚婄磿閻ｈ崵浠﹂悙绮瑰亾瑜濈槐婵嬫焼閸喖甯抽梺鎻掔Т椤﹁尙鎷嬮敍鍕毈
// 3. @Monitor 闁?缂侇喖澧界划蹇涙儎閹存繃鍎旈柣妯垮煐閳ь兛绀佽ぐ澶愬礌閺嶇數绀勯柛姘煎亜瑜板宕犻弽褍顤呴柛姘閳ь剛銆嬬槐?// 4. @Param + @Event 闁?闁绘牞娉涢悺娆戠磼閸曨亝顐介梺顐ｇ煯娣?// 5. @Local 闁?缂備礁瀚▎銏ゅ礃閸涙潙鍔ラ柣妯垮煐閳?
import {
  MemberNutritionProfile,
  FamilyNutritionManager,
  MealNutrition,
  createDemoFamilyManager,
  PageResourceTracker, createPageTracker
} from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'V2DemoPage';
const DOMAIN_ZERO = 0x0000;

// ==================== 濡炪倗鏁诲鐗堢▔閼姐倗鐭嬪ù?====================
@Entry
@ComponentV2
struct V2DemoPage {
  @Local manager: FamilyNutritionManager = createDemoFamilyManager();
  @Local newMemberName: string = '';
  private tracker: PageResourceTracker = createPageTracker('V2DemoPage')

  /** 闁烩晜鍨甸幆澶愬箣閹邦剚鍠呴柛鎺戞处瀹?闁?@Monitor 闁告瑯鍨甸獮蹇涘矗閺嵮冪秮闁告牗鐗曟晶鐘诲触鎼粹檧鍋?*/
  @Monitor('manager.selectedMemberIndex')
  onMemberChanged(monitor: IMonitor): void {
    hilog.info(DOMAIN_ZERO, TAG, '闁瑰瓨鍔曢幉鎶藉礆閸ャ劌搴婇悗鐟版湰閸?);
  }

  build() {
    Column() {
      // 闁哄秴娲。浠嬪冀?      Row() {
        Text($r('app.string.v2_demo_title'))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
      }
      .width('100%')
      .height(48)
      .backgroundColor('#007AFF')
      .justifyContent(FlexAlign.Center)

      // 闁瑰瓨鍔曢幉鎶芥焻婢跺顏ラ柛?      Row({ space: 8 }) {
        ForEach(this.manager.members, (member: MemberNutritionProfile, index: number) => {
          Text(member.name)
            .fontSize(14)
            .fontColor(this.manager.selectedMemberIndex === index ? '#FFFFFF' : '#333333')
            .padding({ left: 14, right: 14, top: 6, bottom: 6 })
            .borderRadius(16)
            .backgroundColor(this.manager.selectedMemberIndex === index ? '#007AFF' : '#E8E8E8')
            .onClick(() => {
              this.manager.selectedMemberIndex = index;
            })
            .accessibilityText(member.name)
            .accessibilityLevel('yes')
        }, (member: MemberNutritionProfile, index: number) => index.toString())

        Button('+').fontSize(18).fontColor('#007AFF')
          .width(32).height(32)
          .borderRadius(16)
          .backgroundColor('#E8E8E8')
          .onClick(() => {
            this.newMemberName = '闁瑰瓨鍔曢幉? + (this.manager.members.length + 1);
            this.manager.addMember(this.newMemberName);
          })
          .accessibilityText('婵烇綀顕ф慨鐐哄箣閹邦剚鍠?)
          .accessibilityLevel('yes')
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#FFFFFF')

      // 鐟滅増鎸告晶鐘诲箣閹邦剚鍠呴悹鍥烽檮閸?      if (this.manager.selectedMember) {
        Column() {
          MemberSummary({ member: this.manager.selectedMember })
          MealList({ member: this.manager.selectedMember })
        }
        .layoutWeight(1)
        .width('100%')
      }

      // 婵烇綀顕ф慨鐐搭槮閹邦収鍋ч柟绋款樀閹?      if (this.manager.selectedMember) {
        Row({ space: 8 }) {
          Button($r('app.string.v2_demo_add_breakfast')).fontSize(13)
            .onClick(() => this.addMeal('闁哄啠鏅犻ˇ?, 350, 200, 10, 8))
            .accessibilityText('婵烇綀顕ф慨鐐哄籍閳哄拋妯€')
            .accessibilityLevel('yes')
          Button($r('app.string.v2_demo_add_lunch')).fontSize(13)
            .onClick(() => this.addMeal('闁告鐗撻ˇ?, 650, 500, 12, 18))
            .accessibilityText('婵烇綀顕ф慨鐐哄础閸儺妯€')
            .accessibilityLevel('yes')
          Button($r('app.string.v2_demo_add_dinner')).fontSize(13)
            .onClick(() => this.addMeal('闁哄懏宀搁ˇ?, 500, 400, 10, 15))
            .accessibilityText('婵烇綀顕ф慨鐐哄疾濮橀妯€')
            .accessibilityLevel('yes')
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .justifyContent(FlexAlign.SpaceEvenly)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  private addMeal(name: string, cal: number, na: number, sug: number, fat: number): void {
    const member = this.manager.selectedMember;
    if (member) {
      member.today.addMeal(new MealNutrition(name, cal, na, sug, fat));
    }
  }

  aboutToAppear(): void {
    this.tracker.onAppear()
  }

  aboutToDisappear(): void {
    this.tracker.onDisappear()
  }

  pageTransition() {
    PageTransitionEnter({ duration: 350, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 250, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
  }
}

// ==================== 闁瑰瓨鍔曢幉鎶芥媰閵夈儱鎮嬮柟鑺ヮ焾椤?====================
@ComponentV2
export struct MemberSummary {
  @Require @Param member: MemberNutritionProfile;

  /** @Computed 闁?闁告瑯浜ｉ鍝ョ不濡炲墽顏辨繛鍡忔缁辨繃寰勫顒夋П濞达綀娉曢弫銈嗙▔瀹ュ娅㈠璺虹Х椤撳摜绮?*/
  @Computed
  get todayCalories(): number {
    return this.member.today.meals.reduce((sum, m) => sum + m.calories, 0);
  }

  @Computed
  get todaySodium(): number {
    return this.member.today.meals.reduce((sum, m) => sum + m.sodium, 0);
  }

  @Computed
  get todaySugar(): number {
    return this.member.today.meals.reduce((sum, m) => sum + m.sugar, 0);
  }

  @Computed
  get todayFat(): number {
    return this.member.today.meals.reduce((sum, m) => sum + m.fat, 0);
  }

  @Computed
  get caloriePercent(): number {
    return Math.min(100, Math.round((this.todayCalories / this.member.dailyCalorieGoal) * 100));
  }

  build() {
    Column() {
      Text() { Span(`${this.member.name} 鐠?`); Span($r('app.string.v2_demo_today_intake')) }
        .fontSize(16).fontWeight(FontWeight.Medium)
        .margin({ bottom: 12 })

      Row({ space: 16 }) {
        this.NutritionCard($r('app.string.v2_demo_calories'), this.todayCalories, this.member.dailyCalorieGoal, 'kcal',
          this.caloriePercent >= 90 ? '#FF5722' : '#4CAF50')
        this.NutritionCard($r('app.string.v2_demo_sodium'), this.todaySodium, this.member.dailySodiumGoal, 'mg', '#FF9800')
        this.NutritionCard($r('app.string.v2_demo_sugar'), this.todaySugar, this.member.dailySugarGoal, 'g', '#2196F3')
        this.NutritionCard($r('app.string.v2_demo_fat'), this.todayFat, this.member.dailyFatGoal, 'g', '#9C27B0')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ left: 12, right: 12, top: 8, bottom: 8 })
  }

  @Builder
  NutritionCard(label: ResourceStr, current: number, goal: number, unit: string, color: string) {
    Column({ space: 4 }) {
      Text(label).fontSize(11).fontColor('#999999')
      Text(`${current}`).fontSize(18).fontWeight(FontWeight.Bold).fontColor(color)
      Text(`${unit}`).fontSize(10).fontColor('#999999')
      Row() {
        Row()
          .width(`${Math.min(100, (current / goal) * 100)}%`)
          .height(4)
          .borderRadius(2)
          .backgroundColor(color)
      }
      .width(60)
      .height(4)
      .borderRadius(2)
      .backgroundColor('#E0E0E0')
    }
    .alignItems(HorizontalAlign.Center)
  }
}

// ==================== 濡炰焦鍔栭濂稿礆濡ゅ嫨鈧?====================
@ComponentV2
export struct MealList {
  @Require @Param member: MemberNutritionProfile;

  build() {
    Column() {
      Text($r('app.string.v2_demo_today_meals')).fontSize(14).fontWeight(FontWeight.Medium)
        .width('100%').padding({ left: 4, bottom: 8 })

      if (this.member.today.meals.length === 0) {
        Text($r('app.string.v2_demo_no_records'))
          .fontSize(13).fontColor('#999999')
          .width('100%').textAlign(TextAlign.Center).padding(20)
      } else {
        List() {
          ForEach(this.member.today.meals, (meal: MealNutrition, index: number) => {
            ListItem() {
              // 闁哄牃鍋撴繛锝呭船缁佸灚绺藉Δ鍐煁濞?闁?濡ょ姴鐭侀惁澶娗庨崡鐐差唺閻熸瑥鍊搁惂?              MealItem({ meal: meal })
            }
          }, (meal: MealNutrition, index: number) => `${index}_${meal.mealName}`)
        }
        .width('100%')
        .height(240)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ left: 12, right: 12, bottom: 8 })
  }
}

// ==================== 闁告娲熼ˇ鍨亜閻у摜绀勯柡鍫氬亾婵烇絽宕粊鍨附濡ゅ绀?====================
@ComponentV2
export struct MealItem {
  @Require @Param meal: MealNutrition;
  @Local editing: boolean = false;

  build() {
    Column() {
      Row() {
        Column({ space: 2 }) {
          Text(this.meal.mealName).fontSize(14).fontWeight(FontWeight.Medium)
          Text(`妫ｅ啯鏆?{this.meal.calories}kcal 妫ｅ喚娼?{this.meal.sodium}mg 妫ｅ啫绾?{this.meal.sugar}g 妫ｅ啨鍋?{this.meal.fat}g`)
            .fontSize(11).fontColor('#888888')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Button('闁翠礁楠忕粭?).fontSize(12)
          .width(28).height(28)
          .borderRadius(14)
          .backgroundColor('#E8E8E8')
          .onClick(() => { this.editing = !this.editing; })
          .accessibilityText('缂傚倹鐗炵欢顐ｎ槮閹邦収鍋?)
          .accessibilityLevel('yes')
      }
      .width('100%')
      .padding(10)
      .backgroundColor('#FAFAFA')
      .borderRadius(8)
      .margin({ bottom: 6 })

      // 闁告劕鎳撴禒鍫㈢磽閺嶎剛甯?闁?閻忕偞娲滈妵?@Local 缂備礁瀚▎銏ゅ礃閸涙潙鍔ラ柣妯垮煐閳?      if (this.editing) {
        Row({ space: 6 }) {
          Text() { Span($r('app.string.v2_demo_calorie_inline')); Span(`: ${this.meal.calories}`) }.fontSize(12)
          Button('+50').fontSize(11).height(24)
            .onClick(() => { this.meal.calories += 50; })
            .accessibilityText('濠⒀呭仜婵?0闁告銈囩唴闂?)
            .accessibilityLevel('yes')
          Button('-50').fontSize(11).height(24)
            .onClick(() => { this.meal.calories = Math.max(0, this.meal.calories - 50); })
            .accessibilityText('闁告垵绻愰惃?0闁告銈囩唴闂?)
            .accessibilityLevel('yes')
          Button($r('app.string.v2_demo_reset')).fontSize(11).height(24)
            .onClick(() => { this.meal.calories = 300; })
            .accessibilityText('闂佹彃绉堕悿鍡涘础闄囬惌楣冩煂?)
            .accessibilityLevel('yes')
        }
        .width('100%')
        .padding({ left: 16, bottom: 8 })
      }
    }
  }
}
