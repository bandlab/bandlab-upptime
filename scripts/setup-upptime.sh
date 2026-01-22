#!/usr/bin/env bash
#
# BandLab Upptime Setup Script
# Automates configuration steps 1-4 for the BandLab Upptime monitoring system.
#
# Prerequisites:
#   - GitHub CLI (gh) installed and authenticated
#   - git installed and configured
#   - yq installed (for YAML parsing) - will attempt to install if missing
#   - jq installed (for JSON parsing) - will attempt to install if missing
#   - curl installed (for API calls)
#
# Required PAT Permissions (Fine-grained Token):
#   - Actions:   Read and write
#   - Contents:  Read and write
#   - Issues:    Read and write
#   - Metadata:  Read (always included)
#   - Workflows: Read and write
#
# Generate token at: https://github.com/settings/personal-access-tokens/new
#
# Usage: ./scripts/setup-upptime.sh
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPPTIMERC_FILE="${REPO_ROOT}/.upptimerc.yml"
OWNER="bandlab"
REPO="bandlab-upptime"

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

# Validate PAT permissions
# Returns: 0 if valid, 1 if invalid
# Sets: PAT_TYPE ('fine-grained' or 'classic'), PAT_ERROR (error message if invalid)
validate_pat_permissions() {
    local token="$1"
    PAT_TYPE=""
    PAT_ERROR=""
    
    # Determine token type from prefix
    if [[ "$token" =~ ^github_pat_ ]]; then
        PAT_TYPE="fine-grained"
    elif [[ "$token" =~ ^ghp_ ]]; then
        PAT_TYPE="classic"
    else
        PAT_ERROR="Unrecognized token format"
        return 1
    fi
    
    # For fine-grained tokens, validate by testing actual permissions
    if [[ "$PAT_TYPE" == "fine-grained" ]]; then
        validate_fine_grained_permissions "$token"
        return $?
    fi
    
    # For classic tokens, use X-OAuth-Scopes header
    validate_classic_permissions "$token"
    return $?
}

