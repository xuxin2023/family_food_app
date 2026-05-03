import os
import re

base_dir = "E:/APP/family_food_app/entry/src/ohosTest/ets/test/uitest"

# Step 1: Find all files that contain findText
for fname in os.listdir(base_dir):
    if not fname.endswith('.ets'):
        continue
    fpath = os.path.join(base_dir, fname)
    with open(fpath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if 'findText' not in content:
        continue
    
    print(f"Processing: {fname}")
    
    # Replace findText calls with findComponent(ON.text()) pattern
    # Pattern: await driver.findText('xxx', 0, undefined, undefined)
    # Replace with: await driver.findComponent(ON.text('xxx'))
    
    # Also replace variable assignments that check !== null
    # const xxx = await driver.findText('txt', 0, undefined, undefined);
    # -> const xxx = await driver.findComponent(ON.text('txt'));
    
    # Pattern 1: driver.findText('...', 0, undefined, undefined)
    content = re.sub(
        r"driver\.findText\(('[^']*')\s*,\s*0\s*,\s*undefined\s*,\s*undefined\)",
        r"driver.findComponent(ON.text(\1))",
        content
    )
    
    # Pattern 2: driver.findText("...", 0, undefined, undefined) 
    content = re.sub(
        r'driver\.findText\("[^"]*"\s*,\s*0\s*,\s*undefined\s*,\s*undefined\)',
        lambda m: f'driver.findComponent(ON.text({m.group(0).split("(")[1].split(",")[0].strip()}))',
        content
    )
    
    # For import: add ON if needed
    if 'ON' not in content and 'findComponent' in content:
        content = content.replace(
            "import { Driver, ON, Component, UiDirection } from '@kit.TestKit';",
            "import { Driver, ON, Component, UiDirection } from '@kit.TestKit';"
        )
    
    # Remove the let driver: Driver at describe level - won't compile properly
    # Replace with local declarations in each it block
    
    with open(fpath, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"  Fixed: {fname}")

print("Done!")
