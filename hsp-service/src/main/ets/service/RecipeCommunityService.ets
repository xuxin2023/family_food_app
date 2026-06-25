// RecipeCommunityService.ets
// 社区功能增强 — 食谱PK投票/挑战赛/排行榜/成就徽章

import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';

const TAG = 'RecipeCommunityService';
const DOMAIN = HILOG_DOMAIN_DEFAULT;

export interface RecipePkVote {
  recipeId: string;
  voterId: string;
  voteType: 'up' | 'down';
  votedAt: number;
}

export interface ChallengeRule {
  id: string;
  title: string;
  description: string;
  target: string;
  startDate: string;
  endDate: string;
  reward: string;
  category: ChallengeCategory;
}

export enum ChallengeCategory {
  LOW_SODIUM = '低钠挑战',
  SUGAR_FREE = '无糖挑战',
  HIGH_PROTEIN = '高蛋白挑战',
  VEGGIE_DAY = '素食日挑战',
  HOMEMADE = '自制美食挑战',
  RAINBOW = '七彩食盘挑战',
}

export interface ChallengeParticipant {
  memberId: string;
  displayName: string;
  submissions: number;
  score: number;
  rank: number;
  lastActive: number;
}

export interface Leaderboard {
  challengeId: string;
  period: 'weekly' | 'monthly' | 'all_time';
  topParticipants: LeaderboardEntry[];
  updatedAt: number;
}

export interface LeaderboardEntry {
  memberId: string;
  displayName: string;
  avatarEmoji: string;
  score: number;
  rank: number;
  trend: 'up' | 'down' | 'stable';
  highlight: string;
}

export interface VoteStats {
  upCount: number;
  downCount: number;
  score: number;
}

export interface RecipeScoreEntry {
  recipeId: string;
  score: number;
}

export interface ParticipantRank {
  rank: number;
  totalParticipants: number;
  percentile: number;
}

export interface Achievement {
  id: string;
  name: string;
  description: string;
  icon: string;
  category: AchievementCategory;
  requiredCount: number;
  currentCount: number;
  unlockedAt: number | null;
  isUnlocked: boolean;
}

export interface PresetAchievement {
  id: string;
  name: string;
  description: string;
  icon: string;
  category: AchievementCategory;
  requiredCount: number;
}

export enum AchievementCategory {
  SCANNING = '扫码达人',
  COOKING = '烹饪大师',
  SHARING = '社区贡献',
  HEALTH = '健康守护',
  STREAK = '连续打卡',
  EXPLORER = '探索先锋',
}

const PRESET_CHALLENGES: ChallengeRule[] = [
  {
    id: 'low_sodium_week',
    title: '低钠美食周',
    description: '本周每餐钠含量<400mg/100g即算合格',
    target: '累计7餐达标',
    startDate: '', endDate: '',
    reward: '低钠达人徽章 + 7天高级会员',
    category: ChallengeCategory.LOW_SODIUM,
  },
  {
    id: 'sugar_free_3days',
    title: '三天无糖挑战',
    description: '连续3天糖摄入<15g/天',
    target: '连续3天达标',
    startDate: '', endDate: '',
    reward: '控糖先锋徽章 + 3天高级会员',
    category: ChallengeCategory.SUGAR_FREE,
  },
  {
    id: 'rainbow_plate',
    title: '七彩食盘挑战',
    description: '每餐至少5种颜色食材',
    target: '累计10餐达标',
    startDate: '', endDate: '',
    reward: '彩虹食客徽章 + 主题皮肤',
    category: ChallengeCategory.RAINBOW,
  },
  {
    id: 'homemade_master',
    title: '自制美食争霸',
    description: '发布原创食谱获得赞数排名',
    target: '获得50个赞',
    startDate: '', endDate: '',
    reward: '烹饪达人徽章 + 首页推荐位',
    category: ChallengeCategory.HOMEMADE,
  },
  {
    id: 'high_protein_challenge',
    title: '高蛋白增肌挑战',
    description: '每日蛋白质摄入>80g',
    target: '连续7天达标',
    startDate: '', endDate: '',
    reward: '增肌达人徽章 + 定制食谱',
    category: ChallengeCategory.HIGH_PROTEIN,
  },
  {
    id: 'veggie_day_marathon',
    title: '素食日马拉松',
    description: '每周至少2天全素食',
    target: '连续4周达标',
    startDate: '', endDate: '',
    reward: '绿色食者徽章 + 植物基食谱集',
    category: ChallengeCategory.VEGGIE_DAY,
  },
];

