import os, glob

test_dir = r'E:\APP\family_food_app\entry\src\ohosTest\ets\test'
count = 0

for f in sorted(glob.glob(os.path.join(test_dir, '**/*.ets'), recursive=True)):
    content = open(f, 'r', encoding='utf-8').read()
    original = content
    
    # 替换错误的 ../../../../main/ets/ -> ../../../../src/main/ets/
    content = content.replace("'../../../../main/ets/", "'../../../../src/main/ets/")
    
    if content != original:
        open(f, 'w', encoding='utf-8').write(content)
        count += 1
        print(f'FIXED: {os.path.relpath(f, test_dir)}')

print(f'\nTotal files fixed: {count}')
