#!/bin/bash

set -e
LOG=/var/log/webapp-setup.log
exec > >(tee -a "$LOG") 2>&1

echo "[INFO] System update..."
apt-get update
apt-get upgrade -y

echo "[INFO] Installing packages..."
apt-get install -y python3 python3-pip python3-venv git nginx unzip

echo "[INFO] Cloning repo..."
git clone --branch main --single-branch https://github.com/charithsrng/OCI_Proj01.git /opt/webapp

echo "[INFO] Creating Python venv..."
python3 -m venv /opt/webapp/venv
source /opt/webapp/venv/bin/activate

echo "[INFO] Installing Python requirements..."
pip install --upgrade pip
pip install -r /opt/webapp/src/backend/requirements.txt

echo "[INFO] Running initial SQL script..."
cat > /opt/webapp/init_db.py <<EOF
import oracledb

oracledb.init_oracle_client(config_dir="/opt/webapp/wallet")

conn = oracledb.connect(
    user="${db_user}",
    password="${db_password}",
    dsn="${db_service}"
)

cursor = conn.cursor()

cursor.execute(\"""
BEGIN
    EXECUTE IMMEDIATE 'CREATE TABLE employees (
        employee_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        name VARCHAR2(100),
        department VARCHAR2(100),
        salary NUMBER
    )';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -955 THEN RAISE; END IF;
END;
\""")  # Safe re-creation

cursor.executemany(
    "INSERT INTO employees (name, department, salary) VALUES (:1, :2, :3)",
    [
        ("John Doe", "IT", 75000),
        ("Jane Smith", "HR", 65000),
        ("Bob Johnson", "Finance", 85000),
    ]
)

conn.commit()
conn.close()
print("✅ Initialized employee table.")
EOF

/opt/webapp/venv/bin/python /opt/webapp/init_db.py

echo "[INFO] Creating systemd service..."
cat > /etc/systemd/system/webapp.service <<EOF
[Unit]
Description=WebApp Flask Application
After=network.target

[Service]
User=root
WorkingDirectory=/opt/webapp/src/backend
Environment="DB_HOST=${db_host}"
Environment="DB_SERVICE=${db_service}"
Environment="DB_USER=${db_user}"
Environment="DB_PASSWORD=${db_password}"
ExecStart=/opt/webapp/venv/bin/python /opt/webapp/src/backend/app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable webapp
systemctl start webapp

echo "[INFO] Configuring Nginx reverse proxy..."
cat > /etc/nginx/sites-available/webapp <<EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

ln -s /etc/nginx/sites-available/webapp /etc/nginx/sites-enabled
rm /etc/nginx/sites-enabled/default
systemctl restart nginx

echo "[INFO] Setup complete at $(date)"
