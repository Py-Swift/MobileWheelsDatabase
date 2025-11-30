# Package Database Search

Search through 714,850+ Python packages to check iOS and Android mobile platform support.
---

<!-- Load Swift WASM Runtime -->
<script>
  console.log('🧪 Script tag executed');
  window.scriptTagWorks = true;
</script>

<script type="module">
  console.log('🧪 Module script executed');
  window.moduleScriptWorks = true;
  
  (async () => {
    try {
      // Show progress bar
      const progressBar = document.getElementById('loading-progress');
      const progressFill = document.getElementById('progress-fill');
      const progressText = document.getElementById('progress-text');
      const resultsContainer = document.getElementById('results-container');
      
      progressBar.style.display = 'block';
      resultsContainer.style.display = 'none';
      
      function updateProgress(percent, text) {
        progressFill.style.width = percent + '%';
        progressText.textContent = text;
      }
      
      console.log('🚀 Starting Swift WASM load...');
      console.log('📍 Current page:', window.location.href);
      
      updateProgress(10, 'Fetching WASM module...');
      console.log('🚀 Loading Swift WASM module...');
      
      const wasmPath = '/Py-Swift/assets/MobileWheelsDatabase.wasm';
      console.log('📦 Fetching WASM from:', wasmPath);
      const wasmResponse = await fetch(wasmPath);
      
      if (!wasmResponse.ok) {
        throw new Error(`Failed to fetch WASM: ${wasmResponse.status}`);
      }
      
      updateProgress(20, 'WASM fetched, loading...');
      console.log('✅ WASM fetched successfully');
      const wasmBytes = await wasmResponse.arrayBuffer();
      console.log(`📊 WASM size: ${(wasmBytes.byteLength / 1024 / 1024).toFixed(2)} MB`);
      const textDecoder = new TextDecoder('utf-8');
      
      updateProgress(40, 'Instantiating WASM...');
      
      // Set up memory reference
      let wasmMemory = null;
      
      // Complete wasi_snapshot_preview1 module
      const wasi = {
        fd_write: () => 0,
        fd_close: () => 0,
        fd_seek: () => 0,
        fd_read: () => 0,
        fd_fdstat_get: () => 0,
        fd_fdstat_set_flags: () => 0,
        fd_filestat_get: () => 0,
        fd_filestat_set_size: () => 0,
        fd_filestat_set_times: () => 0,
        fd_pread: () => 0,
        fd_pwrite: () => 0,
        fd_readdir: () => 0,
        fd_sync: () => 0,
        fd_tell: () => 0,
        fd_advise: () => 0,
        fd_allocate: () => 0,
        fd_datasync: () => 0,
        fd_prestat_get: () => 0,
        fd_prestat_dir_name: () => 0,
        path_open: () => 0,
        path_create_directory: () => 0,
        path_filestat_get: () => 0,
        path_filestat_set_times: () => 0,
        path_link: () => 0,
        path_readlink: () => 0,
        path_remove_directory: () => 0,
        path_rename: () => 0,
        path_symlink: () => 0,
        path_unlink_file: () => 0,
        environ_get: () => 0,
        environ_sizes_get: () => 0,
        args_get: () => 0,
        args_sizes_get: () => 0,
        clock_res_get: () => 0,
        clock_time_get: () => 0,
        poll_oneoff: () => 0,
        proc_exit: (code) => {},
        proc_raise: () => 0,
        sched_yield: () => 0,
        random_get: (buf, buf_len) => 0,
        sock_recv: () => 0,
        sock_send: () => 0,
        sock_shutdown: () => 0
      };
      
      // Instantiate WASM with required import modules (no JavaScriptKit needed)
      const { instance } = await WebAssembly.instantiate(wasmBytes, {
        wasi_snapshot_preview1: wasi,
        env: {
          // Swift calls this to log to console
          consoleLog: (messagePtr, messageLen) => {
            if (!wasmMemory) return;
            const memory = new Uint8Array(wasmMemory.buffer);
            const messageBytes = memory.subarray(messagePtr, messagePtr + messageLen);
            const message = textDecoder.decode(messageBytes);
            console.log('[Swift]', message);
          }
        }
      });
      wasmMemory = instance.exports.memory;
      window.wasmInstance = instance; // Store globally for search function
      
      updateProgress(60, 'Initializing Swift runtime...');
      console.log('✅ WASM instantiated');
      console.log('📋 Instance exports:', Object.keys(instance.exports));
      
      // Must call _initialize first for reactor mode
      if (instance.exports._initialize) {
        console.log('🔧 Calling _initialize()...');
        instance.exports._initialize();
        console.log('✅ _initialize() completed');
      }
      
      // Test swiftTest function
      const testResult = instance.exports.swiftTest();
      console.log('🧪 swiftTest() returned:', testResult);
      
      updateProgress(70, 'Loading index database...');
      
      // Load index database directly (no sql.js needed - Swift has native SQLite)
      console.log('📥 Loading index database for Swift...');
      const dbBaseUrl = '../mobile-wheels-sql/';
      const dbUrl = dbBaseUrl + 'index.sqlite';
      const indexBuffer = await fetch(dbUrl).then(r => r.arrayBuffer());
      const dbBytes = new Uint8Array(indexBuffer);
      console.log(`📦 Index database size: ${(dbBytes.byteLength / 1024 / 1024).toFixed(2)} MB`);
      
      updateProgress(80, 'Preparing database memory...');
      
      // We'll load data chunks on-demand when needed
      const loadedChunks = new Set(); // Track which chunks Swift has loaded
      const cachedChunks = new Map(); // Cache chunk bytes in JavaScript to avoid refetching
      const dbMemoryOffset = 100 * 1024 * 1024;  // 100MB offset for safety
      const memory = new Uint8Array(instance.exports.memory.buffer);
      
      // Allocate enough memory for index + all potential chunks (350MB total to be safe)
      // Index: 50MB, Chunks: ~110MB, Output buffer: 10MB at 300MB = 360MB needed
      const totalMemoryNeeded = 400 * 1024 * 1024; // 400MB to be safe
      if (memory.length < totalMemoryNeeded) {
        console.log(`📈 Growing WASM memory from ${memory.length} to ${totalMemoryNeeded}`);
        const pagesNeeded = Math.ceil((totalMemoryNeeded - memory.length) / 65536);
        instance.exports.memory.grow(pagesNeeded);
      }
      
      // Copy index database to WASM memory
      let currentOffset = dbMemoryOffset;
      const updatedMemory = new Uint8Array(instance.exports.memory.buffer);
      updatedMemory.set(dbBytes, currentOffset);
      console.log(`✅ Index database copied to offset ${currentOffset}`);
      const indexDbOffset = currentOffset;
      const indexDbSize = dbBytes.length;
      currentOffset += dbBytes.length;
      
      // Track where chunks will be loaded
      let nextChunkOffset = currentOffset;
      
      // Call swiftInit with just the index database
      console.log(`🔧 Calling swiftInit(${indexDbOffset}, ${indexDbSize})...`);
      let swiftInitialized = false;
      
      updateProgress(90, 'Initializing database...');
      
      try {
        if (typeof instance.exports.swiftInit === 'function') {
          const initResult = instance.exports.swiftInit(indexDbOffset, indexDbSize);
          console.log(`✅ swiftInit() returned: ${initResult}`);
          if (initResult === 0) {
            console.error('❌ swiftInit() failed - returned 0');
            throw new Error('Swift initialization failed');
          }
          swiftInitialized = true;
        } else {
          throw new Error('swiftInit function not found');
        }
      } catch (e) {
        console.error('❌ swiftInit() crashed:', e);
        throw e;
      }
      
      // Function to load a specific chunk on-demand (with JavaScript-side caching)
      async function loadChunk(chunkNum) {
        try {
          let chunkBytes;
          
          // Check if we have this chunk cached in JavaScript
          if (cachedChunks.has(chunkNum)) {
            console.log(`📦 Using cached chunk ${chunkNum} from JavaScript memory`);
            chunkBytes = cachedChunks.get(chunkNum);
          } else {
            // Fetch from network and cache
            const chunkUrl = dbBaseUrl + `data-${chunkNum}.sqlite`;
            console.log(`📥 Loading chunk ${chunkNum} on-demand...`);
            const chunkBuffer = await fetch(chunkUrl).then(r => r.arrayBuffer());
            chunkBytes = new Uint8Array(chunkBuffer);
            console.log(`📦 Loaded data-${chunkNum}.sqlite: ${(chunkBuffer.byteLength / 1024 / 1024).toFixed(2)} MB`);
            
            // Cache for future reuse
            cachedChunks.set(chunkNum, chunkBytes);
            console.log(`💾 Cached chunk ${chunkNum} in JavaScript memory`);
          }
          
          // Always copy to WASM memory and attach (Swift only keeps one at a time)
          const memory = new Uint8Array(instance.exports.memory.buffer);
          memory.set(chunkBytes, nextChunkOffset);
          
          // Attach chunk in Swift (replaces previous chunk)
          if (typeof instance.exports.swiftAttachChunk === 'function') {
            const attachResult = instance.exports.swiftAttachChunk(chunkNum, nextChunkOffset, chunkBytes.length);
            console.log(`✅ Attached data-${chunkNum}.sqlite: ${attachResult}`);
            if (attachResult === 1) {
              loadedChunks.add(chunkNum); // Track for statistics
              return true;
            }
          }
          return false;
        } catch (error) {
          console.error(`❌ Failed to load chunk ${chunkNum}:`, error);
          return false;
        }
      }
      
      // Create SwiftSearch API that calls Swift WASM
      window.SwiftSearch = {
        search: async (query) => {
          console.log('🔍 SwiftSearch.search called with:', query);
          
          if (!swiftInitialized) {
            console.error('❌ Swift not initialized, cannot search');
            return [];
          }
            
            try {
              if (!instance.exports.swiftSearch) {
                console.error('❌ swiftSearch export not found');
                return [];
              }
              
              console.log('📝 Encoding query to UTF-8...');
              // Allocate memory for query
              const queryBytes = new TextEncoder().encode(query);
              console.log(`📝 Query bytes: [${Array.from(queryBytes).join(', ')}]`);
              console.log(`📝 Query bytes length: ${queryBytes.length}`);
              
              const queryMemory = new Uint8Array(instance.exports.memory.buffer);
              queryMemory.set(queryBytes, 0);  // Write at offset 0
              
              // Verify the write
              const verifyBytes = queryMemory.slice(0, queryBytes.length);
              console.log(`📝 Verification read: [${Array.from(verifyBytes).join(', ')}]`);
              console.log('📝 Query written to memory at offset 0');
              
              // Output buffer setup
              const outputOffset = 314572800;  // 300MB - after all databases
              const outputSize = 10 * 1024 * 1024;  // 10MB
              
              console.log(`📞 Starting incremental search...`);
              
              // Call Swift repeatedly until all chunks loaded
              let bytesWritten;
              let maxRetries = 20; // Prevent infinite loop
              
              while (maxRetries-- > 0) {
                try {
                  bytesWritten = instance.exports.swiftSearch(
                    0,                  // queryPtr
                    queryBytes.length,  // queryLen
                    outputOffset,       // outputPtr
                    outputSize          // outputLen
                  );
                  console.log(`📞 swiftSearch returned: ${bytesWritten} bytes`);
                } catch (swiftError) {
                  console.error('❌ Swift function threw error:', swiftError);
                  console.error('Stack:', swiftError.stack);
                  return [];
                }
                
                if (bytesWritten <= 0) {
                  console.log('📊 No results from Swift (0 bytes)');
                  return [];
                }
                
                // Read response
                const outputMemory = new Uint8Array(instance.exports.memory.buffer);
                const responseBytes = outputMemory.slice(outputOffset, outputOffset + bytesWritten);
                const responseString = new TextDecoder().decode(responseBytes);
                
                // Check if it's a chunk request (format: "-1,2,3" or "-5")
                if (responseString.startsWith('-')) {
                  const chunkList = responseString.substring(1).split(',').map(n => parseInt(n.trim()));
                  console.log(`🔄 Swift requests ${chunkList.length} chunks: [${chunkList.join(', ')}], currently loaded: [${Array.from(loadedChunks).join(', ')}]`);
                  
                  // Load all requested chunks
                  for (const chunkNum of chunkList) {
                    console.log(`📥 Loading chunk ${chunkNum}...`);
                    const loaded = await loadChunk(chunkNum);
                    if (!loaded) {
                      console.error(`❌ Failed to load chunk ${chunkNum}`);
                      return [];
                    }
                    console.log(`✅ Chunk ${chunkNum} loaded and stored in SQLChunks`);
                  }
                  
                  // Retry search with all chunks now loaded
                  continue;
                }
                
                // Got actual results - break loop
                break;
              }
              
              console.log(`📖 Reading ${bytesWritten} bytes of results...`);
              const outputMemory = new Uint8Array(instance.exports.memory.buffer);
              const jsonBytes = outputMemory.slice(outputOffset, outputOffset + bytesWritten);
              const jsonString = new TextDecoder().decode(jsonBytes);
              console.log('📖 JSON string:', jsonString.substring(0, 200) + '...');
              
              const results = JSON.parse(jsonString);
              
              console.log(`✅ Swift returned ${results.length} results`);
              return results;
            } catch (e) {
              console.error('❌ Swift search failed:', e);
              console.error('Stack:', e.stack);
              return [];
            }
          }
        };
        
        console.log('✅ SwiftSearch API created');
        
        updateProgress(100, 'Ready!');
        
        // Hide progress bar and show results container
        setTimeout(() => {
          progressBar.style.display = 'none';
          resultsContainer.style.display = 'block';
        }, 500);
        
        // Set global flag that Swift is ready
        window.swiftWasmReady = true;
        window.dispatchEvent(new Event('swiftWasmLoaded'));
      } catch (error) {
        console.error('❌ Failed to load Swift WASM:', error);
        console.error('Stack:', error.stack);
        window.swiftWasmReady = false;
      }
    })();
