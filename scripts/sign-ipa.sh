#!/bin/bash

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

sign_ipa() {
    if [ "$#" -ne 5 ]; then
        log_message "Usage: $0 <ipa> <p12> <password> <mobileprovision> <output>"
        return 1
    fi

    local IPA_FILE="$1"
    local P12_FILE="$2"
    local PASSWORD="$3"
    local MOBILEPROVISION_FILE="$4"
    local OUTPUT_FILE="$5"

    local UPLOAD_URL="https://ipa.ipasign.cc:2052/uploadipa"
    local SIGNCHECK_URL="https://ipa.ipasign.cc:2052/signcheck"

    log_message "Signing .ipa with ipasign.cc"
    log_message "Upload in progress..."

    # Verify input files exist
    for file in "$IPA_FILE" "$P12_FILE" "$MOBILEPROVISION_FILE"; do
        if [ ! -f "$file" ]; then
            log_message "Error: File does not exist: $file"
            return 1
        fi
    done

    local RESPONSE
    RESPONSE=$(curl -s $UPLOAD_URL \
        -H 'accept: application/json, text/plain, */*' \
        -H 'accept-language: en-AU,en;q=0.9' \
        -H 'cache-control: no-cache' \
        -H 'dnt: 1' \
        -H 'origin: https://sign.ipasign.cc' \
        -H 'pragma: no-cache' \
        -H 'priority: u=1, i' \
        -H 'referer: https://sign.ipasign.cc/' \
        -H 'sec-ch-ua: "Not(A:Brand";v="99", "Google Chrome";v="133", "Chromium";v="133"' \
        -H 'sec-ch-ua-mobile: ?0' \
        -H 'sec-ch-ua-platform: "macOS"' \
        -H 'sec-fetch-dest: empty' \
        -H 'sec-fetch-mode: cors' \
        -H 'sec-fetch-site: same-site' \
        -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36' \
        -F "ipa=@$IPA_FILE" \
        -F "p12=@$P12_FILE" \
        -F "name=" \
        -F "password=$PASSWORD" \
        -F "unlock=0" \
        -F "identifier=" \
        -F "mobileprovision=@$MOBILEPROVISION_FILE")

    # Check if curl succeeded
    if [ $? -ne 0 ]; then
        log_message "Error: Upload request failed."
        return 1
    fi

    # Extract UUID and time from response (used to construct the download link)
    local UUID
    local TIME
    UUID=$(echo "$RESPONSE" | jq -r '.data.uuid')
    TIME=$(echo "$RESPONSE" | jq -r '.data.time')

    # Validate response
    if [[ "$UUID" == "null" || "$TIME" == "null" || -z "$UUID" || -z "$TIME" ]]; then
        log_message "Error: Failed to retrieve UUID or time from response."
        log_message "Response: $RESPONSE"
        return 1
    fi

    # Poll signcheck endpoint
    local ATTEMPTS=0
    local MAX_ATTEMPTS=10
    local SLEEP_DURATION=20
    local SIGN_STATUS
    local SIGNCHECK_RESPONSE

    while [[ $ATTEMPTS -lt $MAX_ATTEMPTS ]]; do
        SIGNCHECK_RESPONSE=$(curl -s -X POST "$SIGNCHECK_URL" \
            -H "accept: application/json, text/plain, */*" \
            -H "content-type: multipart/form-data" \
            -F "uuid=$UUID" \
            -F "time=$TIME")
        
        if [ $? -ne 0 ]; then
            log_message "Error: Failed to check signing status."
            ((ATTEMPTS++))
            log_message "Retrying... attempt $ATTEMPTS of $MAX_ATTEMPTS."
            sleep $SLEEP_DURATION
            continue
        fi
        
        SIGN_STATUS=$(echo "$SIGNCHECK_RESPONSE" | jq -r '.code')
        
        if [[ "$SIGN_STATUS" == "0" ]]; then
            log_message "Signing successful. Proceeding to download."
            break
        fi
        
        ((ATTEMPTS++))
        log_message "Signing in progress... attempt $ATTEMPTS of $MAX_ATTEMPTS. Checking again in $SLEEP_DURATION seconds."
        sleep $SLEEP_DURATION
    done

    if [[ $ATTEMPTS -eq $MAX_ATTEMPTS ]]; then
        log_message "Error: Signing process timed out after $MAX_ATTEMPTS attempts."
        return 1
    fi

    # Construct the download URL
    local DOWNLOAD_URL="https://ipa.ipasign.cc:2052/sign/$TIME/$UUID/resign_$TIME.ipa"

    # Download the signed IPA file
    curl -s -o "$OUTPUT_FILE" "$DOWNLOAD_URL"
    
    if [ $? -ne 0 ] || [ ! -f "$OUTPUT_FILE" ] || [ ! -s "$OUTPUT_FILE" ]; then
        log_message "Error: Failed to download the signed IPA file."
        return 1
    fi

    log_message "Download complete: $OUTPUT_FILE"
    return 0
}

sign_ipa "$@"
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    log_message ".ipa signing completed successfully."
    exit 0
else
    log_message ".ipa signing failed with exit code $EXIT_CODE."
    exit 1
fi