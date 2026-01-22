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

**PAT Requirements (Fine-grained token):**
- Actions: Read and write
- Contents: Read and write
- Issues: Read and write
- Metadata: Read
- Workflows: Read and write

See [docs/PAT-REQUIREMENTS.md](docs/PAT-REQUIREMENTS.md) for detailed token setup instructions.

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

## Maintenance

- **PAT Rotation:** Review and rotate the GitHub Personal Access Token (`GH_PAT`) before expiration. Run `./scripts/setup-upptime.sh` to update.
- **Incident Review:** Check incident history for accuracy after outages.

---

## Configuration

The monitoring configuration is in [.upptimerc.yml](.upptimerc.yml):
- Sites to monitor
- Check frequency
- Status page customization
- Incident assignees

## Documentation

- [PAT Requirements](docs/PAT-REQUIREMENTS.md) - Token setup guide
- [Upptime Docs](https://upptime.js.org/docs/) - Official Upptime documentation
