[Unit]
Description=Inter-site DIMINET daemon server
After=network.target syslog.target

[Service]
User=stack
WorkingDirectory=/opt/stack/intersite/
ExecStart=/usr/bin/python3 /opt/stack/intersite/app.py
RuntimeDirectoryMode=777

[Install]
WantedBy=multi-user.target


