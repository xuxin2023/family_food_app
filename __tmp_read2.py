lines=open('entry/src/main/ets/pages/ScanPage.ets','r',encoding='utf-8').readlines()
for i in range(996,1016):
    print(f'{i+1}:{lines[i]}',end='')
