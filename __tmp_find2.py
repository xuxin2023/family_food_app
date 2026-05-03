with open('entry/src/main/ets/pages/ScanPage.ets','r',encoding='utf-8') as f:
    content = f.read()
idx = content.find('clearTimeout')
# find all occurrences
positions = []
start = 0
while True:
    pos = content.find('clearTimeout', start)
    if pos == -1:
        break
    lines_before = content[:pos].count('\n')
    positions.append((pos, lines_before+1))
    start = pos + 1
print(f'Found {len(positions)} occurrences of clearTimeout in ScanPage.ets:')
for pos, line_num in positions:
    # Get surrounding context
    start_idx = max(0, pos-80)
    end_idx = min(len(content), pos+80)
    context = content[start_idx:end_idx]
    print(f'  Line {line_num}: ...{context!r}...')
