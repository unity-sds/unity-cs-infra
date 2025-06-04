#!/bin/bash

# Test script for Apache config reload race conditions
# Generates random config files and uploads them to S3 with random timing
# Then verifies all files are present in /etc/apache2/venues.d/

set -e

# Configuration
S3_BUCKET_NAME="${S3_BUCKET_NAME:-ucs-shared-services-apache-config-dev-test}"
MIN_FILES="${MIN_FILES:-3}"
MAX_FILES="${MAX_FILES:-8}"
MAX_DELAY_SECONDS="${MAX_DELAY_SECONDS:-30}"
VENUES_DIR="/etc/apache2/venues.d"
TEST_PREFIX="test-race-"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to log with timestamp and color
log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%H:%M:%S')
    
    case $level in
        "INFO")  echo -e "${BLUE}[$timestamp] INFO:${NC} $message" ;;
        "SUCCESS") echo -e "${GREEN}[$timestamp] SUCCESS:${NC} $message" ;;
        "WARNING") echo -e "${YELLOW}[$timestamp] WARNING:${NC} $message" ;;
        "ERROR") echo -e "${RED}[$timestamp] ERROR:${NC} $message" ;;
    esac
}

# Function to generate random config file content
generate_config() {
    local proxy_name=$1
    local path_name=$2
    
    cat << EOF
# Local variables for this venue
Define VENUE_ALB_HOST $proxy_name
Define VENUE_ALB_PORT 8080
Define VENUE_ALB_PATH $path_name

# WebSocket upgrade handling
RewriteCond %{HTTP:Connection} Upgrade [NC]
RewriteCond %{HTTP:Upgrade} websocket [NC]
RewriteCond %{REQUEST_URI} "\${VENUE_ALB_PATH}"
RewriteRule \${VENUE_ALB_PATH}(.*) ws://\${VENUE_ALB_HOST}:\${VENUE_ALB_PORT}\${VENUE_ALB_PATH}\$1 [P,L] [END]

# Location block for this venue
<Location "\${VENUE_ALB_PATH}">
   AuthType openid-connect
   Require valid-user
   ProxyPass "http://\${VENUE_ALB_HOST}:\${VENUE_ALB_PORT}\${VENUE_ALB_PATH}"
   ProxyPassReverse "http://\${VENUE_ALB_HOST}:\${VENUE_ALB_PORT}\${VENUE_ALB_PATH}"
   RequestHeader set "X-Forwarded-Proto" expr=%{REQUEST_SCHEME}
   RequestHeader set "X-Forwarded-Host" "www.dev.mdps.mcp.nasa.gov:\${PORT_NUM}"
</Location>

# Clean up
UnDefine VENUE_ALB_HOST
UnDefine VENUE_ALB_PORT
UnDefine VENUE_ALB_PATH
EOF
}

