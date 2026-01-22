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

## Code Style

- YAML: 2-space indentation
- Shell scripts: Follow ShellCheck recommendations
- Markdown: Follow standard conventions

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->