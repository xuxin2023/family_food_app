export class ScoreWeightProfile {
  nutriWeight: number = 0.5;
  ecoWeight: number = 0.25;
  novaWeight: number = 0.25;

  static forDefault(): ScoreWeightProfile {
    return new ScoreWeightProfile();
  }

  static forChild(): ScoreWeightProfile {
    const p: ScoreWeightProfile = new ScoreWeightProfile()
    p.nutriWeight = 0.7;
    p.ecoWeight = 0.1;
    p.novaWeight = 0.2;
    return p;
  }

  static forTeen(): ScoreWeightProfile {
    const p: ScoreWeightProfile = new ScoreWeightProfile()
    p.nutriWeight = 0.6;
    p.ecoWeight = 0.15;
    p.novaWeight = 0.25;
    return p;
  }

  static forPregnant(): ScoreWeightProfile {
    const p: ScoreWeightProfile = new ScoreWeightProfile()
    p.nutriWeight = 0.8;
    p.ecoWeight = 0.05;
    p.novaWeight = 0.15;
    return p;
  }

  static forElder(): ScoreWeightProfile {
    const p: ScoreWeightProfile = new ScoreWeightProfile()
    p.nutriWeight = 0.65;
    p.ecoWeight = 0.1;
    p.novaWeight = 0.25;
    return p;
  }

  static forEcoConscious(): ScoreWeightProfile {
    const p: ScoreWeightProfile = new ScoreWeightProfile()
    p.nutriWeight = 0.35;
    p.ecoWeight = 0.4;
    p.novaWeight = 0.25;
    return p;
  }

  calculateComprehensiveScore(nutriScore: number, ecoScore: number, novaScore: number): number {
    return nutriScore * this.nutriWeight + ecoScore * this.ecoWeight + novaScore * this.novaWeight;
  }
}
