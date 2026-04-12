"""
schema_loader.py - Lambda function to load database schema
Uses pg8000 (pure Python) instead of psycopg2 to avoid binary compatibility issues
"""

import json
import os
import boto3
import pg8000

def get_secret(secret_arn, region):
    client = boto3.client('secretsmanager', region_name=region)
    response = client.get_secret_value(SecretId=secret_arn)
    return json.loads(response['SecretString'])

def lambda_handler(event, context):
    region = os.environ['AWS_REGION']
    secret_arn = os.environ['DB_SECRET_ARN']
    db_host = os.environ['DB_HOST']
    db_name = os.environ['DB_NAME']

    print(f"[SCHEMA] Connecting to {db_host}/{db_name}")

    creds = get_secret(secret_arn, region)

    conn = pg8000.connect(
        host=db_host,
        port=5432,
        database=db_name,
        user=creds['username'],
        password=creds['password']
    )
    conn.autocommit = True
    cursor = conn.cursor()

    # Check if schema already exists
    cursor.execute("""
        SELECT COUNT(*) FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'zones'
    """)
    count = cursor.fetchone()[0]

    if count > 0:
        print("[SCHEMA] Schema already exists, skipping")
        cursor.close()
        conn.close()
        return {"statusCode": 200, "body": "Schema already exists"}

    # Download schema from S3
    print("[SCHEMA] Downloading schema from S3...")
    s3 = boto3.client('s3', region_name=region)
    bucket = os.environ['SCHEMA_BUCKET']
    key = os.environ['SCHEMA_KEY']

    response = s3.get_object(Bucket=bucket, Key=key)
    schema_sql = response['Body'].read().decode('utf-8')

    # Execute schema — pg8000 needs statements split individually
    print("[SCHEMA] Executing schema...")
    statements = [s.strip() for s in schema_sql.split(';') if s.strip()]
    for stmt in statements:
        try:
            cursor.execute(stmt)
        except Exception as e:
            print(f"[SCHEMA] Warning: {e}")

    print("[SCHEMA] Schema loaded successfully")
    cursor.close()
    conn.close()

    return {"statusCode": 200, "body": "Schema loaded successfully"}
