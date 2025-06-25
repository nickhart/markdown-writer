# Writing Workflow TODO

## 📋 IMPLEMENTATION TASKS

### Phase 1: Foundation & Setup

- [x] Create VERSION file (start at 0.1.0)
- [x] Create setup.sh script
  - [x] Check/install pandoc
  - [x] Check/install yq
  - [x] Check LaTeX installation and provide recommendations
  - [x] Setup shell sourcing (method TBD based on open questions)
- [x] Define YAML configuration structure
- [x] Create example templates structure in templates/

### Phase 2: Core Script Improvements

- [x] Fix shell syntax issues in markdown.sh
  - [x] Fix variable assignments (remove spaces around =)
  - [x] Fix function calls and conditionals
  - [x] Add proper error handling
- [x] Implement md2docx reference file resolution
- [x] Implement format-template function
  - [x] Read .writing.yml configuration
  - [x] Template variable substitution (name, email, etc.)
  - [x] Dynamic date generation ({{date}} → "Month Day, Year")
  - [x] Proper markdown URL formatting (email → [email](mailto:email))
  - [x] Handle missing template or config gracefully
- [x] Implement job-apply function
  - [x] Parameter validation
  - [x] Directory creation
  - [x] Use format-template() instead of cp
  - [x] YAML metadata creation
  - [x] Job description scraping
- [x] Implement job-status function
  - [x] Find application across status directories
  - [x] Show current status
  - [x] Move between status directories
- [x] Implement job-log function
  - [x] Summary by status
  - [x] Detailed listings
  - [x] Date/time information

### Phase 3: Enhanced Features

- [x] Add configuration file support
  - [x] Default template selection
  - [x] Output directory preferences
  - [x] User-specific settings
- [x] Improve url-scrape function
  - [x] Better error handling
  - [x] Content validation
  - [x] Metadata extraction
  - [x] Custom Chrome path support
- [x] Add template validation
  - [x] Check required templates exist
  - [x] Validate YAML frontmatter
  - [x] Template compatibility checks
- [x] Advanced customization
  - [x] Custom path/naming convention overrides
  - [ ] Auto-format on markdown changes (file watching)
  - [x] Template variable substitution from config
  - [x] Git commit workflow for job applications
    - [x] Add job-commit function
    - [x] Auto-generate commit messages from application metadata
    - [x] Handle git add for application files
    - [x] Example: "Added application for Acme Corp, Engineering Manager"

### Phase 4: Documentation & Polish

- [x] Add inline documentation to all functions
- [x] Create usage examples
- [x] Add error recovery suggestions
- [ ] Performance optimizations
- [ ] Cross-platform compatibility testing

### Phase 5: VSCode Integration & Developer Experience

- [x] Research and document recommended VSCode extensions
  - [x] Markdown editing (Markdown All in One)
  - [x] YAML editing (YAML)
  - [x] Shell script support (ShellCheck)
  - [x] File organization (File Utils)
  - [ ] Template snippets support
- [x] Create .vscode/settings.json with optimal configuration
  - [x] Markdown preview settings
  - [x] File associations for .writing.yml
  - [x] Auto-formatting preferences
  - [x] Workspace-specific settings
- [x] Create .vscode/tasks.json for workflow integration
  - [x] job-apply task with input prompts
  - [x] job-format task for current file/directory
  - [x] job-status task with application picker
  - [x] Quick format tasks (md2docx, md2pdf)
  - [x] Template generation tasks
- [x] Create .vscode/extensions.json with recommended extensions
  - [x] Core markdown and YAML support
  - [x] Optional productivity extensions
  - [x] Shell script linting
- [ ] Add VSCode snippets for template variables
  - [ ] Company/position placeholder snippets
  - [ ] Personal info variable snippets
  - [ ] Quick resume/cover letter section snippets
- [ ] Create workspace configuration for multi-root workspace
  - [ ] Support separate blog/ and applications/ folders
  - [ ] Consistent settings across project types

### Phase 6: Quality & Testing

- [ ] Test all functions with various inputs
- [ ] Validate pandoc output formats
- [ ] Test Chrome/curl fallback scenarios
- [ ] Verify file permissions and paths
- [ ] Test setup.sh on clean systems
- [ ] Test VSCode integration on clean installs

---

## 🔄 VERSION HISTORY PLAN

- **0.1.0**: Initial TODO and basic structure
- **0.2.0**: Core script functionality working
- **0.3.0**: Job application workflow complete
- **0.4.0**: Configuration and templates finalized
- **1.0.0**: Ready for public template repo

---

## 📝 NOTES

- Increment VERSION on every commit
- Only minor version bump (0.X.0) for breaking changes
- Only major version bump (1.0.0) for public release
- Keep existing blog/ and job_search/ directories untouched
- Focus on simplicity and clear documentation
- Test each feature thoroughly before moving to next item
