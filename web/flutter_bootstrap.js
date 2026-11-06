// web/flutter_bootstrap.js
(function() {
  'use strict';

  console.log('🚀 Initializing Coffee Shop v1.0.0...');

  // Detect iOS
  const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent);
  const isSafari = /Safari/.test(navigator.userAgent) && !/Chrome/.test(navigator.userAgent);
  const isChromeOnIOS = isIOS && /CriOS/.test(navigator.userAgent);
  
  console.log(`📱 iOS: ${isIOS}, Safari: ${isSafari}, Chrome on iOS: ${isChromeOnIOS}`);

  const startTime = performance.now();
  const isDesktop = !('ontouchstart' in window) || navigator.userAgent.includes('Windows');
  const isMobile = /Android|iPhone|iPad|iPod/i.test(navigator.userAgent);

  // Configuration
  const config = {
    entrypoint: 'main.dart.js',
    engineUrl: new URL('.', window.location.href).toString(),
    options: {
      useCanvasKit: false,
    },
    serviceWorker: {
      serviceWorkerUrl: 'flutter_service_worker.js',
      useServiceWorker: !isChromeOnIOS, // Disable service worker on Chrome iOS
    },
  };

  // Platform detection
  console.log(`📱 Platform: ${isDesktop ? 'Desktop' : 'Mobile'}`);

  // Locale
  const userLocale = navigator.language || 'en';
  console.log(`🌐 Locale set to: ${userLocale}`);

  // Show error message
  function showErrorMessage(message) {
    const errorDiv = document.createElement('div');
    errorDiv.style.cssText = `
      position: fixed;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      background: #f44336;
      color: white;
      padding: 24px 32px;
      border-radius: 12px;
      font-family: -apple-system, BlinkMacSystemFont, sans-serif;
      font-size: 16px;
      text-align: center;
      z-index: 99999;
      box-shadow: 0 8px 32px rgba(0,0,0,0.3);
      max-width: 90%;
    `;
    errorDiv.innerHTML = `
      <div style="font-size:48px;margin-bottom:12px;">⚠️</div>
      <div style="margin-bottom:16px;line-height:1.5;">${message}</div>
      <button onclick="location.reload()" style="
        padding:10px 32px;
        background:white;
        color:#f44336;
        border:none;
        border-radius:8px;
        font-size:14px;
        cursor:pointer;
        font-weight:600;
      ">Refresh</button>
    `;
    document.body.appendChild(errorDiv);
  }

  // Load main.dart.js
  function loadMainDartJs() {
    console.log('📦 Loading Flutter web application...');
    
    const script = document.createElement('script');
    script.src = config.entrypoint;
    script.type = 'application/javascript';
    script.async = true;
    
    script.onload = function() {
      console.log('✅ Flutter web application loaded successfully');
    };
    
    script.onerror = function() {
      console.error('❌ Failed to load Flutter web application');
      showErrorMessage('Failed to load the application. Please refresh the page.');
    };
    
    document.head.appendChild(script);
  }

  // Service Worker - Skip on Chrome iOS
  function registerServiceWorker() {
    if (isChromeOnIOS) {
      console.log('⚠️ Skipping Service Worker on Chrome iOS');
      return Promise.resolve();
    }
    
    if (!('serviceWorker' in navigator) || !config.serviceWorker.useServiceWorker) {
      return Promise.resolve();
    }
    
    console.log('📦 Registering service worker...');
    
    return navigator.serviceWorker
      .register(config.serviceWorker.serviceWorkerUrl)
      .then(function(registration) {
        console.log('✅ Service Worker registered');
        return registration;
      })
      .catch(function(error) {
        console.warn('⚠️ Service worker registration failed:', error.message);
        return Promise.resolve();
      });
  }

  // Performance tracking
  function trackPerformance() {
    try {
      const loadTime = Math.max(0, Math.round(performance.now() - startTime));
      console.log(`⏱️ Page load time: ${loadTime}ms`);
      
      if (window.performance && window.performance.memory) {
        const memoryUsed = Math.round(window.performance.memory.usedJSHeapSize / (1024 * 1024));
        console.log(`💾 Memory: ${memoryUsed}MB used`);
      }
    } catch (e) {
      // Ignore performance tracking errors
    }
  }

  // Fix for iOS Chrome - Force reload if stuck
  function fixIOSChrome() {
    if (isChromeOnIOS) {
      console.log('🔧 Applying iOS Chrome fixes...');
      
      // Force viewport fix
      const viewport = document.querySelector('meta[name=viewport]');
      if (viewport) {
        viewport.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover';
      }
      
      // Fix touch events
      document.addEventListener('touchstart', function() {}, { passive: true });
    }
  }

  // Initialize
  function initializeApp() {
    console.log('📊 Initializing app...');
    
    fixIOSChrome();
    
    // Check if main.dart.js exists
    fetch(config.entrypoint)
      .then(function(response) {
        if (response.ok) {
          loadMainDartJs();
          registerServiceWorker();
          trackPerformance();
        } else {
          console.error('❌ Failed to find main.dart.js (status: ' + response.status + ')');
          showErrorMessage('Application files not found. Please rebuild the app.');
        }
      })
      .catch(function(error) {
        console.error('❌ Network error:', error);
        showErrorMessage('Network error occurred. Please check your connection.');
      });
  }

  // Expose API
  window.coffee_shop = {
    version: '1.0.0',
    platform: isDesktop ? 'Desktop' : 'Mobile',
    locale: userLocale,
    startTime: startTime,
    isIOS: isIOS,
    isChromeOnIOS: isChromeOnIOS,
  };

  // Start when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeApp);
  } else {
    initializeApp();
  }

  // Error handling
  window.addEventListener('error', function(event) {
    console.error('💥 Unhandled error:', event.error || event.message);
  });

  window.addEventListener('unhandledrejection', function(event) {
    console.error('💥 Unhandled rejection:', event.reason);
  });

  console.log('🌐 Flutter bootstrap initialized');
  console.log('📦 coffee_shop bootstrap loaded successfully');
  console.log('📱 For API usage: window.coffee_shop');
})();