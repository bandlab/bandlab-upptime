# GitHub Personal Access Token (PAT) Requirements

This document describes the exact permissions required for the BandLab Upptime monitoring system.

## Token Type

**Use a Classic Personal Access Token** (not Fine-Grained).

Fine-grained tokens are not supported by Upptime because they cannot access the `upptime/uptime-monitor` action's release API.

## Required Scopes

The PAT must have **exactly** these scopes:

| Scope | Description | Why Required |
|-------|-------------|--------------|
| `repo` | Full control of private repositories | Read/write repository contents, create issues for incidents, update status data |
| `workflow` | Update GitHub Action workflows | Allow Upptime to update its own workflow files |

## Security: Least Privilege

⚠️ **Do NOT add additional scopes** beyond `repo` and `workflow`.

Extra scopes increase security risk without benefit:
- ❌ `admin:org` - Not needed
- ❌ `admin:repo_hook` - Not needed  
- ❌ `delete_repo` - Not needed
- ❌ `gist` - Not needed
- ❌ `notifications` - Not needed
- ❌ `user` - Not needed
- ❌ `write:packages` - Not needed

The setup script will warn if your token has extra permissions.

## Generating the Token

1. Go to **[GitHub Token Settings](https://github.com/settings/tokens/new)**

2. Configure:
   - **Note**: `BandLab Upptime Monitor`
   - **Expiration**: 90 days (recommended) or custom
   - **Scopes**: Check ONLY:
     - ☑️ `repo`
     - ☑️ `workflow`

3. Click **Generate token**

4. **Copy the token immediately** (it won't be shown again)

## Setting the Secret

### Using the setup script (recommended):
```bash
./scripts/setup-upptime.sh
```

The script will:
- Validate token format
- Verify token has correct scopes
- Warn about extra scopes
- Set the `GH_PAT` secret
- Trigger a test workflow

### Manual setup:
```bash
gh secret set GH_PAT -R bandlab/bandlab-upptime
# Paste your token when prompted
```

## Token Rotation

Tokens should be rotated before expiration:

1. Generate a new token with the same scopes
2. Run `./scripts/setup-upptime.sh` to update
3. Delete the old token from [GitHub Token Settings](https://github.com/settings/tokens)

## Troubleshooting

### "Bad credentials" error
- Token is invalid, expired, or revoked
- Generate a new token and update the secret

### "Resource not accessible" error
- Token is missing required scopes
- Regenerate with both `repo` and `workflow` checked

### Fine-grained token error
- Upptime requires Classic tokens
- Generate a new Classic token at https://github.com/settings/tokens/new

## Verification

After setting the token, verify it works:

```bash
# Check workflow status
gh run list -R bandlab/bandlab-upptime --limit 3

# Manually trigger a workflow
gh workflow run setup.yml -R bandlab/bandlab-upptime
```

All workflows should complete successfully (green checkmark).
