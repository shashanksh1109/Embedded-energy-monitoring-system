"""
test_db.py - Quick connection test for db_writer

Run: python3 test_db.py
"""

from db_writer import DBWriter

db = DBWriter()
ok = db.connect()
print('Connection:', 'OK' if ok else 'FAILED')
db.disconnect()