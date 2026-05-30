import psycopg2
try:
    psycopg2.connect('postgresql://postgres:password123@127.0.0.1:5432/agrovision_db')
    print("Success 127.0.0.1")
except Exception as e:
    print("Failed 127.0.0.1", repr(e))
