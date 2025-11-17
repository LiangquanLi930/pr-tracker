# PR Tracker

[中文文档](./README.zh-CN.md) | English

Automatically track all your open Pull Requests across GitHub repositories with daily markdown reports.

## Features

- ✅ Automatically track all your open PRs
- 📊 Display PR status (Review status, CI status)
- 📅 Record creation time and last update time
- 📝 Generate readable markdown format reports
- 🔗 Maintain symlink pointing to latest report
- ⏰ Support scheduled automation via cron
- ☁️ Support GitHub Actions cloud automation

## Choose Your Method

This project offers two usage methods:

### Method 1: GitHub Actions (Recommended) ☁️

**Advantages:**
- ✅ No local machine needed, runs on GitHub cloud
- ✅ Auto-commits reports to repo for online viewing
- ✅ Leverage Git version control for history
- ✅ Access from anywhere, no local dependencies
- ✅ No cron configuration needed

**Setup Steps:**
1. Fork or create this repo to your GitHub account
2. Push code to GitHub (including `.github/workflows/track-prs.yml`)
3. GitHub Actions will auto-enable and run daily at UTC 1:00 (9:00 AM Beijing Time)
4. Can also manually trigger from GitHub repo's Actions page

**View Reports:**
- Visit your repo and open `reports/latest.md`
- Or view historical reports: `reports/my-open-prs-YYYY-MM-DD.md`

### Method 2: Local Cron 💻

**Advantages:**
- ✅ Full local control
- ✅ No GitHub repo needed
- ✅ Customizable run schedule

**Use Case:** If you want to run on local machine or don't want to commit reports to GitHub

See "Local Cron Setup" section below for details.

---

## GitHub Actions Setup (Method 1)

### Prerequisites: Create Personal Access Token

Since cross-repository PR search is required, you need to create a Personal Access Token (PAT).

**Steps:**

1. **Visit GitHub Token Settings:**
   - Open https://github.com/settings/tokens
   - Or: GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)

2. **Create New Token:**
   - Click "Generate new token" → "Generate new token (classic)"
   - **Note:** Enter `PR Tracker` or other description
   - **Expiration:** Recommend `No expiration` or `1 year`

3. **Select Permissions (Scopes):**
   - ✅ **`repo`** - Access all repositories (including private repo PRs)
     - If only public repos needed, select only `public_repo`
   - ✅ **`read:org`** - Read organization info (optional, if you have PRs in organizations)

4. **Generate and Copy Token:**
   - Click "Generate token"
   - **Important:** Copy token immediately (only shown once)
   - Format looks like: `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

5. **Add Token to Repo Secrets:**
   - In your GitHub repo page, go to **Settings** → **Secrets and variables** → **Actions**
   - Click **"New repository secret"**
   - **Name:** `GH_PAT`
   - **Value:** Paste the token you just copied
   - Click **"Add secret"**

### Quick Start

1. **Create GitHub Repository:**
   ```bash
   # If you don't have a git repo yet, initialize one
   cd ~/pr-tracker
   git init
   git add .
   git commit -m "Initial commit: PR tracker with GitHub Actions"
   ```

2. **Push to GitHub:**
   ```bash
   # Create a new repo on GitHub, then:
   git remote add origin https://github.com/YOUR_USERNAME/pr-tracker.git
   git branch -M main
   git push -u origin main
   ```

3. **Done!** GitHub Actions will automatically:
   - Run daily at UTC 1:00 (9:00 AM Beijing Time)
   - Generate PR reports
   - Auto-commit to `reports/` directory

### Manual Trigger

1. Visit your repo: `https://github.com/YOUR_USERNAME/pr-tracker`
2. Click "Actions" tab
3. Select "Track My PRs" workflow
4. Click "Run workflow" button

### Modify Run Schedule

Edit the cron expression in `.github/workflows/track-prs.yml`:

```yaml
on:
  schedule:
    - cron: '0 1 * * *'  # UTC 1:00 = 9:00 AM Beijing Time
    # Change to other times, for example:
    # - cron: '0 9 * * *'  # UTC 9:00 = 5:00 PM Beijing Time
```

**Common Time Conversions (Beijing Time = UTC + 8):**
- 9:00 AM Beijing → `cron: '0 1 * * *'`
- 6:00 PM Beijing → `cron: '0 10 * * *'`
- Midnight Beijing → `cron: '0 16 * * *'`

### Troubleshooting (GitHub Actions)

#### Token Permission Issues

**Symptom:** Action fails with authentication or permission errors

**Solution:**
1. Confirm PAT is created (see "Prerequisites" above)
2. Check PAT permissions include `repo` scope
3. Confirm `GH_PAT` is correctly added to repo secrets
4. Check if token has expired

#### Cannot Find PRs

**Possible Causes:**
- Insufficient token permissions (need `repo` or `public_repo`)
- Only public repo PRs will be found (if using `public_repo`)
- PR count exceeds limit (default 100)

