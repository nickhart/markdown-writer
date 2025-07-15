# Remove any conflicting aliases from previous markdown tools
unalias md2html 2>/dev/null || true
unalias md2docx 2>/dev/null || true
unalias md2pdf 2>/dev/null || true

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Sanitize string for filename
sanitize_filename() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/__*/_/g' | sed 's/^_\|_$//g'
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Find project root by walking up directories looking for scripts/markdown.sh
find_project_root() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/scripts/markdown.sh" ]]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    return 1
}

# Validate we're in a writing project and set WRITING_PROJECT_ROOT
validate_project() {
    if ! WRITING_PROJECT_ROOT=$(find_project_root); then
        log_error "Not in a writing project directory"
        log_error "Please run this command from within a writing project (containing scripts/markdown.sh)"
        return 1
    fi
    export WRITING_PROJECT_ROOT
}

# Format template with variable substitution from .writing.yml
# Usage: format-template template_file output_file
format-template() {
    local template_file="$1"
    local output_file="$2"

    # Validate project and arguments
    validate_project || return 1

    if [[ -z "$template_file" ]] || [[ -z "$output_file" ]]; then
        log_error "Usage: format-template <template_file> <output_file>"
        return 1
    fi

    if [[ ! -f "$template_file" ]]; then
        log_error "Template file not found: $template_file"
        return 1
    fi

    local config_file="$WRITING_PROJECT_ROOT/.writing.yml"
    if [[ ! -f "$config_file" ]]; then
        log_error "Configuration file not found: $config_file"
        log_error "Run setup.sh to create .writing.yml"
        return 1
    fi

    log_info "Formatting template: $template_file → $output_file"

    # Create output directory if needed
    local output_dir=$(dirname "$output_file")
    mkdir -p "$output_dir"

    # Read template content
    local content=$(cat "$template_file")

    # Generate dynamic variables
    local current_date=$(date +"%B %d, %Y")

    # Read config values using yq
    if ! command_exists yq; then
        log_error "yq not found. Please install yq to use template substitution."
        return 1
    fi

    # Extract values from config
    local name=$(yq '.name' "$config_file" 2>/dev/null | sed 's/^"//;s/"$//')
    local preferred_name=$(yq '.preferred_name' "$config_file" 2>/dev/null | sed 's/^"//;s/"$//')
    local email=$(yq '.email' "$config_file" 2>/dev/null | sed 's/^"//;s/"$//')
    local phone=$(yq '.phone' "$config_file" 2>/dev/null | sed 's/^"//;s/"$//')
    local address=$(yq '.address' "$config_file" 2>/dev/null | sed 's/^"//;s/"$//')
    local city=$(yq '.city' "$config_file" 2>/dev/null | sed 's/^"//;s/"$//')
    local state=$(yq '.state' "$config_file" 2>/dev/null | sed 's/^"//;s/"$//')
    local zip=$(yq '.zip' "$config_file" 2>/dev/null | sed 's/^"//;s/"$//')
    local linkedin=$(yq '.linkedin' "$config_file" 2>/dev/null | sed 's/^"//;s/"$//')
    local github=$(yq '.github' "$config_file" 2>/dev/null | sed 's/^"//;s/"$//')
    local website=$(yq '.website' "$config_file" 2>/dev/null | sed 's/^"//;s/"$//')

    # Handle potential null values
    [[ "$name" == "null" ]] && name=""
    [[ "$preferred_name" == "null" ]] && preferred_name=""
    [[ "$email" == "null" ]] && email=""
    [[ "$phone" == "null" ]] && phone=""
    [[ "$address" == "null" ]] && address=""
    [[ "$city" == "null" ]] && city=""
    [[ "$state" == "null" ]] && state=""
    [[ "$zip" == "null" ]] && zip=""
    [[ "$linkedin" == "null" ]] && linkedin=""
    [[ "$github" == "null" ]] && github=""
    [[ "$website" == "null" ]] && website=""

    # Create formatted URLs
    local email_link="[${email}](mailto:${email})"
    local linkedin_link="[${linkedin}](https://${linkedin})"
    local github_link="[${github}](https://${github})"
    local website_link="[${website}](https://${website})"

    # Perform substitutions
    content="${content//\{\{name\}\}/$name}"
    content="${content//\{\{preferred_name\}\}/$preferred_name}"
    content="${content//\{\{email\}\}/$email_link}"
    content="${content//\{\{phone\}\}/$phone}"
    content="${content//\{\{address\}\}/$address}"
    content="${content//\{\{city\}\}/$city}"
    content="${content//\{\{state\}\}/$state}"
    content="${content//\{\{zip\}\}/$zip}"
    content="${content//\{\{linkedin\}\}/$linkedin_link}"
    content="${content//\{\{github\}\}/$github_link}"
    content="${content//\{\{website\}\}/$website_link}"
    content="${content//\{\{date\}\}/$current_date}"

    # Write output file
    echo "$content" > "$output_file"

    log_success "Template formatted successfully: $output_file"
    return 0
}

