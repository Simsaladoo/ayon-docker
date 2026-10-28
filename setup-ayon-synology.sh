#!/bin/bash
# AYON on Synology — automated setup script
# Run this on the NAS via SSH: bash setup-ayon-synology.sh
# Must be run from /volume1/docker/ayon-docker or edited to match your path

set -e

NAS_IP="192.168.50.14"
AYON_PORT="5050"
PROJECT_NAME="WoA_2702"
COMPOSE_FILE="docker-compose.synology.yml"

echo "=== AYON Synology Setup ==="
echo "Working directory: $(pwd)"
echo ""

# -------------------------------------------------------
# 1. Ensure directory structure exists
# -------------------------------------------------------
echo "[1/6] Creating directory structure..."
mkdir -p storage/db
mkdir -p addons
mkdir -p settings
echo "   Directories ready."

# -------------------------------------------------------
# 2. Copy settings template (seed admin + service user)
# -------------------------------------------------------
echo "[2/6] Writing settings/template.json..."
cat > settings/template.json << 'JSONEOF'
{
    "users": [
        {
            "name": "admin",
            "password": "admin",
            "fullName": "Ayon admin",
            "isAdmin": true
        },
        {
            "name": "service",
            "apiKey": "veryinsecurapikey",
            "isService": true
        }
    ]
}
JSONEOF
echo "   settings/template.json written."

# -------------------------------------------------------
# 3. Ensure docker-compose.synology.yml exists
# -------------------------------------------------------
echo "[3/6] Checking docker-compose.synology.yml..."
if [ ! -f "$COMPOSE_FILE" ]; then
    echo "   ERROR: $COMPOSE_FILE not found in $(pwd)"
    echo "   Copy it from your Windows machine to this folder first."
    exit 1
fi
echo "   Compose file found."

# -------------------------------------------------------
# 4. Start the stack
# -------------------------------------------------------
echo "[4/6] Starting AYON stack (this may take a minute to pull images)..."
/usr/local/bin/docker-compose -f "$COMPOSE_FILE" up -d

echo "   Waiting for containers to be healthy..."
sleep 15

# -------------------------------------------------------
# 5. Apply settings template (seeds admin/admin + service user)
# -------------------------------------------------------
echo "[5/6] Applying settings template to seed users..."
/usr/local/bin/docker-compose -f "$COMPOSE_FILE" exec -T server python -m setup - < settings/template.json
/usr/local/bin/docker-compose -f "$COMPOSE_FILE" exec server bash /backend/reload.sh
echo "   Users seeded: admin/admin + service API key."

# -------------------------------------------------------
# 6. Show status and next steps
# -------------------------------------------------------
echo ""
echo "=== Setup Complete ==="
echo ""
echo "Containers:"
/usr/local/bin/docker-compose -f "$COMPOSE_FILE" ps
echo ""
echo "AYON Web UI: http://${NAS_IP}:${AYON_PORT}"
echo "Login: admin / admin  (change password immediately!)"
echo ""
echo "=== Manual steps still needed ==="
echo "1. Open http://${NAS_IP}:${AYON_PORT}/settings/anatomyPresets"
echo "   - Create anatomy preset 'Tailwind Custom'"
echo "   - Add roots: artsource -> D:/UE/Tailwind_R E B U I L D"
echo "   - Add roots: ue_project -> D:/UE/Engines/Tailwinds_2702/Projects/WoA_2702"
echo "   - Add roots: work -> {root[artsource]}/work"
echo "   - Add roots: publish -> {root[artsource]}/publish"
echo "   - Set file templates WITHOUT {version} (you version in Perforce)"
echo "   - Add folder types per asset type (character, vehicle, texture, etc.)"
echo ""
echo "2. Open http://${NAS_IP}:${AYON_PORT}/settings/projects"
echo "   - Create project '$PROJECT_NAME' using 'Tailwind Custom' anatomy"
echo ""
echo "3. Point Ayon Launcher on workstations at http://${NAS_IP}:${AYON_PORT}"
echo ""
echo "Done."
