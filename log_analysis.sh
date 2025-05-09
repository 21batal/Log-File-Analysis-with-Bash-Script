#!/bin/bash

LOGFILE="access.log"  # Replace with your actual log file name

# 1. Request Counts
total_requests=$(wc -l < "$LOGFILE")
get_requests=$(grep '"GET ' "$LOGFILE" | wc -l)
post_requests=$(grep '"POST ' "$LOGFILE" | wc -l)

# 2. Unique IP Addresses
unique_ips=$(awk '{print $1}' "$LOGFILE" | sort | uniq | wc -l)

echo "IP GET/POST breakdown:"
awk '{print $1, $6}' "$LOGFILE" | grep -E '"GET|POST' | sed 's/"//' |
    awk '{counts[$1" "$2]++} END {for (k in counts) print k, counts[k]}' |
    sort

# 3. Failure Requests
failures=$(awk '$9 ~ /^4|^5/ {count++} END {print count+0}' "$LOGFILE")
fail_percent=$(awk -v f=$failures -v t=$total_requests 'BEGIN {printf "%.2f", (f/t)*100}')

# 4. Top User
top_ip=$(awk '{print $1}' "$LOGFILE" | sort | uniq -c | sort -nr | head -1)

# 5. Daily Request Averages
total_days=$(awk -F: '{print $1}' "$LOGFILE" | awk -F\[ '{print $2}' | sort -u | wc -l)
avg_daily_requests=$(awk -v total=$total_requests -v days=$total_days 'BEGIN {printf "%.2f", total/days}')

# 6. Failure Analysis
echo "Failures by day:"
awk '$9 ~ /^4|^5/ {split($4, d, ":"); day=substr(d[1], 2); fails[day]++} END {for (d in fails) print d, fails[d]}' "$LOGFILE" | sort

# Additional: Requests by Hour
echo "Requests by hour:"
awk -F: '{split($1, d, "["); split($2, t, ":"); hour=t[1]; print hour}' "$LOGFILE" | sort | uniq -c

# Request Trends (simple trend observation)
echo "Request trend (day-wise):"
awk -F: '{print $1}' "$LOGFILE" | awk -F\[ '{print $2}' | sort | uniq -c

# Status Code Breakdown
echo "Status code breakdown:"
awk '{count[$9]++} END {for (code in count) print code, count[code]}' "$LOGFILE" | sort

# Most Active User by Method
echo "Top GET requester:"
grep '"GET ' "$LOGFILE" | awk '{print $1}' | sort | uniq -c | sort -nr | head -1
echo "Top POST requester:"
grep '"POST ' "$LOGFILE" | awk '{print $1}' | sort | uniq -c | sort -nr | head -1

# Failure Patterns by Hour
echo "Failure patterns by hour:"
awk '$9 ~ /^4|^5/ {split($4, d, ":"); hour=d[2]; fail[hour]++} END {for (h in fail) print h, fail[h]}' "$LOGFILE" | sort

# Summary Output
echo "========== SUMMARY =========="
echo "Total Requests: $total_requests"
echo "GET Requests: $get_requests"
echo "POST Requests: $post_requests"
echo "Unique IPs: $unique_ips"
echo "Failed Requests: $failures ($fail_percent%)"
echo "Most Active IP: $top_ip"
echo "Average Requests per Day: $avg_daily_requests"
echo "============================="
