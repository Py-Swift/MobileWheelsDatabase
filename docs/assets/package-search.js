// Package Search - Swift WASM Integration
// Mobile platform support database for 714,850+ Python packages

(async () => {
  // Auto-detect base URL from script location or use window config
  const DB_BASE_URL = window.MOBILEWHEELS_DB_URL || (() => {
    const scripts = document.querySelectorAll('script[src*="package-search.js"]');
    if (scripts.length > 0) {
      const scriptSrc = scripts[0].src;
      const detectedPath = scriptSrc.substring(0, scriptSrc.lastIndexOf('/') + 1);
      console.log('Auto-detected DB path from script src:', detectedPath);
      return detectedPath;
    }
    console.log('Using fallback path: ../assets/');
    return '../assets/';
  })();
  
  console.log('Using DB_BASE_URL:', DB_BASE_URL);
  const RESULTS_PER_PAGE = 50;
  
  let SQL = null;
  let indexDB = null;
  let dataDBs = {};
  let totalPackages = 714850;
  let currentResults = [];
  let currentPage = 1;

  // Progress bar helpers
  function updateProgress(percent, text) {
    const progressFill = document.getElementById('progress-fill');
    const progressText = document.getElementById('progress-text');
    if (progressFill) progressFill.style.width = percent + '%';
    if (progressText) progressText.textContent = text;
  }

  function showProgressBar() {
    const progressBar = document.getElementById('loading-progress');
    const resultsContainer = document.getElementById('results-container');
    if (progressBar) progressBar.style.display = 'block';
    if (resultsContainer) resultsContainer.style.display = 'none';
  }

  function hideProgressBar() {
    const progressBar = document.getElementById('loading-progress');
    const resultsContainer = document.getElementById('results-container');
    setTimeout(() => {
      if (progressBar) progressBar.style.display = 'none';
      if (resultsContainer) resultsContainer.style.display = 'block';
    }, 500);
  }

  // Initialize Swift WASM
  async function initSwiftWasm() {
    try {
      showProgressBar();
      updateProgress(10, 'Fetching WASM module...');
      
      console.log('🚀 Starting Swift WASM load...');
      console.log('📍 Current page:', window.location.href);
      
      const wasmPath = `${DB_BASE_URL}MobileWheelsDatabase.wasm`;
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
      let wasmMemory = null;
      
      updateProgress(40, 'Instantiating WASM...');
      
      // WASI stubs
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
      
      const { instance } = await WebAssembly.instantiate(wasmBytes, {
        wasi_snapshot_preview1: wasi,
        env: {
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
      window.wasmInstance = instance;
      
      updateProgress(60, 'Initializing Swift runtime...');
      console.log('✅ WASM instantiated');
      console.log('📋 Instance exports:', Object.keys(instance.exports));
      
      if (instance.exports._initialize) {
        console.log('🔧 Calling _initialize()...');
        instance.exports._initialize();
        console.log('✅ _initialize() completed');
      }
      
      const testResult = instance.exports.swiftTest();
      console.log('🧪 swiftTest() returned:', testResult);
      
      updateProgress(70, 'Loading index databases...');
      
      // Load both index databases
      console.log('📥 Loading index database chunks for Swift...');
      
      console.log('📦 Fetching index-1.sqlite...');
      const index1Buffer = await fetch(DB_BASE_URL + 'index-1.sqlite').then(r => r.arrayBuffer());
      const index1Bytes = new Uint8Array(index1Buffer);
      console.log(`📦 Index 1 size: ${(index1Bytes.byteLength / 1024 / 1024).toFixed(2)} MB`);
      
      console.log('📦 Fetching index-2.sqlite...');
      const index2Buffer = await fetch(DB_BASE_URL + 'index-2.sqlite').then(r => r.arrayBuffer());
      const index2Bytes = new Uint8Array(index2Buffer);
      console.log(`📦 Index 2 size: ${(index2Bytes.byteLength / 1024 / 1024).toFixed(2)} MB`);
      
      console.log(`✅ Total index size: ${((index1Bytes.byteLength + index2Bytes.byteLength) / 1024 / 1024).toFixed(2)} MB`);
      
      updateProgress(80, 'Preparing database memory...');
      
      const loadedChunks = new Set();
      const cachedChunks = new Map();
      const dbMemoryOffset = 100 * 1024 * 1024;
      const memory = new Uint8Array(instance.exports.memory.buffer);
      
      const totalMemoryNeeded = 400 * 1024 * 1024;
      if (memory.length < totalMemoryNeeded) {
        console.log(`📈 Growing WASM memory from ${memory.length} to ${totalMemoryNeeded}`);
        const pagesNeeded = Math.ceil((totalMemoryNeeded - memory.length) / 65536);
        instance.exports.memory.grow(pagesNeeded);
      }
      
      let currentOffset = dbMemoryOffset;
      const updatedMemory = new Uint8Array(instance.exports.memory.buffer);
      
      updatedMemory.set(index1Bytes, currentOffset);
      console.log(`✅ Index 1 copied to offset ${currentOffset}`);
      const index1DbOffset = currentOffset;
      const index1DbSize = index1Bytes.length;
      currentOffset += index1Bytes.length;
      
      updatedMemory.set(index2Bytes, currentOffset);
      console.log(`✅ Index 2 copied to offset ${currentOffset}`);
      const index2DbOffset = currentOffset;
      const index2DbSize = index2Bytes.length;
      currentOffset += index2Bytes.length;
      
      let nextChunkOffset = currentOffset;
      
      console.log(`🔧 Calling swiftInit(${index1DbOffset}, ${index1DbSize})...`);
      let swiftInitialized = false;
      
      updateProgress(90, 'Initializing databases...');
      
      if (typeof instance.exports.swiftInit === 'function') {
        const initResult = instance.exports.swiftInit(index1DbOffset, index1DbSize);
        console.log(`✅ swiftInit() returned: ${initResult}`);
        if (initResult === 0) {
          throw new Error('Swift initialization failed');
        }
        
        console.log(`🔧 Calling swiftAttachIndex2(${index2DbOffset}, ${index2DbSize})...`);
        if (typeof instance.exports.swiftAttachIndex2 === 'function') {
          const attachResult = instance.exports.swiftAttachIndex2(index2DbOffset, index2DbSize);
          console.log(`✅ swiftAttachIndex2() returned: ${attachResult}`);
          if (attachResult === 0) {
            throw new Error('Failed to attach second index database');
          }
        }
        
        swiftInitialized = true;
      } else {
        throw new Error('swiftInit function not found');
      }
      
      // Load chunk function
      async function loadChunk(chunkNum) {
        try {
          let chunkBytes;
          
          if (cachedChunks.has(chunkNum)) {
            console.log(`📦 Using cached chunk ${chunkNum} from JavaScript memory`);
            chunkBytes = cachedChunks.get(chunkNum);
          } else {
            const chunkUrl = DB_BASE_URL + `data-${chunkNum}.sqlite`;
            console.log(`📥 Loading chunk ${chunkNum} on-demand...`);
            const chunkBuffer = await fetch(chunkUrl).then(r => r.arrayBuffer());
            chunkBytes = new Uint8Array(chunkBuffer);
            console.log(`📦 Loaded data-${chunkNum}.sqlite: ${(chunkBuffer.byteLength / 1024 / 1024).toFixed(2)} MB`);
            
            cachedChunks.set(chunkNum, chunkBytes);
            console.log(`💾 Cached chunk ${chunkNum} in JavaScript memory`);
          }
          
          const memory = new Uint8Array(instance.exports.memory.buffer);
          memory.set(chunkBytes, nextChunkOffset);
          
          if (typeof instance.exports.swiftAttachChunk === 'function') {
            const attachResult = instance.exports.swiftAttachChunk(chunkNum, nextChunkOffset, chunkBytes.length);
            console.log(`✅ Attached data-${chunkNum}.sqlite: ${attachResult}`);
            if (attachResult === 1) {
              loadedChunks.add(chunkNum);
              return true;
            }
          }
          return false;
        } catch (error) {
          console.error(`❌ Failed to load chunk ${chunkNum}:`, error);
          return false;
        }
      }
      
      // Create SwiftSearch API
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
            
            const queryBytes = new TextEncoder().encode(query);
            const queryMemory = new Uint8Array(instance.exports.memory.buffer);
            queryMemory.set(queryBytes, 0);
            
            const outputOffset = 314572800;
            const outputSize = 10 * 1024 * 1024;
            
            console.log(`📞 Starting incremental search...`);
            
            let bytesWritten;
            let maxRetries = 20;
            
            while (maxRetries-- > 0) {
              bytesWritten = instance.exports.swiftSearch(0, queryBytes.length, outputOffset, outputSize);
              console.log(`📞 swiftSearch returned: ${bytesWritten} bytes`);
              
              if (bytesWritten <= 0) {
                console.log('📊 No results from Swift (0 bytes)');
                return [];
              }
              
              const outputMemory = new Uint8Array(instance.exports.memory.buffer);
              const responseBytes = outputMemory.slice(outputOffset, outputOffset + bytesWritten);
              const responseString = new TextDecoder().decode(responseBytes);
              
              if (responseString.startsWith('-')) {
                const chunkList = responseString.substring(1).split(',').map(n => parseInt(n.trim()));
                console.log(`🔄 Swift requests ${chunkList.length} chunks: [${chunkList.join(', ')}]`);
                
                for (const chunkNum of chunkList) {
                  console.log(`📥 Loading chunk ${chunkNum}...`);
                  const loaded = await loadChunk(chunkNum);
                  if (!loaded) {
                    console.error(`❌ Failed to load chunk ${chunkNum}`);
                    return [];
                  }
                  console.log(`✅ Chunk ${chunkNum} loaded`);
                }
                continue;
              }
              
              break;
            }
            
            const outputMemory = new Uint8Array(instance.exports.memory.buffer);
            const jsonBytes = outputMemory.slice(outputOffset, outputOffset + bytesWritten);
            const jsonString = new TextDecoder().decode(jsonBytes);
            const results = JSON.parse(jsonString);
            
            console.log(`✅ Swift returned ${results.length} results`);
            return results;
          } catch (e) {
            console.error('❌ Swift search failed:', e);
            return [];
          }
        },
        
        batchLookup: async (packageNames) => {
          console.log(`📦 SwiftSearch.batchLookup called with ${packageNames.length} packages`);
          
          if (!swiftInitialized) {
            console.error('❌ Swift not initialized, cannot batch lookup');
            return [];
          }
          
          try {
            if (!instance.exports.swiftBatchLookup) {
              console.error('❌ swiftBatchLookup export not found');
              return [];
            }
            
            const namesJson = JSON.stringify(packageNames);
            const namesBytes = new TextEncoder().encode(namesJson);
            const queryMemory = new Uint8Array(instance.exports.memory.buffer);
            queryMemory.set(namesBytes, 0);
            
            const outputOffset = 314572800;
            const outputSize = 10 * 1024 * 1024;
            
            console.log(`📞 Starting batch lookup with chunk loading...`);
            
            let bytesWritten;
            let maxRetries = 20;
            
            while (maxRetries-- > 0) {
              bytesWritten = instance.exports.swiftBatchLookup(0, namesBytes.length, outputOffset, outputSize);
              console.log(`📞 swiftBatchLookup returned: ${bytesWritten} bytes`);
              
              if (bytesWritten <= 0) {
                console.log('📊 No results from Swift (0 bytes)');
                return [];
              }
              
              const outputMemory = new Uint8Array(instance.exports.memory.buffer);
              const responseBytes = outputMemory.slice(outputOffset, outputOffset + bytesWritten);
              const responseString = new TextDecoder().decode(responseBytes);
              
              if (responseString.startsWith('-')) {
                const chunkList = responseString.substring(1).split(',').map(n => parseInt(n.trim()));
                console.log(`🔄 Swift requests ${chunkList.length} chunks: [${chunkList.join(', ')}]`);
                
                for (const chunkNum of chunkList) {
                  console.log(`📥 Loading chunk ${chunkNum} for batch lookup...`);
                  const loaded = await loadChunk(chunkNum);
                  if (!loaded) {
                    console.error(`❌ Failed to load chunk ${chunkNum}`);
                    return [];
                  }
                  console.log(`✅ Chunk ${chunkNum} loaded`);
                }
                continue;
              }
              
              break;
            }
            
            const outputMemory = new Uint8Array(instance.exports.memory.buffer);
            const jsonBytes = outputMemory.slice(outputOffset, outputOffset + bytesWritten);
            const jsonString = new TextDecoder().decode(jsonBytes);
            const results = JSON.parse(jsonString);
            
            console.log(`✅ Swift returned ${results.length} results`);
            return results;
          } catch (e) {
            console.error('❌ Swift batch lookup failed:', e);
            return [];
          }
        }
      };
      
      console.log('✅ SwiftSearch API created');
      
      updateProgress(100, 'Ready!');
      hideProgressBar();
      
      window.swiftWasmReady = true;
      window.dispatchEvent(new Event('swiftWasmLoaded'));
    } catch (error) {
      console.error('❌ Failed to load Swift WASM:', error);
      window.swiftWasmReady = false;
      throw error;
    }
  }

  // Initialize database
  async function initDatabase() {
    try {
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
      
      document.getElementById('total-results').textContent = `Ready to search ${totalPackages.toLocaleString()} packages`;
      console.log('Database initialization complete!');
    } catch (error) {
      console.error('FATAL ERROR during database initialization:', error);
      showError('Failed to load package database: ' + error.message);
      document.getElementById('total-results').textContent = 'Database failed to load';
    }
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

  // Search packages
  async function searchPackages(query) {
    if (!query || query.length < 2) {
      return [];
    }
    
    if (!window.SwiftSearch) {
      console.log('⏳ Waiting for SwiftSearch to load...');
      await new Promise(resolve => {
        if (window.SwiftSearch) {
          resolve();
        } else {
          window.addEventListener('swiftWasmLoaded', resolve, { once: true });
          setTimeout(resolve, 5000);
        }
      });
    }
    
    if (!window.SwiftSearch || !window.SwiftSearch.search) {
      console.error('SwiftSearch not available after waiting');
      return [];
    }
    
    const startTime = performance.now();
    const searchTerm = query.toLowerCase().trim();
    
    console.log('🔍 Calling Swift to search SQL for:', searchTerm);
    const swiftResults = await window.SwiftSearch.search(searchTerm);
    
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
    document.getElementById('search-time').textContent = `Found ${results.length} packages in ${searchTime}s`;
    
    console.log(`📦 Search complete: ${results.length} results from Swift`);
    return results;
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
        html += `<button onclick="window.PackageSearch.goToPage(${page - 1})">← Previous</button>`;
      }
      
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
          html += `<button class="${activeClass}" onclick="window.PackageSearch.goToPage(${num})">${num}</button>`;
        }
      }
      
      if (page < totalPages) {
        html += `<button onclick="window.PackageSearch.goToPage(${page + 1})">Next →</button>`;
      }
      
      html += '</div>';
    }
    
    container.innerHTML = html;
    document.getElementById('total-results').textContent = `Showing ${start + 1}-${end} of ${totalResults} results`;
  }

  // Handle search
  let searchTimeout;
  async function handleSearch() {
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
    
    document.getElementById('results-container').innerHTML = '<div class="loading">🔍 Searching through packages...</div>';
    
    searchTimeout = setTimeout(async () => {
      currentResults = await searchPackages(query);
      currentPage = 1;
      displayResults(1);
    }, 1000);
  }

  // Show error
  function showError(message) {
    document.getElementById('results-container').innerHTML = `<div class="no-results">❌ ${message}</div>`;
  }

  // Parse requirements.txt line
  function parseRequirement(line) {
    line = line.trim();
    if (!line || line.startsWith('#')) return null;
    
    const platformMarkers = [
      'sys_platform == \'win32\'', 'sys_platform == "win32"',
      'sys_platform == \'darwin\'', 'sys_platform == "darwin"',
      'platform_system == \'Windows\'', 'platform_system == "Windows"',
      'platform_system == \'Darwin\'', 'platform_system == "Darwin"',
      'os_name == \'nt\'', 'os_name == "nt"'
    ];
    
    for (const marker of platformMarkers) {
      if (line.includes(marker)) return null;
    }
    
    line = line.replace(/;\s*sys_platform\s*==\s*['"]linux['"]/gi, '');
    line = line.replace(/;\s*platform_system\s*==\s*['"]Linux['"]/gi, '');
    line = line.trim();
    
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
      const packageNames = requirements.map(r => r.name);
      console.log(`📦 Batch looking up ${packageNames.length} packages...`);
      
      const batchResults = await window.SwiftSearch.batchLookup(packageNames);
      
      const packageDataMap = {};
      for (const pkg of batchResults) {
        packageDataMap[pkg.name.toLowerCase()] = {
          name: pkg.name,
          ios: pkg.ios,
          android: pkg.android,
          iosVersion: pkg.ios_version || '',
          androidVersion: pkg.android_version || '',
          category: pkg.category,
          source: pkg.source
        };
      }
      
      for (const req of requirements) {
        results.push({
          requirement: req,
          package: packageDataMap[req.name.toLowerCase()] || null
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
    
    const showIOS = document.getElementById('req-filter-ios').checked;
    const showAndroid = document.getElementById('req-filter-android').checked;
    
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
    
    document.getElementById('req-total').textContent = `Total: ${results.length}`;
    document.getElementById('req-ios').textContent = `iOS: ${iosCount}`;
    document.getElementById('req-android').textContent = `Android: ${androidCount}`;
    document.getElementById('req-pure').textContent = `Pure Python: ${pureCount}`;
    document.getElementById('req-missing').textContent = `Not Found: ${missingCount}`;
    statsBar.style.display = 'flex';
    
    let warningHtml = '';
    
    if (showIOS || showAndroid) {
      if (showIOS && showAndroid) {
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

  // Setup requirements tab
  function setupRequirementsTab() {
    const fileInput = document.getElementById('file-input');
    const uploadArea = document.getElementById('upload-area');
    const requirementsText = document.getElementById('requirements-text');
    const analyzeBtn = document.getElementById('analyze-btn');
    
    let lastAnalysis = null;
    
    document.getElementById('req-filter-ios').addEventListener('change', () => {
      if (lastAnalysis) displayRequirementsResults(lastAnalysis);
    });
    
    document.getElementById('req-filter-android').addEventListener('change', () => {
      if (lastAnalysis) displayRequirementsResults(lastAnalysis);
    });
    
    fileInput.addEventListener('change', async (e) => {
      const file = e.target.files[0];
      if (file) {
        const text = await file.text();
        requirementsText.value = text;
      }
    });
    
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
    
    analyzeBtn.addEventListener('click', async () => {
      const text = requirementsText.value.trim();
      if (!text) {
        alert('Please upload a file or paste requirements');
        return;
      }
      
      if (!window.SwiftSearch) {
        alert('Package database is still loading. Please wait...');
        return;
      }
      
      analyzeBtn.disabled = true;
      analyzeBtn.textContent = '🔄 Analyzing...';
      
      try {
        const lines = text.split('\n');
        const requirements = lines.map(parseRequirement).filter(r => r !== null);
        
        const analysis = await analyzeRequirements(requirements);
        lastAnalysis = analysis;
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

  // Initialize
  async function init() {
    console.log('Package search initializing...');
    document.getElementById('total-results').textContent = 'Loading database...';
    
    // Initialize Swift WASM first
    await initSwiftWasm();
    await initDatabase();
    
    // Set up event listeners
    document.getElementById('package-search').addEventListener('input', handleSearch);
    
    ['filter-ios', 'filter-android', 'filter-pure', 'filter-binary'].forEach(id => {
      document.getElementById(id).addEventListener('change', handleSearch);
    });
    
    setupRequirementsTab();
    
    console.log('✅ Package search initialized');
  }

  // Export public API
  window.PackageSearch = {
    goToPage: (page) => {
      currentPage = page;
      displayResults(page);
      window.scrollTo({ top: 0, behavior: 'smooth' });
    }
  };

  // Start when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
