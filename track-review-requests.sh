#!/bin/bash

# Script to track all PRs that need attention from the current user
# Including: review requests, assignments, mentions, and team review requests
# Outputs to a markdown file with PR details including status

set -e

# Configuration
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
OUTPUT_DIR="${SCRIPT_DIR}/reports"
OUTPUT_FILE="${OUTPUT_DIR}/review-requests-$(date +%Y-%m-%d).md"
LATEST_LINK="${OUTPUT_DIR}/review-requests-latest.md"

# Ensure output directory exists
mkdir -p "${OUTPUT_DIR}"

# Get current GitHub user
GITHUB_USER=$(gh api user --jq '.login')

if [ -z "$GITHUB_USER" ]; then
    echo "Error: Could not determine GitHub user. Please ensure 'gh' is authenticated."
    echo "Run: gh auth login"
    exit 1
fi

# Create markdown file header
cat > "${OUTPUT_FILE}" << EOF
# Pull Requests Requiring Attention from @${GITHUB_USER}

**Generated:** $(date '+%Y-%m-%d %H:%M:%S %Z')

---

EOF

echo "Fetching PRs requiring your attention..."

# 1. Fetch PRs requesting review from the user
echo "  - Checking direct review requests..."
REVIEW_REQUESTED=$(gh search prs \
    --review-requested="${GITHUB_USER}" \
    --state=open \
    --json number,title,url,repository,createdAt,updatedAt,author \
    --limit 100 2>/dev/null || echo '[]')
REVIEW_REQUESTED=$(echo "$REVIEW_REQUESTED" | jq '[.[] | . + {category: "Review Requested"}]')

# 2. Fetch PRs assigned to the user
echo "  - Checking assigned PRs..."
ASSIGNED=$(gh search prs \
    --assignee="${GITHUB_USER}" \
    --state=open \
    --json number,title,url,repository,createdAt,updatedAt,author \
    --limit 100 2>/dev/null || echo '[]')
ASSIGNED=$(echo "$ASSIGNED" | jq '[.[] | . + {category: "Assigned"}]')

# 3. Fetch PRs mentioning the user
echo "  - Checking mentions..."
MENTIONS=$(gh search prs \
    --mentions="${GITHUB_USER}" \
    --state=open \
    --json number,title,url,repository,createdAt,updatedAt,author \
    --limit 100 2>/dev/null || echo '[]')
MENTIONS=$(echo "$MENTIONS" | jq '[.[] | . + {category: "Mentioned"}]')

# 4. Fetch team review requests (get user's teams first)
echo "  - Checking team review requests..."
TEAM_PRS='[]'

# Get user's team memberships (only teams, not all teams in orgs)
# This uses a more efficient API that only returns teams the user is a member of
USER_TEAMS=$(gh api user/teams --jq '.[] | "\(.organization.login)/\(.slug)"' 2>/dev/null || echo "")

if [ -n "$USER_TEAMS" ]; then
    echo "$USER_TEAMS" | while IFS= read -r team_full; do
        if [ -n "$team_full" ]; then
            # Search for PRs requesting review from this team
            echo "    - Checking team @${team_full}..."
            TEAM_SEARCH=$(gh search prs \
                --review-requested="@${team_full}" \
                --state=open \
                --json number,title,url,repository,createdAt,updatedAt,author \
                --limit 100 2>/dev/null || echo '[]')

            if [ "$TEAM_SEARCH" != "[]" ]; then
                TEAM_SEARCH=$(echo "$TEAM_SEARCH" | jq --arg team "@${team_full}" '[.[] | . + {category: ("Team Review (" + $team + ")")}]')
                TEAM_PRS=$(echo "$TEAM_PRS $TEAM_SEARCH" | jq -s 'add')
            fi
        fi
    done
fi

