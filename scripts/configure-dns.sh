#!/usr/bin/env bash
#
# Configure AWS Route 53 DNS for BandLab Upptime
# Creates a CNAME record pointing upptime.bandlab.com to bandlab.github.io
#
# Prerequisites:
#   - AWS CLI installed and configured with appropriate credentials
#   - Permissions: route53:ListHostedZones, route53:ChangeResourceRecordSets
#
# Usage: ./scripts/configure-dns.sh
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
DOMAIN="bandlab.com"
SUBDOMAIN="upptime"
FULL_DOMAIN="${SUBDOMAIN}.${DOMAIN}"
GITHUB_PAGES_TARGET="bandlab.github.io"
TTL=300

# Helper functions
info() { echo -e "${BLUE}ℹ${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }

prompt_yn() {
    local prompt="$1"
    local default="${2:-y}"
    local answer
    if [[ "$default" == "y" ]]; then
        read -rp "$prompt [Y/n]: " answer
        answer="${answer:-y}"
    else
        read -rp "$prompt [y/N]: " answer
        answer="${answer:-n}"
    fi
    [[ "${answer,,}" == "y" ]]
}

# Execute AWS CLI command with preview and confirmation
# Usage: aws_cmd [--no-confirm] <aws args...>
aws_cmd() {
    local no_confirm=false
    if [[ "${1:-}" == "--no-confirm" ]]; then
        no_confirm=true
        shift
    fi
    
    echo
    echo -e "${YELLOW}▶ aws $*${NC}"
    
    if [[ "$no_confirm" == "false" ]]; then
        if ! prompt_yn "  Execute this command?" "y"; then
            echo "  Skipped."
            return 1
        fi
    fi
    
    aws "$@"
}

# Check prerequisites
check_prerequisites() {
    info "Checking prerequisites..."
    
    if ! command -v aws &> /dev/null; then
        error "AWS CLI is not installed."
        echo "  Install with: brew install awscli"
        echo "  Then configure: aws configure"
        exit 1
    fi
    
    # Check AWS credentials
    echo
    echo -e "${YELLOW}▶ aws sts get-caller-identity${NC}"
    local identity_result
    if ! identity_result=$(aws sts get-caller-identity --output json 2>&1); then
        error "AWS CLI is not configured or credentials are invalid."
        echo "  Run: aws configure"
        echo "  Or set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables."
        exit 1
    fi
    
    local identity
    identity=$(echo "$identity_result" | jq -r '.Arn')
    success "AWS authenticated as: $identity"
    echo
}

# Find the hosted zone ID for the domain
find_hosted_zone() {
    info "Looking for hosted zone for ${DOMAIN}..."
    
    echo
    echo -e "${YELLOW}▶ aws route53 list-hosted-zones --query \"HostedZones[?Name=='${DOMAIN}.']\" --output json${NC}"
    
    local zones
    zones=$(aws route53 list-hosted-zones --query "HostedZones[?Name=='${DOMAIN}.']" --output json)
    
    if [[ "$zones" == "[]" ]]; then
        error "No hosted zone found for ${DOMAIN}"
        echo "  Available hosted zones:"
        echo
        echo -e "${YELLOW}▶ aws route53 list-hosted-zones --query 'HostedZones[*].[Name,Id]' --output table${NC}"
        aws route53 list-hosted-zones --query 'HostedZones[*].[Name,Id]' --output table
        exit 1
    fi
    
    # Extract zone ID (format: /hostedzone/XXXXX -> XXXXX)
    HOSTED_ZONE_ID=$(echo "$zones" | jq -r '.[0].Id' | sed 's|/hostedzone/||')
    
    if [[ -z "$HOSTED_ZONE_ID" || "$HOSTED_ZONE_ID" == "null" ]]; then
        error "Could not extract hosted zone ID"
        exit 1
    fi
    
    success "Found hosted zone: ${HOSTED_ZONE_ID}"
}

# Check if record already exists
check_existing_record() {
    info "Checking for existing record: ${FULL_DOMAIN}..."
    
    echo
    echo -e "${YELLOW}▶ aws route53 list-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --query \"ResourceRecordSets[?Name=='${FULL_DOMAIN}.']\" --output json${NC}"
    
    local existing
    existing=$(aws route53 list-resource-record-sets \
        --hosted-zone-id "$HOSTED_ZONE_ID" \
        --query "ResourceRecordSets[?Name=='${FULL_DOMAIN}.']" \
        --output json)
    
    if [[ "$existing" != "[]" ]]; then
        local record_type
        local record_value
        record_type=$(echo "$existing" | jq -r '.[0].Type')
        record_value=$(echo "$existing" | jq -r '.[0].ResourceRecords[0].Value // .[0].AliasTarget.DNSName // "N/A"')
        
        warn "Record already exists:"
        echo "  Type:  ${record_type}"
        echo "  Value: ${record_value}"
        echo
        
        if [[ "$record_value" == "${GITHUB_PAGES_TARGET}." || "$record_value" == "${GITHUB_PAGES_TARGET}" ]]; then
            success "Record is already correctly configured!"
            if ! prompt_yn "  Update anyway?" "n"; then
                exit 0
            fi
        else
            warn "Record points to a different target."
            if ! prompt_yn "  Replace with ${GITHUB_PAGES_TARGET}?" "y"; then
                echo "  Aborted."
                exit 0
            fi
        fi
        
        RECORD_ACTION="UPSERT"
    else
        info "No existing record found. Will create new CNAME."
        RECORD_ACTION="UPSERT"
    fi
}

# Create or update the DNS record
create_dns_record() {
    info "Creating CNAME record: ${FULL_DOMAIN} -> ${GITHUB_PAGES_TARGET}"
    
    # Create the change batch JSON
    local change_batch
    change_batch=$(cat <<EOF
{
    "Comment": "GitHub Pages custom domain for BandLab Upptime status page",
    "Changes": [
        {
            "Action": "${RECORD_ACTION}",
            "ResourceRecordSet": {
                "Name": "${FULL_DOMAIN}",
                "Type": "CNAME",
                "TTL": ${TTL},
                "ResourceRecords": [
                    {
                        "Value": "${GITHUB_PAGES_TARGET}"
                    }
                ]
            }
        }
    ]
}
EOF
)
    
    echo
    echo "  Change to be applied:"
    echo "    Domain: ${FULL_DOMAIN}"
    echo "    Type:   CNAME"
    echo "    Target: ${GITHUB_PAGES_TARGET}"
    echo "    TTL:    ${TTL} seconds"
    echo
    
    if ! prompt_yn "  Apply this DNS change?" "y"; then
        echo "  Aborted."
        exit 0
    fi
    
    # Show the command
    echo
    echo -e "${YELLOW}▶ aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch '<change-batch-json>' --output json${NC}"
    echo
    echo "  Change batch JSON:"
    echo "$change_batch" | sed 's/^/    /'
    echo
    
    if ! prompt_yn "  Execute this command?" "y"; then
        echo "  Aborted."
        exit 0
    fi
    
    # Apply the change
    local result
    result=$(aws route53 change-resource-record-sets \
        --hosted-zone-id "$HOSTED_ZONE_ID" \
        --change-batch "$change_batch" \
        --output json)
    
    local change_id
    local status
    change_id=$(echo "$result" | jq -r '.ChangeInfo.Id' | sed 's|/change/||')
    status=$(echo "$result" | jq -r '.ChangeInfo.Status')
    
    success "DNS change submitted!"
    echo "  Change ID: ${change_id}"
    echo "  Status:    ${status}"
    
    # Wait for propagation
    if prompt_yn "  Wait for DNS propagation?" "y"; then
        info "Waiting for DNS change to propagate (this may take 30-60 seconds)..."
        
        echo
        echo -e "${YELLOW}▶ aws route53 wait resource-record-sets-changed --id $change_id${NC}"
        
        aws route53 wait resource-record-sets-changed --id "$change_id"
        
        success "DNS change propagated!"
    fi
}

# Verify the record
verify_record() {
    echo
    info "Verifying DNS record..."
    
    echo
    echo -e "${YELLOW}▶ aws route53 list-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --query \"ResourceRecordSets[?Name=='${FULL_DOMAIN}.']\" --output json${NC}"
    
    local result
    result=$(aws route53 list-resource-record-sets \
        --hosted-zone-id "$HOSTED_ZONE_ID" \
        --query "ResourceRecordSets[?Name=='${FULL_DOMAIN}.']" \
        --output json)
    
    if [[ "$result" != "[]" ]]; then
        local record_value
        record_value=$(echo "$result" | jq -r '.[0].ResourceRecords[0].Value')
        
        if [[ "$record_value" == "${GITHUB_PAGES_TARGET}" ]]; then
            success "DNS record verified!"
            echo
            echo "  ${FULL_DOMAIN} -> ${GITHUB_PAGES_TARGET}"
        else
            warn "Record value doesn't match expected target"
            echo "  Expected: ${GITHUB_PAGES_TARGET}"
            echo "  Actual:   ${record_value}"
        fi
    else
        error "Could not verify record"
    fi
}

# Configure GitHub Pages custom domain
configure_github_pages() {
    echo
    info "Configuring GitHub Pages custom domain..."
    
    if ! command -v gh &> /dev/null; then
        warn "GitHub CLI not available. Skipping GitHub Pages configuration."
        echo "  Manually set custom domain at:"
        echo "  https://github.com/bandlab/bandlab-upptime/settings/pages"
        return
    fi
    
    # Set custom domain via API
    if gh api "repos/bandlab/bandlab-upptime/pages" \
        --method PUT \
        --field cname="${FULL_DOMAIN}" \
        --silent 2>/dev/null; then
        success "GitHub Pages custom domain set to: ${FULL_DOMAIN}"
    else
        warn "Could not set GitHub Pages custom domain via API."
        echo "  Manually set at: https://github.com/bandlab/bandlab-upptime/settings/pages"
    fi
}

# Print summary
print_summary() {
    echo
    echo -e "${GREEN}━━━ Configuration Complete ━━━${NC}"
    echo
    echo "  DNS Record:"
    echo "    ${FULL_DOMAIN} CNAME ${GITHUB_PAGES_TARGET}"
    echo
    echo "  Status page will be available at:"
    echo "    https://${FULL_DOMAIN}"
    echo
    echo "  Note: HTTPS certificate provisioning may take a few minutes."
    echo "  Check status at: https://github.com/bandlab/bandlab-upptime/settings/pages"
    echo
}

# Main
main() {
    echo
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║       AWS Route 53 DNS Configuration                       ║${NC}"
    echo -e "${BLUE}║       for BandLab Upptime Status Page                      ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    check_prerequisites
    find_hosted_zone
    check_existing_record
    create_dns_record
    verify_record
    configure_github_pages
    print_summary
}

main "$@"
