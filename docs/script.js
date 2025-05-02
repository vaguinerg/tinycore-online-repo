/**
 * TinyCore Repository Browser
 * A modern interface for browsing the TinyCore Linux package repository
 */

// Global variables
const app = {
  // DOM Elements
  elements: {
    versionSelector: $('#SelectVersion'),
    searchTypeSelector: $('#SearchType'),
    searchInput: $('#InputSearchTerm'),
    packageList: $('#TCZList'),
    infoList: $('#InfoList'),
    statusInfo: $('#StatusInfo'),
    progressBar: $('#ProgressBar'),
    progressFill: $('#ProgressFill')
  },
  
  // Repository data
  repo: {
    selectedVersion: null,
    selectedArch: null,
    githubBaseUrl: 'https://raw.githubusercontent.com/CardealRusso/tinycore-online-repo/main'
  }
};

// Initialize the application
$(document).ready(function() {
  initVersionList();
  setupEventListeners();
});

// Setup all event listeners
function setupEventListeners() {
  // Version selection changed
  app.elements.versionSelector.on('change', handleVersionChange);
  
  // Package selection changed
  app.elements.packageList.on('change', handlePackageSelection);
  
  // Search input (on enter key)
  app.elements.searchInput.on('keypress', function(event) {
    if (event.which === 13) {
      handleSearch();
    }
  });
  
  // Search type changed
  app.elements.searchTypeSelector.on('change', function() {
    // Reset the package list when changing search type
    if (app.elements.searchTypeSelector.val() === 'search') {
      loadTczList();
    }
  });
}

// Load available TinyCore versions
async function initVersionList() {
  showStatus("Loading available versions...");
  
  try {
    const data = await $.get(`${app.repo.githubBaseUrl}/site-data/versions`);
    
    // Fix JSON format (remove trailing commas)
    const jsonString = data.replace(/,\s*([\]}])/g, '$1');
    const parsedData = JSON.parse(jsonString);
    
    // Sort versions in descending order and populate dropdown
    Object.keys(parsedData)
      .sort((a, b) => parseInt(b) - parseInt(a))
      .forEach(version => {
        app.elements.versionSelector.append(
          $('<optgroup>', { label: version }).append(
            parsedData[version].map(value => $('<option>', { text: value }))
          )
        );
      });
    
    clearStatus();
  } catch (error) {
    showStatus("Error loading versions. Please try again later.", true);
    console.error("Error loading versions:", error);
  }
}

// Handle version selection change
async function handleVersionChange() {
  disableControls();
  
  const selectedOption = app.elements.versionSelector.find('option:selected');
  app.repo.selectedVersion = selectedOption.closest('optgroup').attr('label');
  app.repo.selectedArch = selectedOption.val();
  
  await loadTczList();
  enableControls();
}

// Load package list for selected version/architecture
async function loadTczList() {
  showStatus(`Loading packages for ${app.repo.selectedVersion}/${app.repo.selectedArch}...`);
  app.elements.packageList.empty();
  
  try {
    const url = `${app.repo.githubBaseUrl}/data/${app.repo.selectedVersion}/${app.repo.selectedArch}/tczlist`;
    const data = await $.get(url);
    
    // Populate package list
    data.split('\n').forEach(line => {
      if (line.trim()) {
        app.elements.packageList.append($('<option>', { text: line.trim() }));
      }
    });
    
    clearStatus();
  } catch (error) {
    showStatus("Error loading package list. Please try again later.", true);
    console.error("Error loading package list:", error);
  }
}

// Handle package selection
async function handlePackageSelection() {
  const selectedPackage = app.elements.packageList.find('option:selected').text();
  if (!selectedPackage) return;
  
  showStatus(`Loading information for ${selectedPackage}...`);
  app.elements.infoList.empty();
  
  try {
    const url = `${app.repo.githubBaseUrl}/tinycorelinux/${app.repo.selectedVersion}/${app.repo.selectedArch}/tcz/${selectedPackage}.info`;
    const infoData = await $.get(url);
    
    // Format and display package information
    const formattedInfo = infoData.replace(/\n/g, '<br>');
    app.elements.infoList.html(formattedInfo);
    
    clearStatus();
  } catch (error) {
    app.elements.infoList.html('<span class="error">Error loading package information.</span>');
    clearStatus();
    console.error("Error loading package info:", error);
  }
}

