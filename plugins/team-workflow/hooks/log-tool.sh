#!/usr/bin/env bash
set -uo pipefail

# ==============================================================================
# SCRIPT OVERVIEW & LOGGING SPECIFICATION:
# This script handles structured application logging and weekly archiving directly 
# inside the plugin root directory (${CLAUDE_PLUGIN_ROOT}):
# 
# 1. LOGGING DETAILS: Captures incoming standard input (payload), appends an 
#    80-character visual separator, an ISO-8601 timestamp with timezone, the 
#    payload itself, and a fully sanitized list of current environment variables 
#    (automatically masking sensitive keys like tokens, secrets, and passwords).
# 2. WEEKLY ARCHIVING: Groups past daily log files by calendar week 
#    (format: YYYY-WEEK##.tar.gz, e.g., 2026-WEEK24.tar.gz).
# 3. SAFETY GUARANTEE: Implements strict validation checks. Original log files 
#    are ONLY deleted after confirming that the tar.gz archive was successfully 
#    created or updated.
# ==============================================================================

# Strict umask to ensure log files are only readable by the owner
umask 077

# Get plugin name from CLAUDE_PLUGIN_ROOT directory path
PLUGIN_NAME=$(basename "${CLAUDE_PLUGIN_ROOT:-unknown-plugin}")

# Define the root directory for logs and archives directly in the plugin root
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}"

# ==============================================================================
# STEP 1: Weekly Log Compression and Archiving (with safety checks)
# ==============================================================================
# Get current week number and year (e.g., Year: 2026, Week: 24 -> 2026-WEEK24)
CURRENT_YEAR_WEEK="$(date '+%Y-WEEK%V')"

if [ -d "$PLUGIN_ROOT" ]; then
    # Loop through all daily log files in the plugin root
    for log_path in "$PLUGIN_ROOT"/log-tool-*.log; do
        [ -f "$log_path" ] || continue
        
        filename="$(basename "$log_path")"
        
        # Extract date from filename to determine its week (format: log-tool-YYYY-MM-DD.log)
        if [[ "$filename" =~ log-tool-([0-9]{4})-([0-9]{2})-([0-9]{2})\.log ]]; then
            log_year="${BASH_REMATCH[1]}"
            log_month="${BASH_REMATCH[2]}"
            log_day="${BASH_REMATCH[3]}"
            
            # Calculate the ISO week number for this specific log file date
            # (Works on Linux/GNU date; falls back safely if format differs)
            file_year_week=$(date -d "${log_year}-${log_month}-${log_day}" '+%Y-WEEK%V' 2>/dev/null || echo "")
            
            # Process only files that belong to past weeks (exclude current active week)
            if [ -n "$file_year_week" ] && [ "$file_year_week" != "$CURRENT_YEAR_WEEK" ]; then
                archive_gz="${PLUGIN_ROOT}/${file_year_week}.tar.gz"
                archive_tar="${PLUGIN_ROOT}/${file_year_week}.tar"
                archive_success=false
                
                if [ -f "$archive_gz" ]; then
                    # Archive already exists: 
                    # 1. Decompress to .tar
                    # 2. Append the new old log file
                    # 3. Compress back to .tar.gz
                    if gunzip -f "$archive_gz" 2>/dev/null && \
                       tar -rf "$archive_tar" -C "$PLUGIN_ROOT" "$filename" 2>/dev/null && \
                       gzip -f "$archive_tar" 2>/dev/null; then
                        archive_success=true
                    fi
                else
                    # Archive does not exist yet: create initial .tar.gz for this week
                    if tar -czf "$archive_gz" -C "$PLUGIN_ROOT" "log-tool-${log_year}-${log_month}-${log_day}.log" 2>/dev/null; then
                        archive_success=true
                    fi
                fi
                
                # SAFETY CHECK: Delete the original log file ONLY if the archive operation succeeded
                if [ "$archive_success" = true ] && [ -f "$archive_gz" ]; then
                    rm -f "$log_path"
                fi
            fi
        fi
    done
fi

# ==============================================================================
# STEP 2: Writing Current Log Entry
# ==============================================================================
# Set the path for today's log file directly inside the plugin root directory
LOG_FILE="${PLUGIN_ROOT}/log-tool-$(date '+%Y-%m-%d').log"

# Capture standard input (incoming payload/message to log)
INPUT="$(cat)"

# Append formatted separator, timestamp, payload, and sanitized environment variables to the log file
{
  printf -- '-%.0s' $(seq 1 80); echo
  echo "$(date +%Y-%m-%dT%H:%M:%S%z)"
  echo "$INPUT"
  echo "env:"
  # Sort environment variables and mask sensitive keys/tokens/secrets for security
  env | sort | sed -E 's/^([^=]*(KEY|TOKEN|SECRET|PASSWORD|PASSWD|CREDENTIAL|AUTH)[^=]*)=.*/\1=***HIDDEN***/' | sed 's/^/  /'
} >> "$LOG_FILE"

exit 0