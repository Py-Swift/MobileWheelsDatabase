"""
MkDocs MobileWheels Plugin

Adds a Python package compatibility search page to MkDocs sites.
"""

import os
import shutil
import urllib.request
from pathlib import Path
from mkdocs.config import config_options
from mkdocs.plugins import BasePlugin


class MobileWheelsPlugin(BasePlugin):
    """
    Plugin to add MobileWheels database search to MkDocs sites.
    
    Usage in mkdocs.yml:
        plugins:
          - mobilewheelsdb:
              database_url: "https://example.com/database"  # Optional: custom database location
              page_path: "package-search"  # Optional: custom page path
              page_title: "Package Search"  # Optional: custom page title
              wasm_release: "latest"  # Optional: GitHub release tag (default: latest)
    """
    
    config_scheme = (
        ('database_url', config_options.Type(str, default=None)),
        ('page_path', config_options.Type(str, default=None)),
        ('page_title', config_options.Type(str, default='Python Package Compatibility Search')),
        ('include_in_nav', config_options.Type(bool, default=True)),
        ('wasm_release', config_options.Type(str, default='latest')),
    )
    
    def on_config(self, config):
        """
        Add the search page to the MkDocs configuration.
        """
        # Get plugin directory
        plugin_dir = Path(__file__).parent
        assets_dir = plugin_dir / 'assets'
        
        # Store paths for later use
        self.plugin_dir = plugin_dir
        self.assets_dir = assets_dir
        
        return config
    
    def on_files(self, files, config):
        """
        Copy plugin assets to the site directory.
        """
        # Create docs/assets directory if it doesn't exist
        docs_dir = Path(config['docs_dir'])
        target_assets = docs_dir / 'mobilewheels_assets'
        target_assets.mkdir(exist_ok=True)
        
        # Copy all assets from plugin to docs
        if self.assets_dir.exists():
            for item in self.assets_dir.iterdir():
                if item.is_file():
                    shutil.copy2(item, target_assets / item.name)
        
        return files
    
    def on_page_content(self, html, page, config, files):
        """
        Inject the search scripts if this is the package search page.
        """
        page_path = self.config.get('page_path')
        
        # Only inject if page_path is configured and matches current page
        if page_path and page.file.src_path == f"{page_path}.md":
            # Get the base URL from config (handles sites with base paths like /Py-Swift/)
            base_url = config.get('site_url', '').rstrip('/')
            if base_url:
                # Extract just the path component if it's a full URL
                from urllib.parse import urlparse
                parsed = urlparse(base_url)
                base_path = parsed.path.rstrip('/')
            else:
                base_path = ''
            
            # Get database URL (use plugin config or construct from base path)
            if self.config.get('database_url'):
                db_url = self.config.get('database_url')
            else:
                db_url = f'{base_path}/mobilewheels_assets' if base_path else '/mobilewheels_assets'
            
            # Inject script configuration and loader
            injection = f'''
<script>
  window.MOBILEWHEELS_DB_URL = '{db_url}';
</script>
<script src="{db_url}/package-search.js"></script>
'''
            
            # Append to existing HTML instead of replacing
            return html + injection
        
        return html
    
    def on_post_build(self, config):
        """
        Copy assets to the final site directory and download WASM from GitHub releases.
        """
        site_dir = Path(config['site_dir'])
        target_assets = site_dir / 'mobilewheels_assets'
        target_assets.mkdir(exist_ok=True)
        
        # Copy all assets except WASM (databases and JS)
        if self.assets_dir.exists():
            for item in self.assets_dir.iterdir():
                if item.is_file() and not item.name.endswith('.wasm'):
                    target_file = target_assets / item.name
                    shutil.copy2(item, target_file)
        
        # Download WASM from GitHub releases
        wasm_path = target_assets / 'MobileWheelsDatabase.wasm'
        if not wasm_path.exists():
            release_tag = self.config.get('wasm_release', 'latest')
            wasm_url = f'https://github.com/Py-Swift/MobileWheelsDatabase/releases/{release_tag}/download/MobileWheelsDatabase.wasm'
            
            print(f'Downloading WASM from GitHub release ({release_tag})...')
            try:
                urllib.request.urlretrieve(wasm_url, wasm_path)
                print(f'✓ WASM downloaded successfully ({wasm_path.stat().st_size / 1024 / 1024:.1f} MB)')
            except Exception as e:
                print(f'Warning: Failed to download WASM from release: {e}')
                print('Checking for bundled WASM...')
                
                # Fallback: check if WASM is bundled in assets
                bundled_wasm = self.assets_dir / 'MobileWheelsDatabase.wasm'
                if bundled_wasm.exists():
                    shutil.copy2(bundled_wasm, wasm_path)
                    print('✓ Using bundled WASM')
                else:
                    print('ERROR: No WASM file available. Please build or download manually.')
        
        return None
