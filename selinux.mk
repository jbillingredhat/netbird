# Makefile for NetBird SELinux Policy Module
#
# Usage:
#   make -f selinux.mk          # Build the policy module
#   make -f selinux.mk install  # Build and install the policy
#   make -f selinux.mk reload   # Rebuild and reload the policy
#   make -f selinux.mk remove   # Remove the policy module
#   make -f selinux.mk clean    # Clean build artifacts

POLICY_NAME = netbird
POLICY_VERSION = 1.0.4

# SELinux policy development directory
SELINUX_DEVEL ?= /usr/share/selinux/devel

# Build targets
POLICY_MODULE = $(POLICY_NAME).pp
POLICY_PACKAGE = $(POLICY_NAME).pp.bz2

# Source files
TE_FILE = $(POLICY_NAME).te
FC_FILE = $(POLICY_NAME).fc
IF_FILE = $(POLICY_NAME).if

# Installation directories
BINDIR = /usr/bin
SYSCONFDIR = /etc/$(POLICY_NAME)
STATEDIR = /var/lib/$(POLICY_NAME)
LOGDIR = /var/log/$(POLICY_NAME)
RUNDIR = /run

.PHONY: all build install reload remove clean check help

all: build

# Build the policy module
build: $(POLICY_MODULE)

$(POLICY_MODULE): $(TE_FILE) $(FC_FILE) $(IF_FILE)
	@echo "Building SELinux policy module: $(POLICY_NAME)"
	make -f $(SELINUX_DEVEL)/Makefile $(POLICY_MODULE)
	@echo "Policy module built successfully: $(POLICY_MODULE)"

# Create compressed package
package: $(POLICY_PACKAGE)

$(POLICY_PACKAGE): $(POLICY_MODULE)
	@echo "Creating compressed package: $(POLICY_PACKAGE)"
	bzip2 -9 -c $(POLICY_MODULE) > $(POLICY_PACKAGE)

# Install the policy module
install: build
	@echo "Installing SELinux policy module..."
	sudo semodule -i $(POLICY_MODULE)
	@echo "Restoring file contexts..."
	@sudo restorecon -Rv $(BINDIR)/$(POLICY_NAME) 2>/dev/null || true
	@sudo restorecon -Rv $(SYSCONFDIR) 2>/dev/null || true
	@sudo restorecon -Rv $(STATEDIR) 2>/dev/null || true
	@sudo restorecon -Rv $(LOGDIR) 2>/dev/null || true
	@sudo restorecon -Fv $(RUNDIR)/$(POLICY_NAME).sock 2>/dev/null || true
	@echo "Installation complete. You may need to restart the netbird service."

# Reload the policy (rebuild and reinstall)
reload: clean install
	@echo "Reloading netbird service..."
	@sudo systemctl try-restart $(POLICY_NAME).service 2>/dev/null || true

# Remove the policy module
remove:
	@echo "Removing SELinux policy module..."
	sudo semodule -r $(POLICY_NAME) || true
	@echo "Policy module removed."

# Check for SELinux denials
check:
	@echo "Checking for recent netbird SELinux denials..."
	@sudo ausearch -m avc -ts recent 2>/dev/null | grep $(POLICY_NAME) || echo "No denials found."

# View current policy status
status:
	@echo "Checking netbird SELinux policy status..."
	@sudo semodule -l | grep $(POLICY_NAME) || echo "Policy not installed."
	@echo ""
	@echo "File contexts:"
	@ls -Z $(BINDIR)/$(POLICY_NAME) 2>/dev/null || echo "Binary not found"
	@echo ""
	@echo "Process context:"
	@ps auxZ | grep $(POLICY_NAME) | grep -v grep || echo "Process not running"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -f $(POLICY_MODULE) $(POLICY_PACKAGE)
	rm -f tmp/$(POLICY_NAME).*
	rm -rf tmp/
	@echo "Clean complete."

# Generate additional rules from denials
allow:
	@echo "Generating additional policy from recent denials..."
	@sudo ausearch -m avc -ts recent 2>/dev/null | grep $(POLICY_NAME) | audit2allow -M $(POLICY_NAME)_local || echo "No denials to process."
	@if [ -f $(POLICY_NAME)_local.pp ]; then \
		echo "Generated $(POLICY_NAME)_local.pp. Review $(POLICY_NAME)_local.te and install with:"; \
		echo "  sudo semodule -i $(POLICY_NAME)_local.pp"; \
	fi

# Help
help:
	@echo "NetBird SELinux Policy Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  build    - Build the SELinux policy module (default)"
	@echo "  package  - Create compressed policy package (.pp.bz2)"
	@echo "  install  - Build and install the policy module"
	@echo "  reload   - Rebuild, reinstall, and restart the service"
	@echo "  remove   - Remove the policy module"
	@echo "  check    - Check for recent SELinux denials"
	@echo "  status   - Show policy and context status"
	@echo "  allow    - Generate additional policy from denials"
	@echo "  clean    - Remove build artifacts"
	@echo "  help     - Show this help message"
	@echo ""
	@echo "Example usage:"
	@echo "  make -f selinux.mk build"
	@echo "  make -f selinux.mk install"
	@echo "  make -f selinux.mk check"