# HTML for blog posts (clean, WordPress-friendly)
md2html() {
    validate_project || return 1

    if [[ -z "$1" ]]; then
        log_error "Usage: md2html <markdown_file>"
        return 1
    fi

    if [[ ! -f "$1" ]]; then
        log_error "Markdown file not found: $1"
        return 1
    fi

    mkdir -p "./formatted"
    local output_file="./formatted/$(basename "$1" .md).html"

    log_info "Converting $1 to HTML..."
    pandoc --no-highlight --wrap=none -t html -o "$output_file" "$1"

    if [[ $? -eq 0 ]]; then
        log_success "HTML created: $output_file"
    else
        log_error "Failed to convert $1 to HTML"
        return 1
    fi
}

# DOCX with reference template (auto-detects based on filename)
md2docx() {
    validate_project || return 1

    if [[ -z "$1" ]]; then
        log_error "Usage: md2docx <markdown_file>"
        return 1
    fi

    if [[ ! -f "$1" ]]; then
        log_error "Markdown file not found: $1"
        return 1
    fi

    mkdir -p "./formatted"

    # Detect template type from filename (resume.md -> resume, cover_letter.md -> cover_letter)
    local template_type=$(basename "$1" .md)
    local reference_doc="$WRITING_PROJECT_ROOT/templates/$template_type/reference.docx"
    local output_file="./formatted/$(basename "$1" .md).docx"

    # Check if reference document exists
    if [[ ! -f "$reference_doc" ]]; then
        log_warning "Reference document not found: $reference_doc"
        log_info "Converting without reference document..."
        pandoc -o "$output_file" "$1"
    else
        log_info "Converting $1 to DOCX with reference: $reference_doc"
        pandoc --reference-doc="$reference_doc" -o "$output_file" "$1"
    fi

    if [[ $? -eq 0 ]]; then
        log_success "DOCX created: $output_file"
    else
        log_error "Failed to convert $1 to DOCX"
        return 1
    fi
}

# PDF via LaTeX
md2pdf() {
    validate_project || return 1

    if [[ -z "$1" ]]; then
        log_error "Usage: md2pdf <markdown_file>"
        return 1
    fi

    if [[ ! -f "$1" ]]; then
        log_error "Markdown file not found: $1"
        return 1
    fi

    if ! command_exists pdflatex && ! command_exists xelatex && ! command_exists lualatex; then
        log_error "LaTeX not found. Install LaTeX to enable PDF export."
        log_info "Run setup.sh for installation instructions."
        return 1
    fi

    mkdir -p "./formatted"
    local output_file="./formatted/$(basename "$1" .md).pdf"

    log_info "Converting $1 to PDF..."
    pandoc -o "$output_file" "$1"

    if [[ $? -eq 0 ]]; then
        log_success "PDF created: $output_file"
    else
        log_error "Failed to convert $1 to PDF"
        return 1
    fi
}

