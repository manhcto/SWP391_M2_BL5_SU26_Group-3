import sys, re

with open('database/lab_asset_management_full.sql', 'r', encoding='utf-8') as f:
    sql = f.read()

tables = re.findall(r'CREATE\s+TABLE\s+([^\s\(]+)', sql, re.IGNORECASE)
print(f"Found {len(tables)} CREATE TABLE statements in lab_asset_management_full.sql:")
for idx, t in enumerate(tables):
    print(f"{idx+1}. {t}")
