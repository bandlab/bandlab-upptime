# Quickstart Guide: BandLab Upptime Monitoring System

**Created**: 2025-10-12  
**Feature**: BandLab Upptime Monitoring System  

## Prerequisites

- GitHub account with repository creation permissions
- BandLab organization access (for repository creation under organization)
- Basic understanding of YAML configuration files

## Setup Steps

### 1. Create Repository from Upptime Template

1. Visit [Upptime GitHub Template](https://github.com/upptime/upptime/generate)
2. Repository owner: Select "bandlab" organization
3. Repository name: `bandlab-upptime` 
4. ✅ **Important**: Check "Include all branches"
5. Click "Create repository from template"

**Expected Result**: New repository created at `https://github.com/bandlab/bandlab-upptime`

### 2. Enable GitHub Actions

1. Navigate to repository "Actions" tab
2. Click "I understand my workflows, go ahead and enable them"
3. GitHub Actions workflows are now enabled

**Expected Result**: Workflows visible under Actions tab

### 3. Generate Personal Access Token

1. Go to GitHub Settings → Developer settings → Personal access tokens → Fine-grained tokens
2. Click "Generate new token"
3. Token name: "BandLab Upptime Monitor"
4. Expiration: 90 days (renewable)
5. Resource owner: Select "bandlab" organization
6. Repository access: "Only select repositories" → Select `bandlab-upptime`
7. Repository permissions:
   - ✅ Actions: Read and write
   - ✅ Contents: Read and write  
   - ✅ Issues: Read and write
   - ✅ Workflows: Read and write
8. Click "Generate token"
9. **Copy token immediately** (won't be shown again)

### 4. Add Repository Secret

1. In `bandlab-upptime` repository, go to Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: `GH_PAT`
4. Value: Paste the personal access token from step 3
5. Click "Add secret"

**Expected Result**: Secret `GH_PAT` visible in repository secrets list

### 5. Configure Monitoring

Edit `.upptimerc.yml` file in repository root:

```yaml
# GitHub configuration
owner: bandlab
repo: bandlab-upptime
user-agent: bandlab

# Monitoring targets
sites:
  - name: BandLab
    url: https://www.bandlab.com
    slug: bandlab
    maxResponseTime: 5000
    icon: https://www.bandlab.com/favicon.ico

# Team assignments for incidents
assignees:
  - [ADD_GITHUB_USERNAME] # Replace with actual GitHub usernames

# Status website configuration
status-website:
  name: BandLab System Status
  logoUrl: https://www.bandlab.com/favicon.ico
  cname: status.bandlab.com # Or remove if using GitHub Pages URL
  introTitle: "**BandLab** system status and uptime monitoring"
  introMessage: Real-time monitoring of BandLab services powered by Upptime.
  
  # Theme and customization
  theme: light
  navbar:
    - title: Status
      href: /
    - title: BandLab
      href: https://www.bandlab.com
    - title: GitHub
      href: https://github.com/bandlab/bandlab-upptime

# Workflow schedules (optional customization)
workflowSchedule:
  uptime: "*/5 * * * *"  # Check every 5 minutes
  responseTime: "0 23 * * *"  # Generate response time graphs daily
  staticSite: "0 1 * * *"  # Update status website daily
```

**Customization Notes**:
- Replace `[ADD_GITHUB_USERNAME]` with actual team member GitHub usernames
- Update `cname` if using custom domain, or remove for GitHub Pages default
- Adjust `maxResponseTime` threshold as needed (5000ms = 5 seconds)

### 6. Enable GitHub Pages

1. Go to repository Settings → Pages
2. Source: "Deploy from a branch"
3. Branch: Select `gh-pages` → `/ (root)`
4. Click "Save"

**Expected Result**: Status website available at `https://bandlab.github.io/bandlab-upptime/`

### 7. Trigger Initial Setup

1. Go to Actions → "Setup CI" workflow
2. Click "Run workflow" → "Run workflow"
3. Wait for workflow completion (~2-3 minutes)

**Expected Result**: 
- README.md updated with status badges
- Initial API endpoints generated
- Status website deployed

## Verification Steps

### 1. Check Monitoring Status
Visit Actions tab and verify "Uptime CI" workflow runs every 5 minutes successfully.

### 2. View Status Website
Navigate to your status website URL and verify:
- ✅ BandLab status shows "Up" with response time
- ✅ 24-hour uptime percentage displays
- ✅ Historical data graph appears
- ✅ Website loads within 3 seconds

### 3. Test API Endpoints
Verify API accessibility:
```bash
# Test site status API
curl https://bandlab.github.io/bandlab-upptime/api/bandlab/uptime.json

# Test summary API  
curl https://bandlab.github.io/bandlab-upptime/api/summary.json
```

**Expected Response**: Valid JSON with uptime statistics

### 4. Simulate Incident (Optional)
Temporarily modify `.upptimerc.yml` to monitor invalid URL:
```yaml
sites:
  - name: BandLab
    url: https://www.bandlab.com/nonexistent-page
```

**Expected Result**:
- GitHub issue automatically created within 10 minutes
- Status website shows "Down" status
- Incident appears in history

**Revert**: Change URL back to `https://www.bandlab.com` to restore monitoring

## Maintenance Tasks

### Daily
- Monitor Actions tab for workflow failures
- Review any new GitHub issues (incidents)

### Weekly  
- Check status website performance and accessibility
- Review incident trends and response times

### Monthly
- Rotate Personal Access Token if approaching expiration
- Review and update team assignees as needed
- Evaluate adding additional monitoring targets

## Troubleshooting

### Common Issues

**Issue**: Workflows not running
- **Solution**: Verify GitHub Actions enabled and `GH_PAT` secret configured correctly

**Issue**: Status website not updating
- **Solution**: Check GitHub Pages settings and ensure `gh-pages` branch exists

**Issue**: No incident issues created during outages
- **Solution**: Verify PAT has Issues read/write permissions

**Issue**: API endpoints return 404
- **Solution**: Wait for initial setup workflow completion and site generation

### Support Resources

- [Upptime Documentation](https://upptime.js.org/docs/)
- [Upptime GitHub Discussions](https://github.com/upptime/upptime/discussions)
- Internal BandLab DevOps team for repository access issues

## Next Steps

After successful setup:

1. **Add More Monitoring Targets**: Edit `.upptimerc.yml` to include additional BandLab services
2. **Configure Notifications**: Set up Slack/email notifications for incidents
3. **Custom Domain**: Configure `status.bandlab.com` DNS and update `cname` setting
4. **Team Training**: Share status page URL with relevant teams
5. **Integration**: Use API endpoints in internal dashboards or monitoring tools

## Configuration Files Reference

Key files to understand:
- `.upptimerc.yml`: Main configuration
- `.github/workflows/`: Automated workflow definitions
- `history/`: Historical monitoring data
- `api/`: Auto-generated API endpoints
- `graphs/`: Response time trend graphs

All files are managed automatically by Upptime workflows - manual editing only required for configuration changes.