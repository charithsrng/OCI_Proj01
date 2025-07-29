#!/bin/bash

# Update system
apt-get update
apt-get upgrade -y

# Install required packages
apt-get install -y python3 python3-pip python3-venv git nginx

# Clone the repository
git clone --branch main --single-branch https://github.com/charithsrng/OCI_Proj01.git /opt/webapp

# Set up virtual environment
python3 -m venv /opt/webapp/venv
source /opt/webapp/venv/bin/activate

# Install Python dependencies
pip install -r /opt/webapp/src/backend/requirements.txt

# Create systemd service for Flask app
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

# Enable and start the service
systemctl daemon-reload
systemctl enable webapp
systemctl start webapp

# Configure Nginx as reverse proxy
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