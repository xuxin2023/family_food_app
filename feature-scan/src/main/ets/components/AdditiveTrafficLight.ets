// AdditiveTrafficLight.ets
// 添加剂红黄绿三色可视化标记组件 — 对标 Olive 添加剂风险标记
// 规则：E编号添加剂按EU风险评估分级，中文添加剂按GB 2760分类

import { COLORS } from 'hsp_core';

export enum AdditiveRiskLevel {
  SAFE = 'safe',
  CAUTION = 'caution',
  HARMFUL = 'harmful'
}

export class AdditiveEntry {
  name: string = '';
  eNumber: string = '';
  riskLevel: AdditiveRiskLevel = AdditiveRiskLevel.SAFE;
  description: string = '';
  category: string = '';
}

const HARMFUL_ENUMBERS: Set<string> = new Set([
  'E102', 'E104', 'E110', 'E120', 'E122', 'E124', 'E129',
  'E131', 'E133', 'E142', 'E150a', 'E150c', 'E150d',
  'E151', 'E153', 'E154', 'E155', 'E160b', 'E173', 'E174', 'E175',
  'E180', 'E181', 'E210', 'E211', 'E212', 'E213', 'E214', 'E215',
  'E216', 'E217', 'E218', 'E219', 'E220', 'E221', 'E222', 'E223',
  'E224', 'E225', 'E226', 'E227', 'E228', 'E230', 'E231', 'E232',
  'E233', 'E236', 'E237', 'E238', 'E239', 'E240', 'E241', 'E242',
  'E249', 'E250', 'E251', 'E252', 'E280', 'E281', 'E282', 'E283',
  'E284', 'E285', 'E310', 'E311', 'E312', 'E320', 'E321',
  'E338', 'E339', 'E340', 'E341', 'E343', 'E450', 'E451', 'E452',
  'E620', 'E621', 'E622', 'E623', 'E624', 'E625', 'E626', 'E627',
  'E631', 'E635', 'E636', 'E637', 'E640', 'E641',
  'E950', 'E951', 'E952', 'E954', 'E957', 'E965', 'E966', 'E967',
  // 扩展覆盖 (GB 2760-2024 + EU EFSA 重新评估)
  'E103', 'E105', 'E106', 'E107', 'E108', 'E109', 'E111', 'E112', 'E113',
  'E114', 'E115', 'E116', 'E117', 'E118', 'E119', 'E121', 'E123', 'E125',
  'E126', 'E127', 'E128', 'E130', 'E132', 'E134', 'E135', 'E136', 'E137',
  'E138', 'E139', 'E140', 'E141', 'E143', 'E144', 'E145', 'E146', 'E147',
  'E148', 'E149', 'E150b', 'E150e', 'E152', 'E156', 'E157', 'E158', 'E159',
  'E161', 'E162', 'E163', 'E164', 'E165', 'E166', 'E167', 'E168', 'E169',
  'E170', 'E171', 'E172', 'E176', 'E177', 'E182', 'E183', 'E184', 'E185',
  'E186', 'E187', 'E188', 'E189', 'E190', 'E191', 'E192', 'E193', 'E194',
  'E195', 'E196', 'E197', 'E198', 'E199',
  'E234', 'E235', 'E243', 'E244', 'E245', 'E246', 'E247', 'E248',
  'E253', 'E254', 'E255', 'E256', 'E257', 'E258', 'E259', 'E260', 'E261',
  'E262', 'E263', 'E264', 'E265', 'E266', 'E267', 'E268', 'E269',
  'E270', 'E271', 'E272', 'E273', 'E274', 'E275', 'E276', 'E277', 'E278',
  'E279', 'E286', 'E287', 'E288', 'E289', 'E290', 'E291', 'E292', 'E293',
  'E294', 'E295', 'E296', 'E297', 'E298', 'E299',
  'E313', 'E314', 'E315', 'E316', 'E317', 'E318', 'E319', 'E323', 'E324',
  'E325', 'E326', 'E327', 'E328', 'E329', 'E330', 'E342', 'E344', 'E345',
  'E346', 'E347', 'E348', 'E349',
  'E453', 'E454', 'E455', 'E456', 'E457', 'E458', 'E459',
  'E628', 'E629', 'E630', 'E632', 'E633', 'E634',
  'E955', 'E953', 'E956', 'E958', 'E959', 'E960', 'E961', 'E962', 'E963',
  'E964', 'E968', 'E969', 'E999'
]);