</script>

<noscript>
  <div style="padding: 20px; background: #fff3cd; color: #856404; border-radius: 8px; margin: 20px 0;">
    <strong>⚠️ JavaScript Required:</strong> This search feature requires JavaScript to be enabled.
  </div>
</noscript>

<div class="tabs">
  <input type="radio" id="tab-search" name="tabs" checked>
  <label for="tab-search">Package Search</label>
  
  <input type="radio" id="tab-requirements" name="tabs">
  <label for="tab-requirements">Requirements Analysis</label>
  
  <div class="tab-content" id="content-search">
    <div class="search-container">
      <input 
        type="text" 
        id="package-search" 
        placeholder="Search package name (e.g., numpy, pandas, requests)..."
        autocomplete="off"
      />
      <div class="filter-options">
        <label>
          <input type="checkbox" id="filter-ios" checked> iOS Support
        </label>
        <label>
          <input type="checkbox" id="filter-android" checked> Android Support
        </label>
        <label>
          <input type="checkbox" id="filter-pure" checked> Pure Python
        </label>
        <label>
          <input type="checkbox" id="filter-binary" checked> Binary Only
        </label>
      </div>
    </div>

    <div id="search-stats" class="stats-bar">
      <span id="total-results">Loading database...</span>
      <span id="search-time"></span>
    </div>

    <div id="loading-progress" style="display: none;">
      <div class="progress-container">
        <div class="progress-bar">
          <div class="progress-fill" id="progress-fill"></div>
        </div>
        <div class="progress-text" id="progress-text">Loading...</div>
      </div>
    </div>

    <div id="results-container">
      <div class="instructions">
        <h3>🔍 How to use</h3>
        <ul>
          <li><strong>Type to search:</strong> Enter a package name (partial matches work)</li>
          <li><strong>Filter results:</strong> Use checkboxes to filter by platform support</li>
          <li><strong>View details:</strong> Click on a package to see version and source info</li>
        </ul>
        <p class="tip">💡 <strong>Tip:</strong> Search is case-insensitive and searches across all 702,223 packages in real-time.</p>
      </div>
    </div>
  </div>
  
  <div class="tab-content" id="content-requirements">
    <div class="requirements-container">
      <div class="upload-section">
        <h3>📋 Upload requirements.txt</h3>
        
        <div class="filter-options" style="margin-bottom: 20px;">
          <label>
            <input type="checkbox" id="req-filter-ios" checked> Show iOS compatibility
          </label>
          <label>
            <input type="checkbox" id="req-filter-android"> Show Android compatibility
          </label>
        </div>
        
        <div class="upload-area" id="upload-area">
          <input type="file" id="file-input" accept=".txt" style="display: none;">
          <label for="file-input" class="upload-label">
            <span class="upload-icon">📁</span>
            <span class="upload-text">Click to upload or drag & drop requirements.txt</span>
          </label>
        </div>
        <div class="or-divider">— OR —</div>
        <textarea 
          id="requirements-text" 
          placeholder="Paste your requirements here (one per line)&#10;numpy>=1.20.0&#10;pandas&#10;requests==2.28.0&#10;flask~=2.0.0"
          rows="10"
        ></textarea>
        <button id="analyze-btn" class="analyze-button">🔍 Analyze Requirements</button>
      </div>

      <div id="requirements-stats" class="stats-bar" style="display: none;">
        <span id="req-total">Total: 0</span>
        <span id="req-ios">iOS: 0</span>
        <span id="req-android">Android: 0</span>
        <span id="req-pure">Pure Python: 0</span>
        <span id="req-missing">Not Available: 0</span>
      </div>

      <div id="requirements-results"></div>
    </div>
  </div>
