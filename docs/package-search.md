# Package Database Search

Search through 714,850+ Python packages to check iOS and Android mobile platform support.
---

<!-- Load Package Search JavaScript -->
<script src="../assets/package-search.js"></script>

<script type="module">
  console.log('🧪 Module script executed');

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

</script>

