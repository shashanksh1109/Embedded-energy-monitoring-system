"""
schema_loader.py - Lambda function to load database schema
Uses pg8000 (pure Python) instead of psycopg2 to avoid binary compatibility issues
Always runs CREATE TABLE IF NOT EXISTS so new tables get added automatically.
"""
import json
import os
import boto3
import pg8000

def get_secret(secret_arn, region):
    client = boto3.client('secretsmanager', region_name=region)
    response = client.get_secret_value(SecretId=secret_arn)
    return json.loads(response['SecretString'])

def split_sql(sql):
    """Split SQL into statements on ';' - but not inside '...' strings or -- comments.
    Comments are removed. (Good for plain DDL/DML; this schema uses no $$ blocks.)"""
    statements, current = [], []
    i, n = 0, len(sql)
    in_string = False
    while i < n:
        ch = sql[i]
        if in_string:
            current.append(ch)
            if ch == "'":
                if i + 1 < n and sql[i + 1] == "'":   # '' = an escaped quote
                    current.append("'")
                    i += 1
                else:
                    in_string = False
        elif ch == "'":
            in_string = True
            current.append(ch)
        elif ch == "-" and i + 1 < n and sql[i + 1] == "-":
            while i < n and sql[i] != "\n":           # skip the comment
                i += 1
            current.append("\n")
        elif ch == ";":
            stmt = "".join(current).strip()
            if stmt:
                statements.append(stmt)
            current = []
        else:
            current.append(ch)
        i += 1
    stmt = "".join(current).strip()
    if stmt:
        statements.append(stmt)
    return statements


def lambda_handler(event, context):
    region     = os.environ['AWS_REGION']
    secret_arn = os.environ['DB_SECRET_ARN']
    db_host    = os.environ['DB_HOST']
    db_name    = os.environ['DB_NAME']

    print(f"[SCHEMA] Connecting to {db_host}/{db_name}")
    creds = get_secret(secret_arn, region)

    conn = pg8000.connect(
        host     = db_host,
        port     = 5432,
        database = db_name,
        user     = creds['username'],
        password = creds['password']
    )
    conn.autocommit = True
    cursor = conn.cursor()

    # Download schema from S3
    print("[SCHEMA] Downloading schema from S3...")
    s3     = boto3.client('s3', region_name=region)
    bucket = os.environ['SCHEMA_BUCKET']
    key    = os.environ['SCHEMA_KEY']

    response   = s3.get_object(Bucket=bucket, Key=key)
    schema_sql = response['Body'].read().decode('utf-8')

    # Always execute schema - CREATE TABLE IF NOT EXISTS is idempotent
    # This ensures new tables added later get created automatically
    print("[SCHEMA] Executing schema...")
    # split_sql() skips -- comments and ';' inside quoted text. The old
    # schema_sql.split(';') cut statements at a ';' inside a comment, which
    # silently broke CREATE TABLE devices on AWS.
    statements = split_sql(schema_sql)
    success = 0
    skipped = 0
    for stmt in statements:
        try:
            cursor.execute(stmt)
            success += 1
        except Exception as e:
            first_line = stmt.splitlines()[0][:80]
            print(f"[SCHEMA] Skipped: {first_line} -> {str(e).splitlines()[0]}")
            skipped += 1

    print(f"[SCHEMA] Done: {success} statements succeeded, {skipped} skipped")

    # Give the restricted API role (created by schema.sql, without a password)
    # its password from Secrets Manager. ALTER ROLE can't take a query
    # parameter, so the password is generated as letters and digits only
    # (see secrets.tf) and checked here before it is embedded.
    api_secret_arn = os.environ.get('EMS_API_SECRET_ARN')
    api_role_ok = False
    if api_secret_arn:
        api_creds = get_secret(api_secret_arn, region)
        password = api_creds['password']
        if not password.isalnum():
            raise ValueError("ems_api password must be letters and digits only")
        cursor.execute(f"ALTER ROLE ems_api WITH LOGIN PASSWORD '{password}'")
        api_role_ok = True
        print("[SCHEMA] ems_api role password set")

    cursor.close()
    conn.close()
    return {"statusCode": 200,
            "body": f"Schema loaded: {success} succeeded, {skipped} skipped; ems_api password set: {api_role_ok}"}