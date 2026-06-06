// AllergyProfile.ets
// 过敏原/不耐受档案模型 — 对标Yuka/Olive过敏原预警功能

export enum Severity {
  MILD = 'mild',
  MODERATE = 'moderate',
  SEVERE = 'severe',
  LIFE_THREATENING = 'life_threatening'
}

export class AllergyItem {
  allergen: string = '';
  severity: Severity = Severity.MODERATE;
  confirmedAt: number = 0;
  notes: string = '';
}

export class IntoleranceItem {
  substance: string = '';
  severity: Severity = Severity.MILD;
  confirmedAt: number = 0;
  notes: string = '';
}

export class AllergyProfile {
  memberId: string = '';
  allergies: AllergyItem[] = [];
  intolerances: IntoleranceItem[] = [];
  crossContaminationSensitive: boolean = false;
  updatedAt: number = 0;

  getAllAllergens(): string[] {
    return this.allergies.map((a: AllergyItem) => a.allergen);
  }

  getAllIntolerances(): string[] {
    return this.intolerances.map((i: IntoleranceItem) => i.substance);
  }

  hasLifeThreatening(): boolean {
    return this.allergies.some((a: AllergyItem) => a.severity === Severity.LIFE_THREATENING);
  }

  getSeverestAllergy(): AllergyItem | null {
    const severityOrder: Severity[] = [
      Severity.LIFE_THREATENING, Severity.SEVERE, Severity.MODERATE, Severity.MILD
    ];
    for (const s of severityOrder) {
      const found = this.allergies.find((a: AllergyItem) => a.severity === s);
      if (found) return found;
    }
    return null;
  }
}

export class AllergyHint {
  memberId: string = '';
  memberName: string = '';
  foodId: string = '';
  foodName: string = '';
  severity: Severity = Severity.MILD;
  matchedAllergen: string = '';
  certainty: 'certain' | 'probable' | 'possible' = 'certain';
  advice: string = '';
  alternativeSuggestions: string[] = [];
}

export class IntoleranceHint {
  memberId: string = '';
  memberName: string = '';
  foodId: string = '';
  foodName: string = '';
  severity: Severity = Severity.MILD;
  matchedSubstance: string = '';
  advice: string = '';
}

export function createDefaultAllergyProfile(memberId: string): AllergyProfile {
  const profile: AllergyProfile = new AllergyProfile(
  profile.memberId = memberId;
  profile.updatedAt = Date.now();
  return profile;
}

export function severityToLabel(severity: Severity): string {
  switch (severity) {
    case Severity.MILD: return '轻度';
    case Severity.MODERATE: return '中度';
    case Severity.SEVERE: return '重度';
    case Severity.LIFE_THREATENING: return '危及生命';
    default: return '未知';
  }
}

export function severityToColor(severity: Severity): string {
  switch (severity) {
    case Severity.MILD: return '#FFC107';
    case Severity.MODERATE: return '#FF9800';
    case Severity.SEVERE: return '#F44336';
    case Severity.LIFE_THREATENING: return '#B71C1C';
    default: return '#9E9E9E';
  }
}