# BandLab Upptime Monitoring System

[![Uptime CI](https://github.com/bandlab/bandlab-upptime/workflows/Uptime%20CI/badge.svg)](https://github.com/bandlab/bandlab-upptime/actions?query=workflow%3A%22Uptime+CI%22)

Automated uptime monitoring for BandLab services using [Upptime](https://upptime.js.org/).

## Status

🟢 **All systems operational** (auto-updated by Upptime workflows)

| Service | Status | Uptime | Response Time |
|---------|--------|--------|---------------|
| BandLab | Up | 99.95% | ~1100ms |

**Live status page:** https://upptime.bandlab.com

---

## Setup Scripts

### `scripts/setup-upptime.sh`

**When to run:** Initial setup or when reconfiguring the monitoring system.

Automates the manual configuration steps:
1. Configure incident assignees in `.upptimerc.yml`
2. Set up the `GH_PAT` repository secret (with permission validation)
3. Enable GitHub Pages for the status website
4. Configure custom domain

```bash
./scripts/setup-upptime.sh
```

**Prerequisites:**
- GitHub CLI (`gh`) installed and authenticated
- `yq`, `jq`, `curl` installed

---

### `scripts/configure-dns.sh`

**When to run:** Setting up or updating DNS for the custom domain.

Configures AWS Route 53 DNS to point `upptime.bandlab.com` to GitHub Pages.

```bash
./scripts/configure-dns.sh
```

**What it does:**
1. Validates AWS CLI credentials
2. Finds the `bandlab.com` hosted zone
3. Creates/updates CNAME record → `bandlab.github.io`
4. Waits for DNS propagation
5. Configures GitHub Pages custom domain

**Prerequisites:**
- AWS CLI installed and configured
- Permissions: `route53:ListHostedZones`, `route53:ChangeResourceRecordSets`

**Note:** All AWS commands are displayed before execution for confirmation.

---

## GitHub Personal Access Token (PAT)

### Token Type

**Use a Fine-grained Personal Access Token** (recommended for better security).

Fine-grained tokens allow scoping to a single repository with specific permissions.

### Required Permissions

| Permission | Access Level | Why Required |
|------------|--------------|--------------|
| **Actions** | Read and write | Trigger and manage workflow runs |
| **Contents** | Read and write | Update status files, graphs, API data |
| **Issues** | Read and write | Create incident issues when sites go down |
| **Metadata** | Read | Required for repository access (auto-selected) |
| **Workflows** | Read and write | Update workflow files when Upptime updates |

### Generating the Token

1. Go to **[Fine-grained Token Settings](https://github.com/settings/personal-access-tokens/new)**

2. Configure:
   - **Token name**: `BandLab Upptime Monitor`
   - **Expiration**: 90 days (recommended)
   - **Resource owner**: `bandlab`
   - **Repository access**: "Only select repositories" → `bandlab-upptime`

3. Set **Permissions** (Repository permissions):
   - Actions: Read and write
   - Contents: Read and write
   - Issues: Read and write
   - Metadata: Read (auto-selected)
   - Workflows: Read and write

4. Click **Generate token**

5. **Copy the token immediately** (it won't be shown again)

### Setting the Secret

**Using the setup script (recommended):**
```bash
./scripts/setup-upptime.sh
```

The script will:
- Detect token type (fine-grained or classic)
- Validate token has correct permissions
- Test repository access
- Set the `GH_PAT` secret
- Trigger a test workflow

**Manual setup:**
```bash
gh secret set GH_PAT -R bandlab/bandlab-upptime
# Paste your token when prompted
```

### Token Rotation

Tokens should be rotated before expiration:

1. Generate a new token with the same permissions
2. Run `./scripts/setup-upptime.sh` to update
3. Delete the old token from [Token Settings](https://github.com/settings/tokens?type=beta)

### Classic Tokens (Alternative)

If you prefer classic tokens, they also work:

1. Go to https://github.com/settings/tokens/new
2. Select scopes: `repo` and `workflow`
3. The script will accept classic tokens but recommend fine-grained

### Troubleshooting

| Error | Solution |
|-------|----------|
| "Bad credentials" | Token is invalid, expired, or revoked. Generate a new token. |
| "Resource not accessible" | Token missing permissions. Regenerate with all required permissions. |
| Permission test failures | Ensure "Read and write" for Contents, Issues, Actions, Workflows. |

### Verification

After setting the token, verify it works:

```bash
# Check workflow status
gh run list -R bandlab/bandlab-upptime --limit 3

# Manually trigger a workflow
gh workflow run setup.yml -R bandlab/bandlab-upptime
```

---

## Configuration

The monitoring configuration is in [.upptimerc.yml](.upptimerc.yml):
- Sites to monitor
- Check frequency
- Status page customization
- Incident assignees

## External Documentation

- [Upptime Docs](https://upptime.js.org/docs/) - Official Upptime documentation
