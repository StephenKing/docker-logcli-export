#!/bin/bash

set -eou pipefail

# export LOKI_ADDR=https://logs-prod-eu-west-0.grafana.net
# export LOKI_USERNAME=12345
# export LOKI_USERNAME=

# Check if two or four arguments are provided
if [ "$#" -ne 2 ] && [ "$#" -ne 4 ]; then
    echo "Usage: $0 filter s3_uri start_date end_date"
    echo "       $0 filter <-- will then filter for yesterday's data"
    echo
    echo "Dates should be in the format YYYY-MM-DD"
    echo
    echo "Example: $(basename \"$0\") '{app=\"foo\"}' s3://bucket/path 2024-01-01 2024-01-31"
    exit 1
fi

# Assign the s3_uri start and end dates to variables
filter=$1
s3_uri=$2


# if we have no dates specified, use yesterday
if [ "$#" -eq 2 ]; then
  YESTERDAY=$(date -d '-1 day' '+%Y-%m-%d')
  start_date=$YESTERDAY
  end_date=$YESTERDAY
else
  start_date=$3
  end_date=$4
fi

echo "Filter: $filter"

# Convert the dates to Unix timestamps
start_timestamp=$(date -d "$start_date" +%s)
end_timestamp=$(date -d "$end_date" +%s)

mkdir -p data/

# Iterate over the date range
current_timestamp=$start_timestamp
while [ $current_timestamp -le $end_timestamp ]; do
    # Convert the timestamp back to a date
    current_date=$(date -d @$current_timestamp +%Y-%m-%d)
    next_date=$(date -d @$((current_timestamp+86400)) +%Y-%m-%d)

    echo "Starting $current_date"

    logcli query --quiet --forward --limit=1000000000000 \
      --compress \
      --parallel-duration=1h \
      --parallel-max-workers=24 \
      --part-path-prefix="data/part" \
      --from="${current_date}T00:00:00Z" \
      --to="${next_date}T00:00:00Z" \
      ${filter} --output=raw

    # Increment the timestamp by one day (86400 seconds)
    current_timestamp=$((current_timestamp+86400))

    aws s3 mv data/ $s3_uri --recursive --only-show-errors
done