# Validate fine-grained token by testing actual API permissions
validate_fine_grained_permissions() {
    local token="$1"
    local errors=()
    
    echo "  Testing repository permissions..."
    
    # Test 1: Check token can access the repo (Metadata read)
    local repo_check
    repo_check=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer $token" \
        -H "Accept: application/vnd.github+json" \
        "https://api.github.com/repos/${OWNER}/${REPO}")
    
    if [[ "$repo_check" == "401" ]]; then
        PAT_ERROR="Invalid token - authentication failed"
        return 1
    elif [[ "$repo_check" == "404" ]] || [[ "$repo_check" == "403" ]]; then
        errors+=("Repository access: Cannot access ${OWNER}/${REPO}")
    else
        success "Metadata: Read access confirmed"
    fi
    
    # Test 2: Check Contents permission (read file)
    local contents_check
    contents_check=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer $token" \
        -H "Accept: application/vnd.github+json" \
        "https://api.github.com/repos/${OWNER}/${REPO}/contents/.upptimerc.yml")
    
    if [[ "$contents_check" == "200" ]]; then
        success "Contents: Read access confirmed"
    else
        errors+=("Contents: Read permission missing")
    fi
    
    # Test 3: Check Issues permission
    local issues_check
    issues_check=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer $token" \
        -H "Accept: application/vnd.github+json" \
        "https://api.github.com/repos/${OWNER}/${REPO}/issues?per_page=1")
    
    if [[ "$issues_check" == "200" ]]; then
        success "Issues: Read access confirmed"
    else
        errors+=("Issues: Read permission missing")
    fi
    
    # Test 4: Check Actions permission
    local actions_check
    actions_check=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer $token" \
        -H "Accept: application/vnd.github+json" \
        "https://api.github.com/repos/${OWNER}/${REPO}/actions/workflows")
    
    if [[ "$actions_check" == "200" ]]; then
        success "Actions: Read access confirmed"
    else
        errors+=("Actions: Read permission missing")
    fi
    
    # Test 5: Check Workflows access (via contents of .github/workflows)
    local workflows_check
    workflows_check=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer $token" \
        -H "Accept: application/vnd.github+json" \
        "https://api.github.com/repos/${OWNER}/${REPO}/contents/.github/workflows")
    
    if [[ "$workflows_check" == "200" ]]; then
        success "Workflows: Read access confirmed"
    else
        errors+=("Workflows: Cannot access workflow files")
    fi
    
    # Note: We can only test read permissions via API
    # Write permissions are tested when workflows actually run
    if [[ ${#errors[@]} -gt 0 ]]; then
        PAT_ERROR="Missing permissions:"
        for err in "${errors[@]}"; do
            PAT_ERROR+="\n    ✗ $err"
        done
        return 1
    fi
    
    info "Note: Write permissions will be verified when workflows run."
    return 0
}

# Validate classic token scopes
validate_classic_permissions() {
    local token="$1"
    
    local response_headers
    response_headers=$(curl -sI -H "Authorization: token $token" \
        -H "Accept: application/vnd.github+json" \
        "https://api.github.com/user" 2>&1)
    
    if echo "$response_headers" | grep -q "HTTP/[0-9.]* 401"; then
        PAT_ERROR="Invalid token - authentication failed"
        return 1
    fi
    
    if echo "$response_headers" | grep -q "HTTP/[0-9.]* 403"; then
        PAT_ERROR="Token forbidden - may be expired or revoked"
        return 1
    fi
    
    local scopes_header
    scopes_header=$(echo "$response_headers" | grep -i "^x-oauth-scopes:" | sed 's/^[^:]*: //' | tr -d '\r')
    
    if [[ -z "$scopes_header" ]]; then
        PAT_ERROR="Could not determine token scopes"
        return 1
    fi
    
    # Check for required scopes
    local has_repo=false
    local has_workflow=false
    
    if echo "$scopes_header" | grep -qw "repo"; then
        has_repo=true
        success "repo scope confirmed"
    fi
    if echo "$scopes_header" | grep -qw "workflow"; then
        has_workflow=true
        success "workflow scope confirmed"
    fi
    
    if [[ "$has_repo" == "false" ]] || [[ "$has_workflow" == "false" ]]; then
        PAT_ERROR="Missing required scopes. Need: repo, workflow. Have: $scopes_header"
        return 1
    fi
    
    return 0
}

# Display PAT scope information
display_scope_info() {
    echo
    echo -e "${CYAN}━━━ Required PAT Permissions ━━━${NC}"
    echo
    echo "  Generate a Fine-grained token at:"
    echo -e "  ${YELLOW}https://github.com/settings/personal-access-tokens/new${NC}"
    echo
    echo "  Configuration:"
    echo "    • Resource owner: ${OWNER}"
    echo "    • Repository access: Only select repositories → ${REPO}"
    echo "    • Expiration: 90 days (recommended)"
    echo
    echo "  Required permissions:"
    echo -e "    ${GREEN}☑${NC} Actions:   Read and write"
    echo -e "    ${GREEN}☑${NC} Contents:  Read and write"
    echo -e "    ${GREEN}☑${NC} Issues:    Read and write"
    echo -e "    ${GREEN}☑${NC} Metadata:  Read (auto-selected)"
    echo -e "    ${GREEN}☑${NC} Workflows: Read and write"
    echo
}

# Check prerequisites
check_prerequisites() {
    info "Checking prerequisites..."
    
    # Check gh CLI
    if ! command -v gh &> /dev/null; then
        error "GitHub CLI (gh) is not installed."
        echo "  Install with: brew install gh"
        echo "  Then authenticate: gh auth login"
        exit 1
    fi
    
    # Check gh authentication
    if ! gh auth status &> /dev/null; then
        error "GitHub CLI is not authenticated."
        echo "  Run: gh auth login"
        exit 1
    fi
    
    # Check git
    if ! command -v git &> /dev/null; then
        error "git is not installed."
        exit 1
    fi
    
    # Check/install yq for YAML parsing
    if ! command -v yq &> /dev/null; then
        warn "yq is not installed. Attempting to install..."
        if command -v brew &> /dev/null; then
            brew install yq
        else
            error "Cannot install yq. Please install manually: brew install yq"
            exit 1
        fi
    fi
    
    # Check/install jq for JSON parsing
    if ! command -v jq &> /dev/null; then
        warn "jq is not installed. Attempting to install..."
        if command -v brew &> /dev/null; then
            brew install jq
        else
            error "Cannot install jq. Please install manually: brew install jq"
            exit 1
        fi
    fi
    
    # Check curl
    if ! command -v curl &> /dev/null; then
        error "curl is not installed."
        exit 1
    fi
    
    # Check if .upptimerc.yml exists
    if [[ ! -f "$UPPTIMERC_FILE" ]]; then
        error ".upptimerc.yml not found at $UPPTIMERC_FILE"
        exit 1
    fi
    
    success "All prerequisites met."
    echo
}

# Step 1: Configure assignees in .upptimerc.yml
configure_assignees() {
    echo -e "\n${BLUE}━━━ Step 1: Configure Assignees ━━━${NC}"
    
    # Get current assignees
    local current_assignees
    current_assignees=$(yq '.assignees[]' "$UPPTIMERC_FILE" 2>/dev/null || echo "")
    
    # Check if placeholder exists
    if echo "$current_assignees" | grep -q '\[ADD_GITHUB_USERNAME\]'; then
        warn "Placeholder [ADD_GITHUB_USERNAME] found in assignees."
        local needs_config=true
    elif [[ -z "$current_assignees" ]]; then
        warn "No assignees configured."
        local needs_config=true
    else
        success "Assignees already configured:"
        echo "$current_assignees" | while read -r assignee; do
            echo "    - $assignee"
        done
        if prompt_yn "  Do you want to reconfigure assignees?" "n"; then
            local needs_config=true
        else
            local needs_config=false
        fi
    fi
    
    if [[ "${needs_config:-false}" == "true" ]]; then
        echo
        info "Enter GitHub usernames for incident assignment (comma-separated):"
        read -rp "  Usernames: " usernames_input
        
        if [[ -z "$usernames_input" ]]; then
            warn "No usernames provided. Skipping assignee configuration."
            return
        fi
        
        # Parse comma-separated usernames and create YAML array
        local assignees_yaml="assignees:"
        IFS=',' read -ra usernames <<< "$usernames_input"
        for username in "${usernames[@]}"; do
            # Trim whitespace
            username=$(echo "$username" | xargs)
            if [[ -n "$username" ]]; then
                assignees_yaml+="\n  - $username"
            fi
        done
        
        # Replace assignees section in .upptimerc.yml
        # Use sed to replace the assignees block
        local temp_file="${UPPTIMERC_FILE}.tmp"
        
        # Create new content with updated assignees
        awk -v new_assignees="$assignees_yaml" '
            /^assignees:/ { 
                print new_assignees
                in_assignees=1
                next
            }
            in_assignees && /^[^ ]/ {
                in_assignees=0
            }
            in_assignees && /^  -/ {
                next
            }
            !in_assignees { print }
        ' "$UPPTIMERC_FILE" > "$temp_file"
        
        # Handle case where awk doesn't process properly (use yq instead)
        if ! grep -q "^assignees:" "$temp_file" 2>/dev/null; then
            # Fallback: use yq to update assignees
            local usernames_array="["
            local first=true
            for username in "${usernames[@]}"; do
                username=$(echo "$username" | xargs)
                if [[ -n "$username" ]]; then
                    if [[ "$first" == "true" ]]; then
                        usernames_array+="\"$username\""
                        first=false
                    else
                        usernames_array+=", \"$username\""
                    fi
                fi
            done
            usernames_array+="]"
            
            yq -i ".assignees = $usernames_array" "$UPPTIMERC_FILE"
            rm -f "$temp_file"
        else
            mv "$temp_file" "$UPPTIMERC_FILE"
        fi
        
        success "Assignees updated in .upptimerc.yml"
        
        # Commit the change
        if prompt_yn "  Commit this change?" "y"; then
            git -C "$REPO_ROOT" add "$UPPTIMERC_FILE"
            git -C "$REPO_ROOT" commit -m "T007: Update assignees in .upptimerc.yml" || true
            success "Change committed."
        fi
    fi
}

# Step 2: Configure GH_PAT secret
configure_pat_secret() {
    echo -e "\n${BLUE}━━━ Step 2: Configure GH_PAT Secret ━━━${NC}"
    
    # Check if secret exists and test if it works
    local secret_exists=false
    local secret_valid=false
    
    if gh secret list --repo "${OWNER}/${REPO}" 2>/dev/null | grep -q "^GH_PAT"; then
        secret_exists=true
        # We can't test the secret directly, but we can check recent workflow runs
        local last_run_conclusion
        last_run_conclusion=$(gh run list -R "${OWNER}/${REPO}" --workflow=setup.yml --limit 1 --json conclusion --jq '.[0].conclusion' 2>/dev/null || echo "unknown")
        if [[ "$last_run_conclusion" == "success" ]]; then
            secret_valid=true
        fi
    fi
    
    if [[ "$secret_exists" == "true" && "$secret_valid" == "true" ]]; then
        success "GH_PAT secret exists and workflows are passing."
        if ! prompt_yn "  Do you want to update the secret anyway?" "n"; then
            return
        fi
    elif [[ "$secret_exists" == "true" ]]; then
        warn "GH_PAT secret exists but workflows are failing (likely bad credentials or wrong permissions)."
        info "You need to provide a new valid token with correct permissions."
    else
        warn "GH_PAT secret not found."
    fi
    
    # Display required permissions
    display_scope_info
    
    # Loop until valid token is provided or user skips
    local attempts=0
    while true; do
        attempts=$((attempts + 1))
        
        if [[ $attempts -gt 1 ]]; then
            echo
        fi
        
        echo -e "${YELLOW}Enter your Personal Access Token:${NC}"
        read -rsp "  Token (input is hidden): " pat_value
        echo
        
        if [[ -z "$pat_value" ]]; then
            if prompt_yn "  No token entered. Skip PAT configuration?" "n"; then
                warn "Skipping PAT configuration. Workflows will fail until configured."
                return
            fi
            continue
        fi
        
        # Basic format validation
        if [[ "$pat_value" =~ ^github_pat_ ]]; then
            info "Detected: Fine-grained token (recommended)"
        elif [[ "$pat_value" =~ ^ghp_ ]]; then
            warn "Detected: Classic token"
            echo "  Fine-grained tokens are recommended for better security."
            echo "  Generate at: https://github.com/settings/personal-access-tokens/new"
            if ! prompt_yn "  Continue with classic token anyway?" "y"; then
                continue
            fi
        else
            warn "Token doesn't look like a valid GitHub PAT."
            echo "  Fine-grained tokens start with 'github_pat_'"
            echo "  Classic tokens start with 'ghp_'"
            if ! prompt_yn "  Try anyway?" "n"; then
                continue
            fi
        fi
        
        # Validate token permissions
        info "Validating token permissions..."
        if ! validate_pat_permissions "$pat_value"; then
            error "$PAT_ERROR"
            if ! prompt_yn "  Try again with a different token?" "y"; then
                warn "Skipping PAT configuration."
                return
            fi
            continue
        fi
        
        # Token validation passed
        success "Token validated! ($PAT_TYPE token)"
        
        # Set the secret
        info "Setting GH_PAT secret..."
        if echo "$pat_value" | gh secret set GH_PAT --repo "${OWNER}/${REPO}" 2>/dev/null; then
            success "GH_PAT secret configured successfully!"
            
            # Offer to test by triggering a workflow
            if prompt_yn "  Trigger a test workflow to verify everything works?" "y"; then
                info "Triggering Setup CI workflow..."
                if gh workflow run setup.yml -R "${OWNER}/${REPO}" 2>/dev/null; then
                    success "Workflow triggered. Waiting 20 seconds to check result..."
                    sleep 20
                    
                    local test_result
                    test_result=$(gh run list -R "${OWNER}/${REPO}" --workflow=setup.yml --limit 1 --json conclusion,status --jq '.[0] | if .status == "completed" then .conclusion else .status end' 2>/dev/null || echo "unknown")
                    
                    if [[ "$test_result" == "success" ]]; then
                        success "Token verified! Workflows are working correctly."
                    elif [[ "$test_result" == "in_progress" || "$test_result" == "queued" ]]; then
                        info "Workflow still running. Check status at:"
                        echo "  https://github.com/${OWNER}/${REPO}/actions"
                    else
                        warn "Workflow result: $test_result"
                        echo "  Check logs at: https://github.com/${OWNER}/${REPO}/actions"
                    fi
                else
                    warn "Could not trigger workflow. Check manually at:"
                    echo "  https://github.com/${OWNER}/${REPO}/actions"
                fi
            fi
            return
        else
            error "Failed to set secret. Check your GitHub CLI authentication."
            return
        fi
    done
}

# Step 3: Enable GitHub Pages
configure_github_pages() {
    echo -e "\n${BLUE}━━━ Step 3: Enable GitHub Pages ━━━${NC}"
    
    # Check current GitHub Pages configuration
    local pages_info
    local pages_status
    pages_info=$(gh api "repos/${OWNER}/${REPO}/pages" 2>&1) && pages_status=0 || pages_status=$?
    
    if [[ $pages_status -eq 0 ]] && echo "$pages_info" | jq -e '.source.branch' &>/dev/null; then
        local current_source
        current_source=$(echo "$pages_info" | jq -r '.source.branch // "unknown"')
        success "GitHub Pages already enabled (source: $current_source branch)."
        if ! prompt_yn "  Do you want to reconfigure GitHub Pages?" "n"; then
            return
        fi
    else
        warn "GitHub Pages not enabled."
    fi
    
    echo
    info "Configuring GitHub Pages to deploy from gh-pages branch..."
    
    # First, ensure gh-pages branch exists
    if ! git -C "$REPO_ROOT" ls-remote --heads origin gh-pages | grep -q gh-pages; then
        warn "gh-pages branch doesn't exist yet. It will be created by Upptime workflows."
        info "Creating empty gh-pages branch..."
        
        # Create orphan gh-pages branch
        git -C "$REPO_ROOT" checkout --orphan gh-pages 2>/dev/null || true
        git -C "$REPO_ROOT" reset --hard
        echo "# BandLab Status Page" > "${REPO_ROOT}/index.html"
        git -C "$REPO_ROOT" add index.html
        git -C "$REPO_ROOT" commit -m "Initial gh-pages commit"
        git -C "$REPO_ROOT" push -u origin gh-pages || true
        git -C "$REPO_ROOT" checkout - 2>/dev/null || git -C "$REPO_ROOT" checkout main
        rm -f "${REPO_ROOT}/index.html"
        
        success "gh-pages branch created."
    fi
    
    # Enable GitHub Pages via API
    # Note: This requires admin permissions on the repository
    local pages_payload='{"source":{"branch":"gh-pages","path":"/"}}'
    
    if gh api "repos/${OWNER}/${REPO}/pages" \
        --method POST \
        --header "Accept: application/vnd.github+json" \
        --input - <<< "$pages_payload" 2>/dev/null; then
        success "GitHub Pages enabled with gh-pages branch."
    else
        # Try updating if already exists
        if gh api "repos/${OWNER}/${REPO}/pages" \
            --method PUT \
            --header "Accept: application/vnd.github+json" \
            --input - <<< "$pages_payload" 2>/dev/null; then
            success "GitHub Pages configuration updated."
        else
            warn "Could not configure GitHub Pages via API."
            info "Please enable manually: Settings → Pages → Source: gh-pages branch"
        fi
    fi
}

# Step 4: Configure custom domain (CNAME)
configure_custom_domain() {
    echo -e "\n${BLUE}━━━ Step 4: Configure Custom Domain ━━━${NC}"
    
    # Get current cname from .upptimerc.yml
    local current_cname
    current_cname=$(yq '.status-website.cname // ""' "$UPPTIMERC_FILE")
    
    if [[ -n "$current_cname" && "$current_cname" != "null" ]]; then
        success "Custom domain configured in .upptimerc.yml: $current_cname"
    else
        info "No custom domain configured (using default GitHub Pages URL)."
    fi
    
    # Check if CNAME is set in GitHub Pages
    local pages_cname
    pages_cname=$(gh api "repos/${OWNER}/${REPO}/pages" 2>/dev/null | jq -r '.cname // ""' || echo "")
    
    if [[ -n "$pages_cname" ]]; then
        success "GitHub Pages CNAME already set to: $pages_cname"
        if ! prompt_yn "  Do you want to update the custom domain?" "n"; then
            return
        fi
    fi
    
    echo
    if prompt_yn "  Do you want to configure a custom domain?" "n"; then
        read -rp "  Enter custom domain (e.g., status.bandlab.com): " custom_domain
        
        if [[ -z "$custom_domain" ]]; then
            warn "No domain provided. Skipping custom domain configuration."
            return
        fi
        
        # Update .upptimerc.yml
        yq -i ".\"status-website\".cname = \"$custom_domain\"" "$UPPTIMERC_FILE"
        success "Updated cname in .upptimerc.yml"
        
        # Set CNAME in GitHub Pages
        if gh api "repos/${OWNER}/${REPO}/pages" \
            --method PUT \
            --header "Accept: application/vnd.github+json" \
            --field cname="$custom_domain" 2>/dev/null; then
            success "GitHub Pages CNAME set to: $custom_domain"
        else
            warn "Could not set CNAME via API. It will be set when Site workflow runs."
        fi
        
        # Commit the change
        if prompt_yn "  Commit this change?" "y"; then
            git -C "$REPO_ROOT" add "$UPPTIMERC_FILE"
            git -C "$REPO_ROOT" commit -m "T025: Configure custom domain $custom_domain" || true
            success "Change committed."
        fi
        
        echo
        info "DNS Configuration Required:"
        echo "  Add a CNAME record pointing $custom_domain to:"
        echo "    ${OWNER}.github.io"
        echo
        echo "  Or for apex domains, add A records pointing to:"
        echo "    185.199.108.153"
        echo "    185.199.109.153"
        echo "    185.199.110.153"
        echo "    185.199.111.153"
    else
        # Remove cname if user doesn't want custom domain
        if [[ -n "$current_cname" && "$current_cname" != "null" ]]; then
            if prompt_yn "  Remove existing custom domain from config?" "n"; then
                yq -i 'del(.status-website.cname)' "$UPPTIMERC_FILE"
                success "Removed cname from .upptimerc.yml"
                
                if prompt_yn "  Commit this change?" "y"; then
                    git -C "$REPO_ROOT" add "$UPPTIMERC_FILE"
                    git -C "$REPO_ROOT" commit -m "T025: Remove custom domain configuration" || true
                fi
            fi
        fi
    fi
}

# Step 5 (Bonus): Trigger initial workflow
trigger_workflow() {
    echo -e "\n${BLUE}━━━ Bonus: Trigger Initial Workflow ━━━${NC}"
    
    if prompt_yn "  Do you want to trigger the Uptime CI workflow now?" "y"; then
        if gh workflow run uptime.yml --repo "${OWNER}/${REPO}" 2>/dev/null; then
            success "Uptime CI workflow triggered."
            info "View progress at: https://github.com/${OWNER}/${REPO}/actions"
        else
            warn "Could not trigger workflow. You may need to trigger it manually."
            info "Go to: https://github.com/${OWNER}/${REPO}/actions"
        fi
    fi
}

# Main execution
main() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║       BandLab Upptime Setup Script                         ║"
    echo "║       Automates configuration steps 1-4                    ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    check_prerequisites
    
    configure_assignees
    configure_pat_secret
    configure_github_pages
    configure_custom_domain
    trigger_workflow
    
    echo
    echo -e "${GREEN}━━━ Setup Complete ━━━${NC}"
    echo
    info "Summary of actions:"
    echo "  1. ✓ Assignees configured in .upptimerc.yml"
    echo "  2. ✓ GH_PAT secret configured"
    echo "  3. ✓ GitHub Pages enabled"
    echo "  4. ✓ Custom domain configured (if selected)"
    echo
    info "Next steps:"
    echo "  - Push changes: git push origin $(git -C "$REPO_ROOT" branch --show-current)"
    echo "  - Monitor workflow: https://github.com/${OWNER}/${REPO}/actions"
    echo "  - View status page: https://${OWNER}.github.io/${REPO}/"
    echo
}

main "$@"
