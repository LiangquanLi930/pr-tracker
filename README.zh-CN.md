# PR Tracker

[English](./README.md) | 中文文档

自动跟踪你在所有GitHub仓库中打开的Pull Request,并每天生成Markdown格式报告。

## 功能特性

- ✅ 自动追踪你创建的所有open PR
- 📊 显示PR状态(Review状态、CI状态)
- 📅 记录创建时间和最后更新时间
- 📝 生成易读的Markdown格式报告
- 🔗 保持指向最新报告的符号链接
- ⏰ 支持cron定时任务自动运行
- ☁️ 支持 GitHub Actions 云端自动运行

## 使用方式选择

这个项目提供两种使用方式：

### 方式 1: GitHub Actions (推荐) ☁️

**优点:**
- ✅ 无需本地机器，在 GitHub 云端运行
- ✅ 自动提交报告到 repo，方便在线查看
- ✅ 利用 Git 版本控制查看历史
- ✅ 随时随地访问，不依赖本地环境
- ✅ 无需配置 cron

**设置步骤:**
1. Fork 或创建这个 repo 到你的 GitHub 账号
2. Push 代码到 GitHub（包含 `.github/workflows/track-prs.yml`）
3. GitHub Actions 会自动启用，每天 UTC 1:00 (北京时间 9:00) 运行
4. 也可以在 GitHub repo 的 Actions 页面手动触发

**查看报告:**
- 访问你的 repo，打开 `reports/latest.md`
- 或查看历史报告：`reports/my-open-prs-YYYY-MM-DD.md`

### 方式 2: 本地 Cron 💻

**优点:**
- ✅ 完全本地控制
- ✅ 不需要 GitHub repo
- ✅ 自定义运行时间

**适用场景:** 如果你想在本地机器运行，或者不想将报告提交到 GitHub

详细设置见下方的"本地 Cron 设置"部分。

---

## GitHub Actions 设置（方式 1）

### 前置要求：创建 Personal Access Token

由于需要跨仓库搜索 PR，你需要创建一个 Personal Access Token (PAT)。

**步骤：**

1. **访问 GitHub Token 设置：**
   - 打开 https://github.com/settings/tokens
   - 或者：GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)

2. **创建新 token：**
   - 点击 "Generate new token" → "Generate new token (classic)"
   - **Note（备注）:** 填写 `PR Tracker` 或其他描述
   - **Expiration（过期时间）:** 建议选择 `No expiration` 或 `1 year`

3. **选择权限（Scopes）：**
   - ✅ **`repo`** - 访问所有仓库（包括私有仓库的 PR）
     - 如果只需要公开仓库，可以只选择 `public_repo`
   - ✅ **`read:org`** - 读取组织信息（可选，如果你在组织中有 PR）

4. **生成并复制 token：**
   - 点击 "Generate token"
   - **重要：** 立即复制 token（只会显示一次）
   - 格式类似：`ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

5. **将 token 添加到 repo secrets：**
   - 在你的 GitHub repo 页面，进入 **Settings** → **Secrets and variables** → **Actions**
   - 点击 **"New repository secret"**
   - **Name:** `GH_PAT`
   - **Value:** 粘贴刚才复制的 token
   - 点击 **"Add secret"**

### 快速开始

1. **创建 GitHub 仓库:**
   ```bash
   # 如果还没有 git repo，初始化一个
   cd ~/pr-tracker
   git init
   git add .
   git commit -m "Initial commit: PR tracker with GitHub Actions"
   ```

2. **推送到 GitHub:**
   ```bash
   # 在 GitHub 上创建一个新的 repo，然后：
   git remote add origin https://github.com/YOUR_USERNAME/pr-tracker.git
   git branch -M main
   git push -u origin main
   ```

3. **就这样！** GitHub Actions 会自动：
   - 每天 UTC 1:00 (北京时间 9:00) 运行
   - 生成 PR 报告
   - 自动提交到 `reports/` 目录

### 手动触发

1. 访问你的 repo: `https://github.com/YOUR_USERNAME/pr-tracker`
2. 点击 "Actions" 标签
3. 选择 "Track My PRs" workflow
4. 点击 "Run workflow" 按钮

### 修改运行时间

编辑 `.github/workflows/track-prs.yml` 文件中的 cron 表达式:

```yaml
on:
  schedule:
    - cron: '0 1 * * *'  # UTC 1:00 = 北京时间 9:00
    # 改为其他时间，例如：
    # - cron: '0 9 * * *'  # UTC 9:00 = 北京时间 17:00
```

**常用时间对照（北京时间 = UTC + 8）:**
- 北京时间 9:00 → `cron: '0 1 * * *'`
- 北京时间 18:00 → `cron: '0 10 * * *'`
- 北京时间 0:00 → `cron: '0 16 * * *'`

### 故障排除（GitHub Actions）

#### Token 权限问题