# Function to generate random proxy name
generate_proxy_name() {
    local prefixes=("app" "service" "api" "web" "data" "auth" "admin" "dashboard" "gateway" "worker")
    local suffixes=("prod" "dev" "test" "stage" "blue" "green" "alpha" "beta" "main" "backup")
    local environments=("east" "west" "central" "internal" "external" "public" "private" "secure" "fast")
    
    local prefix=${prefixes[$RANDOM % ${#prefixes[@]}]}
    local env=${environments[$RANDOM % ${#environments[@]}]}
    local suffix=${suffixes[$RANDOM % ${#suffixes[@]}]}
    local num=$((RANDOM % 999 + 1))
    
    echo "${prefix}-${env}-${suffix}-${num}.example.com"
}

# Function to generate random path name
generate_path_name() {
    local paths=("unity" "data" "api" "admin" "dashboard" "portal" "app" "service" "gateway" "auth")
    local versions=("v1" "v2" "v3" "beta" "alpha" "latest" "stable" "dev")
    local features=("core" "main" "lite" "pro" "basic" "advanced" "secure" "fast")
    
    local path=${paths[$RANDOM % ${#paths[@]}]}
    local version=${versions[$RANDOM % ${#versions[@]}]}
    local feature=${features[$RANDOM % ${#features[@]}]}
    
    echo "/${path}/${version}/${feature}"
}

# Function to cleanup test files from S3
cleanup_s3() {
    log "INFO" "Cleaning up test files from S3 bucket: $S3_BUCKET_NAME"
    
    # List and delete test files
    local test_files=$(aws s3 ls "s3://$S3_BUCKET_NAME/" | grep "$TEST_PREFIX" | awk '{print $4}' || true)
    
    if [ -n "$test_files" ]; then
        echo "$test_files" | while read -r file; do
            if [ -n "$file" ]; then
                log "INFO" "Deleting s3://$S3_BUCKET_NAME/$file"
                aws s3 rm "s3://$S3_BUCKET_NAME/$file"
            fi
        done
    else
        log "INFO" "No test files found to clean up"
    fi
}

# Function to verify files in venues directory
verify_venues_dir() {
    local expected_files=("$@")
    local wait_time=60
    
    log "INFO" "Waiting $wait_time seconds for Apache reload to complete..."
    sleep $wait_time
    
    log "INFO" "Verifying files in $VENUES_DIR"
    
    # Get actual files (only test files)
    local actual_files=()
    if sudo ls "$VENUES_DIR"/ 2>/dev/null | grep -q "$TEST_PREFIX"; then
        while IFS= read -r file; do
            actual_files+=("$file")
        done < <(sudo ls "$VENUES_DIR"/ | grep "$TEST_PREFIX" | sort)
    fi
    
    # Sort expected files for comparison
    local sorted_expected=($(printf '%s\n' "${expected_files[@]}" | sort))
    
    log "INFO" "Expected files (${#sorted_expected[@]}): ${sorted_expected[*]}"
    log "INFO" "Actual files (${#actual_files[@]}): ${actual_files[*]}"
    
    # Check if arrays match
    local success=true
    
    if [ ${#sorted_expected[@]} -ne ${#actual_files[@]} ]; then
        log "ERROR" "File count mismatch! Expected ${#sorted_expected[@]}, found ${#actual_files[@]}"
        success=false
    else
        for i in "${!sorted_expected[@]}"; do
            if [ "${sorted_expected[$i]}" != "${actual_files[$i]}" ]; then
                log "ERROR" "File mismatch at position $i: expected '${sorted_expected[$i]}', found '${actual_files[$i]}'"
                success=false
                break
            fi
        done
    fi
    
    if [ "$success" = true ]; then
        log "SUCCESS" "All files verified successfully! ✅"
        return 0
    else
        log "ERROR" "File verification failed! ❌"
        
        # Show detailed diff
        log "INFO" "Files missing from venues directory:"
        for file in "${sorted_expected[@]}"; do
            if ! printf '%s\n' "${actual_files[@]}" | grep -q "^$file$"; then
                log "WARNING" "  Missing: $file"
            fi
        done
        
        log "INFO" "Extra files in venues directory:"
        for file in "${actual_files[@]}"; do
            if ! printf '%s\n' "${sorted_expected[@]}" | grep -q "^$file$"; then
                log "WARNING" "  Extra: $file"
            fi
        done
        
        return 1
    fi
}

# Function to run race condition test
run_race_test() {
    local test_num=$1
    
    log "INFO" "🏁 Starting Race Condition Test #$test_num"
    
    # Generate random number of files
    local num_files=$((RANDOM % (MAX_FILES - MIN_FILES + 1) + MIN_FILES))
    log "INFO" "Generating $num_files random config files"
    
    # Generate file names and delays
    local files=()
    local delays=()
    local temp_dir=$(mktemp -d)
    
    for i in $(seq 1 $num_files); do
        local filename="${TEST_PREFIX}venue-${test_num}-${i}.conf"
        local proxy_name=$(generate_proxy_name)
        local path_name=$(generate_path_name)
        local delay=$((RANDOM % MAX_DELAY_SECONDS))
        
        files+=("$filename")
        delays+=("$delay")
        
        # Generate config file
        local filepath="$temp_dir/$filename"
        generate_config "$proxy_name" "$path_name" > "$filepath"
        
        log "INFO" "Created $filename (proxy: $proxy_name, path: $path_name, delay: ${delay}s)"
    done
    
    # Sort by delay to create the upload schedule
    local upload_schedule=()
    for i in "${!files[@]}"; do
        upload_schedule+=("${delays[$i]}:${files[$i]}")
    done
    IFS=$'\n' upload_schedule=($(sort -n <<< "${upload_schedule[*]}"))
    
    log "INFO" "Upload schedule (delay:filename):"
    for item in "${upload_schedule[@]}"; do
        log "INFO" "  $item"
    done
    
    # Start uploads with timing
    local start_time=$(date +%s)
    log "INFO" "🚀 Starting timed uploads at $(date '+%H:%M:%S')"
    
    for item in "${upload_schedule[@]}"; do
        local delay_time=${item%:*}
        local filename=${item#*:}
        local filepath="$temp_dir/$filename"
        
        # Calculate time to wait
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        local wait_time=$((delay_time - elapsed))
        
        if [ $wait_time -gt 0 ]; then
            log "INFO" "⏱️  Waiting ${wait_time}s before uploading $filename"
            sleep $wait_time
        fi
        
        # Upload to S3
        local upload_time=$(date '+%H:%M:%S')
        log "INFO" "📤 Uploading $filename at $upload_time"
        aws s3 cp "$filepath" "s3://$S3_BUCKET_NAME/$filename"
        
        if [ $? -eq 0 ]; then
            log "SUCCESS" "✅ Uploaded $filename"
        else
            log "ERROR" "❌ Failed to upload $filename"
        fi
    done
    
    local end_time=$(date +%s)
    local total_time=$((end_time - start_time))
    log "INFO" "📊 All uploads completed in ${total_time}s"
    
    # Verify results
    verify_venues_dir "${files[@]}"
    local verify_result=$?
    
    # Cleanup temp directory
    rm -rf "$temp_dir"
    
    return $verify_result
}

# Main execution
main() {
    log "INFO" "🧪 Apache Config Reload Race Condition Tester"
    log "INFO" "S3 Bucket: $S3_BUCKET_NAME"
    log "INFO" "File Range: $MIN_FILES-$MAX_FILES files"
    log "INFO" "Max Delay: $MAX_DELAY_SECONDS seconds"
    log "INFO" "Test Prefix: $TEST_PREFIX"
    
    # Check dependencies
    if ! command -v aws >/dev/null 2>&1; then
        log "ERROR" "AWS CLI is required but not installed"
        exit 1
    fi
    
    # Verify S3 bucket access
    log "INFO" "Verifying S3 bucket access..."
    if ! aws s3 ls "s3://$S3_BUCKET_NAME/" >/dev/null 2>&1; then
        log "ERROR" "Cannot access S3 bucket: $S3_BUCKET_NAME"
        exit 1
    fi
    log "SUCCESS" "S3 bucket access verified"
    
    # Cleanup any existing test files first
    cleanup_s3
    
    # Run tests
    local test_count=${1:-1}
    local passed=0
    local failed=0
    
    for test_num in $(seq 1 $test_count); do
        log "INFO" "=============================================="
        log "INFO" "===       $test_num of $test_count         ==="
        
        if run_race_test $test_num; then
            log "SUCCESS" "🎉 Test #$test_num PASSED"
            ((passed++))
        else
            log "ERROR" "💥 Test #$test_num FAILED"
            ((failed++))
        fi
        
        # Cleanup S3 after each test
        log "INFO" "Cleaning up after test #$test_num"
        cleanup_s3
        
        # Wait between tests if not the last one
        if [ $test_num -lt $test_count ]; then
            log "INFO" "Waiting 30 seconds before next test..."
            sleep 30
        fi
    done
    
    # Final results
    log "INFO" "=============================================="
    log "INFO" "📊 FINAL RESULTS"
    log "SUCCESS" "✅ Passed: $passed"
    if [ $failed -gt 0 ]; then
        log "ERROR" "❌ Failed: $failed"
    else
        log "INFO" "❌ Failed: $failed"
    fi
    log "INFO" "🎯 Success Rate: $(( passed * 100 / (passed + failed) ))%"
    
    if [ $failed -eq 0 ]; then
        log "SUCCESS" "🏆 All tests passed!"
        exit 0
    else
        log "ERROR" "💔 Some tests failed!"
        exit 1
    fi
}

# Handle command line arguments
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 [TEST_COUNT]"
    echo ""
    echo "Environment variables:"
    echo "  S3_BUCKET_NAME      S3 bucket for config files (default: ucs-shared-services-apache-config-dev-test)"
    echo "  MIN_FILES           Minimum files per test (default: 3)"
    echo "  MAX_FILES           Maximum files per test (default: 8)"
    echo "  MAX_DELAY_SECONDS   Maximum delay between uploads (default: 30)"
    echo ""
    echo "Examples:"
    echo "  $0                  # Run 1 test"
    echo "  $0 5                # Run 5 tests"
    echo "  S3_BUCKET_NAME=my-bucket $0 3  # Custom bucket, 3 tests"
    exit 0
fi

# Run main function
main "${1:-1}"