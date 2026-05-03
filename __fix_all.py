import re

# ========== Fix patterns ==========
# Pattern: standalone `router.back()`
# Need to replace `\n      router.back()` with `\n      try {\n        router.back()\n      } catch (_e) {\n        // ignore\n      }`

# Pattern: standalone `router.pushUrl(...)`
# Need to wrap with try { ... } catch (_e) { // ignore }

files_to_fix = {
    'entry/src/main/ets/components/HotFoodGuideCard.ets': [],
    'entry/src/main/ets/pages/HomePage.ets': [],
    'entry/src/main/ets/pages/ReportPage.ets': [],
    'entry/src/main/ets/pages/BalancePage.ets': [],
    'entry/src/main/ets/pages/BasketCheckPage.ets': [],
    'entry/src/main/ets/pages/WeeklyReportPage.ets': [],
    'entry/src/main/ets/pages/MemberEditPage.ets': [],
    'entry/src/main/ets/components/PaywallDialog.ets': [],
    'entry/src/main/ets/pages/SettingsPage.ets': [],
    'entry/src/main/ets/pages/SharePage.ets': [],
    'entry/src/main/ets/pages/MemberPage.ets': [],
    'entry/src/main/ets/pages/HistoryPage.ets': [],
    'entry/src/main/ets/pages/SubscriptionPage.ets': [],
}

def fix_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    
    # 1. Fix router.back()
    # Pattern: a line that is just `router.back()` preceded by indentation
    content = re.sub(
        r'(\n[\t ]+)router\.back\(\)',
        r'\1try {\n\1  router.back()\n\1} catch (_e) {\n\1  // ignore router.back() error\n\1}',
        content
    )
    
    # 2. Fix router.pushUrl single-line calls
    # Pattern: a line containing `router.pushUrl({...})` on a single line
    content = re.sub(
        r'(\n[\t ]+)router\.pushUrl\(({[^}]*})\)',
        r'\1try {\n\1  router.pushUrl(\2)\n\1} catch (_e) {\n\1  // ignore router.pushUrl error\n\1}',
        content
    )
    
    # 3. Fix multi-line router.pushUrl calls
    # This is trickier - find try-catch-less pushUrl blocks then wrap them
    # We need to find patterns where router.pushUrl appears and there's no 'try {' before it
    # within the same statement context
    
    # Simpler approach: find pushUrl blocks that don't have 'try' before them
    lines = content.split('\n')
    new_lines = []
    i = 0
    while i < len(lines):
        stripped = lines[i].strip()
        
        # Check if this line has router.pushUrl and no try before it
        if 'router.pushUrl' in stripped and not stripped.startswith('try'):
            # Check if we're inside a try block already
            # Look back a few lines
            is_in_try = False
            for j in range(max(0, i-5), i):
                if 'try {' in lines[j]:
                    is_in_try = True
                    break
            
            if not is_in_try:
                # Find the indentation
                indent = lines[i][:len(lines[i]) - len(lines[i].lstrip())]
                
                # Check if this is a multi-line pushUrl
                if '{' in stripped and '}' not in stripped:
                    # Multi-line pushUrl - find the closing
                    start_line = i
                    end_line = i
                    brace_depth = stripped.count('{')
                    while end_line < len(lines) and brace_depth > 0:
                        end_line += 1
                        if end_line < len(lines):
                            brace_depth += lines[end_line].count('{')
                            brace_depth -= lines[end_line].count('}')
                    
                    # Check if try already exists before this block
                    has_try_before = False
                    for j in range(max(0, start_line-3), start_line):
                        if 'try {' in lines[j]:
                            has_try_before = True
                            break
                    
                    if not has_try_before:
                        # Wrap the block
                        new_lines.append(indent + 'try {')
                        for k in range(start_line, end_line + 1):
                            new_lines.append(lines[k])
                        new_lines.append(indent + '} catch (_e) {')
                        new_lines.append(indent + '  // ignore router.pushUrl error')
                        new_lines.append(indent + '}')
                        i = end_line + 1
                        continue
                else:
                    # Single-line pushUrl - check if already wrapped
                    has_try_before = False
                    for j in range(max(0, i-3), i):
                        if 'try {' in lines[j]:
                            has_try_before = True
                            break
                    
                    if not has_try_before:
                        # Wrap single line
                        new_lines.append(indent + 'try {')
                        new_lines.append(lines[i])
                        new_lines.append(indent + '} catch (_e) {')
                        new_lines.append(indent + '  // ignore router.pushUrl error')
                        new_lines.append(indent + '}')
                        i += 1
                        continue
        
        new_lines.append(lines[i])
        i += 1
    
    content = '\n'.join(new_lines)
    
    if content != original:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f'Fixed: {path}')
        return True
    else:
        print(f'No changes: {path}')
        return False

for filepath in files_to_fix:
    fix_file(filepath)
