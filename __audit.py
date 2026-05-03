import glob, os

# Find all .ets files that might have Function may throw exceptions issues
targets = ['IapService.ets', 'AnalyticsService.ets', 'HotFoodGuideCard.ets', 
           'HomePage.ets', 'ReportPage.ets', 'BalancePage.ets', 'BasketCheckPage.ets',
           'WeeklyReportPage.ets', 'MemberEditPage.ets', 'PaywallDialog.ets',
           'SettingsPage.ets', 'SharePage.ets', 'MemberPage.ets', 'HistoryPage.ets',
           'SubscriptionPage.ets', 'MainNavigation.ets']

for tgt in targets:
    for root, dirs, files in os.walk('entry/src/main/ets'):
        for f in files:
            if f == tgt:
                path = os.path.join(root, f)
                with open(path, 'r', encoding='utf-8') as fp:
                    content = fp.read()
                
                # Find clearTimeout, clearInterval, router.back, router.pushUrl
                for func in ['clearTimeout', 'clearInterval', 'router.back()', 'router.pushUrl']:
                    if func in content:
                        # Count occurrences
                        count = content.count(func)
                        # For each, check if surrounded by try-catch
                        positions = []
                        s = 0
                        while True:
                            p = content.find(func, s)
                            if p == -1:
                                break
                            # Check if 'try' appears within 50 chars before
                            before = max(0, p-100)
                            context_before = content[before:p]
                            has_try = 'try {' in context_before
                            positions.append((content[:p].count('\n')+1, has_try))
                            s = p + 1
                        
                        unprotected = [ln for ln, has_t in positions if not has_t]
                        if unprotected:
                            print(f'{tgt}: {func} - unprotected at lines {unprotected}')
