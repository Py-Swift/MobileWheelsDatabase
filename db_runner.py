#!/usr/bin/env python3
"""Build and serve MobileWheelsDatabase with MkDocs"""

import os
import subprocess
import sys
from pathlib import Path


def main():
    # Get the project root directory (where this script is located)
    project_root = Path(__file__).parent
    os.chdir(project_root)
    
    # Check if we should skip build (if WASM already exists)
    wasm_dest = project_root / 'MobileWheelsDatabaseWasm.wasm'
    skip_build = '--skip-build' in sys.argv or os.environ.get('SKIP_BUILD') == '1'
    
    if not skip_build:
        print("🔨 Building Swift WASM...")
    
    # Set up environment for Swift WASM
    env = os.environ.copy()
    env['TOOLCHAINS'] = 'swift-wasm-6.2.1-RELEASE'
    
    # Build Swift WASM
    build_cmd = [
        'swift', 'build',
        '--swift-sdk', 'swift-6.2.1-RELEASE_wasm',
        '--product', 'MobileWheelsDatabaseWasm',
        '-c', 'release',
        '-Xswiftc', '-Xclang-linker',
        '-Xswiftc', '-mexec-model=reactor'
    ]
    
    try:
        subprocess.run(build_cmd, env=env, check=True)
        
        print("📦 Copying WASM binary...")
        
        # Copy WASM binary
        wasm_src = project_root / '.build' / 'wasm32-unknown-wasip1' / 'release' / 'MobileWheelsDatabaseWasm.wasm'
        wasm_dest = project_root / 'MobileWheelsDatabaseWasm.wasm'
        wasm_docs = project_root / 'docs' / 'assets' / 'MobileWheelsDatabase.wasm'
        
        if wasm_src.exists():
            import shutil
            shutil.copy(wasm_src, wasm_dest)
            
            # Copy to docs directory
            wasm_docs.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy(wasm_src, wasm_docs)
            
            size = wasm_dest.stat().st_size / (1024 * 1024)
            print(f"✅ WASM built: {size:.2f} MB")
            print(f"✅ Files copied to docs/assets/")
        else:
            print("❌ WASM binary not found!", file=sys.stderr)
            sys.exit(1)
        
        print()
        print("🎉 Build complete!")
    except subprocess.CalledProcessError as e:
        print(f"❌ Build failed: {e}", file=sys.stderr)
        sys.exit(1)
    else:
        print("⏭️  Skipping build (use without --skip-build to rebuild)")
        if wasm_dest.exists():
            # Still copy to docs if needed
            import shutil
            wasm_docs = project_root / 'docs' / 'assets' / 'MobileWheelsDatabase.wasm'
            wasm_docs.parent.mkdir(parents=True, exist_ok=True)
            if not wasm_docs.exists() or wasm_dest.stat().st_mtime > wasm_docs.stat().st_mtime:
                shutil.copy(wasm_dest, wasm_docs)
                print("✅ Copied existing WASM to docs/assets/")
    
    print()
    print("Running: mkdocs serve")
    
    # Run MkDocs
    try:
        subprocess.run(['mkdocs', 'serve', '-a', '0.0.0.0:8000'], check=True)
    except KeyboardInterrupt:
        print("\n👋 Shutting down...")
    except subprocess.CalledProcessError as e:
        print(f"❌ MkDocs failed: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
