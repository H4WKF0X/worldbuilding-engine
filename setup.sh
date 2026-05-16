#!/usr/bin/env bash
set -euo pipefail

REPO="H4WKF0X/worldbuilding-engine"
GITHUB_API="https://api.github.com/repos/$REPO"

die()  { echo "error: $*" >&2; exit 1; }
info() { echo "  $*"; }

# Dependency checks
command -v git >/dev/null 2>&1 || die "git is required"

if command -v curl >/dev/null 2>&1; then
    fetch()     { curl -fsSL "$1"; }
    fetch_tar() { curl -fsSL "$1" | tar -xz -C "$2"; }
elif command -v wget >/dev/null 2>&1; then
    fetch()     { wget -qO- "$1"; }
    fetch_tar() { wget -qO- "$1" | tar -xz -C "$2"; }
else
    die "curl or wget is required"
fi

# Args
PROJECT_NAME="${1:-}"
[ -z "$PROJECT_NAME" ] && die "usage: bash setup.sh <project-name> [version]"
[[ "$PROJECT_NAME" =~ ^[a-zA-Z0-9_-]+$ ]] || die "project name must contain only letters, numbers, hyphens, and underscores"
[ -d "$PROJECT_NAME" ] && die "directory '$PROJECT_NAME' already exists"

VERSION="${2:-}"
if [ -z "$VERSION" ]; then
    echo "Fetching latest engine version..."
    VERSION=$(fetch "$GITHUB_API/releases/latest" \
        | grep '"tag_name"' | head -1 \
        | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')
    [ -z "$VERSION" ] && die "could not determine latest version — check your connection or pass a version explicitly"
fi
echo "Engine version: $VERSION"

# Download and extract to a temp dir, cleaned up on exit
WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

echo "Downloading..."
fetch_tar "https://github.com/$REPO/archive/refs/tags/$VERSION.tar.gz" "$WORK_DIR"

ENGINE_SRC=$(echo "$WORK_DIR"/*/engine)
[ -d "$ENGINE_SRC" ] || die "engine directory not found in release archive"

# Create project
mkdir "$PROJECT_NAME"
cd "$PROJECT_NAME"

info "Creating directory structure..."
mkdir -p prompts templates/entries world-config
mkdir -p vault/inbox/_processed
mkdir -p vault/entries/{locations,factions,npcs,history,religion,economy,magic}
mkdir -p vault/staging vault/reports
mkdir -p retired

info "Copying engine files..."
cp    "$ENGINE_SRC/CLAUDE.md"                      CLAUDE.md
cp    "$ENGINE_SRC/prompts/"*.md                   prompts/
cp    "$ENGINE_SRC/templates/entries/"*.md         templates/entries/
cp    "$ENGINE_SRC/templates/world-config/"*.md    world-config/
cp    "$ENGINE_SRC/templates/vault/world-state.md" vault/world-state.md

info "Seeding empty directories..."
for dir in \
    vault/inbox/_processed \
    vault/entries/locations vault/entries/factions vault/entries/npcs \
    vault/entries/history vault/entries/religion vault/entries/economy vault/entries/magic \
    vault/staging vault/reports \
    retired
do
    touch "$dir/.gitkeep"
done

cat > .gitignore << 'EOF'
# OS files
.DS_Store
Thumbs.db

# Obsidian workspace state (personal, not shared)
.obsidian/workspace.json
.obsidian/workspace-mobile.json
EOF

info "Initialising git repository..."
git init -q
git add .
git commit -q -m "Initial world setup (worldbuilding-engine $VERSION)"

echo ""
echo "Done. '$PROJECT_NAME' is ready."
echo ""
echo "Next steps:"
echo "  1. Fill in world-config/identity.md — your world's name, tone, and premise."
echo "  2. Fill in world-config/conventions.md — naming and style rules."
echo "  3. Drop lore fragments into vault/inbox/ and run /process in Claude Code."
