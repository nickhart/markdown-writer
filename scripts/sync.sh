#!/bin/bash

# Sync essential files to public template repository
# Usage: ./sync.sh [public_repo_path]

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

# Default public repo path (can be overridden)
PUBLIC_REPO_PATH="${1:-../markdown-writing-template}"

# Verify we're in the right directory
if [[ ! -f "scripts/markdown.sh" ]] || [[ ! -f "setup.sh" ]]; then
    log_error "Please run this script from the writing workflow root directory"
    log_error "Expected to find: scripts/markdown.sh and setup.sh"
    exit 1
fi

# Check if public repo path exists
if [[ ! -d "$PUBLIC_REPO_PATH" ]]; then
    log_warning "Public repository not found at: $PUBLIC_REPO_PATH"
    read -p "Create directory? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        mkdir -p "$PUBLIC_REPO_PATH"
        log_info "Created directory: $PUBLIC_REPO_PATH"
        
        # Initialize git repo if it doesn't exist
        if [[ ! -d "$PUBLIC_REPO_PATH/.git" ]]; then
            log_info "Initializing git repository..."
            (cd "$PUBLIC_REPO_PATH" && git init)
        fi
    else
        log_error "Aborting sync"
        exit 1
    fi
fi

log_info "Syncing to public repository: $PUBLIC_REPO_PATH"
echo

# Create necessary directories
log_info "Creating directory structure..."
mkdir -p "$PUBLIC_REPO_PATH/scripts"
mkdir -p "$PUBLIC_REPO_PATH/.vscode"
mkdir -p "$PUBLIC_REPO_PATH/templates/resume"
mkdir -p "$PUBLIC_REPO_PATH/templates/cover_letter"
mkdir -p "$PUBLIC_REPO_PATH/applications/active"
mkdir -p "$PUBLIC_REPO_PATH/applications/submitted"
mkdir -p "$PUBLIC_REPO_PATH/applications/interview"
mkdir -p "$PUBLIC_REPO_PATH/applications/offered"
mkdir -p "$PUBLIC_REPO_PATH/applications/rejected"

# Copy essential files
log_info "Copying core files..."

# Core scripts
cp setup.sh "$PUBLIC_REPO_PATH/"
cp scripts/markdown.sh "$PUBLIC_REPO_PATH/scripts/"

# VSCode configuration
cp .vscode/extensions.json "$PUBLIC_REPO_PATH/.vscode/"
cp .vscode/settings.json "$PUBLIC_REPO_PATH/.vscode/"
cp .vscode/tasks.json "$PUBLIC_REPO_PATH/.vscode/"

# Documentation
cp README.md "$PUBLIC_REPO_PATH/"
cp TODO.md "$PUBLIC_REPO_PATH/"
cp VERSION "$PUBLIC_REPO_PATH/"

# Templates (clean versions without personal info)
log_info "Creating template files..."

# Create clean resume template
cat > "$PUBLIC_REPO_PATH/templates/resume/default.md" << 'EOF'
# {{name}}

{{address}} \
{{city}}, {{state}} {{zip}} \
{{phone}} \
{{email}} \
{{linkedin}} \
{{github}} \
{{website}}

## Summary

[Add your professional summary here - 2-3 sentences highlighting your experience and key skills]

## Experience

### [Job Title] - [Company Name]
**[Start Date] - [End Date]**

- [Key achievement or responsibility]
- [Another achievement with quantifiable impact]
- [Third achievement demonstrating relevant skills]

### [Previous Job Title] - [Previous Company]
**[Start Date] - [End Date]**

- [Key achievement or responsibility]
- [Another achievement with quantifiable impact]

## Skills

**Technical:** [List relevant technical skills]
**Languages:** [Programming languages, frameworks, tools]
**Other:** [Additional relevant skills]

## Education

### [Degree] - [University]
**[Graduation Year]**
[Relevant coursework, honors, or achievements]
EOF

# Create mobile-specific resume template
cat > "$PUBLIC_REPO_PATH/templates/resume/mobile.md" << 'EOF'
# {{name}}

{{address}} \
{{city}}, {{state}} {{zip}} \
{{phone}} \
{{email}} \
{{linkedin}} \
{{github}} \
{{website}}

## Summary

[Mobile development professional with X years of experience in iOS/Android development]

## Experience

### [Mobile Developer Title] - [Company Name]
**[Start Date] - [End Date]**

- [Mobile app achievement - downloads, ratings, performance]
- [Technical accomplishment - architecture, optimization, etc.]
- [Cross-platform or native development experience]

## Technical Skills