const PRESET_ACHIEVEMENTS: PresetAchievement[] = [
  { id: 'scan_10', name: '初识食品', description: '扫描10款食品', icon: '🔍', category: AchievementCategory.SCANNING, requiredCount: 10 },
  { id: 'scan_100', name: '食品达人', description: '扫描100款食品', icon: '🏆', category: AchievementCategory.SCANNING, requiredCount: 100 },
  { id: 'scan_500', name: '食品专家', description: '扫描500款食品', icon: '👑', category: AchievementCategory.SCANNING, requiredCount: 500 },
  { id: 'recipe_1', name: '初次下厨', description: '发布第一个食谱', icon: '🍳', category: AchievementCategory.COOKING, requiredCount: 1 },
  { id: 'recipe_10', name: '小有名厨', description: '发布10个食谱', icon: '👨‍🍳', category: AchievementCategory.COOKING, requiredCount: 10 },
  { id: 'share_5', name: '乐于分享', description: '分享5份报告', icon: '📤', category: AchievementCategory.SHARING, requiredCount: 5 },
  { id: 'streak_7', name: '一周坚持', description: '连续7天记录饮食', icon: '🔥', category: AchievementCategory.STREAK, requiredCount: 7 },
  { id: 'streak_30', name: '月度达人', description: '连续30天记录饮食', icon: '💪', category: AchievementCategory.STREAK, requiredCount: 30 },
  { id: 'streak_100', name: '百天守护', description: '连续100天记录饮食', icon: '⭐', category: AchievementCategory.STREAK, requiredCount: 100 },
  { id: 'health_all_green', name: '全A周', description: '连续7天所有食品评分A', icon: '✅', category: AchievementCategory.HEALTH, requiredCount: 7 },
  { id: 'explorer_5_categories', name: '五洲食客', description: '扫描5种不同品类的食品', icon: '🌍', category: AchievementCategory.EXPLORER, requiredCount: 5 },
];

export class RecipeCommunityService {
  private static instance: RecipeCommunityService | null = null;
  private challengeParticipants: Map<string, ChallengeParticipant[]> = new Map();
  private votes: Map<string, RecipePkVote[]> = new Map();
  private leaderboardCache: Map<string, Leaderboard> = new Map();

  static getInstance(): RecipeCommunityService {
    if (!RecipeCommunityService.instance) {
      RecipeCommunityService.instance = new RecipeCommunityService();
    }
    return RecipeCommunityService.instance;
  }

  getActiveChallenges(): ChallengeRule[] {
    return PRESET_CHALLENGES;
  }

  getChallengeById(id: string): ChallengeRule | undefined {
    return PRESET_CHALLENGES.find(c => c.id === id);
  }

  voteRecipe(recipeId: string, voterId: string, voteType: 'up' | 'down'): RecipePkVote {
    let recipeVotes = this.votes.get(recipeId);
    if (!recipeVotes) {
      recipeVotes = [];
      this.votes.set(recipeId, recipeVotes);
    }

    const existing = recipeVotes.findIndex(v => v.voterId === voterId);
    if (existing >= 0) {
      recipeVotes[existing].voteType = voteType;
      recipeVotes[existing].votedAt = Date.now();
      return recipeVotes[existing];
    }

    const vote: RecipePkVote = { recipeId, voterId, voteType, votedAt: Date.now() };
    recipeVotes.push(vote);
    return vote;
  }