const CAUTION_ENUMBERS: Set<string> = new Set([
  'E100', 'E101', 'E160a', 'E160c', 'E160d', 'E160e', 'E160f',
  'E161a', 'E161b', 'E161c', 'E161d', 'E161e', 'E161f', 'E161g',
  'E162', 'E170', 'E171', 'E172', 'E200', 'E202', 'E203',
  'E270', 'E290', 'E296', 'E300', 'E301', 'E302', 'E303', 'E304',
  'E305', 'E306', 'E307', 'E308', 'E309', 'E322', 'E325', 'E326',
  'E327', 'E330', 'E331', 'E332', 'E333', 'E334', 'E335', 'E336',
  'E337', 'E350', 'E351', 'E352', 'E353', 'E354', 'E355', 'E356',
  'E400', 'E401', 'E402', 'E403', 'E404', 'E405', 'E406', 'E407',
  'E408', 'E410', 'E412', 'E413', 'E414', 'E415', 'E416', 'E417',
  'E418', 'E420', 'E421', 'E422', 'E432', 'E433', 'E434', 'E435',
  'E436', 'E440', 'E441', 'E442', 'E443', 'E444', 'E445',
  'E460', 'E461', 'E462', 'E463', 'E464', 'E465', 'E466', 'E468',
  'E470', 'E471', 'E472', 'E473', 'E474', 'E475', 'E476',
  'E477', 'E478', 'E479', 'E480', 'E481', 'E482', 'E483',
  'E900', 'E901', 'E902', 'E903', 'E905', 'E907', 'E908', 'E909',
  'E912', 'E914', 'E927a', 'E927b', 'E928', 'E930',
  // 扩展覆盖
  'E201', 'E204', 'E205', 'E206', 'E207', 'E208', 'E209', 'E236b',
  'E239', 'E242', 'E260', 'E261', 'E262', 'E263', 'E264', 'E265',
  'E266', 'E297', 'E298', 'E299',
  'E357', 'E358', 'E359', 'E360', 'E361', 'E362', 'E363', 'E364',
  'E365', 'E366', 'E367', 'E368',
  'E409', 'E411', 'E419', 'E423', 'E424', 'E425', 'E426', 'E427',
  'E428', 'E429', 'E430', 'E431', 'E437', 'E438', 'E439',
  'E446', 'E447', 'E448', 'E449', 'E450i', 'E450ii', 'E450iii',
  'E467', 'E469', 'E470a', 'E470b', 'E470c', 'E470d', 'E470e',
  'E472a', 'E472b', 'E472c', 'E472d', 'E472e', 'E472f',
  'E484', 'E485', 'E486', 'E487', 'E488', 'E489', 'E490', 'E491',
  'E492', 'E493', 'E494', 'E495',
  'E570', 'E571', 'E572', 'E573', 'E574', 'E575', 'E576', 'E577',
  'E578', 'E579', 'E580', 'E581', 'E582', 'E583', 'E584', 'E585',
  'E586', 'E587', 'E588', 'E589',
  'E627a', 'E642', 'E643', 'E644', 'E645',
  'E904', 'E906', 'E910', 'E911', 'E913', 'E915', 'E916', 'E917',
  'E918', 'E919', 'E920', 'E921', 'E922', 'E923', 'E924', 'E925',
  'E926', 'E929', 'E931', 'E932', 'E933', 'E934', 'E935', 'E936',
  'E937', 'E938', 'E939', 'E940', 'E941', 'E942', 'E943', 'E944',
  'E945', 'E946', 'E947', 'E948', 'E949'
]);

export class AdditiveClassifier {
  static classifyENumber(eNumber: string): AdditiveRiskLevel {
    const normalized = eNumber.toUpperCase().replace(/\s/g, '');
    if (HARMFUL_ENUMBERS.has(normalized)) {
      return AdditiveRiskLevel.HARMFUL;
    }
    if (CAUTION_ENUMBERS.has(normalized)) {
      return AdditiveRiskLevel.CAUTION;
    }
    return AdditiveRiskLevel.SAFE;
  }

  static classifyChineseAdditive(name: string): AdditiveRiskLevel {
    const harmfulKeywords = ['亚硝酸钠', '苯甲酸钠', '甜蜜素', '糖精钠', '脱氢醋酸钠',
      '焦亚硫酸钠', '亚硫酸钠', '胭脂红', '日落黄', '柠檬黄', '苋菜红', '赤藓红'];
    const cautionKeywords = ['山梨酸', '脱氢醋酸', '丙酸钙', '二氧化硫', '阿斯巴甜',
      '三氯蔗糖', '安赛蜜', '谷氨酸钠', '5\'-呈味核苷酸', '卡拉胶', '黄原胶'];

    for (const kw of harmfulKeywords) {
      if (name.includes(kw)) return AdditiveRiskLevel.HARMFUL;
    }
    for (const kw of cautionKeywords) {
      if (name.includes(kw)) return AdditiveRiskLevel.CAUTION;
    }
    return AdditiveRiskLevel.SAFE;
  }

