#!/bin/bash

# Writing Workflow Setup Script
# Version: 0.1.0

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

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check and install pandoc
check_pandoc() {
    log_info "Checking for pandoc..."
    
    if command_exists pandoc; then
        local version=$(pandoc --version | head -1)
        log_success "pandoc found: $version"
        return 0
    fi
    
    log_warning "pandoc not found"
    echo "To install pandoc:"
    case "$(uname)" in
        Darwin*) echo "  brew install pandoc" ;;
        Linux*)  echo "  sudo apt install pandoc  # (Ubuntu/Debian)"
                echo "  sudo yum install pandoc  # (CentOS/RHEL)" ;;
        *)       echo "  Visit: https://pandoc.org/installing.html" ;;
    esac
    return 1
}

# Check and install yq
check_yq() {
    log_info "Checking for yq..."
    
    if command_exists yq; then
        local version=$(yq --version 2>/dev/null || echo "version unknown")
        log_success "yq found: $version"
        return 0
    fi
    
    log_warning "yq not found"
    echo "To install yq:"
    case "$(uname)" in
        Darwin*) echo "  brew install yq" ;;
        Linux*)  echo "  sudo apt install yq  # (Ubuntu/Debian)"
                echo "  sudo yum install yq  # (CentOS/RHEL)" ;;
        *)       echo "  Visit: https://github.com/mikefarah/yq#install" ;;
    esac
    return 1
}

# Check PDF/LaTeX support
check_pdf_support() {
    log_info "Checking for PDF/LaTeX support..."
    
    if command_exists pdflatex || command_exists xelatex || command_exists lualatex; then
        log_success "PDF export supported "
        return 0
    fi
    
    log_warning "PDF export not available (LaTeX not found)"
    echo "To enable PDF support, install LaTeX:"
    case "$(uname)" in
        Darwin*) echo "  brew install --cask mactex-no-gui  # (recommended, smaller)"
                echo "  brew install --cask mactex         # (full distribution)" ;;
        Linux*)  echo "  sudo apt install texlive-latex-base  # (basic, smaller)"
                echo "  sudo apt install texlive-full        # (complete)" ;;
        *)       echo "  Install TeX Live or similar LaTeX distribution" ;;
    esac
    return 1
}

# Setup shell sourcing
setup_shell_sourcing() {
    log_info "Setting up shell integration..."
    
    local project_root="$(pwd)"
    local markdown_script="$project_root/scripts/markdown.sh"
    
    if [[ ! -f "$markdown_script" ]]; then
        log_error "markdown.sh not found at $markdown_script"
        log_error "Please run setup.sh from the writing project root directory"
        return 1
    fi
    
    # Detect shell
    local shell_config=""
    if [[ -n "$ZSH_VERSION" ]] || [[ "$SHELL" == *"zsh"* ]]; then
        shell_config="$HOME/.zshrc"
    elif [[ -n "$BASH_VERSION" ]] || [[ "$SHELL" == *"bash"* ]]; then
        shell_config="$HOME/.bashrc"
    else
        log_warning "Unknown shell. Please manually source scripts/markdown.sh"
        return 1
    fi
    
    # Check if already configured
    if grep -q "scripts/markdown.sh" "$shell_config" 2>/dev/null; then
        log_info "Shell integration already configured in $shell_config"
        return 0
    fi
    
    # Add sourcing to shell config
    echo "" >> "$shell_config"
    echo "# Writing workflow integration" >> "$shell_config"
    echo "if [[ -f \"$markdown_script\" ]]; then" >> "$shell_config"
    echo "    source \"$markdown_script\"" >> "$shell_config"
    echo "fi" >> "$shell_config"
    
    log_success "Added shell integration to $shell_config"
    log_info "Restart your shell or run: source $shell_config"
    return 0
}

