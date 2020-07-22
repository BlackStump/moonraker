#!/bin/bash
# This script installs Moonraker on a Debian machine 
# using systemd

PYTHONDIR="${HOME}/moonraker-env"
SYSTEMDDIR="/etc/systemd/system"
MOONRAKER_USER=$USER

# Step 1:  Verify Klipper has been installed
check_klipper()
{
    if [ "$(systemctl list-units --full -all -t service --no-legend | grep -F "klipper.service")" ]; then
        echo "Klipper service found!"
    else
        echo "Klipper service not found, please install Klipper first"
        exit -1
    fi

}

# Step 2: Install packages
install_packages()
{
    PKGLIST="python3-virtualenv python3-dev nginx"

    
    # Install desired packages
    report_status "Installing packages..."
    sudo apt-get install --yes ${PKGLIST}
}

# Step 3: Create python virtual environment
create_virtualenv()
{
    report_status "Updating python virtual environment..."

    # Create virtualenv if it doesn't already exist
    [ ! -d ${PYTHONDIR} ] && virtualenv -p /usr/bin/python3 ${PYTHONDIR}

    # Install/update dependencies
    ${PYTHONDIR}/bin/pip install -r ${SRCDIR}/scripts/moonraker-requirements.txt
}

# Step 4: Install startup script
install_script()
{
# Create systemd service file
    MOONRAKER_LOG=/tmp/moonraker.log
    report_status "Installing Moonraker start script..."
    sudo /bin/sh -c "cat > $SYSTEMDDIR/moonraker.service" << EOF
#Systemd service file for klipper
[Unit]
Description=Starts moonraker on startup
After=network.target

[Install]
WantedBy=multi-user.target

[Service]
Type=simple
User=$MOONRAKER_USER
RemainAfterExit=yes
ExecStart=${PYTHONDIR}/bin/python ${SRCDIR}/moonraker/moonraker.py 
Restart=always
RestartSec=10
EOF
# Use systemctl to enable the klipper systemd service script
    sudo systemctl enable moonraker.service
}


# Step 5: Start server
start_software()
{
    report_status "Launching Moonraker API Server..."
    sudo systemctl stop klipper
    sudo systemctl restart moonraker
    sudo systemctl start klipper
}

# Helper functions
report_status()
{
    echo -e "\n\n###### $1"
}

verify_ready()
{
    if [ "$EUID" -eq 0 ]; then
        echo "This script must not run as root"
        exit -1
    fi
}

# Force script to exit if an error occurs
set -e

# Find SRCDIR from the pathname of this script
SRCDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"

# Run installation steps defined above
verify_ready
check_klipper
install_packages
create_virtualenv
install_script
start_software
