// AppThemeState.test.ets
// V5 应用主题状态管理单元测试
import { TestSuite, TestCase, expect } from '@ohos/hypium';
import { AppThemeState, ColorScheme } from 'hsp_core';

export default function appThemeTest(): TestSuite {
  const suite: TestSuite = new TestSuite(

  suite.addTest(new TestCase('initial state is light', () => {
    const state: AppThemeState = new AppThemeState()
    expect(state.colorScheme).assertEqual(ColorScheme.LIGHT);
    expect(state.eyeCareEnabled).assertFalse();
    expect(state.eyeCareIntensity).assertEqual(0.5);
  }));

  suite.addTest(new TestCase('applySystemColorMode_dark', () => {
    const state: AppThemeState = new AppThemeState()
    state.applySystemColorMode(1);
    expect(state.colorScheme).assertEqual(ColorScheme.DARK);
  }));

  suite.addTest(new TestCase('applySystemColorMode_light_with_no_eye_care', () => {
    const state: AppThemeState = new AppThemeState()
    state.applySystemColorMode(0);
    expect(state.colorScheme).assertEqual(ColorScheme.LIGHT);
  }));

  suite.addTest(new TestCase('applySystemColorMode_light_with_eye_care', () => {
    const state: AppThemeState = new AppThemeState()
    state.enableEyeCare(true);
    state.applySystemColorMode(0);
    expect(state.colorScheme).assertEqual(ColorScheme.EYE_CARE);
  }));

  suite.addTest(new TestCase('enableEyeCare_true', () => {
    const state: AppThemeState = new AppThemeState()
    state.enableEyeCare(true);
    expect(state.eyeCareEnabled).assertTrue();
    expect(state.colorScheme).assertEqual(ColorScheme.EYE_CARE);
  }));

  suite.addTest(new TestCase('enableEyeCare_false', () => {
    const state: AppThemeState = new AppThemeState()
    state.enableEyeCare(true);
    state.enableEyeCare(false);
    expect(state.eyeCareEnabled).assertFalse();
    expect(state.colorScheme).assertEqual(ColorScheme.LIGHT);
  }));

  suite.addTest(new TestCase('eyeCare_does_not_override_dark', () => {
    const state: AppThemeState = new AppThemeState()
    state.applySystemColorMode(1);
    state.enableEyeCare(true);
    expect(state.colorScheme).assertEqual(ColorScheme.DARK);
  }));

  suite.addTest(new TestCase('setEyeCareIntensity_clamps', () => {
    const state: AppThemeState = new AppThemeState()
    state.setEyeCareIntensity(0);
    expect(state.eyeCareIntensity).assertEqual(0.1);
    state.setEyeCareIntensity(2);
    expect(state.eyeCareIntensity).assertEqual(1.0);
    state.setEyeCareIntensity(0.3);
    expect(state.eyeCareIntensity).assertEqual(0.3);
  }));

  suite.addTest(new TestCase('getEyeCareColorFilter_disabled', () => {
    const state: AppThemeState = new AppThemeState()
    expect(state.getEyeCareColorFilter()).assertEqual('transparent');
  }));

  suite.addTest(new TestCase('getEyeCareColorFilter_enabled', () => {
    const state: AppThemeState = new AppThemeState()
    state.enableEyeCare(true);
    const filter = state.getEyeCareColorFilter();
    expect(filter).assertTrue(filter.startsWith('rgba(255, 220, 180, '));
  }));

  suite.addTest(new TestCase('getEffectiveColorScheme', () => {
    const state: AppThemeState = new AppThemeState()
    expect(state.getEffectiveColorScheme()).assertEqual('light');
    state.applySystemColorMode(1);
    expect(state.getEffectiveColorScheme()).assertEqual('dark');
  }));

  return suite;
}