# Merge all PRs and deduplicate, excluding PRs created by the current user
ALL_PRS=$(echo "$REVIEW_REQUESTED $ASSIGNED $MENTIONS $TEAM_PRS" | jq -s --arg user "$GITHUB_USER" '
    add |
    map(select(.author.login != $user)) |
    group_by(.repository.nameWithOwner + "#" + (.number | tostring)) |
    map({
        pr: .[0],
        categories: map(.category) | join(", ")
    })
')

TOTAL_COUNT=$(echo "$ALL_PRS" | jq 'length')

if [ "$TOTAL_COUNT" -eq 0 ]; then
    cat >> "${OUTPUT_FILE}" << EOF
## No PRs requiring attention

You don't have any PRs requiring your attention at this time. 🎉
EOF
else
    cat >> "${OUTPUT_FILE}" << EOF
## Summary

- **Total PRs Requiring Attention:** ${TOTAL_COUNT}
- **User:** @${GITHUB_USER}

### Categories

EOF

    # Count by category
    REVIEW_COUNT=$(echo "$ALL_PRS" | jq '[.[] | select(.categories | contains("Review Requested"))] | length')
    ASSIGNED_COUNT=$(echo "$ALL_PRS" | jq '[.[] | select(.categories | contains("Assigned"))] | length')
    MENTION_COUNT=$(echo "$ALL_PRS" | jq '[.[] | select(.categories | contains("Mentioned"))] | length')
    TEAM_COUNT=$(echo "$ALL_PRS" | jq '[.[] | select(.categories | contains("Team Review"))] | length')

    cat >> "${OUTPUT_FILE}" << EOF
- 🔍 **Review Requested:** ${REVIEW_COUNT}
- 📌 **Assigned to You:** ${ASSIGNED_COUNT}
- 💬 **Mentioned:** ${MENTION_COUNT}
- 👥 **Team Review:** ${TEAM_COUNT}

---

EOF

    # Group PRs by repository
    REPOS=$(echo "$ALL_PRS" | jq -r '[.[].pr.repository.nameWithOwner] | unique | .[]' | sort)

    # Process each repository
    echo "$REPOS" | while IFS= read -r repo; do
        # Get PRs for this repo
        REPO_PRS=$(echo "$ALL_PRS" | jq --arg repo "$repo" '[.[] | select(.pr.repository.nameWithOwner == $repo)]')
        REPO_PR_COUNT=$(echo "$REPO_PRS" | jq 'length')

        cat >> "${OUTPUT_FILE}" << REPOEOF
## 📦 ${repo} (${REPO_PR_COUNT} PRs)

REPOEOF

        # Process each PR in this repository
        echo "$REPO_PRS" | jq -c '.[]' | while IFS= read -r item; do
            pr=$(echo "$item" | jq '.pr')
            categories=$(echo "$item" | jq -r '.categories')

            # Extract PR details
            REPO=$(echo "$pr" | jq -r '.repository.nameWithOwner')
            NUMBER=$(echo "$pr" | jq -r '.number')
            TITLE=$(echo "$pr" | jq -r '.title')
            URL=$(echo "$pr" | jq -r '.url')
            CREATED=$(echo "$pr" | jq -r '.createdAt')
            UPDATED=$(echo "$pr" | jq -r '.updatedAt')
            AUTHOR=$(echo "$pr" | jq -r '.author.login')

            # Format dates (cross-platform compatible)
            if date --version >/dev/null 2>&1; then
                # GNU date (Linux)
                CREATED_DATE=$(date -d "$CREATED" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "$CREATED")
                UPDATED_DATE=$(date -d "$UPDATED" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "$UPDATED")
            else
                # BSD date (macOS)
                CREATED_DATE=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$CREATED" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "$CREATED")
                UPDATED_DATE=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$UPDATED" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "$UPDATED")
            fi

            # Fetch detailed PR info to get review and CI status
            PR_DETAILS=$(gh pr view "$NUMBER" --repo "$REPO" --json reviewDecision,statusCheckRollup,reviews 2>/dev/null || echo '{}')

            REVIEW_DECISION=$(echo "$PR_DETAILS" | jq -r '.reviewDecision // "PENDING"')

            # Determine review status emoji
            case "$REVIEW_DECISION" in
                "APPROVED")
                    REVIEW_STATUS="✅ Approved"
                    ;;
                "CHANGES_REQUESTED")
                    REVIEW_STATUS="🔴 Changes Requested"
                    ;;
                "REVIEW_REQUIRED")
                    REVIEW_STATUS="⏳ Review Required"
                    ;;
                *)
                    REVIEW_STATUS="⏳ Pending Review"
                    ;;
            esac

            # Get CI status
            CI_STATE=$(echo "$PR_DETAILS" | jq -r '.statusCheckRollup // [] | if length == 0 then "UNKNOWN" else (map(.state) | if any(. == "FAILURE" or . == "ERROR") then "FAILURE" elif any(. == "PENDING") then "PENDING" elif all(. == "SUCCESS") then "SUCCESS" else "UNKNOWN" end) end')

            case "$CI_STATE" in
                "SUCCESS")
                    CI_BADGE="✅ Passing"
                    ;;
                "FAILURE"|"ERROR")
                    CI_BADGE="❌ Failed"
                    ;;
                "PENDING")
                    CI_BADGE="🟡 Pending"
                    ;;
                *)
                    CI_BADGE="⚪ No CI"
                    ;;
            esac

            # Check if the current user has already reviewed
            USER_REVIEW_STATE=$(echo "$PR_DETAILS" | jq -r --arg user "$GITHUB_USER" '.reviews // [] | [.[] | select(.author.login == $user)] | last | .state // "NONE"')

            case "$USER_REVIEW_STATE" in
                "APPROVED")
                    MY_REVIEW="✅ You approved"
                    ;;
                "CHANGES_REQUESTED")
                    MY_REVIEW="🔴 You requested changes"
                    ;;
                "COMMENTED")
                    MY_REVIEW="💬 You commented"
                    ;;
                *)
                    MY_REVIEW="🔔 Awaiting your review"
                    ;;
            esac

            # Write PR entry to markdown
            cat >> "${OUTPUT_FILE}" << PREOF
### [#${NUMBER}](${URL}) ${TITLE}

| | |
|---|---|
| 🏷️  **Reason** | ${categories} |
| 👤 **Author** | @${AUTHOR} |
| 📝 **Review Status** | ${REVIEW_STATUS} |
| 🔧 **CI Status** | ${CI_BADGE} |
| 🔍 **Your Review** | ${MY_REVIEW} |
| 📅 **Created** | ${CREATED_DATE} |
| 🔄 **Last Updated** | ${UPDATED_DATE} |

PREOF
        done

        # Add separator between repositories
        cat >> "${OUTPUT_FILE}" << EOF

---

EOF
    done
fi

# Create/update link to latest report
cp "${OUTPUT_FILE}" "${LATEST_LINK}"

echo ""
echo "✅ Report generated successfully!"
echo "📄 Output: ${OUTPUT_FILE}"
echo "🔗 Latest: ${LATEST_LINK}"
echo ""
echo "Summary: ${TOTAL_COUNT} PR(s) requiring attention"