</div>

<style>
/* Tab Styles */
.tabs {
  margin: 20px 0;
}

.tabs input[type="radio"] {
  display: none;
}

.tabs label {
  display: inline-block;
  padding: 12px 24px;
  background: var(--md-code-bg-color);
  border: 2px solid var(--md-primary-fg-color);
  border-bottom: none;
  cursor: pointer;
  font-weight: 600;
  transition: all 0.3s;
  margin-right: 4px;
  border-radius: 8px 8px 0 0;
}

.tabs label:hover {
  background: var(--md-primary-fg-color--light);
}

.tabs input[type="radio"]:checked + label {
  background: var(--md-primary-fg-color);
  color: white;
}

.tab-content {
  display: none;
  padding: 20px;
  border: 2px solid var(--md-primary-fg-color);
  border-radius: 0 8px 8px 8px;
  background: var(--md-default-bg-color);
}

#tab-search:checked ~ #content-search {
  display: block;
}

#tab-requirements:checked ~ #content-requirements {
  display: block;
}

/* Requirements Tab Styles */
.requirements-container {
  max-width: 1200px;
  margin: 0 auto;
}

.upload-section {
  background: var(--md-code-bg-color);
  padding: 30px;
  border-radius: 8px;
  margin-bottom: 20px;
}

.upload-section h3 {
  margin-top: 0;
  color: var(--md-primary-fg-color);
}

.upload-area {
  border: 3px dashed var(--md-primary-fg-color);
  border-radius: 8px;
  padding: 40px;
  text-align: center;
  background: var(--md-default-bg-color);
  transition: all 0.3s;
  cursor: pointer;
}

.upload-area:hover,
.upload-area.dragover {
  background: var(--md-primary-fg-color--light);
  border-color: var(--md-accent-fg-color);
}

.upload-label {
  cursor: pointer;
  display: block;
}

.upload-icon {
  font-size: 48px;
  display: block;
  margin-bottom: 10px;
}

.upload-text {
  font-size: 16px;
  color: var(--md-default-fg-color);
}

.or-divider {
  text-align: center;
  margin: 20px 0;
  color: var(--md-default-fg-color--light);
  font-weight: 600;
}

#requirements-text {
  width: 100%;
  padding: 12px;
  border: 2px solid var(--md-primary-fg-color);
  border-radius: 6px;
  font-family: var(--md-code-font-family);
  font-size: 14px;
  background: var(--md-default-bg-color);
  color: var(--md-default-fg-color);
  resize: vertical;
}

