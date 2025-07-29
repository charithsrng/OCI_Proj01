

from flask import Flask, jsonify
import oracledb
import os

app = Flask(__name__)

# Database configuration from environment variables
DB_USER = os.getenv('DB_USER')
DB_PASSWORD = os.getenv('DB_PASSWORD')
DB_HOST = os.getenv('DB_HOST')
DB_SERVICE = os.getenv('DB_SERVICE')

def get_db_connection():
    dsn = oracledb.makedsn(DB_HOST, 1521, service_name=DB_SERVICE)
    connection = oracledb.connect(user=DB_USER, password=DB_PASSWORD, dsn=dsn)
    return connection

@app.route('/')
def home():
    return "Welcome to the OCI WebApp!"

@app.route('/employees')
def get_employees():
    try:
        connection = get_db_connection()
        cursor = connection.cursor()
        cursor.execute("SELECT * FROM employees")
        result = cursor.fetchall()
        cursor.close()
        connection.close()
        return jsonify(result)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)