import os

def fix_types_in_file(filepath, type_overrides=None):
    """给 describe 内的 it 块变量添加显式类型"""
    if not os.path.exists(filepath):
        print(f'NOT FOUND: {filepath}')
        return
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    lines = content.split('\n')
    new_lines = []
    changes = 0
    
    for line in lines:
        original = line
        
        # 通用模式：const X = new Y() -> const X: Y = new Y()
        import re
        # const engine = new WeeklyReportEngine() -> const engine: WeeklyReportEngine
        m = re.match(r'(\s*const )(\w+)( = new )(\w+)', line)
        if m and ':' not in line:
            var_name = m.group(2)
            class_name = m.group(4)
            line = f'{m.group(1)}{var_name}: {class_name}{m.group(3)}{class_name}'
        
        # 特定类型覆盖
        if type_overrides:
            for var_name, type_name in type_overrides.items():
                pattern = f'const {var_name} = '
                if pattern in line and f'const {var_name}:' not in line:
                    line = line.replace(f'const {var_name} = ', f'const {var_name}: {type_name} = ')
        
        if line != original:
            changes += 1
        new_lines.append(line)
    
    result = '\n'.join(new_lines)
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(result)
    
    print(f'{os.path.basename(filepath)}: Fix applied, {changes} changes')


# Process all engine test files
engine_dir = 'entry/src/ohosTest/ets/test/engine'
files = {
    'ElderFriendlyEngineTest.ets': {'engine': 'ElderFriendlyEngine', 'profile': 'FamilyProfile', 'food': 'FoodLabel', 'rec': 'Recommendation', 'report': 'ElderFriendlyReport'},
    'RecommendationEngineTest.ets': {'engine': 'RecommendationEngine', 'profile': 'FamilyProfile', 'food': 'FoodLabel', 'signal': 'HealthSignal', 'budget': 'SimpleDailyBudget', 'rec': 'Recommendation'},
    'ScanOrchestratorTest.ets': {'engine': 'ScanOrchestrator', 'profile': 'FamilyProfile'},
    'FoodAdapterEngineTest.ets': {'engine': 'FoodAdapterEngine', 'member': 'FamilyMemberSimple', 'food': 'FoodNutrition', 'signal': 'HealthSignal', 'intake': 'Record<string, Object>', 'result': 'EnhancedFoodRecommendation'},
}

for fname, overrides in files.items():
    fix_types_in_file(os.path.join(engine_dir, fname), overrides)

# Also process RecommendationTest.ets (the function return type any issue)
model_dir = 'entry/src/ohosTest/ets/test/model'
fix_types_in_file(os.path.join(model_dir, 'RecommendationTest.ets'), {'rec': 'Recommendation', 'json': 'Object', 'jsonStr': 'string', 'original': 'Recommendation', 'restored': 'Recommendation'})
fix_types_in_file(os.path.join(model_dir, 'FamilyProfileTest.ets'), {'profile': 'FamilyProfile', 'p': 'FamilyProfile', 'food': 'FoodLabel', 'signal': 'HealthSignal', 'budget': 'DailyBudget'})
fix_types_in_file(os.path.join(model_dir, 'FoodLabelTest.ets'), {'food': 'FoodLabel', 'f': 'FoodLabel', 'label': 'FoodLabel'})
fix_types_in_file(os.path.join(model_dir, 'DailyBudgetTest.ets'), {'budget': 'DailyBudget', 'b': 'DailyBudget'})
fix_types_in_file(os.path.join(model_dir, 'HealthSignalTest.ets'), {'signal': 'HealthSignal', 's': 'HealthSignal'})

print('Done!')