**Mobile:** iOS (Swift/Objective-C), Android (Kotlin/Java), React Native, Flutter
**Backend:** [APIs, databases, cloud services you've worked with]
**Tools:** Xcode, Android Studio, Git, CI/CD, App Store/Play Store

## Projects

### [App Name]
- [Brief description and key features]
- [Technologies used]
- [Impact metrics if available]

## Education

### [Degree] - [University]
**[Graduation Year]**
EOF

# Create frontend-specific resume template
cat > "$PUBLIC_REPO_PATH/templates/resume/frontend.md" << 'EOF'
# {{name}}

{{address}} \
{{city}}, {{state}} {{zip}} \
{{phone}} \
{{email}} \
{{linkedin}} \
{{github}} \
{{website}}

## Summary

[Frontend developer with X years of experience creating responsive web applications]

## Experience

### [Frontend Developer Title] - [Company Name]
**[Start Date] - [End Date]**

- [UI/UX achievement - user engagement, performance improvements]
- [Technical accomplishment - framework implementation, optimization]
- [Collaboration with design/backend teams]

## Technical Skills

**Frontend:** JavaScript/TypeScript, React, Vue.js, Angular, HTML5, CSS3, SASS
**Tools:** Webpack, Vite, Git, NPM/Yarn, Figma, Browser DevTools
**Testing:** Jest, Cypress, Testing Library

## Projects

### [Project Name]
- [Brief description of the application]
- [Technologies used and your role]
- [Performance metrics or user impact]

## Education

### [Degree] - [University]
**[Graduation Year]**
EOF

# Copy cover letter template (should already be clean since it has placeholders)
if [[ -f "templates/cover_letter/default.md" ]]; then
    cp "templates/cover_letter/default.md" "$PUBLIC_REPO_PATH/templates/cover_letter/"
else
    log_warning "Cover letter template not found, creating example..."
    cat > "$PUBLIC_REPO_PATH/templates/cover_letter/default.md" << 'EOF'
<!-- markdownlint-disable MD036 -->
# {{name}}

{{address}} \
{{city}}, {{state}} {{zip}} \
{{phone}} \
{{email}} \
{{linkedin}} \
{{github}} \
{{website}}

**{{date}}**

**[[Company]] Hiring Team** \
**re: [[Position]]**

**Dear [[Company]] Hiring Team,**

I'm excited to apply for the position of [[Position]] at [[Company]]. With my background in [relevant field], I am confident I can contribute effectively to your team and help advance [[Company]]'s mission.

What draws me to [[Company]] is [specific reason - company values, mission, recent news, etc.]. I am particularly interested in [specific aspect of the role or company] and believe my experience in [relevant area] would enable me to make meaningful contributions from day one.

In my previous roles, I have:

- [Key achievement that relates to the job requirements]
- [Another relevant accomplishment with quantifiable impact]
- [Third point demonstrating skills relevant to the position]

My experience with [relevant technologies/methodologies] and passion for [relevant domain] position me well to [specific contribution you'd make in this role].

I would welcome the opportunity to discuss how my background and enthusiasm can contribute to [[Company]]'s continued success. Thank you for considering my application.

**Best regards,**

**{{preferred_name}}**

---

**Attachments:** Resume
EOF
fi

# Create example configuration (without personal details)
log_info "Creating example configuration..."
cat > "$PUBLIC_REPO_PATH/.writing.yml.example" << 'EOF'
# Writing Workflow Configuration
# Copy this to .writing.yml and edit with your information

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

# Create .gitignore for the public repo
cat > "$PUBLIC_REPO_PATH/.gitignore" << 'EOF'
# Personal configuration
.writing.yml

# Personal content
blog/
job_search/

# Application data (users will create their own)
applications/*/

# Formatted output
formatted/
*.docx
*.pdf
*.html

# System files
.DS_Store
Thumbs.db

# Editor files
*.swp
*.swo
*~
.idea/
EOF

# Create empty .gitkeep files for application directories
touch "$PUBLIC_REPO_PATH/applications/active/.gitkeep"
touch "$PUBLIC_REPO_PATH/applications/submitted/.gitkeep"
touch "$PUBLIC_REPO_PATH/applications/interview/.gitkeep"
touch "$PUBLIC_REPO_PATH/applications/offered/.gitkeep"
touch "$PUBLIC_REPO_PATH/applications/rejected/.gitkeep"

log_success "Sync completed successfully!"
echo
log_info "Public repository structure:"
echo "  $PUBLIC_REPO_PATH/"
echo "  ├── setup.sh"
echo "  ├── README.md"
echo "  ├── .writing.yml.example"
echo "  ├── .vscode/ (VSCode configuration)"
echo "  ├── scripts/markdown.sh"
echo "  ├── templates/"
echo "  │   ├── resume/ (default.md, mobile.md, frontend.md)"
echo "  │   └── cover_letter/ (default.md)"
echo "  └── applications/ (empty directories with .gitkeep)"
echo
log_info "Next steps:"
echo "  1. cd $PUBLIC_REPO_PATH"
echo "  2. git add ."
echo "  3. git commit -m 'Initial writing workflow template'"
echo "  4. git remote add origin <your-public-repo-url>"
echo "  5. git push -u origin main"
echo
log_warning "Note: .writing.yml is gitignored in the public repo"
log_warning "Users will copy .writing.yml.example to .writing.yml"