# Generate reference.docx files from default templates
generate_reference_docs() {
    log_info "Checking for reference documents..."
    
    local project_root="$(pwd)"
    local templates_generated=false
    
    # Check pandoc availability
    if ! command_exists pandoc; then
        log_warning "Pandoc not available - skipping reference document generation"
        log_info "Install pandoc and run setup.sh again to generate reference documents"
        return 0
    fi
    
    # Generate resume reference.docx
    local resume_template="$project_root/templates/resume/default.md"
    local resume_reference="$project_root/templates/resume/reference.docx"
    
    if [[ -f "$resume_template" ]] && [[ ! -f "$resume_reference" ]]; then
        log_info "Generating resume reference document..."
        if pandoc -o "$resume_reference" "$resume_template"; then
            log_success "Created: $resume_reference"
            templates_generated=true
        else
            log_warning "Failed to generate resume reference document"
        fi
    elif [[ -f "$resume_reference" ]]; then
        log_info "Resume reference document already exists: $resume_reference"
    elif [[ ! -f "$resume_template" ]]; then
        log_warning "Resume template not found: $resume_template"
    fi
    
    # Generate cover letter reference.docx
    local cover_letter_template="$project_root/templates/cover_letter/default.md"
    local cover_letter_reference="$project_root/templates/cover_letter/reference.docx"
    
    if [[ -f "$cover_letter_template" ]] && [[ ! -f "$cover_letter_reference" ]]; then
        log_info "Generating cover letter reference document..."
        if pandoc -o "$cover_letter_reference" "$cover_letter_template"; then
            log_success "Created: $cover_letter_reference"
            templates_generated=true
        else
            log_warning "Failed to generate cover letter reference document"
        fi
    elif [[ -f "$cover_letter_reference" ]]; then
        log_info "Cover letter reference document already exists: $cover_letter_reference"
    elif [[ ! -f "$cover_letter_template" ]]; then
        log_warning "Cover letter template not found: $cover_letter_template"
    fi
    
    if $templates_generated; then
        echo ""
        log_info "Reference documents generated successfully!"
        echo "You can now customize the formatting by:"
        echo "  1. Opening the reference.docx files in Word/LibreOffice"
        echo "  2. Modifying styles, fonts, margins, etc."
        echo "  3. Saving the files"
        echo "  4. Future documents will use your customized formatting"
    fi
    
    return 0
}

# Create example .writing.yml if it doesn't exist
create_example_config() {
    log_info "Checking for .writing.yml configuration..."
    
    if [[ -f ".writing.yml" ]]; then
        log_info "Configuration file already exists"
        return 0
    fi
    
    log_info "Creating example .writing.yml configuration..."
    
    cat > .writing.yml << 'EOF'
# Writing Workflow Configuration
# Version: 0.1.0

# Output preferences
output_format: docx  # or pdf

# Default templates
default_resume_template: default
default_cover_letter_template: default

# Personal info for template substitution
name: "Your Name"
preferred_name: "Your Name"
email: "your.email@example.com"
phone: "(555) 123-4567"
address: "123 Main St"
city: "Your City"
state: "ST"
zip: "12345"
linkedin: "linkedin.com/in/yourname"
github: "github.com/yourusername"
website: "yourwebsite.com"
EOF
    
    log_success "Created .writing.yml - please edit with your information"
    return 0
}

# Main setup function
main() {
    echo "Writing Workflow Setup"
    echo "====================="
    echo
    
    local success=true
    
    # Check dependencies
    check_pandoc || success=false
    check_yq || success=false
    check_pdf_support  # This can fail without affecting overall success
    
    echo
    
    # Setup integration
    setup_shell_sourcing || success=false
    create_example_config || success=false
    generate_reference_docs || success=false
    
    echo
    
    if $success; then
        log_success "Setup completed successfully!"
        log_info "Next steps:"
        echo "  1. Edit .writing.yml with your personal information"
        echo "  2. Add content to your templates in templates/"
        echo "  3. Restart your shell or run: source ~/.zshrc (or ~/.bashrc)"
        echo "  4. Try: job-apply \"company\" \"role\" \"https://job-url\""
    else
        log_error "Setup completed with errors"
        log_info "Please install missing dependencies and run setup.sh again"
        return 1
    fi
}

# Run main function
main "$@"