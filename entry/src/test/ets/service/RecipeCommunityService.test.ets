// RecipeCommunityService.test.ets
// 社区功能单元测试 — PK投票/挑战赛/排行榜/成就
import { TestSuite, TestCase, expect } from '@ohos/hypium';
import {
  RecipeCommunityService, ChallengeCategory, AchievementCategory,
  RecipePkVote, ChallengeRule, Leaderboard, Achievement
} from 'hsp_service';

export default function recipeCommTest(): TestSuite {
  const suite: TestSuite = new TestSuite(
  const svc = RecipeCommunityService.getInstance();

  suite.addTest(new TestCase('getActiveChallenges returns 6', () => {
    const challenges = svc.getActiveChallenges();
    expect(challenges.length).assertEqual(6);
  }));

  suite.addTest(new TestCase('getChallengeById returns correct challenge', () => {
    const c = svc.getChallengeById('low_sodium_week');
    expect(c).assertTrue(c !== undefined);
    expect(c!.category).assertEqual(ChallengeCategory.LOW_SODIUM);
  }));

  suite.addTest(new TestCase('getChallengeById returns undefined for invalid', () => {
    expect(svc.getChallengeById('nonexistent')).assertTrue(svc.getChallengeById('nonexistent') === undefined);
  }));

  suite.addTest(new TestCase('voteRecipe adds new vote', () => {
    const vote = svc.voteRecipe('recipe_1', 'user_a', 'up');
    expect(vote.recipeId).assertEqual('recipe_1');
    expect(vote.voterId).assertEqual('user_a');
    expect(vote.voteType).assertEqual('up');
  }));

  suite.addTest(new TestCase('voteRecipe toggles existing vote', () => {
    svc.voteRecipe('recipe_1', 'user_a', 'up');
    const updated = svc.voteRecipe('recipe_1', 'user_a', 'down');
    expect(updated.voteType).assertEqual('down');
  }));

  suite.addTest(new TestCase('getRecipeVoteStats computes correctly', () => {
    svc.voteRecipe('recipe_stats', 'u1', 'up');
    svc.voteRecipe('recipe_stats', 'u2', 'up');
    svc.voteRecipe('recipe_stats', 'u3', 'down');
    const stats = svc.getRecipeVoteStats('recipe_stats');
    expect(stats.upCount).assertEqual(2);
    expect(stats.downCount).assertEqual(1);
    expect(stats.score).assertEqual(1);
  }));

  suite.addTest(new TestCase('getRecipeVoteStats empty returns zeros', () => {
    const stats = svc.getRecipeVoteStats('nonexistent_recipe');
    expect(stats.upCount).assertEqual(0);
    expect(stats.score).assertEqual(0);
  }));

  suite.addTest(new TestCase('getTopRecipes sorts by score', () => {
    svc.voteRecipe('top_r1', 'u1', 'up');
    svc.voteRecipe('top_r1', 'u2', 'up');
    svc.voteRecipe('top_r2', 'u1', 'down');
    const top = svc.getTopRecipes(5);
    expect(top.length).assertTrue(top.length >= 1);
    expect(top[0].score).assertTrue(top[0].score > 0);
  }));

  suite.addTest(new TestCase('getLeaderboard returns valid structure', () => {
    const lb = svc.getLeaderboard('low_sodium_week', 'weekly');
    expect(lb.challengeId).assertEqual('low_sodium_week');
    expect(lb.period).assertEqual('weekly');
    expect(Array.isArray(lb.topParticipants)).assertTrue();
  }));

  suite.addTest(new TestCase('getAllAchievements returns 11 preset achievements', () => {
    const achievements = svc.getAllAchievements();
    expect(achievements.length).assertEqual(11);
    expect(achievements.every((a: Achievement) => a.id.length > 0)).assertTrue();
  }));

  suite.addTest(new TestCase('achievement categories are correctly assigned', () => {
    const achievements = svc.getAllAchievements();
    const scanning = achievements.filter((a: Achievement) => a.category === AchievementCategory.SCANNING);
    expect(scanning.length).assertEqual(3);
    const cooking = achievements.filter((a: Achievement) => a.category === AchievementCategory.COOKING);
    expect(cooking.length).assertEqual(2);
  }));

  suite.addTest(new TestCase('getChallengeCategories returns 6 categories', () => {
    expect(svc.getChallengeCategories().length).assertEqual(6);
  }));

  suite.addTest(new TestCase('getCategoryLabel returns category value', () => {
    expect(svc.getCategoryLabel(AchievementCategory.SCANNING)).assertEqual('扫码达人');
  }));

  suite.addTest(new TestCase('getParticipantRank returns null for empty', () => {
    const rank = svc.getParticipantRank('empty_challenge', 'user_x');
    expect(rank).assertTrue(rank === null);
  }));

  return suite;
}