  getRecipeVoteStats(recipeId: string): VoteStats {
    const recipeVotes = this.votes.get(recipeId) ?? [];
    const upCount: number = recipeVotes.filter((v: RecipePkVote): boolean => v.voteType === 'up').length;
    const downCount: number = recipeVotes.filter((v: RecipePkVote): boolean => v.voteType === 'down').length;
    const stats: VoteStats = { upCount: upCount, downCount: downCount, score: upCount - downCount };
    return stats;
  }

  getTopRecipes(limit: number = 10): RecipeScoreEntry[] {
    const scores: RecipeScoreEntry[] = [];
    this.votes.forEach((votes: RecipePkVote[], recipeId: string): void => {
      const up: number = votes.filter((v: RecipePkVote): boolean => v.voteType === 'up').length;
      const down: number = votes.filter((v: RecipePkVote): boolean => v.voteType === 'down').length;
      const entry: RecipeScoreEntry = { recipeId: recipeId, score: up - down };
      scores.push(entry);
    });
    return scores.sort((a: RecipeScoreEntry, b: RecipeScoreEntry): number => b.score - a.score).slice(0, limit);
  }

  getLeaderboard(
    challengeId: string,
    period: 'weekly' | 'monthly' | 'all_time' = 'weekly'
  ): Leaderboard {
    const cacheKey = `${challengeId}_${period}`;
    const cached = this.leaderboardCache.get(cacheKey);
    if (cached && Date.now() - cached.updatedAt < 60 * 60 * 1000) {
      return cached;
    }

    const participants = this.challengeParticipants.get(challengeId) ?? [];
    const sorted: ChallengeParticipant[] = [];
    for (const p of participants) {
      sorted.push(p);
    }
    sorted.sort((a: ChallengeParticipant, b: ChallengeParticipant): number => b.score - a.score);

    const top: LeaderboardEntry[] = sorted.slice(0, 20).map((p: ChallengeParticipant, i: number): LeaderboardEntry => {
      const entry: LeaderboardEntry = {
        memberId: p.memberId,
        displayName: p.displayName,
        avatarEmoji: this.getRankEmoji(i),
        score: p.score,
        rank: i + 1,
        trend: i < sorted.length / 2 ? 'up' : 'stable',
        highlight: `${p.submissions}次提交`,
      };
      return entry;
    });

    const leaderboard: Leaderboard = {
      challengeId: challengeId, period: period, topParticipants: top, updatedAt: Date.now(),
    };
    this.leaderboardCache.set(cacheKey, leaderboard);
    return leaderboard;
  }

  getParticipantRank(
    challengeId: string,
    memberId: string
  ): ParticipantRank | null {
    const participants = this.challengeParticipants.get(challengeId);
    if (!participants || participants.length === 0) return null;

    const sorted: ChallengeParticipant[] = [];
    for (const p of participants) {
      sorted.push(p);
    }
    sorted.sort((a: ChallengeParticipant, b: ChallengeParticipant): number => b.score - a.score);
    const idx = sorted.findIndex((p: ChallengeParticipant): boolean => p.memberId === memberId);
    if (idx < 0) return null;

    const rank: ParticipantRank = {
      rank: idx + 1,
      totalParticipants: sorted.length,
      percentile: Math.round(((sorted.length - idx - 1) / sorted.length) * 100),
    };
    return rank;
  }

  getAllAchievements(): Achievement[] {
    const achievements: Achievement[] = [];
    for (const preset of PRESET_ACHIEVEMENTS) {
      const achievement: Achievement = {
        id: preset.id,
        name: preset.name,
        description: preset.description,
        icon: preset.icon,
        category: preset.category,
        requiredCount: preset.requiredCount,
        currentCount: 0,
        unlockedAt: null,
        isUnlocked: false,
      };
      achievements.push(achievement);
    }
    return achievements;
  }

  getCategoryLabel(category: AchievementCategory): string {
    return category;
  }

  getChallengeCategories(): ChallengeCategory[] {
    return Object.values(ChallengeCategory);
  }

  private getRankEmoji(rank: number): string {
    if (rank === 0) return '🥇';
    if (rank === 1) return '🥈';
    if (rank === 2) return '🥉';
    if (rank < 10) return '⭐';
    return '🍀';
  }
}