with open('entry/src/main/ets/pages/ScanPage.ets','r',encoding='utf-8') as f:
    content = f.read()

# Find router.back()
idx = content.find('router.back()')
if idx >= 0:
    lines_before = content[:idx].count('\n')
    print(f'router.back() at line {lines_before+1}')
    start = max(0, idx-300)
    end = min(len(content), idx+100)
    segment = content[start:end]
    seg_lines = segment.split('\n')
    for i,line in enumerate(seg_lines):
        print(f'{lines_before+1+i-len(seg_lines)+len(seg_lines)}:{line!r}')

# Also find all Function may throw remaining issues
# Find router.back and router.pushUrl
for func_name in ['router.back()', 'router.pushUrl']:
    positions = []
    s = 0
    while True:
        p = content.find(func_name, s)
        if p == -1:
            break
        ln = content[:p].count('\n') + 1
        positions.append(ln)
        s = p + 1
    print(f'\n{func_name} total: {len(positions)} occurrences at lines: {positions}')
