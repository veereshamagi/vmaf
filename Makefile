# Makefile for video_quality_lab

# OpenMP flags (from scratch_file_1.txt)
export LDFLAGS := -L/usr/local/opt/libomp/lib
export CPPFLAGS := -I/usr/local/opt/libomp/include

# libvmaf configuration
LIBVMAF_DIR := libvmaf
LIBVMAF_SOURCE_DIR := $(LIBVMAF_DIR)/libvmaf
LIBVMAF_BUILD_DIR := $(LIBVMAF_SOURCE_DIR)/build
LIBVMAF_VMAF_TOOL := $(LIBVMAF_BUILD_DIR)/tools/vmaf
LIBVMAF_VMAF_LINK := $(LIBVMAF_DIR)/vmaf
LIBVMAF_PYTHON_DIR := $(LIBVMAF_DIR)/python
LIBVMAF_URL := https://github.com/Netflix/vmaf.git

.PHONY: all clean help libvmaf libvmaf-clone libvmaf-build libvmaf-clean libvmaf-python libvmaf-python-requirements libvmaf-link libvmaf-test

# Default target
all: libvmaf

# Show help message
help:
	@echo "Available targets:"
	@echo "  make all            - Build libvmaf (default)"
	@echo "  make libvmaf        - Clone and build libvmaf"
	@echo "  make libvmaf-clone  - Clone libvmaf repository"
	@echo "  make libvmaf-build  - Build libvmaf (requires meson and ninja)"
	@echo "  make libvmaf-link              - Create symlink: ./libvmaf/vmaf -> build/tools/vmaf"
	@echo "  make libvmaf-python-requirements - Install VMAF Python requirements"
	@echo "  make libvmaf-python            - Install VMAF Python package (pip install -e)"
	@echo "  make libvmaf-test              - Run VMAF Python unit tests"
	@echo "  make libvmaf-clean             - Clean libvmaf build directory"
	@echo "  make clean          - Clean all build artifacts"
	@echo "  make help           - Show this help message"
	@echo ""
	@echo "After building, use: ./libvmaf/vmaf (if linked) or ./libvmaf/libvmaf/build/tools/vmaf"

# Build libvmaf (clone if needed, then build)
libvmaf: $(LIBVMAF_VMAF_TOOL) libvmaf-link

# Clone libvmaf if it doesn't exist
libvmaf-clone:
	@if [ ! -d "$(LIBVMAF_DIR)" ]; then \
		echo "Cloning libvmaf..."; \
		git clone $(LIBVMAF_URL) $(LIBVMAF_DIR); \
	else \
		echo "libvmaf directory already exists. Skipping clone."; \
	fi

# Build libvmaf using meson
libvmaf-build: libvmaf-clone
	@if [ ! -f "$(LIBVMAF_VMAF_TOOL)" ]; then \
		echo "Building libvmaf with floating-point support..."; \
		MESON=$$(command -v meson 2>/dev/null || command -v .venv/bin/meson 2>/dev/null || command -v $$(which python3)/../bin/meson 2>/dev/null || echo ""); \
		NINJA=$$(command -v ninja 2>/dev/null || command -v .venv/bin/ninja 2>/dev/null || echo ""); \
		if [ -z "$$MESON" ]; then \
			echo "Error: meson not found. Please install it:"; \
			echo "  pip install meson"; \
			echo "  or: brew install meson"; \
			exit 1; \
		fi; \
		if [ -z "$$NINJA" ]; then \
			echo "Error: ninja not found. Please install it:"; \
			echo "  pip install ninja"; \
			echo "  or: brew install ninja"; \
			exit 1; \
		fi; \
		cd $(LIBVMAF_SOURCE_DIR) && \
		$$MESON setup build --buildtype release -Denable_float=true && \
		$$NINJA -C build; \
	else \
		echo "libvmaf already built."; \
	fi

# Ensure vmaf tool exists
$(LIBVMAF_VMAF_TOOL): libvmaf-build
	@if [ ! -f "$(LIBVMAF_VMAF_TOOL)" ]; then \
		echo "Error: libvmaf build failed. vmaf tool not found."; \
		exit 1; \
	fi

# Create convenience symlink for vmaf tool
libvmaf-link: $(LIBVMAF_VMAF_TOOL)
	@if [ ! -L "$(LIBVMAF_VMAF_LINK)" ] && [ ! -f "$(LIBVMAF_VMAF_LINK)" ]; then \
		echo "Creating symlink: $(LIBVMAF_VMAF_LINK) -> libvmaf/build/tools/vmaf"; \
		cd $(LIBVMAF_DIR) && ln -s libvmaf/build/tools/vmaf vmaf; \
	else \
		echo "Symlink already exists or file exists at $(LIBVMAF_VMAF_LINK)"; \
	fi

# Install VMAF Python requirements
# Note: If you get permission errors, fix ownership with:
#   sudo chown -R $(whoami) .venv/lib/python3.11/site-packages/numpy*
libvmaf-python-requirements:
	@if [ -f "$(LIBVMAF_PYTHON_DIR)/requirements.txt" ]; then \
		echo "Installing VMAF Python requirements..."; \
		echo "Note: If you encounter permission errors with numpy, you may need to:"; \
		echo "  1. Fix ownership: sudo chown -R \$$(whoami) .venv/lib/python3.11/site-packages/numpy*"; \
		echo "  2. Or recreate venv: rm -rf .venv && python3 -m venv .venv"; \
		pip install -r $(LIBVMAF_PYTHON_DIR)/requirements.txt || \
		(echo "Installation failed. Try fixing permissions or recreating venv." && exit 1); \
	else \
		echo "Error: requirements.txt not found at $(LIBVMAF_PYTHON_DIR)/requirements.txt"; \
		exit 1; \
	fi

# Install VMAF Python package in development mode
libvmaf-python: libvmaf libvmaf-python-requirements
	@if [ -d "$(LIBVMAF_PYTHON_DIR)" ]; then \
		echo "Installing VMAF Python package..."; \
		cd $(LIBVMAF_PYTHON_DIR) && \
		pip install -e .; \
	else \
		echo "Error: Python directory not found at $(LIBVMAF_PYTHON_DIR)"; \
		exit 1; \
	fi

# Run VMAF Python unit tests
libvmaf-test:
	@if [ -f "$(LIBVMAF_DIR)/unittest" ]; then \
		echo "Running VMAF Python unit tests..."; \
		cd $(LIBVMAF_DIR) && ./unittest; \
	else \
		echo "Error: unittest script not found at $(LIBVMAF_DIR)/unittest"; \
		exit 1; \
	fi

# Clean libvmaf build directory
libvmaf-clean:
	@if [ -d "$(LIBVMAF_BUILD_DIR)" ]; then \
		echo "Cleaning libvmaf build directory..."; \
		rm -rf $(LIBVMAF_BUILD_DIR); \
		echo "libvmaf build directory cleaned."; \
	else \
		echo "No libvmaf build directory to clean."; \
	fi

# Clean all build artifacts
clean: libvmaf-clean
	@echo "Cleaning build artifacts..."
	@find . -type f -name "*.pyc" -delete
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name ".mypy_cache" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.so" -delete 2>/dev/null || true
	@find . -type f -name "*.o" -delete 2>/dev/null || true
	@echo "Clean complete."
