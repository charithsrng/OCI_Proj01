from flask import Flask, jsonify
import oracledb
import os
import logging

# Set up basic logging
logging.basicConfig(level=logging.INFO)

app = Flask(__name__)

# --- Configuration from environment variables ---
# The user, password, and service name for the database
DB_USER = os.getenv('DB_USER')
DB_PASSWORD = os.getenv('DB_PASSWORD')
# For ADB, DB_SERVICE should be the net service name from tnsnames.ora
# e.g., 'myadb_high', 'myadb_medium'
DB_SERVICE = os.getenv('DB_SERVICE') 
# Path to the unzipped wallet directory
WALLET_DIR = os.getenv('WALLET_DIR')

# --- Initialize Oracle Client ---
# This must be done once when the application starts.
try:
    if WALLET_DIR:
        logging.info(f"Initializing Oracle Client with wallet from: {WALLET_DIR}")
        oracledb.init_oracle_client(config_dir=WALLET_DIR)
    else:
        logging.error("WALLET_DIR environment variable is not set. Cannot connect to ADB.")
except oracledb.ProgrammingError:
    # This error is raised if init_oracle_client is called more than once.
    # It's safe to ignore in a web app where modules might be reloaded.
    logging.info("Oracle Client already initialized.")
    pass
except Exception as e:
    logging.error(f"Error initializing Oracle Client: {e}")


def get_db_connection():
    """Establishes a secure connection to the Autonomous Database using a wallet."""
    # For ADB, the DSN is the service name from the wallet's tnsnames.ora file.
    # The python-oracledb library uses the pre-initialized wallet for credentials.
    connection = oracledb.connect(user=DB_USER, password=DB_PASSWORD, dsn=DB_SERVICE)
    return connection

@app.route('/')
def home():
    return "Welcome to the OCI WebApp (ADB Connected)!"

@app.route('/employees')
def get_employees():
    # Check if configuration is missing
    if not all([DB_USER, DB_PASSWORD, DB_SERVICE, WALLET_DIR]):
        return jsonify({"error": "Database environment variables are not fully configured."}), 500

    try:
        connection = get_db_connection()
        cursor = connection.cursor()
        cursor.execute("SELECT * FROM employees")
        
        # Fetch column names to create a list of dictionaries
        columns = [col[0] for col in cursor.description]
        rows = [dict(zip(columns, row)) for row in cursor.fetchall()]
        
        cursor.close()
        connection.close()
        return jsonify(rows)
    except Exception as e:
        logging.error(f"Database error: {e}")
        return jsonify({"error": f"Database connection or query failed: {e}"}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
