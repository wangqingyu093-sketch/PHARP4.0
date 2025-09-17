#!/bin/bash
# Download SRA files using aria2

DOWNLOAD_LIST="sra_urls.txt"
LOG_FILE="sra_download.log"
MAX_RETRIES=5

echo "Starting SRA download at $(date)" | tee -a $LOG_FILE

for ((i=1; i<=$MAX_RETRIES; i++)); do
    echo "Download attempt $i of $MAX_RETRIES" | tee -a $LOG_FILE
    aria2c -c -x5 -s 5 --max-download-limit=10M -i $DOWNLOAD_LIST
    
    if [ $? -eq 0 ]; then
        echo "Download completed successfully" | tee -a $LOG_FILE
        break
    else
        echo "Download failed, retrying..." | tee -a $LOG_FILE
        sleep 300
    fi
done

echo "SRA download finished at $(date)" | tee -a $LOG_FILE
