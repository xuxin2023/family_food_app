with open('entry/src/main/ets/pages/ScanPage.ets','r',encoding='utf-8') as f:
    content = f.read()

# Find ALL router.pushUrl occurrences after line 1020
idx = content.find('router.pushUrl', 31350)
while idx != -1:
    line_no = content[:idx].count('\n') + 1
    start = max(0, idx - 200)
    end = min(len(content), idx + 200)
    context = content[start:end]
    print(f'=== router.pushUrl at line {line_no} ===')
    context_lines = context.split('\n')
    base_line = content[:start].count('\n')
    for i, l in enumerate(context_lines):
        print(f'  {base_line+1+i}:{l!r}')
    idx = content.find('router.pushUrl', idx + 1)
