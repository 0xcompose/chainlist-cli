# Chainlist CLI

Command Line Interface for Chainlist functionality:

-   Finding networks by name / chain ID
-   Getting Chain RPC URLs
-   Checking RPC URLs
-   Getting Chain's block explorer

## Installation

```bash
make install
```

This will install the `chainlist` command globally.

## Usage

Search by chain name:

```bash
chainlist arbitrum
```

Search by chain ID:

```bash
chainlist 56
```

Check RPC endpoint health:

```bash
chainlist ethereum --check-rpc
```

## Features

-   **Smart Caching**: Caches data for 1 hour to reduce API calls
-   **Flexible Search**: Case-insensitive search by name or exact chain ID
-   **RPC Health Check**: Test RPC endpoints with `--check-rpc` flag
-   **Colored Output**: Easy-to-read terminal output with color coding
-   **Comprehensive Info**: Shows chain details, RPC URLs, and block explorers

## Requirements

-   `jq` - JSON processor
    ```bash
    brew install jq
    ```

## Uninstall

```bash
make uninstall
```
