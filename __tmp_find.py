# Find context for router.pushUrl in ScanPage.ets
import json
with open('entry/src/main/ets/pages/ScanPage.ets','r',encoding='utf-8') as f:
    content = f.read()

idx = content.find('router.pushUrl')
if idx >= 0:
    start = max(0, idx-200)
    end = min(len(content), idx+300)
    segment = content[start:end]
    # show with line numbers
    lines_before = content[:start].count('\n')
    print(f'router.pushUrl found at absolute char position {idx}')
    print(f'Approx line: {lines_before+1}')
    print('---')
    seg_lines = segment.split('\n')
    for i,line in enumerate(seg_lines):
        print(f'{lines_before+1+i}:{line!r}')
