#!/bin/bash

# Sync essential files FROM this public template repository TO a private repository
# Usage: ./scripts/sync.sh /path/to/private/writing-repo
# This script should be run from the PUBLIC template repository

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Private repo path (destination)
PRIVATE_REPO_PATH="$1"

if [[ -z "$PRIVATE_REPO_PATH" ]]; then
    log_error "Usage: ./scripts/sync.sh /path/to/private/writing-repo"
    exit 1
fi

# Verify we're in the PUBLIC template repository
if [[ ! -f "scripts/markdown.sh" ]] || [[ ! -f "setup.sh" ]]; then
    log_error "Please run this script from the public template repository root"
    log_error "Expected to find: scripts/markdown.sh and setup.sh"
    exit 1
fi

# Safety check: Ensure we're in the PUBLIC template repository
check_public_repository() {
    local current_remote=""
    if git rev-parse --git-dir >/dev/null 2>&1; then
        current_remote=$(git remote get-url origin 2>/dev/null || echo "")

        # Check if this looks like a private repository (has personal data)
        if [[ -f ".writing.yml" ]]; then
            # If .writing.yml exists, it should contain example data, not real personal data
            if grep -q -E "(your\.email@example\.com|test@example\.com)" ".writing.yml" 2>/dev/null; then
                log_info "Found example .writing.yml - this appears to be the public template"
            else
                log_error "SAFETY CHECK FAILED: .writing.yml appears to contain personal data!"
                log_error "This appears to be a private repository with real personal information"
                log_error "This script should be run from the PUBLIC template repository"
                log_error "Current directory: $(pwd)"
                log_error "Expected to find example email like 'your.email@example.com' or 'test@example.com'"
                exit 1
            fi
        else
            log_info "No .writing.yml found - this appears to be the public template"
        fi
    fi

    log_info "Public repository safety check passed"
}

# Check if private repo exists and has correct structure
if [[ ! -d "$PRIVATE_REPO_PATH" ]]; then
    log_error "Private repository not found at: $PRIVATE_REPO_PATH"
    exit 1
fi

# Verify private repo has expected structure
if [[ ! -f "$PRIVATE_REPO_PATH/scripts/markdown.sh" ]] || [[ ! -f "$PRIVATE_REPO_PATH/setup.sh" ]]; then
    log_error "Private repository structure invalid at: $PRIVATE_REPO_PATH"
    log_error "Expected to find: scripts/markdown.sh and setup.sh"
    exit 1
fi

# Check git status of private repo
check_private_repo_git_status() {
    local repo_path="$1"

    if [[ ! -d "$repo_path/.git" ]]; then
        log_warning "Private repository is not a git repository: $repo_path"
        log_warning "Consider initializing git for better change tracking"
        return 0
    fi

    # Check if there are unstaged changes
    if ! git -C "$repo_path" diff --quiet; then
        log_error "Private repository has unstaged changes!"
        log_error "Please commit or stash changes before syncing:"
        echo
        git -C "$repo_path" status --short
        echo
        log_error "Suggested actions:"
        echo "  git -C '$repo_path' add ."
        echo "  git -C '$repo_path' commit -m 'Save changes before sync'"
        echo "  OR: git -C '$repo_path' stash"
        exit 1
    fi

    # Check if there are staged changes
    if ! git -C "$repo_path" diff --cached --quiet; then
        log_error "Private repository has staged but uncommitted changes!"
        log_error "Please commit changes before syncing:"
        echo
        git -C "$repo_path" status --short
        echo
        log_error "Suggested action:"
        echo "  git -C '$repo_path' commit -m 'Save changes before sync'"
        exit 1
    fi

    # Show current branch info
    local current_branch=$(git -C "$repo_path" branch --show-current 2>/dev/null || echo "detached")
    log_info "Private repository is on branch: $current_branch"
    log_info "Working directory is clean - safe to sync"
}

# Run safety checks
check_public_repository
check_private_repo_git_status "$PRIVATE_REPO_PATH"

# Confirm the operation
echo
log_info "About to sync updates FROM: $(pwd)"
log_info "TO private repository: $PRIVATE_REPO_PATH"
echo
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Sync cancelled by user"
    exit 0
fi

log_info "Syncing updates to private repository..."
echo

# Copy core files FROM public template TO private repo
log_info "Updating core files..."

# Core scripts
cp setup.sh "$PRIVATE_REPO_PATH/"
cp scripts/markdown.sh "$PRIVATE_REPO_PATH/scripts/"

