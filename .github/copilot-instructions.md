# bandlab-upptime Development Guidelines

## Active Technologies
- JavaScript/TypeScript (Node.js ecosystem via GitHub Actions)
- Svelte/Sapper for status website
- Upptime template repository
- GitHub Actions runners
- GitHub Pages

## Project Structure
```
.github/
  workflows/       # GitHub Actions for monitoring
  copilot-instructions.md
.upptimerc.yml     # Monitoring configuration
scripts/           # Setup and maintenance scripts
README.md          # Comprehensive documentation
```

## Branch Strategy

⚠️ **CRITICAL: Never push directly to `master` branch**

### Why?

Upptime workflows automatically commit to `master` throughout the day:
- `summary.yml` updates README.md with status badges
- `uptime.yml` updates history/ and graphs/
- `graphs.yml` generates response time charts
- `site.yml` force-pushes to `gh-pages` branch

These auto-commits will conflict with direct pushes to master.

### Development Workflow

**Always use feature branches:**

```bash
# Create feature branch
git checkout -b feature/your-change

# Make changes
vim .upptimerc.yml

# Commit and push to feature branch
git commit -am "feat: add new monitoring target"
git push origin feature/your-change

# Create PR to master
gh pr create --base master
```

**Files Modified by Upptime (do not edit manually):**
- `README.md` (status section)
- `history/*.yml`
- `api/*.json`
- `graphs/*.png`
- `gh-pages` branch (entire branch)

**Files Developers Should Modify:**
- `.upptimerc.yml` (monitoring configuration)
- `.github/workflows/*.yml` (workflow definitions)
- `scripts/*.sh` (maintenance scripts)

## Configuration

All monitoring configuration is in `.upptimerc.yml`:
- `sites` - URLs to monitor
- `assignees` - GitHub users for incident notifications
- `status-website` - Status page customization
- `workflowSchedule` - Check frequency

See README.md for detailed configuration options.

## Common Tasks

### Add New Site to Monitor

1. Create feature branch: `git checkout -b feature/monitor-api`
2. Edit `.upptimerc.yml`:
   ```yaml
   sites:
     - name: BandLab API
       url: https://api.bandlab.com/health
       slug: bandlab-api
       maxResponseTime: 3000
   ```
3. Commit, push, create PR
4. Merge PR to master
5. Upptime workflows will start monitoring automatically

### Update PAT Secret

```bash
./scripts/setup-upptime.sh
```

### Configure DNS

```bash
./scripts/configure-dns.sh
```

## Testing

**Trigger workflows manually:**
```bash
gh workflow run uptime.yml
gh workflow run site.yml
```

**Check workflow status:**
```bash
gh run list --limit 5
```

**View logs:**
```bash
gh run view <run-id> --log
```

### Testing Changes

After making changes to configuration or workflows, follow these steps to test:

#### 1. Local Validation
- **YAML Syntax**: Validate `.upptimerc.yml` with `yamllint .upptimerc.yml`
- **Configuration**: Check that all required fields are present
- **URLs**: Verify monitoring URLs are accessible: `curl -I <url>`

#### 2. Feature Branch Testing
- **Create PR**: Always test via PR to avoid direct master pushes
- **Workflow Check**: Ensure workflows run successfully on the feature branch
- **Configuration Test**: For monitoring changes, manually verify target URLs respond

#### 3. Site Deployment Testing
After merging to master and site rebuild:

**Basic Functionality:**
```bash
# Test main page loads
curl -s https://upptime.bandlab.com/ | grep -q "BandLab Status" && echo "✓ Main page OK"

# Test monitoring targets appear
curl -s https://upptime.bandlab.com/ | grep -q "bandlab</a>" && echo "✓ BandLab target OK"
curl -s https://upptime.bandlab.com/ | grep -q "bandlab-user-page</a>" && echo "✓ User page target OK"
```

**History Pages:**
```bash
# Test history pages load without 500 errors
status=$(curl -s -o /dev/null -w "%{http_code}" https://upptime.bandlab.com/history/bandlab)
if [ "$status" = "200" ]; then
  echo "✓ BandLab history OK (HTTP $status)"
else
  echo "✗ BandLab history FAILED (HTTP $status)"
fi

status=$(curl -s -o /dev/null -w "%{http_code}" https://upptime.bandlab.com/history/bandlab-user-page)
if [ "$status" = "200" ]; then
  echo "✓ User page history OK (HTTP $status)"
else
  echo "✗ User page history FAILED (HTTP $status)"
fi

# Check for error indicators in response
response=$(curl -s https://upptime.bandlab.com/history/bandlab)
if echo "$response" | grep -q -E "(500|Failed|Error|dynamically imported module)"; then
  echo "✗ BandLab history contains error indicators"
else
  echo "✓ BandLab history no error indicators"
fi
```

**Content Validation:**
```bash
# Check for JavaScript errors in browser console
# Check that status indicators update correctly
# Verify response time graphs load
# Test navigation between pages
```

#### 4. Monitoring Validation
- **Wait for uptime checks**: Allow 5-10 minutes for initial monitoring cycles
- **Verify status updates**: Check that new targets show up/down status
- **Test incident creation**: Verify incident reports generate correctly

#### 5. Troubleshooting Failed Tests

**Site Build Failures:**
```bash
# Check build logs
gh run view --log <run-id>

# Common issues:
# - Invalid YAML syntax in .upptimerc.yml
# - Inaccessible monitoring URLs
# - GitHub Actions permissions issues
```

**Runtime Errors:**
```bash
# Check browser console for JavaScript errors
# Verify dynamic imports work: curl -I https://upptime.bandlab.com/client/*.js
# Test with different browsers/devices
```

**Monitoring Issues:**
```bash
# Manually test URLs: curl -I <monitoring-url>
# Check GitHub Actions secrets are set
# Verify workflow schedules are correct
```

## Code Style

- YAML: 2-space indentation
- Shell scripts: Follow ShellCheck recommendations
- Markdown: Follow standard conventions

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->