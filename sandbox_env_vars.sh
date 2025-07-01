# NSO Version
NSO_VERSION=6.4.4.1

# NSO Container Image Path for deployment (used by load_nso_image.sh)
NSO_CONTAINER_IMAGE_PATH=~

# Container Configuration
CONTAINER_IP=10.10.20.57
BASE_IMAGE=cisco-nso-prod
TAG_IMAGE=cisco-nso-prod-sandbox

# SSH Configuration for Sandbox Access
SSH_KEY_PATH=~/.ssh/sandbox_key
SANDBOX_USER=developer
SANDBOX_IP=10.10.20.52

EXPECTED_CONTAINER_COUNT=1
CONTAINER_NAME="sandbox-nso"