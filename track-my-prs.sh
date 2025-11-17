#!/bin/bash

# Script to track all open PRs created by the current user
# Outputs to a markdown file with PR details including status

set -e

# Configuration
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
OUTPUT_DIR="${SCRIPT_DIR}/reports"
OUTPUT_FILE="${OUTPUT_DIR}/my-open-prs-$(date +%Y-%m-%d).md"
LATEST_LINK="${OUTPUT_DIR}/latest.md"

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
# Open Pull Requests for @${GITHUB_USER}

**Generated:** $(date '+%Y-%m-%d %H:%M:%S %Z')

---

EOF

# Fetch all open PRs created by the user
echo "Fetching open PRs for ${GITHUB_USER}..."

# Use GitHub search API to find all open PRs by the user
PRS=$(gh search prs \
    --author="${GITHUB_USER}" \
    --state=open \
    --json number,title,url,repository,createdAt,updatedAt \
    --limit 100)

# Count PRs
PR_COUNT=$(echo "$PRS" | jq '. | length')

if [ "$PR_COUNT" -eq 0 ]; then
    cat >> "${OUTPUT_FILE}" << EOF
## No open pull requests found

You don't have any open pull requests at this time.
EOF
else
    # Get unique repositories
    REPOS=$(echo "$PRS" | jq -r '.[].repository.nameWithOwner' | sort -u)
    REPO_COUNT=$(echo "$REPOS" | wc -l | tr -d ' ')

    cat >> "${OUTPUT_FILE}" << EOF
## Summary

- **Total Open PRs:** ${PR_COUNT}
- **Repositories:** ${REPO_COUNT}
- **User:** @${GITHUB_USER}

---

EOF

    # Process each repository
    echo "$REPOS" | while IFS= read -r repo; do
        # Get PRs for this repository
        REPO_PRS=$(echo "$PRS" | jq --arg repo "$repo" '[.[] | select(.repository.nameWithOwner == $repo)]')
        REPO_PR_COUNT=$(echo "$REPO_PRS" | jq '. | length')

        cat >> "${OUTPUT_FILE}" << REPOEOF
## 📦 ${repo} (${REPO_PR_COUNT} PRs)

REPOEOF

        # Process each PR in this repository
        echo "$REPO_PRS" | jq -r '.[] | @json' | while IFS= read -r pr; do
            # Extract PR details
            REPO=$(echo "$pr" | jq -r '.repository.nameWithOwner')
            NUMBER=$(echo "$pr" | jq -r '.number')
            TITLE=$(echo "$pr" | jq -r '.title')
            URL=$(echo "$pr" | jq -r '.url')
            CREATED=$(echo "$pr" | jq -r '.createdAt')
            UPDATED=$(echo "$pr" | jq -r '.updatedAt')

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
            PR_DETAILS=$(gh pr view "$NUMBER" --repo "$REPO" --json reviewDecision,statusCheckRollup 2>/dev/null || echo '{}')

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

            # Get CI status - get the overall state
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

            # Write PR entry to markdown
            cat >> "${OUTPUT_FILE}" << PREOF
### [#${NUMBER}](${URL}) ${TITLE}

| | |
|---|---|
| 📝 **Review Status** | ${REVIEW_STATUS} |
| 🔧 **CI Status** | ${CI_BADGE} |
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
# Use cp instead of ln for better GitHub Actions compatibility
cp "${OUTPUT_FILE}" "${LATEST_LINK}"

echo ""
echo "✅ Report generated successfully!"
echo "📄 Output: ${OUTPUT_FILE}"
echo "🔗 Latest: ${LATEST_LINK}"
echo ""
echo "Summary: ${PR_COUNT} open pull request(s) found"