// Handle search operations
async function handleSearch() {
  const searchTerm = app.elements.searchInput.val().toLowerCase();
  const searchType = app.elements.searchTypeSelector.val();
  
  if (!searchTerm || !app.repo.selectedVersion) return;
  
  // Search by package name (filter existing list)
  if (searchType === 'search') {
    app.elements.packageList.find('option').each(function() {
      const itemText = $(this).text().toLowerCase();
      $(this).toggle(itemText.includes(searchTerm));
    });
    
    if (searchTerm.length === 0) {
      app.elements.packageList.find('option').show();
    }
  } 
  // Search within package descriptions
  else if (searchType === 'info') {
    disableControls();
    await deepInfoSearch(searchTerm);
    enableControls();
  }
}

// Search within package info files
async function deepInfoSearch(searchTerm) {
  showStatus(`Searching for "${searchTerm}" in package descriptions...`);
  app.elements.packageList.empty();
  
  try {
    // Get the full package list
    const url = `${app.repo.githubBaseUrl}/data/${app.repo.selectedVersion}/${app.repo.selectedArch}/tczlist`;
    const data = await $.get(url);
    const packages = data.split('\n').filter(line => line.trim());
    
    // Show progress bar for deep searches
    showProgressBar();
    
    // Search each package info
    let matches = 0;
    for (let i = 0; i < packages.length; i++) {
      const packageName = packages[i].trim();
      
      // Update progress
      updateProgress(i, packages.length);
      showStatus(`Searching... (${i + 1}/${packages.length}): ${packageName}`);
      
      try {
        const infoUrl = `${app.repo.githubBaseUrl}/tinycorelinux/${app.repo.selectedVersion}/${app.repo.selectedArch}/tcz/${packageName}.info`;
        const infoData = await $.get(infoUrl);
        
        // Add to results if match found
        if (infoData.toLowerCase().includes(searchTerm)) {
          app.elements.packageList.append($('<option>', { text: packageName }));
          matches++;
        }
      } catch (error) {
        // Skip packages with missing info files
        console.warn(`Info not found for ${packageName}`);
      }
    }
    
    // Hide progress bar
    hideProgressBar();
    
    showStatus(`Found ${matches} packages matching "${searchTerm}"`);
    setTimeout(clearStatus, 3000);
  } catch (error) {
    hideProgressBar();
    showStatus("Error performing search. Please try again later.", true);
    console.error("Search error:", error);
  }
}

// Utility functions
function showStatus(message, isError = false) {
  app.elements.statusInfo.text(message);
  if (isError) {
    app.elements.statusInfo.addClass('error');
  } else {
    app.elements.statusInfo.removeClass('error');
  }
}

function clearStatus() {
  app.elements.statusInfo.text('');
  app.elements.statusInfo.removeClass('error');
}

function disableControls() {
  app.elements.searchTypeSelector.prop('disabled', true);
  app.elements.searchInput.prop('disabled', true);
  app.elements.versionSelector.prop('disabled', true);
}

function enableControls() {
  app.elements.searchTypeSelector.prop('disabled', false);
  app.elements.searchInput.prop('disabled', false);
  app.elements.versionSelector.prop('disabled', false);
}

function showProgressBar() {
  app.elements.progressBar.show();
}

function hideProgressBar() {
  app.elements.progressBar.hide();
  app.elements.progressFill.css('width', '0%');
}

function updateProgress(current, total) {
  const percent = Math.floor((current / total) * 100);
  app.elements.progressFill.css('width', `${percent}%`);
               }
