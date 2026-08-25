import re

with open('database/lab_asset_management_full.sql', 'r', encoding='utf-8') as f:
    text = f.read()

batches = re.split(r'(?i)\r?\nGO\r?\n', text)
print(f"Total batches: {len(batches)}")
for idx, b in enumerate(batches):
    first_line = b.strip().split('\n')[0] if b.strip() else 'EMPTY'
    print(f"Batch {idx+1} ({len(b)} chars): {first_line[:80]}")