.analyze-button {
  width: 100%;
  padding: 14px;
  background: var(--md-primary-fg-color);
  color: white;
  border: none;
  border-radius: 6px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  margin-top: 15px;
  transition: all 0.3s;
}

.analyze-button:hover {
  background: var(--md-accent-fg-color);
  transform: translateY(-2px);
  box-shadow: 0 4px 8px rgba(0,0,0,0.2);
}

.analyze-button:active {
  transform: translateY(0);
}

.requirements-table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 20px;
  background: var(--md-default-bg-color);
  border-radius: 8px;
  overflow: hidden;
}

.requirements-table th {
  background: var(--md-primary-fg-color);
  color: white;
  padding: 12px;
  text-align: left;
  font-weight: 600;
}

.requirements-table td {
  padding: 12px;
  border-bottom: 1px solid var(--md-default-fg-color--lightest);
}

.requirements-table tr:hover {
  background: var(--md-code-bg-color);
}

.requirements-table tr:last-child td {
  border-bottom: none;
}

.req-status {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

.version-spec {
  font-family: var(--md-code-font-family);
  color: var(--md-default-fg-color--light);
  font-size: 12px;
}

/* Compatibility Warning Styles */
.compatibility-warning {
  padding: 20px;
  border-radius: 8px;
  margin-bottom: 20px;
  font-size: 16px;
  line-height: 1.6;
  border-left: 5px solid;
}

.compatibility-warning.success {
  background: #d4edda;
  color: #155724;
  border-color: #28a745;
}

.compatibility-warning.warning {
  background: #fff3cd;
  color: #856404;
  border-color: #ffc107;
}

.compatibility-warning.critical {
  background: #f8d7da;
  color: #721c24;
  border-color: #dc3545;
}

.compatibility-warning strong {
  display: block;
  margin-bottom: 5px;
  font-size: 18px;
}

/* Original Search Styles */
.search-container {
  margin: 20px 0;
  background: var(--md-default-bg-color);
  padding: 20px;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

#package-search {
  width: 100%;
  padding: 12px 16px;
  font-size: 16px;
  border: 2px solid var(--md-primary-fg-color);
  border-radius: 6px;
  outline: none;
  transition: border-color 0.3s;
  background: var(--md-code-bg-color);
  color: var(--md-default-fg-color);
}

#package-search:focus {
  border-color: var(--md-accent-fg-color);
}

.filter-options {
  display: flex;
  gap: 20px;
  margin-top: 15px;
  flex-wrap: wrap;
}

.filter-options label {
  display: flex;
  align-items: center;
  gap: 6px;
  cursor: pointer;
  font-size: 14px;
}

.filter-options input[type="checkbox"] {
  cursor: pointer;
  width: 18px;
  height: 18px;
}

.stats-bar {
  display: flex;
  justify-content: space-between;
  padding: 12px 16px;
  background: var(--md-code-bg-color);
  border-radius: 6px;
  margin: 10px 0;
  font-size: 14px;
  color: var(--md-default-fg-color--light);
}

#results-container {
  margin-top: 20px;
}

.instructions {
  background: var(--md-code-bg-color);
  padding: 20px;
  border-radius: 8px;
  border-left: 4px solid var(--md-primary-fg-color);
}

.instructions h3 {
  margin-top: 0;
  color: var(--md-primary-fg-color);
}

.instructions ul {
  margin: 10px 0;
}

.instructions li {
  margin: 8px 0;
}

.tip {
  margin-top: 15px;
  padding: 10px;
  background: var(--md-default-bg-color);
  border-radius: 4px;
}

.results-table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 10px;
  background: var(--md-default-bg-color);
  border-radius: 8px;
  overflow: hidden;
}

.results-table th {
  background: var(--md-primary-fg-color);
  color: white;
  padding: 12px;
  text-align: left;
  font-weight: 600;
}

.results-table td {
  padding: 12px;
  border-bottom: 1px solid var(--md-default-fg-color--lightest);
}

.results-table tr:hover {
  background: var(--md-code-bg-color);
}

.results-table tr:last-child td {
  border-bottom: none;
}

.status-badge {
  display: inline-block;
  padding: 4px 10px;
  border-radius: 4px;
  font-size: 12px;
  font-weight: 600;
  white-space: nowrap;
}

.status-supported {
  background: #4caf50;
  color: white;
}

.status-not-available {
  background: #ff9800;
  color: white;
}

.status-pure-python {
  background: #2196f3;
  color: white;
}

.package-name {
  font-family: var(--md-code-font-family);
  font-weight: 600;
}

.package-name a {
  color: var(--md-primary-fg-color);
  text-decoration: none;
  transition: color 0.3s;
}

.package-name a:hover {
  color: var(--md-accent-fg-color);
  text-decoration: underline;
}

.package-details {
  font-size: 12px;
  color: var(--md-default-fg-color--light);
  margin-top: 4px;
}

.loading {
  text-align: center;
  padding: 40px;
  color: var(--md-default-fg-color--light);
}

.no-results {
  text-align: center;
  padding: 40px;
  color: var(--md-default-fg-color--light);
  font-size: 16px;
}

.pagination {
  display: flex;
  justify-content: center;
  gap: 10px;
  margin: 20px 0;
  flex-wrap: wrap;
}

.pagination button {
  padding: 8px 16px;
  border: 1px solid var(--md-primary-fg-color);
  background: var(--md-default-bg-color);
  color: var(--md-primary-fg-color);
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.3s;
}

.pagination button:hover:not(:disabled) {
  background: var(--md-primary-fg-color);
  color: white;
}

.pagination button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.pagination button.active {
  background: var(--md-primary-fg-color);
  color: white;
}

/* Progress Bar Styles */
.progress-container {
  padding: 20px;
  background: var(--md-code-bg-color);
  border-radius: 8px;
  margin: 20px 0;
}

.progress-bar {
  width: 100%;
  height: 30px;
  background: var(--md-default-bg-color);
  border-radius: 15px;
  overflow: hidden;
  box-shadow: inset 0 2px 4px rgba(0,0,0,0.1);
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, var(--md-primary-fg-color), var(--md-accent-fg-color));
  border-radius: 15px;
  transition: width 0.3s ease;
  width: 0%;
}

.progress-text {
  text-align: center;
  margin-top: 10px;
  color: var(--md-default-fg-color);
  font-size: 14px;
}
</style>

