# BandLab Upptime Monitoring System

[![Uptime CI](https://github.com/bandlab/bandlab-upptime/workflows/Uptime%20CI/badge.svg)](https://github.com/bandlab/bandlab-upptime/actions?query=workflow%3A%22Uptime+CI%22)

Automated uptime monitoring and status page for BandLab services using [Upptime](https://upptime.js.org/).

## 📊 Status

🟢 **All systems operational**

| Service | Status | Uptime | Response Time |
| ------- | ------ | ------ | ------------- |
| BandLab | Up     | 99.95% | ~1100ms       |

**Live status page:** https://upptime.bandlab.com

---

## 📖 Table of Contents

- [Overview](#overview)
- [Quickstart](#quickstart)
- [Setup Scripts](#setup-scripts)
- [GitHub Personal Access Token](#github-personal-access-token)
- [Configuration](#configuration)
- [Data Model](#data-model)
- [API Specification](#api-specification)
- [Architecture](#architecture)
- [Maintenance](#maintenance)
- [Troubleshooting](#troubleshooting)

---

## Overview

This repository implements a public status monitoring system for BandLab.com using the Upptime open-source framework. The system leverages:

- **GitHub Actions** for automated monitoring checks every 5 minutes
- **GitHub Issues** for incident tracking and team collaboration
- **GitHub Pages** for hosting the public status website
- **Git repository** for immutable historical data storage

### Key Features

✅ **5-minute monitoring intervals** - Checks BandLab.com every 5 minutes  
✅ **Automatic incident detection** - Creates GitHub issues when sites go down  
✅ **Public status page** - Real-time dashboard at upptime.bandlab.com  
✅ **Historical data** - 90+ days of uptime and response time history  
✅ **RESTful API** - JSON endpoints for programmatic access  
✅ **Zero infrastructure** - Fully serverless using GitHub's platform

### Success Metrics

- 🎯 Status page loads in <3 seconds
- 🎯 Monitoring reliability >99.5%
- 🎯 Incident detection within 5 minutes
- 🎯 Historical data retention for 90+ days
- 🎯 Status page availability >99.9%

---

## Quickstart

### Prerequisites

- GitHub account with repository access
- BandLab organization permissions
- Basic understanding of YAML configuration

### Initial Setup

1. **Repository is already created** from Upptime template ✓
2. **Enable GitHub Actions** (already done) ✓
3. **Generate Personal Access Token** (see [PAT section](#github-personal-access-token))
4. **Run setup script:**

```bash
./scripts/setup-upptime.sh
```

5. **Configure DNS** (if using custom domain):

```bash
./scripts/configure-dns.sh
```

6. **Verify deployment:**

```bash
# Check monitoring is running
gh run list --workflow uptime.yml --limit 3

# Visit status page
open https://upptime.bandlab.com
```

### Adding More Sites to Monitor

Edit [.upptimerc.yml](.upptimerc.yml):

```yaml
sites:
  - name: BandLab
    url: https://www.bandlab.com
    slug: bandlab
    maxResponseTime: 5000
    icon: https://www.bandlab.com/favicon.ico

  # Add new site
  - name: BandLab API
    url: https://api.bandlab.com/health
    slug: bandlab-api
    maxResponseTime: 3000
```

Commit and push - monitoring starts automatically.

---

## Setup Scripts

### `scripts/setup-upptime.sh`

**When to run:** Initial setup or when reconfiguring the monitoring system.

Automates configuration steps:

1. Configure incident assignees in `.upptimerc.yml`
2. Set up `GH_PAT` repository secret with permission validation
3. Enable GitHub Pages for status website
4. Configure custom domain

```bash
./scripts/setup-upptime.sh
```

**Prerequisites:**

- GitHub CLI (`gh`) installed and authenticated
- `yq`, `jq`, `curl` installed

---

### `scripts/configure-dns.sh`

**When to run:** Setting up or updating DNS for custom domain.

Configures AWS Route 53 DNS to point `upptime.bandlab.com` to GitHub Pages.

```bash
./scripts/configure-dns.sh
```

**What it does:**

1. Validates AWS CLI credentials
2. Finds `bandlab.com` hosted zone
3. Creates/updates CNAME record → `bandlab.github.io`
4. Waits for DNS propagation
5. Configures GitHub Pages custom domain

**Prerequisites:**

- AWS CLI installed and configured with BandLab profile
- Permissions: `route53:ListHostedZones`, `route53:ChangeResourceRecordSets`

---

## GitHub Personal Access Token

### Token Type

**Use Fine-grained Personal Access Token** (recommended for better security).

### Required Permissions

| Permission    | Access Level   | Why Required                                   |
| ------------- | -------------- | ---------------------------------------------- |
| **Actions**   | Read and write | Trigger and manage workflow runs               |
| **Contents**  | Read and write | Update status files, graphs, API data          |
| **Issues**    | Read and write | Create incident issues when sites go down      |
| **Metadata**  | Read           | Required for repository access (auto-selected) |
| **Workflows** | Read and write | Update workflow files when Upptime updates     |

### Generating the Token

1. Go to **[Fine-grained Token Settings](https://github.com/settings/personal-access-tokens/new)**

2. Configure:

   - **Token name**: `BandLab Upptime Monitor`
   - **Expiration**: 90 days (recommended)
   - **Resource owner**: `bandlab`
   - **Repository access**: "Only select repositories" → `bandlab-upptime`

3. Set **Repository permissions**:

   - Actions: Read and write
   - Contents: Read and write
   - Issues: Read and write
   - Metadata: Read (auto-selected)
   - Workflows: Read and write

4. Click **Generate token**
5. **Copy the token immediately** (won't be shown again)

### Setting the Secret

**Using setup script (recommended):**

```bash
./scripts/setup-upptime.sh
```

The script validates token permissions and sets the secret.

**Manual setup:**

```bash
gh secret set GH_PAT -R bandlab/bandlab-upptime
# Paste token when prompted
```

### Token Rotation

Rotate tokens before expiration:

1. Generate new token with same permissions
2. Run `./scripts/setup-upptime.sh` to update
3. Delete old token from [Token Settings](https://github.com/settings/tokens?type=beta)

### Verification

```bash
# Check workflow status
gh run list -R bandlab/bandlab-upptime --limit 3

# Manually trigger workflow
gh workflow run setup.yml -R bandlab/bandlab-upptime
```

---

## Configuration

All monitoring configuration is in [.upptimerc.yml](.upptimerc.yml).

### Key Configuration Sections

#### Sites to Monitor

```yaml
sites:
  - name: BandLab
    url: https://www.bandlab.com
    slug: bandlab
    maxResponseTime: 5000
    icon: https://www.bandlab.com/favicon.ico
```

**Options:**

- `name` - Display name for the site
- `url` - URL to monitor
- `slug` - Unique identifier for API endpoints
- `maxResponseTime` - Response time threshold in ms (degraded status)
- `icon` - Custom icon URL
- `method` - HTTP method (default: GET)
- `expectedStatusCodes` - Acceptable status codes (default: 200-399)
- `headers` - Custom HTTP headers

#### Status Website

```yaml
status-website:
  name: BandLab System Status
  logoUrl: https://www.bandlab.com/favicon.ico
  cname: upptime.bandlab.com
  theme: light
  navbar:
    - title: Status
      href: /
    - title: BandLab
      href: https://www.bandlab.com
```

#### Incident Assignees

```yaml
assignees:
  - github-username1
  - github-username2
```

When sites go down, GitHub issues are created and assigned to these users.

#### Workflow Schedules

```yaml
workflowSchedule:
  uptime: "*/5 * * * *" # Check every 5 minutes
  responseTime: "0 23 * * *" # Generate graphs daily
  staticSite: "0 1 * * *" # Update status website daily
```

---

## Data Model

### Monitoring Target

Represents a URL endpoint being monitored.

**Attributes:**

- `name` - Human-readable identifier
- `url` - Target URL to monitor
- `slug` - Unique identifier for file naming
- `maxResponseTime` - Degradation threshold (ms)
- `expectedStatusCodes` - Acceptable HTTP codes

**Storage:** `.upptimerc.yml`

### Status Check

Individual monitoring attempt recording health and performance.

**Attributes:**

- `timestamp` - ISO 8601 timestamp
- `status` - Check result (up, down, degraded)
- `responseTime` - Response time in milliseconds
- `httpStatusCode` - HTTP response code
- `error` - Error message (if applicable)

**Storage:** `history/{slug}.yml`

**Example:**

```yaml
- date: "2026-01-22T15:00:00.000Z"
  status: "up"
  code: 200
  responseTime: 1234
```

### Incident

Period of service unavailability or degradation.

**Attributes:**

- `incidentId` - GitHub issue number
- `startTime` - Incident start timestamp
- `endTime` - Incident resolution timestamp
- `duration` - Total downtime in milliseconds
- `status` - Current status (investigating, resolved)
- `title` - Incident description
- `updates` - Array of incident updates

**Storage:** GitHub Issues

**Lifecycle:**

1. **Open** - Incident detected, issue created
2. **Investigating** - Team members adding updates
3. **Resolved** - Service restored, issue auto-closed
4. **Deleted** - Incidents <15 minutes auto-deleted (false positive prevention)

### Uptime Metrics

Calculated availability statistics over time periods.

**Attributes:**

- `uptimePercentage` - Calculated uptime % (24h, 7d, 30d, 90d)
- `averageResponseTime` - Mean response time per period
- `totalChecks` - Number of checks in period
- `successfulChecks` - Number of successful checks

**Storage:** `api/{slug}/uptime.json`

**Example:**

```json
{
  "uptimeDay": 100.0,
  "uptimeWeek": 99.95,
  "uptimeMonth": 99.89,
  "uptimeYear": 99.92,
  "time": {
    "day": 1234,
    "week": 1456,
    "month": 1523,
    "year": 1445
  }
}
```

### Data Flow Architecture

#### 1. Monitoring Workflow (Every 5 minutes)

```
GitHub Actions Trigger → HTTP Request → Record Result → Update History → Generate API → Update Status Page
```

#### 2. Incident Workflow

```
Failed Check → Validate Failure → Create GitHub Issue → Notify Assignees → Auto-close on Recovery
```

#### 3. Metrics Calculation (Daily)

```
Historical Data → Calculate Statistics → Update API Endpoints → Generate Graphs → Update Status Page
```

### Data Retention Policy

- **Raw Check Data**: Indefinite (stored in Git history)
- **API Endpoints**: Last 365 days of detailed data
- **Incident History**: Permanent (via GitHub Issues)
- **Response Time Graphs**: Regenerated daily, historical in Git
- **Summary Statistics**: Rolling calculations with configurable periods

---

## API Specification

All APIs are auto-generated, read-only, and publicly accessible via GitHub Pages.

**Base URL:** `https://upptime.bandlab.com/api/`  
**Content-Type:** `application/json`  
**Authentication:** None required

### Endpoints

#### GET `/api/{site-slug}/uptime.json`

Returns current uptime statistics for a specific site.

**Response:**

```json
{
  "uptimeDay": 100.0,
  "uptimeWeek": 99.95,
  "uptimeMonth": 99.89,
  "uptimeYear": 99.92,
  "time": {
    "day": 1234,
    "week": 1456,
    "month": 1523,
    "year": 1445
  }
}
```

#### GET `/api/{site-slug}/history.json`

Returns historical monitoring check data.

**Response:**

```json
[
  {
    "date": "2026-01-22T15:00:00.000Z",
    "status": "up",
    "code": 200,
    "responseTime": 1234
  }
]
```

#### GET `/api/summary.json`

Returns aggregated status for all monitored sites.

**Response:**

```json
{
  "status": "up",
  "message": "All systems operational",
  "count": {
    "up": 1,
    "down": 0,
    "degraded": 0
  },
  "sites": [
    {
      "name": "BandLab",
      "slug": "bandlab",
      "status": "up",
      "uptime": "99.95%",
      "time": 1234,
      "url": "https://www.bandlab.com"
    }
  ]
}
```

### Usage Examples

**JavaScript:**

```javascript
const response = await fetch(
  "https://upptime.bandlab.com/api/bandlab/uptime.json"
);
const data = await response.json();
console.log(`BandLab uptime: ${data.uptimeDay}%`);
```

**Python:**

```python
import requests
response = requests.get('https://upptime.bandlab.com/api/summary.json')
data = response.json()
print(f"System status: {data['status']}")
```

**curl:**

```bash
curl https://upptime.bandlab.com/api/bandlab/uptime.json
```

### CORS Policy

All APIs support Cross-Origin Resource Sharing:

```http
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, OPTIONS
```

---

## Architecture

### Technical Stack

- **Monitoring Engine**: GitHub Actions with Upptime workflows
- **Data Storage**: Git repository (YAML for history, JSON for API)
- **Status Website**: Static site via GitHub Pages (Svelte/Sapper)
- **Configuration**: YAML-based (`.upptimerc.yml`)
- **Incident Management**: GitHub Issues with automatic lifecycle
- **API**: Auto-generated JSON endpoints

### Project Structure

```
.github/
├── workflows/              # GitHub Actions workflows
│   ├── uptime.yml         # Core monitoring (5-minute checks)
│   ├── site.yml           # Status website generation
│   ├── graphs.yml         # Response time graph generation
│   ├── response-time.yml  # Response time tracking
│   ├── summary.yml        # Summary statistics
│   └── setup.yml          # Repository initialization

.upptimerc.yml             # Central configuration
api/                       # Auto-generated API endpoints
├── bandlab/
│   ├── uptime.json
│   └── history.json
└── summary.json

history/                   # Historical monitoring data
├── bandlab.yml
└── summary.yml

graphs/                    # Response time graphs
└── bandlab/
    ├── response-time.png
    └── response-time-day.png

README.md                  # Auto-updated status (this file)
```

### Workflows

#### Uptime CI (`uptime.yml`)

- **Schedule**: Every 5 minutes
- **Purpose**: Monitor all sites, record results, create/close incidents
- **Triggers**: Schedule, manual dispatch

#### Site CI (`site.yml`)

- **Schedule**: Daily at 1 AM
- **Purpose**: Generate and deploy status website
- **Output**: GitHub Pages deployment

#### Response Time (`response-time.yml`)

- **Schedule**: Daily at 11 PM
- **Purpose**: Calculate and update response time metrics
- **Output**: Updated API endpoints

#### Graphs CI (`graphs.yml`)

- **Schedule**: Daily
- **Purpose**: Generate response time trend graphs
- **Output**: PNG graphs in `graphs/` directory

---

## Maintenance

### Daily Tasks

- Monitor Actions tab for workflow failures
- Review any new GitHub issues (incidents)

### Weekly Tasks

- Check status website performance
- Review incident trends and response times

### Monthly Tasks

- **Rotate Personal Access Token** before expiration
- Review and update team assignees
- Evaluate adding additional monitoring targets
- Review uptime trends and adjust thresholds

### Updating Upptime

The `update-template.yml` workflow automatically checks for Upptime updates.

Manual update:

```bash
# Merge latest from Upptime template
git remote add upptime https://github.com/upptime/upptime
git fetch upptime
git merge upptime/master
```

---

## Troubleshooting

### Common Issues

#### Workflows Not Running

**Symptom:** Monitoring checks not happening every 5 minutes

**Solutions:**

- Verify GitHub Actions are enabled in repository settings
- Check `GH_PAT` secret is set correctly
- Ensure token hasn't expired
- Check Actions tab for workflow failures

#### Status Website Not Updating

**Symptom:** Status page shows stale data

**Solutions:**

- Check GitHub Pages is enabled (`gh-pages` branch)
- Verify Site CI workflow runs successfully
- Check DNS configuration for custom domain
- Clear browser cache

#### No Incident Issues Created

**Symptom:** Sites go down but no GitHub issues are created

**Solutions:**

- Verify PAT has Issues read/write permissions
- Check assignees are configured in `.upptimerc.yml`
- Ensure site has been down for >1 check (2 failures required)

#### API Endpoints Return 404

**Symptom:** `/api/*` endpoints not accessible

**Solutions:**

- Wait for initial setup workflow completion
- Check `gh-pages` branch contains `api/` directory
- Verify GitHub Pages is deployed from `gh-pages` branch

#### DNS Not Resolving

**Symptom:** `upptime.bandlab.com` not accessible

**Solutions:**

- Run `./scripts/configure-dns.sh` to verify DNS setup
- Check Route 53 CNAME record exists and points to `bandlab.github.io`
- Wait for DNS propagation (up to 48 hours, usually <10 minutes)
- Verify CNAME file exists in `gh-pages` branch

### Debug Commands

```bash
# Check recent workflow runs
gh run list --limit 10

# View workflow logs
gh run view <run-id> --log

# Check monitoring status
curl https://upptime.bandlab.com/api/summary.json

# Test DNS resolution
nslookup upptime.bandlab.com
dig upptime.bandlab.com

# Check GitHub Pages status
gh api repos/bandlab/bandlab-upptime/pages
```

### Support Resources

- [Upptime Documentation](https://upptime.js.org/docs/)
- [Upptime GitHub Discussions](https://github.com/upptime/upptime/discussions)
- Internal BandLab DevOps team

---

## Constitutional Compliance

This implementation adheres to BandLab's engineering principles:

✅ **Transparency** - Public status page with immutable Git history  
✅ **Everything-as-Code** - All configuration in `.upptimerc.yml`  
✅ **Reliability** - 5-minute monitoring with automatic incident detection  
✅ **Security** - Minimal PAT permissions, secrets stored securely  
✅ **Testability** - Manual workflow triggers, synthetic incident testing  
✅ **Rollback** - Single-step: revert commit or disable workflow  
✅ **Documentation** - Comprehensive README with architecture details

---

## License

This repository is based on [Upptime](https://github.com/upptime/upptime) (MIT License).

---

**Last Updated:** Auto-updated by Upptime workflows  
**Repository:** https://github.com/bandlab/bandlab-upptime  
**Status Page:** https://upptime.bandlab.com
