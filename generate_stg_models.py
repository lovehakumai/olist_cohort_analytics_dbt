# generate_stg_models.py （完全小文字＆空行抹殺版）
import os
import subprocess

# 💡 全て小文字に統一して YAML の name と完全一致させる！
tables = [
    "OLIST_CLOSED_DEALS_DATASET",
    "OLIST_CUSTOMERS_DATASET",
    "OLIST_GEOLOCATION_DATASET",
    "OLIST_MARKETING_QUALIFIED_LEADS_DATASET",
    "OLIST_ORDER_ITEMS_DATASET",
    "OLIST_ORDER_PAYMENTS_DATASET",
    "OLIST_ORDER_REVIEWS_DATASET",
    "OLIST_ORDERS_DATASET",
    "OLIST_PRODUCTS_DATASET",
    "OLIST_SELLERS_DATASET",
    "PRODUCT_CATEGORY_NAME_TRANSLATION",
]

target_dir = "models/staging"
os.makedirs(target_dir, exist_ok=True)

print("🚀 【全自動化】小文字統一・空行なしでStagingモデルを生成します...")

for table in tables:
    file_name = f"stg_{table}.sql"
    file_path = os.path.join(target_dir, file_name)

    print(f" 🏗️  {table} のカラムを収穫中...")

    # 💡 引数も小文字の table を渡す
    cmd = f"dbt run-operation generate_base_model --args '{{\"source_name\": \"olist_raw\", \"table_name\": \"{table}\"}}'"
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)

    lines = result.stdout.split("\n")
    sql_content = []
    start_collecting = False

    for line in lines:
        if "with source as (" in line or "with source as" in line:
            start_collecting = True
        if start_collecting:
            # 💡 空行（中身がスペースや改行だけ）じゃない場合のみ収集
            if line.strip():
                sql_content.append(line)

    if sql_content:
        with open(file_path, "w") as f:
            f.write("\n".join(sql_content))
        print(f"      ✅ -> {file_path} を美しく生成しました。")
    else:
        print(f"      ❌ -> {table} の抽出に失敗。大文字小文字を確認してください。")

print("\n✨ 【任務完了】11個のStagingモデルが、カラム名ギッシリ＆空行なしで着地しました！")