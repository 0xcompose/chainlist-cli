.PHONY: install uninstall test

install:
	@echo "Installing chainlist CLI..."
	@chmod +x chainlist.sh
	@ln -sf $(PWD)/chainlist.sh /usr/local/bin/chainlist
	@echo "✓ Installed! Run 'chainlist --help' to get started"

uninstall:
	@echo "Uninstalling chainlist CLI..."
	@rm -f /usr/local/bin/chainlist
	@echo "✓ Uninstalled"

test:
	@echo "Testing chainlist with Ethereum..."
	@./chainlist.sh ethereum