<script>
(function() {
  const DB_BASE_URL = '../mobile-wheels-sql/';
  const RESULTS_PER_PAGE = 50;
  
  let SQL = null; // sql.js instance for data chunks only
  let indexDB = null; // Deprecated - Swift handles index
  let dataDBs = {}; // Cache for loaded data chunks
  let totalPackages = 714850;
  let currentResults = [];
  let currentPage = 1;
  
  // Initialize database connection (Swift WASM handles index, sql.js for data chunks)
  async function initDatabase() {
    try {
      // Wait for Swift WASM to load
      if (!window.swiftWasmReady) {
        console.log('⏳ Waiting for Swift WASM to load...');
        await new Promise(resolve => {
          if (window.swiftWasmReady) {
            resolve();
          } else {
            window.addEventListener('swiftWasmLoaded', resolve, { once: true });
          }
        });
      }
      
      console.log('Starting database initialization...');
      console.log('🦅 Swift WASM backend:', window.SwiftSearch ? 'loaded' : 'unavailable');
      
      if (!window.SwiftSearch) {
        throw new Error('Swift WASM not available');
      }
      
      // Swift has already loaded the index database during WASM initialization
      console.log('✅ Swift WASM ready with native SQLite for all databases');
      
      document.getElementById('total-results').textContent = `Ready to search ${totalPackages.toLocaleString()} packages`;
      console.log('Database initialization complete!');
    } catch (error) {
      console.error('FATAL ERROR during database initialization:', error);
      console.error('Error stack:', error.stack);
      showError('Failed to load package database: ' + error.message);
      document.getElementById('total-results').textContent = 'Database failed to load';
    }
  }
  
  // Load a specific data chunk
  async function loadDataChunk(chunkNum) {
    if (dataDBs[chunkNum]) {
      return dataDBs[chunkNum];
    }
    
    try {
      const buffer = await fetch(DB_BASE_URL + `data-${chunkNum}.sqlite`).then(r => r.arrayBuffer());
      dataDBs[chunkNum] = new SQL.Database(new Uint8Array(buffer));
      console.log(`Loaded data chunk ${chunkNum}`);
      return dataDBs[chunkNum];
    } catch (error) {
      console.error(`Error loading chunk ${chunkNum}:`, error);
      return null;
    }
  }
  
  // Get filter state
  function getFilters() {
    return {
      ios: document.getElementById('filter-ios').checked,
      android: document.getElementById('filter-android').checked,
      pure: document.getElementById('filter-pure').checked,
      binary: document.getElementById('filter-binary').checked
    };
  }
  
  // Map database support codes to our format
  function mapSupportStatus(supportCode) {
    // 1=Binary, 2=Pure Python, 3=Both
    if (supportCode === 1) return 'supported'; // Binary support
    if (supportCode === 2) return 'pure_python'; // Pure Python
    if (supportCode === 3) return 'supported'; // Both (treat as supported)
    return 'not_available';
  }
  
  // Map source integer to text
  function mapSource(sourceCode) {
    const sources = {
      0: 'PyPI',
      1: 'PySwift',
      2: 'KivySchool'
    };
    return sources[sourceCode] || 'Unknown';
  }
  
  // Map category integer to our format
  function mapCategory(categoryCode, androidSupport, iosSupport) {
    // If pure python support, always return pure_python
    if (androidSupport === 2 || iosSupport === 2) return 'pure_python';
    
    // Category codes (based on typical patterns)
    const categories = {
      0: 'binary_without_mobile',
      1: 'official_binary',
      2: 'pyswift_binary',
      3: 'pure_python'
    };
    return categories[categoryCode] || 'binary_without_mobile';
  }
  
  // Search packages using Swift WASM with native SQLite
  async function searchPackages(query) {
    if (!query || query.length < 2) {
      return [];
    }
    
    // Wait for SwiftSearch if not ready yet
    if (!window.SwiftSearch) {
      console.log('⏳ Waiting for SwiftSearch to load...');
      await new Promise(resolve => {
        if (window.SwiftSearch) {
          resolve();
        } else {
          window.addEventListener('swiftWasmLoaded', resolve, { once: true });
          // Timeout after 5 seconds
          setTimeout(resolve, 5000);
        }
      });
    }
    
    // Check if SwiftSearch is available
    if (!window.SwiftSearch || !window.SwiftSearch.search) {
      console.error('SwiftSearch not available after waiting');
      return [];
    }
    
    const startTime = performance.now();
    const searchTerm = query.toLowerCase().trim();
    
    // Call Swift WASM - it queries SQL and returns enhanced JSON results
    console.log('🔍 Calling Swift to search SQL for:', searchTerm);
    const swiftResults = await window.SwiftSearch.search(searchTerm);
    
    // Swift returns results - just SQL query results with enum conversions
    // Convert to display format
    const results = swiftResults.map(pkg => ({
      name: pkg.name,
      ios: pkg.ios,
      android: pkg.android,
      iosVersion: pkg.ios_version || '',
      androidVersion: pkg.android_version || '',
      category: pkg.category,
      source: pkg.source,
      downloads: pkg.downloads || 0,
      latestVersion: pkg.latest_version || ''
    }));
    
    const endTime = performance.now();
    const searchTime = ((endTime - startTime) / 1000).toFixed(2);
    document.getElementById('search-time').textContent = `Found ${results.length} packages in ${searchTime}s (Swift + SQL)`;
    
    console.log(`📦 Search complete: ${results.length} results from Swift`);
    return results;
  }
  
  // Check if package matches filters
  function matchesFilters(pkg, filters) {
    const hasIOS = pkg.ios === 'supported';
    const hasAndroid = pkg.android === 'supported';
    const isPure = pkg.ios === 'pure_python' || pkg.android === 'pure_python';
    const isBinary = pkg.category === 'official_binary' || pkg.category === 'pyswift_binary';
    
    if (!filters.ios && hasIOS && !isPure) return false;
    if (!filters.android && hasAndroid && !isPure) return false;
    if (!filters.pure && isPure) return false;
    if (!filters.binary && isBinary && !isPure) return false;
    
    return true;
  }
  
  // Format status badge
  function formatStatus(status, version) {
    if (status === 'supported') {
      const versionText = version ? ` (${version})` : '';
      return `<span class="status-badge status-supported">✅ Supported${versionText}</span>`;
    } else if (status === 'pure_python') {
      return `<span class="status-badge status-pure-python">🐍 Pure Python</span>`;
    } else {
      return `<span class="status-badge status-not-available">⚠️ Not available</span>`;
    }
  }
  
  // Get category display name
  function getCategoryName(category, source) {
    // For official_binary, show the actual source
    if (category === 'official_binary') {
      if (source === 'PySwift') return 'PySwift Binary';
      if (source === 'KivySchool') return 'KivySchool Binary';
      return 'Official Binary (PyPI)';
    }
    
    const categories = {
      'pyswift_binary': 'PySwift Binary',
      'pure_python': 'Pure Python',
      'binary_without_mobile': 'Binary (No Mobile)'
    };
    return categories[category] || category;
  }
  
  // Display results
  function displayResults(page = 1) {
    const container = document.getElementById('results-container');
    const totalResults = currentResults.length;
    
    if (totalResults === 0) {
      container.innerHTML = '<div class="no-results">No packages found matching your search criteria.</div>';
      return;
    }
    
    const start = (page - 1) * RESULTS_PER_PAGE;
    const end = Math.min(start + RESULTS_PER_PAGE, totalResults);
    const pageResults = currentResults.slice(start, end);
    
    let html = `
      <table class="results-table">
        <thead>
          <tr>
            <th>Package</th>
            <th>iOS</th>
            <th>Android</th>
            <th>Category</th>
          </tr>
        </thead>
        <tbody>
    `;
    
    for (const pkg of pageResults) {
      html += `
        <tr>
          <td>
            <div class="package-name"><a href="https://pypi.org/project/${pkg.name}/" target="_blank" rel="noopener noreferrer">${pkg.name}</a></div>
            <div class="package-details">Source: ${pkg.source || 'Unknown'}</div>
          </td>
          <td>${formatStatus(pkg.ios, pkg.iosVersion)}</td>
          <td>${formatStatus(pkg.android, pkg.androidVersion)}</td>
          <td>${getCategoryName(pkg.category, pkg.source)}</td>
        </tr>
      `;
    }
    
    html += '</tbody></table>';
    
    // Add pagination
    const totalPages = Math.ceil(totalResults / RESULTS_PER_PAGE);
    if (totalPages > 1) {
      html += '<div class="pagination">';
      
      if (page > 1) {
        html += `<button onclick="goToPage(${page - 1})">← Previous</button>`;
      }
      
      // Show page numbers (with ellipsis for many pages)
      const pageNumbers = [];
      if (totalPages <= 7) {
        for (let i = 1; i <= totalPages; i++) pageNumbers.push(i);
      } else {
        pageNumbers.push(1);
        if (page > 3) pageNumbers.push('...');
        for (let i = Math.max(2, page - 1); i <= Math.min(totalPages - 1, page + 1); i++) {
          pageNumbers.push(i);
        }
        if (page < totalPages - 2) pageNumbers.push('...');
        pageNumbers.push(totalPages);
      }
      
      for (const num of pageNumbers) {
        if (num === '...') {
          html += '<span>...</span>';
        } else {
          const activeClass = num === page ? 'active' : '';
          html += `<button class="${activeClass}" onclick="goToPage(${num})">${num}</button>`;
        }
      }
      
      if (page < totalPages) {
        html += `<button onclick="goToPage(${page + 1})">Next →</button>`;
      }
      
      html += '</div>';
    }
    
    container.innerHTML = html;
    
    // Update stats
    document.getElementById('total-results').textContent = 
      `Showing ${start + 1}-${end} of ${totalResults} results`;
  }
  
  // Go to page (exposed globally)
  window.goToPage = function(page) {
    currentPage = page;
    displayResults(page);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };
  
  // Handle search
  let searchTimeout;
  async function handleSearch() {
    // Only search if on the search tab
    if (!document.getElementById('tab-search').checked) {
      return;
    }
    
    const query = document.getElementById('package-search').value;
    
    clearTimeout(searchTimeout);
    
    if (query.length < 2) {
      document.getElementById('results-container').innerHTML = `
        <div class="instructions">
          <h3>🔍 How to use</h3>
          <ul>
            <li><strong>Type to search:</strong> Enter a package name (partial matches work)</li>
            <li><strong>Filter results:</strong> Use checkboxes to filter by platform support</li>
            <li><strong>View details:</strong> Click on a package to see version and source info</li>
          </ul>
          <p class="tip">💡 <strong>Tip:</strong> Search is case-insensitive and searches across all 714,850 packages in real-time.</p>
        </div>
      `;
      document.getElementById('total-results').textContent = `Ready to search ${totalPackages.toLocaleString()} packages`;
      document.getElementById('search-time').textContent = '';
      return;
    }
    
    document.getElementById('results-container').innerHTML = 
      '<div class="loading">🔍 Searching through packages...</div>';
    
    searchTimeout = setTimeout(async () => {
      currentResults = await searchPackages(query);
      currentPage = 1;
      displayResults(1);
    }, 1000); // 1 second throttle to avoid loading chunks too frequently
  }
  
  // Show error message
  function showError(message) {
    document.getElementById('results-container').innerHTML = 
      `<div class="no-results">❌ ${message}</div>`;
  }
  
  // Initialize
  async function init() {
    console.log('Init function called');
    document.getElementById('total-results').textContent = 'Loading database...';
    
    await initDatabase();
    
    // Set up event listeners
    document.getElementById('package-search').addEventListener('input', handleSearch);
    
    // Filter checkboxes
    ['filter-ios', 'filter-android', 'filter-pure', 'filter-binary'].forEach(id => {
      document.getElementById(id).addEventListener('change', handleSearch);
    });
    
    // Initialize requirements tab
    setupRequirementsTab();
    
    console.log('Package search initialized');
  }
  
  // Start when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
  
  // === Requirements Analysis Functionality ===
  
  // Parse requirements.txt line
  function parseRequirement(line) {
    line = line.trim();
    if (!line || line.startsWith('#')) return null;
    
    // Check for platform-specific markers
    const platformMarkers = [
      'sys_platform == \'win32\'',
      'sys_platform == "win32"',
      'sys_platform == \'darwin\'',
      'sys_platform == "darwin"',
      'platform_system == \'Windows\'',
      'platform_system == "Windows"',
      'platform_system == \'Darwin\'',
      'platform_system == "Darwin"',
      'os_name == \'nt\'',
      'os_name == "nt"'
    ];
    
    // Skip packages with non-mobile platform markers
    for (const marker of platformMarkers) {
      if (line.includes(marker)) {
        return null; // Skip this package
      }
    }
    
    // Remove mobile platform markers if present (we want these)
    line = line.replace(/;\s*sys_platform\s*==\s*['"]linux['"]/gi, '');
    line = line.replace(/;\s*platform_system\s*==\s*['"]Linux['"]/gi, '');
    line = line.trim();
    
    // Match package name and version specifier
    const match = line.match(/^([a-zA-Z0-9_-]+)(.*?)$/);
    if (!match) return null;
    
    return {
      name: match[1].toLowerCase(),
      version: match[2].trim() || '',
      original: line
    };
  }
  
  // Analyze requirements
  async function analyzeRequirements(requirements) {
    const results = [];
    const startTime = performance.now();
    
    try {
      // Batch lookup all package names at once
      const packageNames = requirements.map(r => r.name);
      const placeholders = packageNames.map(() => '?').join(',');
      const indexQuery = `SELECT name, CAST(hash_id AS TEXT) as hash_id, chunk_file FROM package_index WHERE name IN (${placeholders})`;
      const indexResults = indexDB.exec(indexQuery, packageNames);
      
      // Create a map of package name to index data
      const indexMap = {};
      if (indexResults.length > 0) {
        for (const [name, hashId, chunkFile] of indexResults[0].values) {
          indexMap[name] = { hashId, chunkFile };
        }
      }
      
      // Group by chunk file
      const chunkGroups = {};
      for (const req of requirements) {
        const indexData = indexMap[req.name];
        if (indexData) {
          if (!chunkGroups[indexData.chunkFile]) chunkGroups[indexData.chunkFile] = [];
          chunkGroups[indexData.chunkFile].push({ req, indexData });
        }
      }
      
      // Load chunks and fetch data
      const packageDataMap = {};
      for (const [chunkFile, items] of Object.entries(chunkGroups)) {
        const dataDB = await loadDataChunk(chunkFile);
        if (!dataDB) continue;
        
        const hashIds = items.map(item => item.indexData.hashId);
        const placeholders = hashIds.map(() => '?').join(',');
        const dataQuery = `SELECT CAST(hash_id AS TEXT) as hash_id, downloads, android_support, ios_support, source, category, android_version, ios_version, latest_version FROM package_data WHERE CAST(hash_id AS TEXT) IN (${placeholders})`;
        
        const dataResults = dataDB.exec(dataQuery, hashIds);
        if (dataResults.length === 0) continue;
        
        for (const row of dataResults[0].values) {
          // Correct column positions: hash_id(0), downloads(1), android_support(2), ios_support(3), source(4), category(5), android_version(6), ios_version(7), latest_version(8)
          const [hashId, downloads, androidSupport, iosSupport, sourceCode, categoryCode, androidVersion, iosVersion, latestVersion] = row;
          
          // Find the package name for this hash_id
          const item = items.find(i => i.indexData.hashId === hashId);
          if (item) {
            packageDataMap[item.req.name] = {
              name: item.req.name,
              ios: mapSupportStatus(iosSupport),
              android: mapSupportStatus(androidSupport),
              iosVersion: iosVersion || '',
              androidVersion: androidVersion || '',
              category: mapCategory(categoryCode, androidSupport, iosSupport),
              source: mapSource(sourceCode)
            };
          }
        }
      }
      
      // Build final results array maintaining original order
      for (const req of requirements) {
        results.push({
          requirement: req,
          package: packageDataMap[req.name] || null
        });
      }
      
    } catch (error) {
      console.error('Analysis error:', error);
    }
    
    const endTime = performance.now();
    const analysisTime = ((endTime - startTime) / 1000).toFixed(2);
    
    return { results, analysisTime };
  }
  
  // Display requirements results
  function displayRequirementsResults(analysis) {
    const { results, analysisTime } = analysis;
    const container = document.getElementById('requirements-results');
    const statsBar = document.getElementById('requirements-stats');
    
    // Get filter state
    const showIOS = document.getElementById('req-filter-ios').checked;
    const showAndroid = document.getElementById('req-filter-android').checked;
    
    // Calculate statistics
    let iosCount = 0, androidCount = 0, pureCount = 0, missingCount = 0;
    let iosUnsupported = 0, androidUnsupported = 0;
    
    results.forEach(r => {
      if (!r.package) {
        missingCount++;
        iosUnsupported++;
        androidUnsupported++;
      } else {
        if (r.package.ios === 'supported') iosCount++;
        else if (r.package.ios === 'not_available') iosUnsupported++;
        
        if (r.package.android === 'supported') androidCount++;
        else if (r.package.android === 'not_available') androidUnsupported++;
        
        if (r.package.ios === 'pure_python' || r.package.android === 'pure_python') pureCount++;
      }
    });
    
    const totalPackages = results.length;
    const iosFullySupported = (iosCount + pureCount) === totalPackages;
    const androidFullySupported = (androidCount + pureCount) === totalPackages;
    const iosPartiallySupported = (iosCount + pureCount) > 0 && (iosCount + pureCount) < totalPackages;
    const androidPartiallySupported = (androidCount + pureCount) > 0 && (androidCount + pureCount) < totalPackages;
    
    // Update stats
    document.getElementById('req-total').textContent = `Total: ${results.length}`;
    document.getElementById('req-ios').textContent = `iOS: ${iosCount}`;
    document.getElementById('req-android').textContent = `Android: ${androidCount}`;
    document.getElementById('req-pure').textContent = `Pure Python: ${pureCount}`;
    document.getElementById('req-missing').textContent = `Not Found: ${missingCount}`;
    statsBar.style.display = 'flex';
    
    // Build compatibility warning
    let warningHtml = '';
    
    // Only show warnings for selected platforms
    if (showIOS || showAndroid) {
      if (showIOS && showAndroid) {
        // Both platforms selected - show combined warning
        if (!iosFullySupported && !androidFullySupported) {
          if (iosUnsupported === totalPackages && androidUnsupported === totalPackages) {
            warningHtml = `
              <div class="compatibility-warning critical">
                <strong>⛔️ NOT SUPPORTED:</strong> This requirements.txt is <strong>NOT compatible</strong> with iOS or Android. 
                pip install will fail on both platforms. All packages lack mobile platform support.
              </div>
            `;
          } else if (iosPartiallySupported && androidPartiallySupported) {
            warningHtml = `
              <div class="compatibility-warning warning">
                <strong>⚠️ PARTIALLY SUPPORTED:</strong> This requirements.txt is partially compatible with mobile platforms.<br>
                pip install may fail on:<br>
                • iOS (${iosUnsupported} unsupported)<br>
                • Android (${androidUnsupported} unsupported)
              </div>
            `;
          } else if (iosUnsupported === totalPackages) {
            warningHtml = `
              <div class="compatibility-warning warning">
                <strong>⚠️ iOS NOT SUPPORTED:</strong> pip install will <strong>fail on iOS</strong>. All packages lack iOS support.<br>
                Android support: ${androidCount + pureCount}/${totalPackages} packages supported.
              </div>
            `;
          } else if (androidUnsupported === totalPackages) {
            warningHtml = `
              <div class="compatibility-warning warning">
                <strong>⚠️ Android NOT SUPPORTED:</strong> pip install will <strong>fail on Android</strong>. All packages lack Android support.<br>
                iOS support: ${iosCount + pureCount}/${totalPackages} packages supported.
              </div>
            `;
          } else {
            warningHtml = `
              <div class="compatibility-warning warning">
                <strong>⚠️ PARTIALLY SUPPORTED:</strong> pip install may fail on mobile platforms.<br>
                iOS: ${iosUnsupported} unsupported packages | Android: ${androidUnsupported} unsupported packages
              </div>
            `;
          }
        } else if (!iosFullySupported) {
          warningHtml = `
            <div class="compatibility-warning warning">
              <strong>⚠️ iOS PARTIALLY SUPPORTED:</strong> pip install may fail on iOS. ${iosUnsupported} packages are not supported on iOS.<br>
              Android: ✅ Fully supported
            </div>
          `;
        } else if (!androidFullySupported) {
          warningHtml = `
            <div class="compatibility-warning warning">
              <strong>⚠️ Android PARTIALLY SUPPORTED:</strong> pip install may fail on Android. ${androidUnsupported} packages are not supported on Android.<br>
              iOS: ✅ Fully supported
            </div>
          `;
        } else {
          warningHtml = `
            <div class="compatibility-warning success">
              <strong>✅ FULLY SUPPORTED:</strong> All packages are compatible with iOS and Android. pip install should work successfully on both platforms.
            </div>
          `;
        }
      } else if (showIOS) {
        // iOS only
        if (iosUnsupported === totalPackages) {
          warningHtml = `
            <div class="compatibility-warning critical">
              <strong>⛔️ iOS NOT SUPPORTED:</strong> pip install will <strong>fail on iOS</strong>. All packages lack iOS support.
            </div>
          `;
        } else if (iosPartiallySupported) {
          warningHtml = `
            <div class="compatibility-warning warning">
              <strong>⚠️ iOS PARTIALLY SUPPORTED:</strong> pip install may fail on iOS.<br>
              ${iosUnsupported} unsupported packages
            </div>
          `;
        } else {
          warningHtml = `
            <div class="compatibility-warning success">
              <strong>✅ iOS FULLY SUPPORTED:</strong> All packages are compatible with iOS. pip install should work successfully.
            </div>
          `;
        }
      } else if (showAndroid) {
        // Android only
        if (androidUnsupported === totalPackages) {
          warningHtml = `
            <div class="compatibility-warning critical">
              <strong>⛔️ Android NOT SUPPORTED:</strong> pip install will <strong>fail on Android</strong>. All packages lack Android support.
            </div>
          `;
        } else if (androidPartiallySupported) {
          warningHtml = `
            <div class="compatibility-warning warning">
              <strong>⚠️ Android PARTIALLY SUPPORTED:</strong> pip install may fail on Android.<br>
              ${androidUnsupported} unsupported packages
            </div>
          `;
        } else {
          warningHtml = `
            <div class="compatibility-warning success">
              <strong>✅ Android FULLY SUPPORTED:</strong> All packages are compatible with Android. pip install should work successfully.
            </div>
          `;
        }
      }
    }
    
    // Build results table
    let html = warningHtml + `
      <div style="margin-bottom: 10px; margin-top: 20px; color: var(--md-default-fg-color--light);">
        Analysis completed in ${analysisTime}s
      </div>
      <table class="requirements-table">
        <thead>
          <tr>
            <th>Package</th>
            ${showIOS ? '<th>iOS</th>' : ''}
            ${showAndroid ? '<th>Android</th>' : ''}
            <th>Category</th>
          </tr>
        </thead>
        <tbody>
    `;
    
    for (const result of results) {
      const req = result.requirement;
      const pkg = result.package;
      
      if (!pkg) {
        const colspan = (showIOS ? 1 : 0) + (showAndroid ? 1 : 0) + 1;
        html += `
          <tr>
            <td>
              <div class="package-name"><a href="https://pypi.org/project/${req.name}/" target="_blank" rel="noopener noreferrer">${req.name}</a></div>
              <div class="version-spec">${req.version}</div>
            </td>
            <td colspan="${colspan}">
              <span class="status-badge status-not-available">❌ Package not found in database</span>
            </td>
          </tr>
        `;
      } else {
        html += `
          <tr>
            <td>
              <div class="package-name"><a href="https://pypi.org/project/${pkg.name}/" target="_blank" rel="noopener noreferrer">${pkg.name}</a></div>
              <div class="version-spec">${req.version}</div>
              <div class="package-details">Source: ${pkg.source || 'Unknown'}</div>
            </td>
            ${showIOS ? `<td>${formatStatus(pkg.ios, pkg.iosVersion)}</td>` : ''}
            ${showAndroid ? `<td>${formatStatus(pkg.android, pkg.androidVersion)}</td>` : ''}
            <td>${getCategoryName(pkg.category, pkg.source)}</td>
          </tr>
        `;
      }
    }
    
    html += '</tbody></table>';
    container.innerHTML = html;
  }
  
  // Handle file upload
  function setupRequirementsTab() {
    const fileInput = document.getElementById('file-input');
    const uploadArea = document.getElementById('upload-area');
    const requirementsText = document.getElementById('requirements-text');
    const analyzeBtn = document.getElementById('analyze-btn');
    
    let lastAnalysis = null; // Store last analysis result
    
    // Filter checkboxes - re-render when changed
    document.getElementById('req-filter-ios').addEventListener('change', () => {
      if (lastAnalysis) {
        displayRequirementsResults(lastAnalysis);
      }
    });
    
    document.getElementById('req-filter-android').addEventListener('change', () => {
      if (lastAnalysis) {
        displayRequirementsResults(lastAnalysis);
      }
    });
    
    // File input change
    fileInput.addEventListener('change', async (e) => {
      const file = e.target.files[0];
      if (file) {
        const text = await file.text();
        requirementsText.value = text;
      }
    });
    
    // Drag and drop
    uploadArea.addEventListener('dragover', (e) => {
      e.preventDefault();
      uploadArea.classList.add('dragover');
    });
    
    uploadArea.addEventListener('dragleave', () => {
      uploadArea.classList.remove('dragover');
    });
    
    uploadArea.addEventListener('drop', async (e) => {
      e.preventDefault();
      uploadArea.classList.remove('dragover');
      
      const file = e.dataTransfer.files[0];
      if (file && file.name.endsWith('.txt')) {
        const text = await file.text();
        requirementsText.value = text;
      }
    });
    
    // Analyze button
    analyzeBtn.addEventListener('click', async () => {
      const text = requirementsText.value.trim();
      if (!text) {
        alert('Please upload a file or paste requirements');
        return;
      }
      
      if (!indexDB) {
        alert('Package database is still loading. Please wait...');
        return;
      }
      
      analyzeBtn.disabled = true;
      analyzeBtn.textContent = '🔄 Analyzing...';
      
      try {
        const lines = text.split('\n');
        const requirements = lines.map(parseRequirement).filter(r => r !== null);
        
        const analysis = await analyzeRequirements(requirements);
        lastAnalysis = analysis; // Store for filter changes
        displayRequirementsResults(analysis);
      } catch (error) {
        console.error('Analysis error:', error);
        alert('Error analyzing requirements. Check console for details.');
      } finally {
        analyzeBtn.disabled = false;
        analyzeBtn.textContent = '🔍 Analyze Requirements';
      }
    });
  }
  
  // Start when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
  
  console.log('Package search script loaded. Waiting for DOM...');
  
})();
</script>
