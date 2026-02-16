# =============================================================================
# Utils for third-org-server scripts (learning)
# =============================================================================
# This file is sourced by scripts in third-org-server/scripts/. It reuses the
# parent fabric-workspace utils (infoln, successln, fatalln, etc.) so we don't
# duplicate logging and helpers. ROOTDIR is fabric-workspace (parent of third-org-server).
# =============================================================================
ROOTDIR=$(cd "$(dirname "$0")/../.." && pwd)
. "${ROOTDIR}/scripts/utils.sh"