#### View Action Logs

1. Visit repo's "Actions" tab
2. Click on recent workflow run
3. View detailed logs to troubleshoot

---

## Local Cron Setup (Method 2)

### Prerequisites

- macOS or Linux
- [GitHub CLI (gh)](https://cli.github.com/) installed and authenticated
- Bash shell

### Install GitHub CLI

**macOS:**
```bash
brew install gh
```

**Linux:**
See [official documentation](https://github.com/cli/cli/blob/trunk/docs/install_linux.md)

### Authenticate GitHub CLI

```bash
gh auth login
```

## Quick Start

### 1. Run Setup Script

```bash
cd ~/pr-tracker
./setup-pr-tracker.sh
```

The setup script will:
- Check dependencies (gh CLI)
- Let you choose run time (9 AM, 6 PM, midnight, or custom)
- Configure cron scheduled task
- Display configuration summary

### 2. Choose Run Schedule

During setup you can choose:
1. Daily at 9:00 AM
2. Daily at 6:00 PM
3. Daily at midnight
4. Custom cron expression

### 3. Manual Test (Optional)

Before configuring scheduled task, you can manually run the script to test:

```bash
./track-my-prs.sh
```

## Directory Structure

```
~/pr-tracker/
├── track-my-prs.sh          # Main script
├── setup-pr-tracker.sh      # Setup script
├── README.md                # Documentation
├── cron.log                 # Cron task log
└── reports/                 # Report output directory
    ├── my-open-prs-2025-11-06.md
    ├── my-open-prs-2025-11-07.md
    └── latest.md            # Symlink pointing to latest report
```

## Report Format Example

```markdown
# Open Pull Requests for @username

**Generated:** 2025-11-06 09:00:00 CST

---

## Summary

- **Total Open PRs:** 3
- **User:** @username

---

## Pull Requests

### [openshift/hypershift#7131](https://github.com/openshift/hypershift/pull/7131)

**test(e2e): add N-3 and N-4 release image flags**

| | |
|---|---|
| 📝 **Review Status** | ✅ Approved |
| 🔧 **CI Status** | ✅ Passing |
| 📅 **Created** | 2025-11-05 14:23 |
| 🔄 **Last Updated** | 2025-11-06 08:45 |

---
```

## Managing Cron Tasks

### View Current Cron Tasks

```bash
crontab -l
```

### Edit Cron Tasks

```bash
crontab -e
```

### Remove PR Tracker Cron Task

```bash
crontab -e
# Delete the line containing 'track-my-prs.sh'
```

### View Cron Logs

```bash
cat ~/pr-tracker/cron.log
```

## Troubleshooting

### Script Not Running?

1. Check if cron is set:
   ```bash
   crontab -l | grep track-my-prs
   ```

2. Check cron logs:
   ```bash
   tail -f ~/pr-tracker/cron.log
   ```

3. Manually run script to see errors:
   ```bash
   cd ~/pr-tracker
   ./track-my-prs.sh
   ```

### GitHub CLI Authentication Issues

If you encounter authentication errors:
```bash
gh auth status
gh auth refresh
# Or re-login
gh auth login
```

### Permission Errors

Ensure scripts have execute permissions:
```bash
chmod +x ~/pr-tracker/track-my-prs.sh
chmod +x ~/pr-tracker/setup-pr-tracker.sh
```

## Custom Configuration

### Modify PR Query Limit

Default queries up to 100 PRs. To modify the limit, edit `track-my-prs.sh`:

```bash
--limit 100  # Change to your desired number
```

### Track Only Specific Organization PRs

To only track PRs from specific organization (e.g., openshift), modify the search command in `track-my-prs.sh`:

```bash
gh search prs \
    --author="${GITHUB_USER}" \
    --state=open \
    org:openshift \    # Add this line
    --json number,title,url,repository,createdAt,updatedAt,reviewDecision,statusCheckRollup \
    --limit 100
```

## Uninstall

1. Remove cron task:
   ```bash
   crontab -l | grep -v "track-my-prs.sh" | crontab -
   ```

2. (Optional) Delete entire directory:
   ```bash
   rm -rf ~/pr-tracker
   ```

## Advanced Usage

### Integrate with Git Version Control

If you want to version control your PR reports:

```bash
cd ~/pr-tracker
git init
git add track-my-prs.sh setup-pr-tracker.sh README.md
git commit -m "Initial commit"
# Optional: Add .gitignore to exclude cron.log
echo "cron.log" > .gitignore
git add .gitignore
git commit -m "Add gitignore"
```

### View Historical Reports

```bash
# List all reports
ls -lh ~/pr-tracker/reports/

# View specific date report
cat ~/pr-tracker/reports/my-open-prs-2025-11-06.md

# View latest report
cat ~/pr-tracker/reports/latest.md
```

## License

MIT

## Contributing

Issues and Pull Requests are welcome!
