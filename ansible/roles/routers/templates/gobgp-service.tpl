[Unit]
Description=GoBGP daemon server
After=network.target syslog.target
ConditionPathExists=/home/gobgp.conf

[Service]
Type=simple
ExecStart=/usr/bin/gobgpd -l debug -f /home/gobgp.conf --disable-stdlog --syslog yes
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s TERM $MAINPID

[Install]
WantedBy=multi-user.target
