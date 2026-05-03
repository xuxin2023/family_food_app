import re

def fix_router_calls(content):
    """Fix all unprotected router.back() and router.pushUrl calls"""
    
    # Fix router.back() inside onClick callbacks
    # Pattern: onClick(() => { router.back() })
    content = re.sub(
        r'onClick\(\(\)\s*=>\s*\{\s*router\.back\(\)\s*\}\)',
        "onClick(() => { try { router.back() } catch (_e) { /* ignore */ } })",
        content
    )
    
    # Fix router.pushUrl in callbacks - need to handle multi-line
    # Find all onClick(() => { ... }) blocks and check for router.pushUrl inside
    def fix_onclick_block(match):
        full = match.group(0)
        inner = match.group(1)
        if 'router.pushUrl' in inner and 'try {' not in inner:
            # Need to indent properly
            # Find the router.pushUrl line and wrap it
            # Reconstruct: wrap the pushUrl block in try-catch
            lines = inner.split('\n')
            for li, line in enumerate(lines):
                stripped = line.strip()
                if stripped.startswith('router.pushUrl') and 'try {' not in inner:
                    indent = line[:len(line) - len(line.lstrip())]
                    # Check if multi-line
                    if '{' in stripped and '}' not in stripped:
                        # Find closing brace
                        brace_count = stripped.count('{') - stripped.count('}')
                        end_idx = li + 1
                        while end_idx < len(lines) and brace_count > 0:
                            brace_count += lines[end_idx].count('{')
                            brace_count -= lines[end_idx].count('}')
                            end_idx += 1
                        # Wrap
                        lines[li] = indent + 'try {'
                        lines.insert(end_idx + 1, indent + '} catch (_e) {')
                        lines.insert(end_idx + 2, indent + '  // ignore')
                        lines.insert(end_idx + 3, indent + '}')
                        break
                    else:
                        lines[li] = indent + 'try {\n' + line + '\n' + indent + '} catch (_e) {\n' + indent + '  // ignore\n' + indent + '}'
                        break
            inner = '\n'.join(lines)
            return full.replace(match.group(1), inner)
        return full
    
    # Apply to onClick blocks with multi-line content
    content = re.sub(
        r'onClick\(\(\)\s*=>\s*\{([^}]*router\.pushUrl[^}]*)\}\)',
        fix_onclick_block,
        content
    )
    
    return content

files = [
    'entry/src/main/ets/pages/ReportPage.ets',
    'entry/src/main/ets/pages/BalancePage.ets',
    'entry/src/main/ets/pages/BasketCheckPage.ets',
    'entry/src/main/ets/pages/WeeklyReportPage.ets',
    'entry/src/main/ets/pages/MemberEditPage.ets',
    'entry/src/main/ets/components/PaywallDialog.ets',
    'entry/src/main/ets/pages/SettingsPage.ets',
    'entry/src/main/ets/pages/SharePage.ets',
    'entry/src/main/ets/pages/MemberPage.ets',
    'entry/src/main/ets/pages/HistoryPage.ets',
    'entry/src/main/ets/pages/SubscriptionPage.ets',
    'entry/src/main/ets/components/HotFoodGuideCard.ets',
    'entry/src/main/ets/pages/HomePage.ets',
]

for filepath in files:
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    content = fix_router_calls(content)
    
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f'Fixed: {filepath}')
    else:
        print(f'No changes: {filepath}')
