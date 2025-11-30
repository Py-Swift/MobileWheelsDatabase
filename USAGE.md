# Using MkDocs MobileWheels Plugin in Other Projects

This guide shows how to add the MobileWheels package search to any MkDocs site.

## Quick Start

### 1. Install the Plugin

```bash
pip install git+https://github.com/Py-Swift/MobileWheelsDatabase.git
```

### 2. Configure Your Site

Add to your `mkdocs.yml`:

```yaml
plugins:
  - search  # Keep your existing plugins
  - mobilewheels
```

### 3. Create the Search Page

Create `docs/package-search.md`:

```markdown
# Package Search

Search for Python packages and check their compatibility.
```

### 4. Build and Serve

```bash
mkdocs serve
```

Visit `http://localhost:8000/package-search/` to see the search interface!

## Custom Configuration

### Change the Page Path

```yaml
plugins:
  - mobilewheels:
      page_path: "tools/packages"  # Will be at /tools/packages/
```

### Use Custom Database URL (CDN)

```yaml
plugins:
  - mobilewheels:
      database_url: "https://cdn.yoursite.com/mobilewheels"
```

Then upload these files to your CDN:
- `MobileWheelsDatabase.wasm` (~59MB)
- `index-1.sqlite`, `index-2.sqlite`
- `data-1.sqlite` through `data-29.sqlite`
- `package-search.js`

### Full Configuration Example

```yaml
site_name: My Documentation
site_url: https://docs.example.com

theme:
  name: material

plugins:
  - search
  - mobilewheels:
      page_path: "package-search"
      page_title: "Find Python Packages"
      database_url: "https://cdn.example.com/db"
      include_in_nav: true

nav:
  - Home: index.md
  - API Reference: api.md
  - Package Search: package-search.md  # Your search page
```

## Advanced Usage

### Hosting on GitHub Pages

The plugin works perfectly with GitHub Pages. The database files will be included in your site build automatically.

**`.github/workflows/docs.yml`:**

```yaml
name: Deploy Docs
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: 3.x
      
      - run: pip install mkdocs-material
      - run: pip install git+https://github.com/Py-Swift/MobileWheelsDatabase.git
      
      - run: mkdocs gh-deploy --force
```

### Custom Styling

Add custom CSS in your `docs/stylesheets/extra.css`:

```css
/* Customize the search interface */
.search-container {
    max-width: 1400px;
}

.search-box {
    font-size: 18px;
}

.badge-success {
    background: #your-color;
}
```

Reference it in `mkdocs.yml`:

```yaml
extra_css:
  - stylesheets/extra.css
```

## File Size Considerations

The plugin includes ~180MB of database files. For optimal performance:

1. **Use CDN**: Host database files on a CDN
2. **Use Git LFS**: If committing to git, use Git Large File Storage
3. **Exclude from git**: Add to `.gitignore` and download during build

### Example: Download During Build

**`.gitignore`:**
```
docs/mobilewheels_assets/
```

**Build script:**
```bash
#!/bin/bash
# Download database files during CI build
mkdir -p docs/mobilewheels_assets
wget -O docs/mobilewheels_assets/MobileWheelsDatabase.wasm \
  https://github.com/Py-Swift/MobileWheelsDatabase/releases/latest/download/MobileWheelsDatabase.wasm
# ... download other files
```

## Troubleshooting

### Plugin Not Found
```bash
# Verify installation
pip show mkdocs-mobilewheels

# Reinstall if needed
pip install --force-reinstall git+https://github.com/Py-Swift/MobileWheelsDatabase.git
```

### Database Files Not Loading
- Check browser console for errors
- Verify `database_url` path is correct
- Ensure CORS headers are set if using CDN

### Page Not Showing
- Verify `package-search.md` exists in `docs/`
- Check `mkdocs.yml` syntax
- Run `mkdocs serve -v` for verbose output

## Examples

### Example 1: Simple Blog with Package Search

```
my-blog/
├── docs/
│   ├── index.md
│   ├── blog/
│   │   └── post1.md
│   └── package-search.md  # Add this
├── mkdocs.yml  # Add plugin here
└── requirements.txt
```

### Example 2: API Documentation

```
my-api-docs/
├── docs/
│   ├── index.md
│   ├── api/
│   │   ├── endpoints.md
│   │   └── models.md
│   ├── guides/
│   │   ├── quickstart.md
│   │   └── packages.md  # Custom path for search
│   └── ...
└── mkdocs.yml
```

**mkdocs.yml:**
```yaml
plugins:
  - mobilewheels:
      page_path: "guides/packages"
```

## Support

- 📖 [Full Documentation](https://github.com/Py-Swift/MobileWheelsDatabase)
- 🐛 [Report Issues](https://github.com/Py-Swift/MobileWheelsDatabase/issues)
- 💬 [Discussions](https://github.com/Py-Swift/MobileWheelsDatabase/discussions)
