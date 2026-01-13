.PHONY: install uninstall check test help

INSTALL_PATH := /usr/local/bin/chainlist
SCRIPT_PATH := $(CURDIR)/chainlist.sh

help:
	@echo "Chainlist CLI - Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  make check      - Check if dependencies are installed"
	@echo "  make install    - Install chainlist command globally"
	@echo "  make uninstall  - Remove chainlist command"
	@echo "  make test       - Run example searches"
	@echo "  make help       - Show this help message"

check:
	@echo "Checking dependencies..."
	@command -v jq >/dev/null 2>&1 || { echo "❌ jq is not installed. Run: brew install jq"; exit 1; }
	@echo "✓ jq is installed"
	@command -v curl >/dev/null 2>&1 || { echo "❌ curl is not installed. Run: brew install curl"; exit 1; }
	@echo "✓ curl is installed"
	@test -f "$(SCRIPT_PATH)" || { echo "❌ token.sh not found"; exit 1; }
	@echo "✓ token.sh found"
	@echo "✓ All dependencies are satisfied"

install: check
	@echo "Installing token command..."
	@chmod +x "$(SCRIPT_PATH)"
	@ln -sf "$(SCRIPT_PATH)" "$(INSTALL_PATH)"
	@echo "✓ Installed to $(INSTALL_PATH)"
	@echo ""
	@echo "You can now use: token 1 USDC"

uninstall:
	@echo "Uninstalling token command..."
	@rm -f "$(INSTALL_PATH)"
	@echo "✓ Removed $(INSTALL_PATH)"

test: check
	@echo "Running test queries..."
	@echo ""
	@echo "Test 1: Find Arbitrum (chainId 42161)"
	@./chainlist.sh 42161
	@echo ""
	@echo "✓ Tests completed"
