# GitHub Personal Access Token (PAT) Requirements

This document describes the exact permissions required for the BandLab Upptime monitoring system.

## Token Type

**Use a Fine-grained Personal Access Token** (recommended for better security).

Fine-grained tokens allow scoping to a single repository with specific permissions.

## Required Permissions

The PAT must have these repository permissions:

| Permission | Access Level | Why Required |
|------------|--------------|--------------|
| **Actions** | Read and write | Trigger and manage workflow runs |
| **Contents** | Read and write | Update status files, graphs, API data |
| **Issues** | Read and write | Create incident issues when sites go down |
| **Metadata** | Read | Required for repository access (auto-selected) |
| **Workflows** | Read and write | Update workflow files when Upptime updates |

## Security: Least Privilege

Fine-grained tokens are scoped to a single repository, so they're inherently more secure than classic tokens.

## Generating the Token

1. Go to **[Fine-grained Token Settings](https://github.com/settings/personal-access-tokens/new)**

2. Configure:
   - **Token name**: `BandLab Upptime Monitor`
   - **Expiration**: 90 days (recommended)
   - **Resource owner**: `bandlab`
   - **Repository access**: "Only select repositories" → `bandlab-upptime`

3. Set **Permissions**:
   - **Repository permissions**:
     - Actions: Read and write
     - Contents: Read and write
     - Issues: Read and write
     - Metadata: Read (auto-selected)
     - Workflows: Read and write

4. Click **Generate token**

5. **Copy the token immediately** (it won't be shown again)

## Setting the Secret

### Using the setup script (recommended):
```bash
./scripts/setup-upptime.sh
```

The script will:
- Detect token type (fine-grained or classic)
- Validate token has correct permissions
- Test repository access
- Set the `GH_PAT` secret
- Trigger a test workflow

### Manual setup:
```bash
gh secret set GH_PAT -R bandlab/bandlab-upptime
# Paste your token when prompted
```

## Token Rotation

Tokens should be rotated before expiration:

1. Generate a new token with the same permissions
2. Run `./scripts/setup-upptime.sh` to update
3. Delete the old token from [Token Settings](https://github.com/settings/tokens?type=beta)

## Troubleshooting

### "Bad credentials" error
- Token is invalid, expired, or revoked
- Generate a new token and update the secret

### "Resource not accessible" error
- Token is missing required permissions
- Regenerate with all required permissions (Actions, Contents, Issues, Metadata, Workflows)

### Permission test failures
- Ensure the token has "Read and write" access for Contents, Issues, Actions, and Workflows
- Metadata should be "Read" access

## Classic Tokens (Alternative)

If you prefer classic tokens, they also work:

1. Go to https://github.com/settings/tokens/new
2. Select scopes: `repo` and `workflow`
3. The script will accept classic tokens but recommend fine-grained

## Verification

After setting the token, verify it works:

```bash
# Check workflow status
gh run list -R bandlab/bandlab-upptime --limit 3

# Manually trigger a workflow
gh workflow run setup.yml -R bandlab/bandlab-upptime
```

All workflows should complete successfully (green checkmark).
