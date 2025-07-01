# Markdown Writing Workflow

![Version](https://img.shields.io/badge/version-0.2.1-blue)
![Shell](https://img.shields.io/badge/shell-bash%2Fzsh-green)
![License](https://img.shields.io/badge/license-MIT-blue)

A markdown-based job application and document management system that streamlines creating, formatting, and tracking job applications.

## Features

- **Template-based workflow**: Create resumes and cover letters from markdown templates with automatic variable substitution
- **Professional formatting**: Automatic conversion to DOCX with customizable reference documents
- **Job application tracking**: Organize applications by status (active, submitted, interview, offered, rejected)
- **Batch operations**: Format all documents for an application with a single command
- **Web scraping**: Automatically archive job descriptions from URLs

## Quick Start

### Getting Started

**Option 1: Use as Template (Recommended)**

1. Visit the [Markdown Writer repository](https://github.com/nickhart/markdown-writer)
1. Click "Use this template" to create your own private repository
1. Clone your new repository and run `./setup.sh`

**Option 2: Clone and Experiment**

```bash
git clone git@github.com:nickhart/markdown-writer.git
cd markdown-writer
```

### 1. Setup

Run the setup script to install dependencies and configure your environment:

```bash
./setup.sh
```

This will:

- Check for required dependencies (pandoc, yq)
- Set up shell integration
- Create example configuration file (`.writing.yml`)
- Generate reference DOCX templates automatically

### 2. Configure Personal Information

Edit `.writing.yml` with your personal details:

```yaml
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
```

### 3. Customize Templates

Add content to your templates:

- **Resume**: Edit `templates/resume/default.md`
- **Cover Letter**: Edit `templates/cover_letter/default.md`

Templates support variable substitution using `{{variable}}` syntax:

- `{{name}}`, `{{email}}`, `{{phone}}`, etc. - replaced with your info
- `{{date}}` - automatically generates current date
- `{{email}}` becomes `[your.email@example.com](mailto:your.email@example.com)`
- `{{website}}` becomes `[yourwebsite.com](https://yourwebsite.com)`

### 4. Customize Document Formatting

Reference documents control the final DOCX formatting:

1. Open `templates/resume/reference.docx` or `templates/cover_letter/reference.docx` in Word/LibreOffice
2. Modify styles, fonts, margins, headers, footers as desired
3. Save the file
4. All future documents will use your custom formatting

## Workflow

### Create a Job Application

```bash
# With URL (auto-detects and uses default template)
job-apply "Acme Corp" "Engineering Manager" "https://jobs.acme.com/123"

# With specific template (no URL)
job-apply "Acme Corp" "Mobile Engineer" "mobile"

# With specific template and URL
job-apply "Acme Corp" "Mobile Engineer" "mobile" "https://jobs.acme.com/456"
```

This creates:

- `applications/active/acme_corp_engineering_manager_20250624/`
  - `resume.md` (from template with your info substituted)
  - `cover_letter.md` (from template with your info substituted)
  - `application.yml` (metadata: company, role, date, URL)
  - `job_description.html` (scraped from URL)

### Edit and Customize

Edit the generated markdown files for job-specific content:

- Customize `resume.md` for the specific role
- Customize `cover_letter.md` with company-specific details
- Replace `[[Company]]` and `[[Position]]` placeholders

### Format Documents

```bash
# Convert both resume and cover letter to DOCX
job-format acme_corp_engineering_manager_20250624
```

Creates:

- `applications/active/acme_corp_engineering_manager_20250624/formatted/resume.docx`
- `applications/active/acme_corp_engineering_manager_20250624/formatted/cover_letter.docx`

### Track Application Status

```bash
# View current status
job-status acme_corp_engineering_manager_20250624

# Update status
job-status acme_corp_engineering_manager_20250624 submitted
job-status acme_corp_engineering_manager_20250624 interview
job-status acme_corp_engineering_manager_20250624 offered
```

### View Application Summary

```bash
# Summary of all applications
job-log

# Applications in specific status
job-log active
job-log submitted
job-log interview
```

### Commit Application to Git

```bash
# Commit the most recent application
job-commit

# Commit a specific application
job-commit acme_corp_engineering_manager_20250624
```

Automatically:

- Adds application files to git
- Generates commit message: "Add application for Acme Corp, Engineering Manager"
- Creates the commit

## Adding Resume Templates

Create additional resume templates for different roles:

1. Add new template file: `templates/resume/frontend.md`
2. Customize content for frontend roles
3. Use in applications:
   - With URL: `job-apply "Company" "Frontend Developer" "frontend" "https://..."`
   - Without URL: `job-apply "Company" "Frontend Developer" "frontend"`

The system automatically uses the correct reference document (`templates/resume/reference.docx`) for all resume templates.

## Individual Commands

### Template Processing

```bash
# Generate document from template with variable substitution
format-template templates/resume/mobile.md output/resume.md
```

### Document Conversion

```bash
# Convert markdown to DOCX (auto-detects reference document)
md2docx resume.md

# Convert to HTML
md2html resume.md

# Convert to PDF (requires LaTeX)
md2pdf resume.md
```

### Web Scraping

```bash
# Archive a job posting
url-scrape "https://company.com/jobs/123" job_description.html
```

## Project Structure

```text
├── setup.sh                    # Setup script
├── .writing.yml                # Personal configuration
├── VERSION                     # Version tracking
├── scripts/
│   └── markdown.sh             # Core functions
├── templates/
│   ├── resume/
│   │   ├── default.md          # Default resume template
│   │   ├── frontend.md         # Frontend-specific template
│   │   ├── mobile.md           # Mobile-specific template
│   │   └── reference.docx      # DOCX formatting reference
│   └── cover_letter/
│       ├── default.md          # Default cover letter template
│       └── reference.docx      # DOCX formatting reference
└── applications/
    ├── active/                 # Applications in progress
    ├── submitted/              # Applications submitted
    ├── interview/              # Interview scheduled
    ├── offered/                # Job offers received
    └── rejected/               # Applications rejected
```

## Dependencies

- **pandoc**: Document conversion
- **yq**: YAML file processing
- **Chrome** (optional): Better web scraping (falls back to curl)
- **LaTeX** (optional): PDF generation

## Tips

- Use `job-log` regularly to track your application pipeline
- Customize reference DOCX files to match your preferred formatting
- Create role-specific resume templates for different job types
- The system works from any directory within your writing project
- If functions aren't available, restart your shell or source the script again

## Development and Sync Workflow

### Public Template vs Private Usage

This repository serves as a **public template** for the markdown writing workflow.
When using this system for actual job applications, you should
maintain a **separate private repository** with your personal data.

**Why separate repositories?**

- **Privacy**: Keep personal information, application data, and job descriptions private
- **Development**: Safely pull updates from this template without exposing personal data
- **Flexibility**: Customize your private setup without affecting the template

### Getting Updates from the Template

If you used the template to create your private repository, you'll need to manually get updates from the original template.
Here's how:

**Method 1: Clone the original template for updates**

```bash
# Clone the original template to get updates
git clone git@github.com:nickhart/markdown-writer.git ../markdown-writer-template

# From your private repository, sync the updates
./scripts/sync.sh ../markdown-writer-template
```

**Method 2: Add the template as a remote**

```bash
# From your private repository, add the template as a remote
git remote add template git@github.com:nickhart/markdown-writer.git

# Fetch updates
git fetch template

# Use sync script to copy specific files
git clone template/main ../temp-template
./scripts/sync.sh ../temp-template
rm -rf ../temp-template
```

**What the sync script does:**

- Copies core functionality (setup.sh, scripts/, .vscode/)
- Updates template files without overwriting your personal data
- Preserves your .writing.yml and application data
- Updates .gitignore to protect your private information

Note: Since GitHub templates create a clean copy without git history connection to the original, you need to manually
manage updates. The sync script helps copy only the files you want while protecting your personal data.

## Version

Current version: 0.9.0

For issues and contributions, see TODO.md for planned enhancements.
