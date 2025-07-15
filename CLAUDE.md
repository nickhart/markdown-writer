# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a markdown-based job application and document management system built with bash scripts. It provides a template-driven workflow for creating resumes, cover letters, and tracking job applications through different stages.

## Core Architecture

### Main Components

- **scripts/markdown.sh**: Core shell functions for document processing and job application management
- **setup.sh**: Initial setup script for dependencies and configuration
- **templates/**: Markdown templates for resumes and cover letters with variable substitution
- **applications/**: Directory structure organizing applications by status (active, submitted, interview, offered, rejected)

### Key Functions (in scripts/markdown.sh)

- `job-apply`: Creates new job applications from templates
- `job-format`: Converts markdown to DOCX using pandoc
- `job-status`: Manages application status transitions
- `job-log`: Displays application summaries
- `job-commit`: Git workflow for committing applications
- `format-template`: Variable substitution from `.writing.yml`
- `md2docx/md2html/md2pdf`: Document conversion utilities
- `url-scrape`: Job description archiving

## Common Commands

### Setup and Dependencies
```bash
./setup.sh                    # Initial setup, installs dependencies
```

### Job Application Workflow
```bash
# Create new application
job-apply "Company Name" "Role" "https://job-url"
job-apply "Company Name" "Role" "template_name" "https://job-url"

# Format documents to DOCX
job-format application_name

# Update application status
job-status application_name submitted
job-status application_name interview

# View applications
job-log                       # All applications
job-log submitted            # Specific status

# Commit to git
job-commit application_name   # Specific application
job-commit                   # Most recent application
```

### Document Processing
```bash
# Convert individual files
md2docx resume.md            # Uses templates/resume/reference.docx
md2html document.md
md2pdf document.md

# Template processing
format-template template.md output.md
```

## Configuration

### .writing.yml Structure
Personal information for template substitution:
```yaml
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
```

### Template Variables
Templates use `{{variable}}` syntax for substitution:
- `{{name}}`, `{{email}}`, `{{phone}}`, etc. from `.writing.yml`
- `{{date}}` - auto-generated current date
- `{{email}}` becomes `[email](mailto:email)` format
- `{{website}}` becomes `[website](https://website)` format

## Directory Structure

```
├── applications/
│   ├── active/             # New applications
│   ├── submitted/          # Submitted applications
│   ├── interview/          # Interview scheduled
│   ├── offered/            # Job offers
│   └── rejected/           # Rejected applications
├── templates/
│   ├── resume/
│   │   ├── default.md      # Default resume template
│   │   ├── mobile.md       # Mobile-specific template
│   │   ├── frontend.md     # Frontend-specific template
│   │   └── reference.docx  # DOCX formatting reference
│   └── cover_letter/
│       ├── default.md      # Default cover letter template
│       └── reference.docx  # DOCX formatting reference
└── scripts/
    └── markdown.sh         # Core functions
```

## Dependencies

- **pandoc**: Document conversion (required)
- **yq**: YAML processing (required)
- **Chrome** (optional): Better web scraping, falls back to curl
- **LaTeX** (optional): PDF generation

## Application Structure

Each application creates:
- `resume.md` - Generated from template
- `cover_letter.md` - Generated from template
- `application.yml` - Metadata (company, role, date, status)
- `job_description.html` - Scraped from URL (if provided)
- `formatted/` - DOCX outputs after running `job-format`

## Development Notes

- All functions validate project root using `find_project_root()`
- Status changes move directories between application folders
- Git integration through `job-commit` with auto-generated messages
- Reference DOCX files control formatting for pandoc conversion
- Template substitution happens during `job-apply`, not format time
- Web scraping prefers Chrome with UTF-8 BOM for proper encoding
- Error handling with colored log functions (log_error, log_success, etc.)

## Testing

- Use `job-log` to verify application states
- Check `formatted/` directory for DOCX output
- Validate template substitution in generated markdown
- Test status transitions with `job-status`
- Verify git commits include proper application files