**症状：** Action 运行失败，提示认证或权限错误

**解决方法：**
1. 确认已创建 PAT（见上方"前置要求"）
2. 检查 PAT 的权限包含 `repo` scope
3. 确认在 repo secrets 中正确添加了 `GH_PAT`
4. 检查 token 是否过期

#### 无法搜索到 PR

**可能原因：**
- Token 权限不足（需要 `repo` 或 `public_repo`）
- 只有公开仓库的 PR 会被搜索到（如果使用 `public_repo`）
- PR 数量超过限制（默认 100）

#### 查看 Action 日志

1. 访问 repo 的 "Actions" 标签
2. 点击最近的 workflow 运行
3. 查看详细日志排查问题

---

## 本地 Cron 设置（方式 2）

### 前置要求

- macOS 或 Linux
- [GitHub CLI (gh)](https://cli.github.com/) 已安装并认证
- Bash shell

### 安装 GitHub CLI

**macOS:**
```bash
brew install gh
```

**Linux:**
参考 [官方文档](https://github.com/cli/cli/blob/trunk/docs/install_linux.md)

### 认证 GitHub CLI

```bash
gh auth login
```

## 快速开始

### 1. 运行安装脚本

```bash
cd ~/pr-tracker
./setup-pr-tracker.sh
```

安装脚本会:
- 检查依赖项(gh CLI)
- 让你选择运行时间(每天9点、18点、午夜,或自定义)
- 配置cron定时任务
- 显示配置摘要

### 2. 选择运行计划

安装过程中你可以选择:
1. 每天上午9:00
2. 每天下午6:00
3. 每天午夜0:00
4. 自定义cron表达式

### 3. 手动测试(可选)

在配置定时任务之前,你可以手动运行脚本测试:

```bash
./track-my-prs.sh
```

## 目录结构

```
~/pr-tracker/
├── track-my-prs.sh          # 主脚本
├── setup-pr-tracker.sh      # 安装脚本
├── README.md                # 文档
├── cron.log                 # Cron任务日志
└── reports/                 # 报告输出目录
    ├── my-open-prs-2025-11-06.md
    ├── my-open-prs-2025-11-07.md
    └── latest.md            # 符号链接,指向最新报告
```

## 报告格式示例

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

## 管理Cron任务

### 查看当前cron任务

```bash
crontab -l
```

### 编辑cron任务

```bash
crontab -e
```

### 删除PR tracker cron任务

```bash
crontab -e
# 删除包含 'track-my-prs.sh' 的行
```

### 查看cron日志

```bash
cat ~/pr-tracker/cron.log
```

## 故障排除

### 脚本没有运行?

1. 检查cron是否已设置:
   ```bash
   crontab -l | grep track-my-prs
   ```

2. 检查cron日志:
   ```bash
   tail -f ~/pr-tracker/cron.log
   ```

3. 手动运行脚本查看错误:
   ```bash
   cd ~/pr-tracker
   ./track-my-prs.sh
   ```

### GitHub CLI认证问题

如果遇到认证错误:
```bash
gh auth status
gh auth refresh
# 或重新登录
gh auth login
```

### 权限错误

确保脚本有执行权限:
```bash
chmod +x ~/pr-tracker/track-my-prs.sh
chmod +x ~/pr-tracker/setup-pr-tracker.sh
```

## 自定义配置

### 修改PR查询限制

默认查询最多100个PR。要修改限制,编辑 `track-my-prs.sh`:

```bash
--limit 100  # 修改为你需要的数量
```

### 只追踪特定组织的PR

要只追踪特定组织(如openshift)的PR,修改 `track-my-prs.sh` 中的搜索命令:

```bash
gh search prs \
    --author="${GITHUB_USER}" \
    --state=open \
    org:openshift \    # 添加这行
    --json number,title,url,repository,createdAt,updatedAt,reviewDecision,statusCheckRollup \
    --limit 100
```

## 卸载

1. 删除cron任务:
   ```bash
   crontab -l | grep -v "track-my-prs.sh" | crontab -
   ```

2. (可选) 删除整个目录:
   ```bash
   rm -rf ~/pr-tracker
   ```

## 高级用法

### 集成到Git版本控制

如果想版本控制你的PR报告:

```bash
cd ~/pr-tracker
git init
git add track-my-prs.sh setup-pr-tracker.sh README.md
git commit -m "Initial commit"
# 可选: 添加 .gitignore 来排除 cron.log
echo "cron.log" > .gitignore
git add .gitignore
git commit -m "Add gitignore"
```

### 查看历史报告

```bash
# 列出所有报告
ls -lh ~/pr-tracker/reports/

# 查看特定日期的报告
cat ~/pr-tracker/reports/my-open-prs-2025-11-06.md

# 查看最新报告
cat ~/pr-tracker/reports/latest.md
```

## 许可证

MIT

## 贡献

欢迎提交 Issues 和 Pull Requests！
