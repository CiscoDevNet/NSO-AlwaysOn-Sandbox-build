#!/bin/bash

set -e

echo "=============================================="
echo "Starting NSO Demo Environment Setup"
echo "=============================================="

cd $HOME

echo "=============================================="
echo "Phase 1: NETSIM Network Configuration"
echo "Deleting existing netsim network..."
ncs-netsim delete-network 
echo "Creating Netsim network"
ncs-netsim create-network $NCS_DIR/packages/neds/cisco-ios-cli-3.8 3 dist-rtr0
ncs-netsim add-to-network $NCS_DIR/packages/neds/cisco-ios-cli-3.8 2 edge-sw0
ncs-netsim add-to-network $NCS_DIR/packages/neds/cisco-ios-cli-3.8 2 internet-rtr0
ncs-netsim add-to-network $NCS_DIR/packages/neds/cisco-asa-cli-6.6 2 edge-firewall0
ncs-netsim add-to-network $NCS_DIR/packages/neds/cisco-nx-cli-3.0 3 dist-sw0
ncs-netsim add-to-network $NCS_DIR/packages/neds/cisco-iosxr-cli-3.5 3 core-rtr0
echo "Starting netsim network..."
ncs-netsim start 

echo "=============================================="
echo "Phase 2: Device Initialization and Sync"
ncs-netsim ncs-xml-init > /tmp/netsim_devices_init.xml
ncs_load -lm /tmp/netsim_devices_init.xml
ncs_load -lm /tmp/config/devices/groups.xml
echo 'devices sync-from' | ncs_cli -Cu admin

echo "=============================================="
echo "Phase 3: Services Configuration"
echo "Loading services configuration..."
# Services configuration.
ncs_cli -Cu admin --noaaa --cwd /tmp/config/services << EOF
config
load merge services.conf
commit and-quit
exit
EOF

echo "=============================================="
echo "Phase 4: User Access Configuration"
echo "Configuring Developer user with READ-ONLY access..."
# Give Developer user READ-ONLY access to NSO at the end.
# Allow users to interact with netsim devices.
# Only works at runtime.
ncs_cli -Cu admin << EOF
config
nacm rule-list oper rule devices path /devices access-operations exec action permit
nacm rule-list oper cmdrule deny-commit command commit action deny
nacm rule-list oper cmdrule deny-config command config action deny
nacm rule-list oper cmdrule deny-configure command configure action deny
move nacm rule-list oper cmdrule any-command last
commit and-quit
exit
EOF


echo "=============================================="
echo "Phase 5: configuring tacacs authentication"

# ncs_load -l -m /tmp/config/phase0/cisco-nso-tacacs-auth.xml

echo "=============================================="
echo "NSO Demo Environment Setup Complete!"
echo "=============================================="
cd -