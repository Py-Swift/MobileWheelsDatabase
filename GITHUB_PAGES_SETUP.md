# GitHub Pages Setup for MobileWheelsDB Plugin

## Problem
When using the MobileWheelsDB plugin with GitHub Pages, the WASM file (59MB) gets downloaded during build and may be committed to the repository, triggering GitHub's large file warnings.

## Solution

### Option 1: Add to .gitignore (Recommended)
Add the following to your repository's `.gitignore` file:

```
# Ignore downloaded WASM files from MobileWheelsDB plugin
mobilewheels_assets/*.wasm
**/MobileWheelsDatabase.wasm
```

This prevents the WASM file from being tracked by git while still allowing it to be deployed to GitHub Pages.

### Option 2: Modify GitHub Pages Workflow
If you're using a custom GitHub Actions workflow to build and deploy your site, ensure the WASM file is excluded from the commit step:

```yaml
- name: Deploy to GitHub Pages
  run: |
    # Remove WASM files before committing
    find . -name "*.wasm" -type f -delete
    
    # Or specifically:
    rm -f mobilewheels_assets/MobileWheelsDatabase.wasm
    
    # Then commit and push the rest
    git add -A
    git commit -m "Update site"
    git push
```

### Option 3: Use GitHub Pages Deploy Action
Use the official GitHub Pages deployment action which doesn't commit files:

```yaml
name: Deploy MkDocs to GitHub Pages

on:
  push:
    branches: ["master"]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      
      - name: Install dependencies
        run: |
          pip install mkdocs mkdocs-material
          pip install git+https://github.com/Py-Swift/MobileWheelsDatabase.git
      
      - name: Build MkDocs site
        run: mkdocs build
      
      - name: Upload artifact
        uses: actions/upload-pages-artifact@v2
        with:
          path: './site'
      
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v2
```

This approach:
- ✅ Builds the site with the WASM file included
- ✅ Deploys everything to GitHub Pages
- ✅ Does NOT commit the WASM file back to the repo
- ✅ No LFS issues

## For Py-Swift/wiki Repository

To fix the current issue in https://github.com/Py-Swift/wiki:

1. **Add `.gitignore`** to the root of the wiki repo:
   ```
   mobilewheels_assets/*.wasm
   ```

2. **Remove existing WASM from git tracking**:
   ```bash
   git rm --cached mobilewheels_assets/MobileWheelsDatabase.wasm
   git commit -m "Remove WASM from git tracking"
   git push
   ```

3. **The WASM will still be present in the deployed site**, it just won't be in git history anymore.

## How the Plugin Works

1. During `mkdocs build`, the plugin downloads the WASM file from GitHub releases
2. The WASM is placed in the build output directory (`site/mobilewheels_assets/`)
3. When deployed to GitHub Pages, the WASM is served to users
4. The WASM should NOT be committed to git (hence the .gitignore)

## Verification

After applying the fix, verify:
```bash
# Check that .gitignore is working
git status
# Should NOT show mobilewheels_assets/*.wasm files

# Verify WASM is in build output
ls -lh site/mobilewheels_assets/*.wasm
# Should show the WASM file exists in the built site
```
