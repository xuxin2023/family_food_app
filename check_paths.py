import os, glob, re

test_dir = r'E:\APP\family_food_app\entry\src\ohosTest\ets\test'
found = False
for f in sorted(glob.glob(os.path.join(test_dir, '**/*.ets'), recursive=True)):
    content = open(f, 'r', encoding='utf-8').read()
    for m in re.findall(r"from '([^']+)'", content):
        if m.startswith('.'):
            resolved = os.path.normpath(os.path.join(os.path.dirname(f), m))
            if not os.path.exists(resolved) and not os.path.exists(resolved + '.ets'):
                print(f'BROKEN: {os.path.relpath(f, test_dir)}')
                print(f'  Path: {m}')
                print(f'  Resolved: {resolved}')
                found = True

if not found:
    print('ALL PATHS ARE CORRECT!')
