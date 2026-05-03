lines=open('entry/src/main/ets/pages/ScanPage.ets','r',encoding='utf-8').readlines()
print('Total lines:', len(lines))

print('=== Line 155-162 ===')
for i in range(154,162):
    print(f'{i+1}:{lines[i]}',end='')

print('=== Line 344-350 ===')
for i in range(343,350):
    print(f'{i+1}:{lines[i]}',end='')

print('=== Line 879-886 ===')
for i in range(878,886):
    print(f'{i+1}:{lines[i]}',end='')

print('=== Line 1005-1016 ===')
for i in range(1004,1016):
    print(f'{i+1}:{lines[i]}',end='')
