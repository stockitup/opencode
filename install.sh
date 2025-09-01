#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Detect OS and architecture
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

# Map architecture names for Bun
case "$ARCH" in
    x86_64) BUN_ARCH="x64"; GO_ARCH="amd64" ;;
    aarch64|arm64) BUN_ARCH="arm64"; GO_ARCH="arm64" ;;
    *) 
        print_error "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Map OS names for build targets
case "$OS" in
    linux) OS_TARGET="linux" ;;
    darwin) OS_TARGET="darwin" ;;
    *)
        print_error "Unsupported OS: $OS"
        exit 1
        ;;
esac

print_info "Building opencode for $OS_TARGET-$BUN_ARCH"

# Check for required tools
check_command() {
    if ! command -v "$1" &> /dev/null; then
        print_error "$1 is not installed. Please install $1 first."
        exit 1
    fi
}

print_info "Checking prerequisites..."
check_command "bun"
check_command "go"

# Check versions
BUN_VERSION=$(bun --version)
GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')

print_info "Found Bun version: $BUN_VERSION"
print_info "Found Go version: $GO_VERSION"

# Install dependencies
print_info "Installing dependencies..."
bun install

# Get version from package.json if available
VERSION=$(grep '"version"' package.json | head -1 | cut -d'"' -f4 || echo "dev")
print_info "Building version: $VERSION"

# Build directory setup
BUILD_NAME="${OS_TARGET}-${BUN_ARCH}"
BUILD_DIR="packages/opencode/dist/${BUILD_NAME}"
mkdir -p "${BUILD_DIR}/bin"

# Build Go TUI component
print_info "Building TUI component..."
cd packages/tui
CGO_ENABLED=0 GOOS="${OS_TARGET}" GOARCH="${GO_ARCH}" go build \
    -ldflags="-s -w -X main.Version=${VERSION}" \
    -o "../opencode/dist/${BUILD_NAME}/bin/tui" \
    ./cmd/opencode/main.go
cd ../..

# Build Bun CLI component
print_info "Building CLI component..."
cd packages/opencode

# Determine Bun target
BUN_TARGET="bun-${OS_TARGET}-${BUN_ARCH}"
if [ "$BUN_ARCH" = "x64" ] && [ "$OS_TARGET" = "linux" ]; then
    # Use baseline for better compatibility on Linux x64
    BUN_TARGET="bun-${OS_TARGET}-${BUN_ARCH}-baseline"
fi

bun build \
    --define "OPENCODE_TUI_PATH='../../../dist/${BUILD_NAME}/bin/tui'" \
    --define "OPENCODE_VERSION='${VERSION}'" \
    --compile \
    --target="${BUN_TARGET}" \
    --outfile="dist/${BUILD_NAME}/bin/opencode" \
    ./src/index.ts

cd ../..

# Installation
INSTALL_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR"

print_info "Installing to $INSTALL_DIR..."

# Remove old installations if they exist
rm -f "$INSTALL_DIR/opencode" "$INSTALL_DIR/o"

# Copy binaries
cp "${BUILD_DIR}/bin/opencode" "$INSTALL_DIR/opencode"
cp "${BUILD_DIR}/bin/tui" "$INSTALL_DIR/opencode-tui"

# Make them executable
chmod +x "$INSTALL_DIR/opencode"
chmod +x "$INSTALL_DIR/opencode-tui"

# Create symlink for 'o' command
ln -sf "$INSTALL_DIR/opencode" "$INSTALL_DIR/o"

print_info "Installation complete!"

# Check if ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    print_warn "$INSTALL_DIR is not in your PATH"
    print_warn "Add the following to your shell configuration file:"
    echo "    export PATH=\"\$PATH:$INSTALL_DIR\""
fi

print_info "You can now use 'opencode' or 'o' commands"
print_info "Try running: opencode --version"