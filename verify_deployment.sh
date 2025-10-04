#!/bin/bash
# Deployment Verification Script
# Run this to verify all deployment files are properly configured

set -e

echo "🔍 Verifying Railway Deployment Configuration..."
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

check_file_exists() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} $1 exists"
        return 0
    else
        echo -e "${RED}✗${NC} $1 is missing"
        ((ERRORS++))
        return 1
    fi
}

check_file_not_empty() {
    if [ -s "$1" ]; then
        echo -e "${GREEN}✓${NC} $1 has content"
        return 0
    else
        echo -e "${RED}✗${NC} $1 is empty"
        ((ERRORS++))
        return 1
    fi
}

check_file_contains() {
    if grep -q "$2" "$1"; then
        echo -e "${GREEN}✓${NC} $1 contains '$2'"
        return 0
    else
        echo -e "${YELLOW}⚠${NC} $1 might be missing '$2'"
        ((WARNINGS++))
        return 1
    fi
}

echo "📁 Checking Required Files..."
check_file_exists "Dockerfile"
check_file_exists "entrypoint.sh"
check_file_exists "odoo.conf.template"
check_file_exists "requirements.txt"
check_file_exists ".dockerignore"
check_file_exists "railway.json"
echo ""

echo "📝 Checking File Contents..."
check_file_not_empty "Dockerfile"
check_file_not_empty "entrypoint.sh"
check_file_not_empty "odoo.conf.template"
check_file_not_empty ".dockerignore"
echo ""

echo "🔧 Checking Configuration..."
check_file_contains "odoo.conf.template" "db_host"
check_file_contains "odoo.conf.template" "admin_passwd"
check_file_contains "odoo.conf.template" "addons_path"
echo ""

echo "🐳 Checking Dockerfile..."
check_file_contains "Dockerfile" "FROM odoo:18.0"
check_file_contains "Dockerfile" "COPY addons /mnt/extra-addons"
check_file_contains "Dockerfile" "ENTRYPOINT"
echo ""

echo "🚀 Checking Entrypoint..."
check_file_contains "entrypoint.sh" "#!/bin/bash"
if grep -q "exit 0" entrypoint.sh | grep -q "DO_INIT_DB"; then
    echo -e "${RED}✗${NC} entrypoint.sh still exits after DB init (OLD VERSION)"
    ((ERRORS++))
else
    echo -e "${GREEN}✓${NC} entrypoint.sh continues after DB init (FIXED)"
fi
echo ""

echo "📦 Checking Custom Addons..."
if [ -d "addons/fieldservice_navigate" ]; then
    echo -e "${GREEN}✓${NC} Custom addon 'fieldservice_navigate' found"
    if [ -f "addons/fieldservice_navigate/__manifest__.py" ]; then
        echo -e "${GREEN}✓${NC} Manifest file exists"
    else
        echo -e "${RED}✗${NC} Manifest file missing"
        ((ERRORS++))
    fi
else
    echo -e "${YELLOW}⚠${NC} Custom addon directory not found"
    ((WARNINGS++))
fi
echo ""

echo "📊 Verification Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "Your deployment is ready for Railway."
    echo ""
    echo "Next steps:"
    echo "  1. git add ."
    echo "  2. git commit -m 'Fix Railway deployment'"
    echo "  3. git push"
    echo "  4. Set environment variables in Railway"
    echo "  5. Deploy!"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ ${WARNINGS} warning(s) found${NC}"
    echo ""
    echo "Review warnings above. You may still be able to deploy."
    exit 0
else
    echo -e "${RED}✗ ${ERRORS} error(s) found${NC}"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}⚠ ${WARNINGS} warning(s) found${NC}"
    fi
    echo ""
    echo "Please fix the errors above before deploying."
    exit 1
fi