# Create a new job application in "active" status
# Usage: job-apply <company> <role> [resume_template] <url>
# eg: job-apply "acme" "engineering manager" "https://acme.com/jobs/listing/engineering-manager/123456"
# eg: job-apply "acme" "mobile engineer" "mobile" "https://acme.com/jobs/listing/mobile-engineer/456789"
job-apply() {
    validate_project || return 1

    local company="$1"
    local role="$2"
    local resume_template="default"
    local url=""

    # Parse arguments - expect template but fall back to default if it's a URL
    if [[ $# -eq 3 ]]; then
        local third_arg="$3"
        if [[ "$third_arg" =~ ^https?:// ]]; then
            # Third argument is a URL, use default template
            log_info "No template specified, using default"
            resume_template="default"
            url="$third_arg"
        else
            # Third argument is a template name
            resume_template="$third_arg"
            url=""
        fi
    elif [[ $# -eq 4 ]]; then
        # job-apply "company" "role" "template" "url"
        resume_template="$3"
        url="$4"
    else
        log_error "Usage: job-apply <company> <role> <template_or_url> [url]"
        log_error "Examples:"
        log_error "  job-apply \"Acme Corp\" \"Engineering Manager\" \"https://jobs.acme.com/123\""
        log_error "  job-apply \"Acme Corp\" \"Mobile Engineer\" \"mobile\" \"https://jobs.acme.com/456\""
        log_error "  job-apply \"Acme Corp\" \"Backend Engineer\" \"backend\""
        return 1
    fi

    if [[ -z "$company" ]] || [[ -z "$role" ]]; then
        log_error "Company and role are required"
        return 1
    fi

    # Create application directory name
    local date_suffix=$(date +"%Y%m%d")
    local application_name=$(sanitize_filename "${company}_${role}_${date_suffix}")
    local application_path="$WRITING_PROJECT_ROOT/applications/active/$application_name"

    # Check if application already exists
    if [[ -d "$application_path" ]]; then
        log_warning "Application already exists: $application_path"
        log_info "Use format-template or url-scrape to regenerate individual files"
        return 1
    fi

    log_info "Creating job application: $application_name"

    # Create application directory
    mkdir -p "$application_path"

    # Validate templates exist
    local resume_template_path="$WRITING_PROJECT_ROOT/templates/resume/$resume_template.md"
    local cover_letter_template_path="$WRITING_PROJECT_ROOT/templates/cover_letter/default.md"

    if [[ ! -f "$resume_template_path" ]]; then
        log_error "Resume template not found: $resume_template_path"
        rmdir "$application_path" 2>/dev/null
        return 1
    fi

    if [[ ! -f "$cover_letter_template_path" ]]; then
        log_error "Cover letter template not found: $cover_letter_template_path"
        rmdir "$application_path" 2>/dev/null
        return 1
    fi

    # Format templates using format-template function
    log_info "Formatting resume from template: $resume_template"
    format-template "$resume_template_path" "$application_path/resume.md" || {
        log_error "Failed to format resume template"
        rm -rf "$application_path" 2>/dev/null
        return 1
    }

    log_info "Formatting cover letter from template"
    format-template "$cover_letter_template_path" "$application_path/cover_letter.md" || {
        log_error "Failed to format cover letter template"
        rm -rf "$application_path" 2>/dev/null
        return 1
    }

    # Create application metadata YAML
    local metadata_file="$application_path/application.yml"
    cat > "$metadata_file" << EOF
# Job Application Metadata
company: "$company"
role: "$role"
resume_template: "$resume_template"
url: "$url"
date_created: "$(date -Iseconds)"
status: "active"
EOF

    # Scrape job description if URL provided
    if [[ -n "$url" ]]; then
        log_info "Scraping job description from: $url"
        url-scrape "$url" "$application_path/job_description.html" || {
            log_warning "Failed to scrape job description, but application was created"
        }
    else
        log_info "No URL provided - skipping job description scraping"
    fi

    log_success "Job application created successfully!"
    log_info "Location: $application_path"
    log_info "Next steps:"
    echo "  1. Edit resume.md and cover_letter.md with job-specific content"
    echo "  2. Format documents: job-format $application_name"
    echo "  3. Update status: job-status $application_name submitted"

    return 0
}

# Format resume and cover letter for a job application to DOCX
# Usage: job-format <application_name>
# eg: job-format stripe_engineering_manager_20250624
job-format() {
    validate_project || return 1

    local application_name="$1"

    if [[ -z "$application_name" ]]; then
        log_error "Usage: job-format <application_name>"
        log_error "Example: job-format stripe_engineering_manager_20250624"
        return 1
    fi

    # Valid status directories
    local valid_statuses=("active" "submitted" "interview" "offered" "rejected")
    local current_status=""
    local current_path=""

    # Find the application in status directories
    for app_status in "${valid_statuses[@]}"; do
        local check_path="$WRITING_PROJECT_ROOT/applications/$app_status/$application_name"
        if [[ -d "$check_path" ]]; then
            current_status="$app_status"
            current_path="$check_path"
            break
        fi
    done

    if [[ -z "$current_status" ]]; then
        log_error "Application not found: $application_name"
        log_info "Available applications:"
        for app_status in "${valid_statuses[@]}"; do
            local apps=$(ls "$WRITING_PROJECT_ROOT/applications/$app_status/" 2>/dev/null | head -3)
            if [[ -n "$apps" ]]; then
                echo "  $app_status: $(echo "$apps" | tr '\n' ' ')"
            fi
        done
        return 1
    fi

    log_info "Formatting documents for: $application_name"
    log_info "Location: $current_path"

    # Check if resume and cover letter exist
    local resume_file="$current_path/resume.md"
    local cover_letter_file="$current_path/cover_letter.md"

    if [[ ! -f "$resume_file" ]]; then
        log_error "Resume not found: $resume_file"
        return 1
    fi

    if [[ ! -f "$cover_letter_file" ]]; then
        log_error "Cover letter not found: $cover_letter_file"
        return 1
    fi

    # Create formatted directory in the application folder
    local formatted_dir="$current_path/formatted"
    mkdir -p "$formatted_dir"

    # Format resume to DOCX
    log_info "Converting resume to DOCX..."
    local resume_template_type="resume"
    local resume_reference_doc="$WRITING_PROJECT_ROOT/templates/$resume_template_type/reference.docx"
    local resume_output="$formatted_dir/resume.docx"

    if [[ -f "$resume_reference_doc" ]]; then
        log_info "Using reference document: $resume_reference_doc"
        pandoc --reference-doc="$resume_reference_doc" -o "$resume_output" "$resume_file"
    else
        log_warning "Reference document not found: $resume_reference_doc"
        log_info "Converting without reference document..."
        pandoc -o "$resume_output" "$resume_file"
    fi

    if [[ $? -eq 0 ]]; then
        log_success "Resume DOCX created: $resume_output"
    else
        log_error "Failed to convert resume to DOCX"
        return 1
    fi

    # Format cover letter to DOCX
    log_info "Converting cover letter to DOCX..."
    local cover_letter_template_type="cover_letter"
    local cover_letter_reference_doc="$WRITING_PROJECT_ROOT/templates/$cover_letter_template_type/reference.docx"
    local cover_letter_output="$formatted_dir/cover_letter.docx"

    if [[ -f "$cover_letter_reference_doc" ]]; then
        log_info "Using reference document: $cover_letter_reference_doc"
        pandoc --reference-doc="$cover_letter_reference_doc" -o "$cover_letter_output" "$cover_letter_file"
    else
        log_warning "Reference document not found: $cover_letter_reference_doc"
        log_info "Converting without reference document..."
        pandoc -o "$cover_letter_output" "$cover_letter_file"
    fi

    if [[ $? -eq 0 ]]; then
        log_success "Cover letter DOCX created: $cover_letter_output"
    else
        log_error "Failed to convert cover letter to DOCX"
        return 1
    fi

    log_success "Job application formatted successfully!"
    log_info "Documents available in: $formatted_dir"
    echo "  - resume.docx"
    echo "  - cover_letter.docx"

    return 0
}

# try to use Google Chrome to scrape the job posting and save it as html
# fall back to curl
# add the UTF-8 BOM at the beginning of the file so UTF-8 characters are handled correctly when rendered locally
# pass in the url and the filename to save to
# eg: url-scrape "https://acme.com/jobs/listing/engineering-manager/123456" job_posting.html
url-scrape() {
    local url="$1"
    local filename="$2"

    # Preserve PATH to prevent it being overwritten
    local ORIGINAL_PATH="$PATH"

    log_info "Archiving url with proper UTF-8..."

    # look for common Chrome locations
    local chrome_executable=""
    local chrome_locations=(
        "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
        "/usr/bin/google-chrome"
        "/usr/bin/google-chrome-stable"
        "/usr/bin/chromium"
        "/usr/bin/chromium-browser"
    )

    for chrome_location in "${chrome_locations[@]}"; do
        if [[ -x "$chrome_location" ]]; then
            chrome_executable="$chrome_location"
            break
        fi
    done

    # Try Chrome first if available
    if [[ -n "$chrome_executable" ]] && [[ -x "$chrome_executable" ]]; then
        log_info "Using Chrome for archiving..."
        # UTF-8 BOM + Chrome dump = perfect encoding
        {
            printf '\xEF\xBB\xBF'  # UTF-8 BOM
            "$chrome_executable" \
                --headless \
                --disable-gpu \
                --dump-dom \
                --virtual-time-budget=5000 \
                "$url"
        } > "$filename"
        log_success "Clean UTF-8 HTML saved to $filename (via Chrome)"
        return 0
    fi

    # Fallback to curl with UTF-8 support
    log_warning "Chrome not available, falling back to curl..."

    if ! command_exists curl; then
        log_error "Neither Chrome nor curl is available for downloading job postings"
        return 1
    fi

    # Download with curl and UTF-8 handling
    {
        printf '\xEF\xBB\xBF'  # UTF-8 BOM
        curl -L -s \
            -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
            -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
            -H "Accept-Charset: utf-8" \
            "$url"
    } > "$filename"

    if [[ -s "$filename" ]]; then
        log_success "UTF-8 HTML saved to $filename (via curl)"
        return 0
    else
        log_error "Failed to download job posting with curl"
        return 1
    fi

    # Restore PATH just in case
    export PATH="$ORIGINAL_PATH"
}

# Check or change the status of a job application
# Usage: job-status <application_name> [new_status]
# eg: job-status acme_engineering_manager_20250624
# eg: job-status acme_engineering_manager_20250624 interview
job-status() {
    validate_project || return 1

    local application_name="$1"
    local new_status="$2"

    if [[ -z "$application_name" ]]; then
        log_error "Usage: job-status <application_name> [new_status]"
        log_error "Valid statuses: active, submitted, interview, offered, rejected"
        return 1
    fi

    # Valid status directories
    local valid_statuses=("active" "submitted" "interview" "offered" "rejected")
    local current_status=""
    local current_path=""

    # Find the application in status directories
    for app_status in "${valid_statuses[@]}"; do
        local check_path="$WRITING_PROJECT_ROOT/applications/$app_status/$application_name"
        if [[ -d "$check_path" ]]; then
            current_status="$app_status"
            current_path="$check_path"
            break
        fi
    done

    if [[ -z "$current_status" ]]; then
        log_error "Application not found: $application_name"
        log_info "Available applications:"
        for app_status in "${valid_statuses[@]}"; do
            local apps=$(ls "$WRITING_PROJECT_ROOT/applications/$app_status/" 2>/dev/null | head -3)
            if [[ -n "$apps" ]]; then
                echo "  $app_status: $(echo "$apps" | tr '\n' ' ')"
            fi
        done
        return 1
    fi

    # If no new status provided, show current status
    if [[ -z "$new_status" ]]; then
        log_info "Application: $application_name"
        log_info "Current status: $current_status"
        log_info "Location: $current_path"

        # Show metadata if available
        local metadata_file="$current_path/application.yml"
        if [[ -f "$metadata_file" ]]; then
            echo ""
            echo "Application details:"
            cat "$metadata_file"
        fi
        return 0
    fi

    # Validate new status
    local valid_new_status=false
    for app_status in "${valid_statuses[@]}"; do
        if [[ "$app_status" == "$new_status" ]]; then
            valid_new_status=true
            break
        fi
    done

    if [[ "$valid_new_status" != true ]]; then
        log_error "Invalid status: $new_status"
        log_error "Valid statuses: ${valid_statuses[*]}"
        return 1
    fi

    # If already in the requested status
    if [[ "$current_status" == "$new_status" ]]; then
        log_info "Application is already in status: $new_status"
        return 0
    fi

    # Move to new status directory
    local new_path="$WRITING_PROJECT_ROOT/applications/$new_status/$application_name"

    log_info "Moving $application_name: $current_status → $new_status"

    # Create target directory if it doesn't exist
    mkdir -p "$WRITING_PROJECT_ROOT/applications/$new_status"

    # Move the application directory
    mv "$current_path" "$new_path" || {
        log_error "Failed to move application to $new_status"
        return 1
    }

    # Update metadata if available
    local metadata_file="$new_path/application.yml"
    if [[ -f "$metadata_file" ]] && command_exists yq; then
        yq eval ".status = \"$new_status\"" -i "$metadata_file" 2>/dev/null || true
        yq eval ".date_updated = \"$(date -Iseconds)\"" -i "$metadata_file" 2>/dev/null || true
    fi

    log_success "Application moved to: $new_status"
    log_info "New location: $new_path"

    return 0
}

# Show summary of job applications by status
# Usage: job-log [status]
# eg: job-log
# eg: job-log submitted
job-log() {
    validate_project || return 1

    local filter_status="$1"
    local valid_statuses=("active" "submitted" "interview" "offered" "rejected")

    # If specific status requested, validate it
    if [[ -n "$filter_status" ]]; then
        local valid_filter=false
        for app_status in "${valid_statuses[@]}"; do
            if [[ "$app_status" == "$filter_status" ]]; then
                valid_filter=true
                break
            fi
        done

        if [[ "$valid_filter" != true ]]; then
            log_error "Invalid status: $filter_status"
            log_error "Valid statuses: ${valid_statuses[*]}"
            return 1
        fi
    fi

    echo "Job Application Summary"
    echo "======================"
    echo ""

    local total_count=0

    # Show summary for each status (or just the filtered one)
    for app_status in "${valid_statuses[@]}"; do
        if [[ -n "$filter_status" ]] && [[ "$app_status" != "$filter_status" ]]; then
            continue
        fi

        local status_dir="$WRITING_PROJECT_ROOT/applications/$app_status"
        local count=0

        if [[ -d "$status_dir" ]]; then
            count=$(ls -1 "$status_dir" 2>/dev/null | wc -l)
            total_count=$((total_count + count))
        fi

        printf "%-12s: %d applications\n" "$app_status" "$count"

        # Show application names if filtering by specific status
        if [[ -n "$filter_status" ]] && [[ "$count" -gt 0 ]]; then
            echo ""
            ls -1 "$status_dir" 2>/dev/null | while read -r app; do
                echo "  - $app"
                # Show brief metadata if available
                local metadata_file="$status_dir/$app/application.yml"
                if [[ -f "$metadata_file" ]]; then
                    local company=$(yq '.company' "$metadata_file" 2>/dev/null | sed 's/^"//;s/"$//')
                    local role=$(yq '.role' "$metadata_file" 2>/dev/null | sed 's/^"//;s/"$//')
                    if [[ "$company" != "null" ]] && [[ "$role" != "null" ]]; then
                        echo "    Company: $company, Role: $role"
                    fi
                fi
            done
        fi
    done

    if [[ -z "$filter_status" ]]; then
        echo ""
        echo "Total: $total_count applications"
    fi

    return 0
}

# Git commit workflow for job applications
# Usage: job-commit [application_name]
# eg: job-commit acme_engineering_manager_20250624
# eg: job-commit (uses most recent application)
job-commit() {
    validate_project || return 1

    local application_name="$1"
    local valid_statuses=("active" "submitted" "interview" "offered" "rejected")
    local current_status=""
    local current_path=""

    # If no application name provided, find the most recent one
    if [[ -z "$application_name" ]]; then
        log_info "Finding most recent application..."
        local most_recent=""
        local most_recent_time=0
        
        for app_status in "${valid_statuses[@]}"; do
            local status_dir="$WRITING_PROJECT_ROOT/applications/$app_status"
            if [[ -d "$status_dir" ]]; then
                for app_dir in "$status_dir"/*; do
                    if [[ -d "$app_dir" ]]; then
                        local app_name=$(basename "$app_dir")
                        local metadata_file="$app_dir/application.yml"
                        if [[ -f "$metadata_file" ]]; then
                            local date_created=$(yq '.date_created' "$metadata_file" 2>/dev/null | sed 's/^"//;s/"$//')
                            if [[ "$date_created" != "null" ]]; then
                                local timestamp=$(date -j -f "%Y-%m-%dT%H:%M:%S%z" "$date_created" "+%s" 2>/dev/null || echo "0")
                                if [[ "$timestamp" -gt "$most_recent_time" ]]; then
                                    most_recent_time="$timestamp"
                                    most_recent="$app_name"
                                    current_status="$app_status"
                                    current_path="$app_dir"
                                fi
                            fi
                        fi
                    fi
                done
            fi
        done
        
        if [[ -z "$most_recent" ]]; then
            log_error "No applications found to commit"
            return 1
        fi
        
        application_name="$most_recent"
        log_info "Using most recent application: $application_name"
    else
        # Find the specified application in status directories
        for app_status in "${valid_statuses[@]}"; do
            local check_path="$WRITING_PROJECT_ROOT/applications/$app_status/$application_name"
            if [[ -d "$check_path" ]]; then
                current_status="$app_status"
                current_path="$check_path"
                break
            fi
        done

        if [[ -z "$current_status" ]]; then
            log_error "Application not found: $application_name"
            return 1
        fi
    fi

    log_info "Committing application: $application_name"
    log_info "Location: $current_path"

    # Check if we're in a git repository
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        log_error "Not in a git repository"
        return 1
    fi

    # Read application metadata
    local metadata_file="$current_path/application.yml"
    if [[ ! -f "$metadata_file" ]]; then
        log_error "Application metadata not found: $metadata_file"
        return 1
    fi

    local company=$(yq '.company' "$metadata_file" 2>/dev/null | sed 's/^"//;s/"$//')
    local role=$(yq '.role' "$metadata_file" 2>/dev/null | sed 's/^"//;s/"$//')
    local resume_template=$(yq '.resume_template' "$metadata_file" 2>/dev/null | sed 's/^"//;s/"$//')

    # Handle null values
    [[ "$company" == "null" ]] && company="Unknown Company"
    [[ "$role" == "null" ]] && role="Unknown Role"
    [[ "$resume_template" == "null" ]] && resume_template="default"

    # Generate commit message
    local commit_message="Add application for $company, $role"
    if [[ "$resume_template" != "default" ]]; then
        commit_message="$commit_message (using $resume_template template)"
    fi

    log_info "Adding files to git..."
    
    # Add the application directory to git
    local relative_path="applications/$current_status/$application_name"
    git add "$relative_path" || {
        log_error "Failed to add application files to git"
        return 1
    }

    log_info "Creating commit with message: $commit_message"
    
    # Commit the changes
    git commit -m "$commit_message" || {
        log_error "Failed to create git commit"
        return 1
    }

    log_success "Successfully committed application!"
    log_info "Commit message: $commit_message"
    
    return 0
}

# Create a new blog post in "drafts" status
# Usage: blog-create <title> [template]
# eg: blog-create "My Amazing Blog Post"
# eg: blog-create "Tech Tutorial" "tutorial"
blog-create() {
    validate_project || return 1

    local title="$1"
    local template="$2"

    if [[ -z "$title" ]]; then
        log_error "Usage: blog-create <title> [template]"
        log_error "Example: blog-create \"My Amazing Blog Post\""
        return 1
    fi

    # Default template if not specified
    if [[ -z "$template" ]]; then
        template="default"
    fi

    # Create blog post directory name
    local date_suffix=$(date +"%m%d%Y")
    local post_name=$(sanitize_filename "${title}_${date_suffix}")
    local post_path="$WRITING_PROJECT_ROOT/blog/drafts/$post_name"

    # Check if post already exists
    if [[ -d "$post_path" ]]; then
        log_warning "Blog post already exists: $post_path"
        return 1
    fi

    log_info "Creating blog post: $post_name"

    # Create post directory and images subdirectory
    mkdir -p "$post_path/images"

    # Validate template exists
    local template_path="$WRITING_PROJECT_ROOT/templates/blog/$template.md"
    if [[ ! -f "$template_path" ]]; then
        log_error "Blog template not found: $template_path"
        rmdir "$post_path/images" "$post_path" 2>/dev/null
        return 1
    fi

    # Create content.md from template with title substitution
    log_info "Formatting blog post from template: $template"
    local content_file="$post_path/content.md"
    
    # Read template and perform substitutions
    local content=$(cat "$template_path")
    local current_date=$(date +"%B %d, %Y")
    
    # Read config for personal info
    local config_file="$WRITING_PROJECT_ROOT/.writing.yml"
    if [[ -f "$config_file" ]] && command_exists yq; then
        local name=$(yq '.name' "$config_file" 2>/dev/null | sed 's/^"//;s/"$//')
        [[ "$name" == "null" ]] && name="Author"
        
        content="${content//\{\{name\}\}/$name}"
    else
        content="${content//\{\{name\}\}/Author}"
    fi
    
    # Perform substitutions
    content="${content//\{\{title\}\}/$title}"
    content="${content//\{\{date\}\}/$current_date}"
    
    # Write content file
    echo "$content" > "$content_file"

    # Create blog post metadata YAML
    local metadata_file="$post_path/post.yml"
    cat > "$metadata_file" << EOF
# Blog Post Metadata
title: "$title"
template: "$template"
date_created: "$(date -Iseconds)"
status: "drafts"
slug: "$post_name"
tags: []
category: ""
excerpt: ""
EOF

    log_success "Blog post created successfully!"
    log_info "Location: $post_path"
    log_info "Next steps:"
    echo "  1. Edit content.md with your blog post content"
    echo "  2. Add images to the images/ directory"
    echo "  3. Update post.yml with tags and category"
    echo "  4. Format to HTML: blog-format $post_name"
    echo "  5. Publish: blog-status $post_name published"

    return 0
}

# Check or change the status of a blog post
# Usage: blog-status <post_name> [new_status]
# eg: blog-status my_amazing_blog_post_01152024
# eg: blog-status my_amazing_blog_post_01152024 published
blog-status() {
    validate_project || return 1

    local post_name="$1"
    local new_status="$2"

    if [[ -z "$post_name" ]]; then
        log_error "Usage: blog-status <post_name> [new_status]"
        log_error "Valid statuses: drafts, published"
        return 1
    fi

    # Valid status directories
    local valid_statuses=("drafts" "published")
    local current_status=""
    local current_path=""

    # Find the post in status directories
    for blog_status in "${valid_statuses[@]}"; do
        local check_path="$WRITING_PROJECT_ROOT/blog/$blog_status/$post_name"
        if [[ -d "$check_path" ]]; then
            current_status="$blog_status"
            current_path="$check_path"
            break
        fi
    done

    if [[ -z "$current_status" ]]; then
        log_error "Blog post not found: $post_name"
        log_info "Available posts:"
        for blog_status in "${valid_statuses[@]}"; do
            local posts=$(ls "$WRITING_PROJECT_ROOT/blog/$blog_status/" 2>/dev/null | head -3)
            if [[ -n "$posts" ]]; then
                echo "  $blog_status: $(echo "$posts" | tr '\n' ' ')"
            fi
        done
        return 1
    fi

    # If no new status provided, show current status
    if [[ -z "$new_status" ]]; then
        log_info "Blog post: $post_name"
        log_info "Current status: $current_status"
        log_info "Location: $current_path"

        # Show metadata if available
        local metadata_file="$current_path/post.yml"
        if [[ -f "$metadata_file" ]]; then
            echo ""
            echo "Post details:"
            cat "$metadata_file"
        fi
        return 0
    fi

    # Validate new status
    local valid_new_status=false
    for blog_status in "${valid_statuses[@]}"; do
        if [[ "$blog_status" == "$new_status" ]]; then
            valid_new_status=true
            break
        fi
    done

    if [[ "$valid_new_status" != true ]]; then
        log_error "Invalid status: $new_status"
        log_error "Valid statuses: ${valid_statuses[*]}"
        return 1
    fi

    # If already in the requested status
    if [[ "$current_status" == "$new_status" ]]; then
        log_info "Blog post is already in status: $new_status"
        return 0
    fi

    # Move to new status directory
    local new_path="$WRITING_PROJECT_ROOT/blog/$new_status/$post_name"

    log_info "Moving $post_name: $current_status → $new_status"

    # Create target directory if it doesn't exist
    mkdir -p "$WRITING_PROJECT_ROOT/blog/$new_status"

    # Move the post directory
    mv "$current_path" "$new_path" || {
        log_error "Failed to move blog post to $new_status"
        return 1
    }

    # Update metadata if available
    local metadata_file="$new_path/post.yml"
    if [[ -f "$metadata_file" ]] && command_exists yq; then
        yq eval ".status = \"$new_status\"" -i "$metadata_file" 2>/dev/null || true
        yq eval ".date_updated = \"$(date -Iseconds)\"" -i "$metadata_file" 2>/dev/null || true
        
        # Add publish date if moving to published
        if [[ "$new_status" == "published" ]]; then
            yq eval ".date_published = \"$(date -Iseconds)\"" -i "$metadata_file" 2>/dev/null || true
        fi
    fi

    log_success "Blog post moved to: $new_status"
    log_info "New location: $new_path"

    return 0
}

# Show summary of blog posts by status
# Usage: blog-log [status]
# eg: blog-log
# eg: blog-log published
blog-log() {
    validate_project || return 1

    local filter_status="$1"
    local valid_statuses=("drafts" "published")

    # If specific status requested, validate it
    if [[ -n "$filter_status" ]]; then
        local valid_filter=false
        for blog_status in "${valid_statuses[@]}"; do
            if [[ "$blog_status" == "$filter_status" ]]; then
                valid_filter=true
                break
            fi
        done

        if [[ "$valid_filter" != true ]]; then
            log_error "Invalid status: $filter_status"
            log_error "Valid statuses: ${valid_statuses[*]}"
            return 1
        fi
    fi

    echo "Blog Post Summary"
    echo "=================="
    echo ""

    local total_count=0

    # Show summary for each status (or just the filtered one)
    for blog_status in "${valid_statuses[@]}"; do
        if [[ -n "$filter_status" ]] && [[ "$blog_status" != "$filter_status" ]]; then
            continue
        fi

        local status_dir="$WRITING_PROJECT_ROOT/blog/$blog_status"
        local count=0

        if [[ -d "$status_dir" ]]; then
            count=$(ls -1 "$status_dir" 2>/dev/null | wc -l)
            total_count=$((total_count + count))
        fi

        printf "%-12s: %d posts\n" "$blog_status" "$count"

        # Show post names if filtering by specific status
        if [[ -n "$filter_status" ]] && [[ "$count" -gt 0 ]]; then
            echo ""
            ls -1 "$status_dir" 2>/dev/null | while read -r post; do
                echo "  - $post"
                # Show brief metadata if available
                local metadata_file="$status_dir/$post/post.yml"
                if [[ -f "$metadata_file" ]]; then
                    local title=$(yq '.title' "$metadata_file" 2>/dev/null | sed 's/^"//;s/"$//')
                    local category=$(yq '.category' "$metadata_file" 2>/dev/null | sed 's/^"//;s/"$//')
                    if [[ "$title" != "null" ]]; then
                        echo "    Title: $title"
                        if [[ "$category" != "null" ]] && [[ -n "$category" ]]; then
                            echo "    Category: $category"
                        fi
                    fi
                fi
            done
        fi
    done

    if [[ -z "$filter_status" ]]; then
        echo ""
        echo "Total: $total_count posts"
    fi

    return 0
}

# Format blog post content to HTML
# Usage: blog-format <post_name>
# eg: blog-format my_amazing_blog_post_01152024
blog-format() {
    validate_project || return 1

    local post_name="$1"

    if [[ -z "$post_name" ]]; then
        log_error "Usage: blog-format <post_name>"
        log_error "Example: blog-format my_amazing_blog_post_01152024"
        return 1
    fi

    # Valid status directories
    local valid_statuses=("drafts" "published")
    local current_status=""
    local current_path=""

    # Find the post in status directories
    for blog_status in "${valid_statuses[@]}"; do
        local check_path="$WRITING_PROJECT_ROOT/blog/$blog_status/$post_name"
        if [[ -d "$check_path" ]]; then
            current_status="$blog_status"
            current_path="$check_path"
            break
        fi
    done

    if [[ -z "$current_status" ]]; then
        log_error "Blog post not found: $post_name"
        log_info "Available posts:"
        for blog_status in "${valid_statuses[@]}"; do
            local posts=$(ls "$WRITING_PROJECT_ROOT/blog/$blog_status/" 2>/dev/null | head -3)
            if [[ -n "$posts" ]]; then
                echo "  $blog_status: $(echo "$posts" | tr '\n' ' ')"
            fi
        done
        return 1
    fi

    log_info "Formatting blog post: $post_name"
    log_info "Location: $current_path"

    # Check if content.md exists
    local content_file="$current_path/content.md"
    if [[ ! -f "$content_file" ]]; then
        log_error "Content file not found: $content_file"
        return 1
    fi

    # Create formatted directory in the post folder
    local formatted_dir="$current_path/formatted"
    mkdir -p "$formatted_dir"

    # Format to HTML
    log_info "Converting content.md to HTML..."
    local html_output="$formatted_dir/index.html"

    # Use pandoc to convert to HTML with nice formatting
    pandoc --standalone \
           --from markdown \
           --to html \
           --css-url="../../../templates/blog/style.css" \
           --metadata title="$(yq '.title' "$current_path/post.yml" 2>/dev/null | sed 's/^"//;s/"$//' || echo "Blog Post")" \
           --output "$html_output" \
           "$content_file" || {
        log_error "Failed to convert content.md to HTML"
        return 1
    }

    log_success "HTML created: $html_output"

    # Also create a plain HTML version for blog platforms
    local plain_html_output="$formatted_dir/content.html"
    pandoc --from markdown \
           --to html \
           --output "$plain_html_output" \
           "$content_file" || {
        log_warning "Failed to create plain HTML version"
    }

    if [[ -f "$plain_html_output" ]]; then
        log_success "Plain HTML created: $plain_html_output"
    fi

    log_success "Blog post formatted successfully!"
    log_info "Files available in: $formatted_dir"
    echo "  - index.html (standalone with CSS)"
    echo "  - content.html (plain HTML for blog platforms)"

    return 0
}