# VSCode configuration (if exists)
if [[ -d ".vscode" ]]; then
    mkdir -p "$PRIVATE_REPO_PATH/.vscode"
    
    # Handle extensions.json (safe to overwrite - it's just recommendations)
    if [[ -f ".vscode/extensions.json" ]]; then
        cp .vscode/extensions.json "$PRIVATE_REPO_PATH/.vscode/" 2>/dev/null || true
        log_info "Updated .vscode/extensions.json"
    fi
    
    # Handle settings.json (preserve user customizations)
    if [[ -f ".vscode/settings.json" ]]; then
        if [[ -f "$PRIVATE_REPO_PATH/.vscode/settings.json" ]]; then
            log_warning "Found existing .vscode/settings.json with potential customizations"
            echo "Template version: .vscode/settings.json"
            echo "Your version: $PRIVATE_REPO_PATH/.vscode/settings.json"
            echo
            read -p "Overwrite your settings.json? (y/n/d for diff): " -n 1 -r
            echo
            case $REPLY in
                [Yy]* ) 
                    cp .vscode/settings.json "$PRIVATE_REPO_PATH/.vscode/"
                    log_info "Overwrote .vscode/settings.json"
                    ;;
                [Dd]* )
                    echo "=== DIFF: Template -> Your current ==="
                    diff .vscode/settings.json "$PRIVATE_REPO_PATH/.vscode/settings.json" || true
                    echo "=== END DIFF ==="
                    echo
                    read -p "Now overwrite? (y/N): " -n 1 -r
                    echo
                    if [[ $REPLY =~ ^[Yy]$ ]]; then
                        cp .vscode/settings.json "$PRIVATE_REPO_PATH/.vscode/"
                        log_info "Overwrote .vscode/settings.json"
                    else
                        log_info "Kept your existing .vscode/settings.json"
                    fi
                    ;;
                * )
                    log_info "Kept your existing .vscode/settings.json"
                    ;;
            esac
        else
            cp .vscode/settings.json "$PRIVATE_REPO_PATH/.vscode/"
            log_info "Created new .vscode/settings.json"
        fi
    fi
    
    # Handle tasks.json (preserve user customizations)
    if [[ -f ".vscode/tasks.json" ]]; then
        if [[ -f "$PRIVATE_REPO_PATH/.vscode/tasks.json" ]]; then
            log_warning "Found existing .vscode/tasks.json with potential customizations"
            echo "Template version: .vscode/tasks.json"
            echo "Your version: $PRIVATE_REPO_PATH/.vscode/tasks.json"
            echo
            read -p "Overwrite your tasks.json? (y/n/d for diff): " -n 1 -r
            echo
            case $REPLY in
                [Yy]* ) 
                    cp .vscode/tasks.json "$PRIVATE_REPO_PATH/.vscode/"
                    log_info "Overwrote .vscode/tasks.json"
                    ;;
                [Dd]* )
                    echo "=== DIFF: Template -> Your current ==="
                    diff .vscode/tasks.json "$PRIVATE_REPO_PATH/.vscode/tasks.json" || true
                    echo "=== END DIFF ==="
                    echo
                    read -p "Now overwrite? (y/N): " -n 1 -r
                    echo
                    if [[ $REPLY =~ ^[Yy]$ ]]; then
                        cp .vscode/tasks.json "$PRIVATE_REPO_PATH/.vscode/"
                        log_info "Overwrote .vscode/tasks.json"
                    else
                        log_info "Kept your existing .vscode/tasks.json"
                    fi
                    ;;
                * )
                    log_info "Kept your existing .vscode/tasks.json"
                    ;;
            esac
        else
            cp .vscode/tasks.json "$PRIVATE_REPO_PATH/.vscode/"
            log_info "Created new .vscode/tasks.json"
        fi
    fi
fi

# Update VERSION and sync script itself
if [[ -f "VERSION" ]]; then
    cp VERSION "$PRIVATE_REPO_PATH/"
fi
cp scripts/sync.sh "$PRIVATE_REPO_PATH/scripts/"

# Update templates (but preserve personal ones)
log_info "Updating template files..."
mkdir -p "$PRIVATE_REPO_PATH/templates/resume" "$PRIVATE_REPO_PATH/templates/cover_letter" "$PRIVATE_REPO_PATH/templates/blog" "$PRIVATE_REPO_PATH/templates/notes"

# Copy template files that don't contain personal data
cp templates/resume/default.md "$PRIVATE_REPO_PATH/templates/resume/" 2>/dev/null || true
cp templates/cover_letter/default.md "$PRIVATE_REPO_PATH/templates/cover_letter/" 2>/dev/null || true
cp templates/blog/default.md "$PRIVATE_REPO_PATH/templates/blog/" 2>/dev/null || true
cp templates/blog/style.css "$PRIVATE_REPO_PATH/templates/blog/" 2>/dev/null || true
cp templates/notes/default.md "$PRIVATE_REPO_PATH/templates/notes/" 2>/dev/null || true

# Update documentation files
mkdir -p "$PRIVATE_REPO_PATH/docs"
if [[ -f "docs/DEVELOPMENT.md" ]]; then
    cp docs/DEVELOPMENT.md "$PRIVATE_REPO_PATH/docs/"
fi
if [[ -f "docs/AI_DEVELOPMENT.md" ]]; then
    cp docs/AI_DEVELOPMENT.md "$PRIVATE_REPO_PATH/docs/"
fi

# Preserve personal configuration
if [[ -f "$PRIVATE_REPO_PATH/.writing.yml" ]]; then
    log_info "Preserving your personal .writing.yml configuration"
else
    log_info "No .writing.yml found in private repo - you may want to create one"
fi

# Don't overwrite personal applications or blog content
log_info "Preserving personal applications and blog content"

log_success "Sync completed successfully!"
echo
log_info "Updated files in private repository:"
echo "  - setup.sh"
echo "  - scripts/markdown.sh"
echo "  - scripts/sync.sh"
echo "  - .vscode/ configuration"
echo "  - templates/ (default templates only)"
echo "  - templates/notes/default.md"
echo "  - VERSION"
echo "  - docs/DEVELOPMENT.md"
echo "  - docs/AI_DEVELOPMENT.md"
echo
log_info "Next steps:"
echo "  1. cd '$PRIVATE_REPO_PATH'"
echo "  2. Test the updated functions: source scripts/markdown.sh"
echo "  3. Review changes: git diff"
echo "  4. Commit if satisfied: git add . && git commit -m 'Sync updates from template'"
echo
log_warning "Your personal data (.writing.yml, applications/, blog/) was preserved"