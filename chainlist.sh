#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CHAINLIST_URL="https://chainlist.org/rpcs.json"
CACHE_FILE="/tmp/chainlist_cache.json"
CACHE_DURATION=3600 # 1 hour in seconds

# Function to fetch and cache data
fetch_data() {
    if [ -f "$CACHE_FILE" ] && [ -s "$CACHE_FILE" ]; then
        local file_age=$(($(date +%s) - $(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)))
        if [ $file_age -lt $CACHE_DURATION ]; then
            cat "$CACHE_FILE"
            return
        fi
    fi
    
    echo -e "${YELLOW}Fetching latest data from Chainlist...${NC}" >&2
    
    # Try to fetch data with curl
    local temp_file=$(mktemp)
    if curl -s -f -L "$CHAINLIST_URL" -o "$temp_file" 2>/dev/null; then
        if [ -s "$temp_file" ]; then
            cat "$temp_file" | tee "$CACHE_FILE"
            rm "$temp_file"
            return 0
        fi
    fi
    
    # If curl fails, try with insecure flag (for environments with cert issues)
    if curl -s -f -L -k "$CHAINLIST_URL" -o "$temp_file" 2>/dev/null; then
        if [ -s "$temp_file" ]; then
            cat "$temp_file" | tee "$CACHE_FILE"
            rm "$temp_file"
            return 0
        fi
    fi
    
    rm -f "$temp_file"
    
    # If we have an old cache, use it
    if [ -f "$CACHE_FILE" ] && [ -s "$CACHE_FILE" ]; then
        echo -e "${YELLOW}Using cached data (fetch failed)${NC}" >&2
        cat "$CACHE_FILE"
        return 0
    fi
    
    echo -e "${RED}Failed to fetch data from Chainlist API${NC}" >&2
    exit 1
}

# Function to check if argument is a number
is_number() {
    [[ $1 =~ ^[0-9]+$ ]]
}

# Function to check RPC URL
check_rpc() {
    local rpc_url=$1
    echo -e "${YELLOW}Checking RPC: $rpc_url${NC}"
    
    # Skip websocket URLs
    if [[ $rpc_url == wss://* ]] || [[ $rpc_url == ws://* ]]; then
        echo -e "${BLUE}WebSocket URL (skipping HTTP check)${NC}"
        return
    fi
    
    # Try to get chain ID via eth_chainId
    local response=$(curl -s -m 5 -X POST "$rpc_url" \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$response" ]; then
        local chain_id=$(echo "$response" | jq -r '.result // empty' 2>/dev/null)
        if [ -n "$chain_id" ]; then
            echo -e "${GREEN}✓ Active (Chain ID: $chain_id)${NC}"
        else
            echo -e "${RED}✗ No valid response${NC}"
        fi
    else
        echo -e "${RED}✗ Timeout or connection error${NC}"
    fi
}

# Function to display chain info
display_chain() {
    local chain_data=$1
    
    echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Chain Information${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    echo "$chain_data" | jq -r '
        "Name:           \(.name)",
        "Chain:          \(.chain)",
        "Chain ID:       \(.chainId)",
        "Network ID:     \(.networkId)",
        "Native Token:   \(.nativeCurrency.name) (\(.nativeCurrency.symbol))",
        "Info URL:       \(.infoURL // "N/A")",
        "Testnet:        \(if .isTestnet then "Yes" else "No" end)"
    '
    
    echo -e "\n${BLUE}RPC Endpoints:${NC}"
    echo "$chain_data" | jq -r '.rpc[] | 
        if type == "object" then
            "  • \(.url) | Tracking: \(.tracking // "N/A") | Open Source: \(.isOpenSource // "N/A")"
        else
            "  • \(.)"
        end'
    
    local explorers=$(echo "$chain_data" | jq -r '.explorers // [] | length')
    if [ "$explorers" -gt 0 ]; then
        echo -e "\n${BLUE}Block Explorers:${NC}"
        echo "$chain_data" | jq -r '.explorers[] | "  • \(.name): \(.url) (Standard: \(.standard // "N/A"))"'
    else
        echo -e "\n${YELLOW}No block explorers available${NC}"
    fi
    
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# Main script
main() {
    if [ $# -eq 0 ]; then
        echo "Usage: chainlist <chain-name|chain-id> [--check-rpc]"
        echo ""
        echo "Examples:"
        echo "  chainlist arbitrum"
        echo "  chainlist 56"
        echo "  chainlist ethereum --check-rpc"
        exit 1
    fi
    
    local query=$1
    local check_rpc_flag=false
    
    if [ "$2" == "--check-rpc" ]; then
        check_rpc_flag=true
    fi
    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Error: jq is not installed. Please install it first.${NC}"
        echo "  brew install jq"
        exit 1
    fi
    
    # Fetch data
    local data=$(fetch_data)
    
    # Search by chain ID or name
    local result
    if is_number "$query"; then
        result=$(echo "$data" | jq ".[] | select(.chainId == $query)")
    else
        # Case-insensitive search by name
        result=$(echo "$data" | jq --arg query "$query" '.[] | select(.name | ascii_downcase | contains($query | ascii_downcase))')
    fi
    
    if [ -z "$result" ]; then
        echo -e "${RED}No chain found matching: $query${NC}"
        exit 1
    fi
    
    # Count results
    local count=$(echo "$result" | jq -s 'length')
    
    if [ "$count" -eq 1 ]; then
        display_chain "$result"
        
        if [ "$check_rpc_flag" = true ]; then
            echo -e "${YELLOW}Checking RPC endpoints...${NC}\n"
            echo "$result" | jq -r '.rpc[] | if type == "object" then .url else . end' | while read -r rpc_url; do
                check_rpc "$rpc_url"
            done
        fi
    else
        echo -e "${GREEN}Found $count matching chains:${NC}\n"
        echo "$result" | jq -s '.[] | "\(.name) (Chain ID: \(.chainId))"' -r
        echo -e "\n${YELLOW}Please be more specific or use the exact chain ID${NC}"
    fi
}

main "$@"
