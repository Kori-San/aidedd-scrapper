.phony: all clean

help: ## Show this help.
	@grep "##" $(MAKEFILE_LIST) | grep -v "grep" | sed 's/:.*##\s*/:@\t/g' | column -t -s "@"

all: help

clean: ## Clean all the JSON using the `$SCRIPT_NAME.$TIMESTAMP.json` formatting.
	@echo "🧹 Cleaning..."
	@$(RM) *\.*\:*\:*\-*\_*\_*\.json
	@echo "✨ Cleaned"