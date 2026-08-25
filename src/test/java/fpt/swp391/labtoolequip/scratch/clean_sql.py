import sys

with open('database/lab_asset_management_full.sql', 'r', encoding='utf-8') as f:
    content = f.read()

# Let's inspect the structure of lab_asset_management_full.sql
print("File length:", len(content))
