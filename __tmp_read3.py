lines=open('entry/src/main/ets/pages/ScanPage.ets','r',encoding='utf-8').readlines()
for i in range(1018,1030):
    if i < len(lines):
        print(f'{i+1}:{lines[i]}',end='')
print(f'Total lines: {len(lines)}')
