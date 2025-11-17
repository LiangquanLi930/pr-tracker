#!/bin/bash

# Setup script for the PR tracker cron job
# This script configures a daily cron job to track your open PRs

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TRACKER_SCRIPT="${SCRIPT_DIR}/track-my-prs.sh"
LOG_FILE="${SCRIPT_DIR}/cron.log"

echo "🚀 Setting up PR Tracker Cron Job"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ Error: GitHub CLI (gh) is not installed"
    echo ""
    echo "Please install it first:"
    echo "  macOS: brew install gh"
    echo "  Linux: https://github.com/cli/cli/blob/trunk/docs/install_linux.md"
    echo ""
    exit 1
fi

# Check if gh is authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ Error: GitHub CLI is not authenticated"
    echo ""
    echo "Please run: gh auth login"
    echo ""
    exit 1
fi

echo "✅ GitHub CLI is installed and authenticated"
echo ""

# Verify the tracker script exists
if [ ! -f "$TRACKER_SCRIPT" ]; then
    echo "❌ Error: Tracker script not found at ${TRACKER_SCRIPT}"
    exit 1
fi

echo "✅ Tracker script found at ${TRACKER_SCRIPT}"
echo ""

# Ask for cron schedule
echo "When would you like to run the PR tracker?"
echo "1) Daily at 9:00 AM"
echo "2) Daily at 6:00 PM"
echo "3) Daily at midnight"
echo "4) Custom cron expression"
echo ""
read -p "Choose an option (1-4): " SCHEDULE_CHOICE

case $SCHEDULE_CHOICE in
    1)
        CRON_SCHEDULE="0 9 * * *"
        SCHEDULE_DESC="Daily at 9:00 AM"
        ;;
    2)
        CRON_SCHEDULE="0 18 * * *"
        SCHEDULE_DESC="Daily at 6:00 PM"
        ;;
    3)
        CRON_SCHEDULE="0 0 * * *"
        SCHEDULE_DESC="Daily at midnight"
        ;;
    4)
        read -p "Enter custom cron expression (e.g., '0 9 * * *'): " CRON_SCHEDULE
        SCHEDULE_DESC="Custom: $CRON_SCHEDULE"
        ;;
    *)
        echo "Invalid choice. Defaulting to daily at 9:00 AM"
        CRON_SCHEDULE="0 9 * * *"
        SCHEDULE_DESC="Daily at 9:00 AM"
        ;;
esac

echo ""
echo "📅 Schedule: $SCHEDULE_DESC"
echo ""

# Create cron job entry
CRON_COMMAND="$CRON_SCHEDULE $TRACKER_SCRIPT >> $LOG_FILE 2>&1"

# Check if cron job already exists
if crontab -l 2>/dev/null | grep -q "track-my-prs.sh"; then
    echo "⚠️  A PR tracker cron job already exists"
    read -p "Do you want to replace it? (y/n): " REPLACE
    if [[ $REPLACE != "y" && $REPLACE != "Y" ]]; then
        echo "Keeping existing cron job. Exiting."
        exit 0
    fi
    # Remove existing entry
    crontab -l 2>/dev/null | grep -v "track-my-prs.sh" | crontab -
    echo "✅ Removed existing cron job"
fi

# Add new cron job
(crontab -l 2>/dev/null; echo "$CRON_COMMAND") | crontab -

echo ""
echo "✅ Cron job installed successfully!"
echo ""
echo "📋 Cron job details:"
echo "   Schedule: $SCHEDULE_DESC"
echo "   Command: $TRACKER_SCRIPT"
echo "   Logs: $LOG_FILE"
echo "   Output: ${SCRIPT_DIR}/reports/my-open-prs-YYYY-MM-DD.md"
echo "   Latest: ${SCRIPT_DIR}/reports/latest.md"
echo ""
echo "📝 To view your cron jobs: crontab -l"
echo "📝 To remove this cron job: crontab -e (then delete the line)"
echo ""
echo "🧪 To test the script manually, run:"
echo "   $TRACKER_SCRIPT"
echo ""
echo "🎉 Setup complete!"