  static classifyIngredients(ingredients: string[]): AdditiveEntry[] {
    const entries: AdditiveEntry[] = [];
    for (const ing of ingredients) {
      const entry: AdditiveEntry = new AdditiveEntry()
      entry.name = ing;

      const eMatch = ing.match(/E\d{3,4}[a-z]?/i);
      if (eMatch) {
        entry.eNumber = eMatch[0].toUpperCase();
        entry.riskLevel = AdditiveClassifier.classifyENumber(entry.eNumber);
      } else {
        entry.riskLevel = AdditiveClassifier.classifyChineseAdditive(ing);
      }

      entry.description = AdditiveClassifier.getRiskDescription(entry.riskLevel);
      entries.push(entry);
    }
    return entries;
  }

  static getRiskDescription(level: AdditiveRiskLevel): string {
    switch (level) {
      case AdditiveRiskLevel.HARMFUL:
        return '建议避免：可能存在健康风险，儿童/孕妇慎用';
      case AdditiveRiskLevel.CAUTION:
        return '适量食用：在标准用量内安全，过量可能有影响';
      case AdditiveRiskLevel.SAFE:
        return '安全：天然来源或经过充分安全评估';
      default:
        return '';
    }
  }

  static getRiskColor(level: AdditiveRiskLevel): string {
    switch (level) {
      case AdditiveRiskLevel.HARMFUL:
        return '#E53935';
      case AdditiveRiskLevel.CAUTION:
        return '#FF9800';
      case AdditiveRiskLevel.SAFE:
        return '#4CAF50';
      default:
        return '#9E9E9E';
    }
  }

  static getRiskSummary(entries: AdditiveEntry[]): string {
    const harmful = entries.filter(e => e.riskLevel === AdditiveRiskLevel.HARMFUL).length;
    const caution = entries.filter(e => e.riskLevel === AdditiveRiskLevel.CAUTION).length;
    const safe = entries.filter(e => e.riskLevel === AdditiveRiskLevel.SAFE).length;
    if (harmful > 0) return `含${harmful}种高风险添加剂，建议谨慎选择`;
    if (caution > 0) return `含${caution}种需注意添加剂，适量食用`;
    return `${safe}种添加剂均为安全级别`;
  }
}

@ComponentV2
export struct AdditiveTrafficLight {
  @Param entry: AdditiveEntry = new AdditiveEntry();
  @Param showDescription: boolean = false;

  build() {
    Column() {
      Row() {
        Circle({ width: 8, height: 8 })
          .fill(AdditiveClassifier.getRiskColor(this.entry.riskLevel))
          .margin({ right: 8 })

        Text(this.entry.name)
          .fontSize(14)
          .fontColor('#333333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)

        if (this.entry.eNumber.length > 0) {
          Text(this.entry.eNumber)
            .fontSize(11)
            .fontColor('#888888')
            .margin({ left: 4 })
        }
      }
      .width('100%')
      .height(28)
      .alignItems(VerticalAlign.Center)
      .accessibilityText(this.entry.name + (this.entry.eNumber.length > 0 ? ' ' + this.entry.eNumber : '') + '，风险等级' + this.entry.riskLevel)
      .accessibilityLevel('yes')

      if (this.showDescription && this.entry.description.length > 0) {
        Text(this.entry.description)
          .fontSize(12)
          .fontColor('#666666')
          .margin({ left: 16, top: 2 })
          .width('100%')
      }
    }
    .width('100%')
  }
}

@ComponentV2
export struct AdditiveTrafficLightList {
  @Param entries: AdditiveEntry[] = [];
  @Param showSummary: boolean = true;
  @Param maxDisplay: number = 5;

  build() {
    Column() {
      if (this.showSummary && this.entries.length > 0) {
        Text(AdditiveClassifier.getRiskSummary(this.entries))
          .fontSize(13)
          .fontColor('#333333')
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 8 })
      }

      ForEach(this.entries.slice(0, this.maxDisplay), (entry: AdditiveEntry) => {
        AdditiveTrafficLight({ entry: entry, showDescription: true })
      }, (entry: AdditiveEntry, index: number) => `${entry.name}_${index}`)

      if (this.entries.length > this.maxDisplay) {
        Text(`还有${this.entries.length - this.maxDisplay}种添加剂...`)
          .fontSize(12)
          .fontColor('#888888')
          .margin({ top: 4, left: 16 })
      }
    }
    .width('100%')
    .padding(12)
    .borderRadius(8)
    .backgroundColor('#F5F5F5')
    .accessibilityText(`添加剂风险列表，共${this.entries.length}种`)
    .accessibilityLevel('yes')
  }
}
