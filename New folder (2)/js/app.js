/**
 * EmotiGuard - Main Application Controller
 * Coordinates services, UI views, telemetry event routing, and navigation.
 */

import { APP_CONFIG } from './config.js';
import { StorageService } from './services/storageService.js';
import { SessionManager, SESSION_STATES } from './services/sessionManager.js';
import { BluetoothService, BLE_STATES } from './services/bluetoothService.js';
import { SimulatorService } from './services/simulatorService.js';
import { ChartManager } from './ui/chartManager.js';
import { DashboardView } from './ui/dashboardView.js';
import { BleView } from './ui/bleView.js';
import { ParticipantView } from './ui/participantView.js';
import { ExportView } from './ui/exportView.js';

class EmotiGuardApp {
  constructor() {
    this.isDemoMode = false;
    this.currentSample = null;
    this.activeTab = 'dashboard';

    // Services
    this.storage = new StorageService();
    this.sessionManager = new SessionManager(this.storage);
    this.chartManager = new ChartManager();

    // Telemetry handlers
    this.onTelemetrySample = (sample) => this.handleTelemetryData(sample);

    // Bluetooth Service
    this.bleService = new BluetoothService({
      onData: this.onTelemetrySample,
      onStateChange: (state, details) => this.handleBleStateChange(state, details),
      onLog: (msg, type) => this.bleView?.appendLog(msg, type)
    });

    // Synthetic Simulator (Demo Mode)
    this.simulator = new SimulatorService(this.onTelemetrySample);
  }

  init() {
    this.cacheDomElements();
    this.initViews();
    this.bindEvents();
    this.seedSampleSessionIfEmpty();

    // Initialize Chart
    this.chartManager.initLiveChart('liveTelemetryChart');

    // Default start state
    this.switchTab('dashboard');
    this.updateSystemStatus();

    // Check if URL has ?demo=true or auto-prompt
    const urlParams = new URLSearchParams(window.location.search);
    if (urlParams.get('demo') === 'true') {
      this.toggleDemoMode(true);
    }

    if (window.lucide) {
      window.lucide.createIcons();
    }

    console.log(`[EmotiGuard] Initialized v${APP_CONFIG.VERSION}`);
  }

  cacheDomElements() {
    this.els = {
      // Navigation
      navLinks: document.querySelectorAll('.nav-link'),
      tabPanels: document.querySelectorAll('.tab-panel'),
      mobileMenuBtn: document.getElementById('btnMobileMenu'),
      mobileSidebar: document.getElementById('mobileSidebar'),
      mobileOverlay: document.getElementById('mobileOverlay'),
      btnCloseSidebar: document.getElementById('btnCloseSidebar'),

      // Demo Toggle
      btnToggleDemo: document.getElementById('btnToggleDemo'),
      demoToggleCheckbox: document.getElementById('demoToggleCheckbox'),
      demoBanner: document.getElementById('demoBanner'),
      btnSimulateArousal: document.getElementById('btnSimulateArousal'),
      disconnectedAlert: document.getElementById('disconnectedAlert'),
      btnQuickDemo: document.getElementById('btnQuickDemo'),
      btnQuickBle: document.getElementById('btnQuickBle'),

      // Sensor Metrics
      hrVal: document.getElementById('metricHrVal'),
      hrMin: document.getElementById('metricHrMin'),
      hrMax: document.getElementById('metricHrMax'),
      hrAvg: document.getElementById('metricHrAvg'),

      hrvVal: document.getElementById('metricHrvVal'),
      hrvMin: document.getElementById('metricHrvMin'),
      hrvMax: document.getElementById('metricHrvMax'),
      hrvAvg: document.getElementById('metricHrvAvg'),

      spo2Val: document.getElementById('metricSpo2Val'),
      spo2Min: document.getElementById('metricSpo2Min'),
      spo2Max: document.getElementById('metricSpo2Max'),
      spo2Avg: document.getElementById('metricSpo2Avg'),

      gsrVal: document.getElementById('metricGsrVal'),
      gsrMin: document.getElementById('metricGsrMin'),
      gsrMax: document.getElementById('metricGsrMax'),
      gsrAvg: document.getElementById('metricGsrAvg'),

      // Arousal Gauge
      arousalScore: document.getElementById('arousalScore'),
      arousalBar: document.getElementById('arousalBar'),
      arousalBadge: document.getElementById('arousalBadge'),
      arousalLevel: document.getElementById('arousalLevel'),
      arousalDesc: document.getElementById('arousalDesc'),
      telemetrySourceTag: document.getElementById('telemetrySourceTag'),

      // Session Controls
      btnStartSession: document.getElementById('btnStartSession'),
      btnPauseSession: document.getElementById('btnPauseSession'),
      btnStopSession: document.getElementById('btnStopSession'),
      sessionTimer: document.getElementById('sessionTimerDisplay'),
      sampleCountBadge: document.getElementById('sessionSampleCount'),
      activeParticipantBadge: document.getElementById('sessionActivePartBadge'),
      sessionIndicator: document.getElementById('sessionActiveIndicator'),
      sessionStatusText: document.getElementById('sessionStatusText'),

      // BLE Elements
      btnConnectBle: document.getElementById('btnConnectBle'),
      btnDisconnectBle: document.getElementById('btnDisconnectBle'),
      bleStatusText: document.getElementById('bleStatusText'),
      bleStatusBadge: document.getElementById('bleStatusBadge'),
      bleSupportBanner: document.getElementById('bleSupportBanner'),
      bleSupportBannerText: document.getElementById('bleSupportBannerText'),
      bleDeviceInfoCard: document.getElementById('bleDeviceInfoCard'),
      bleDeviceName: document.getElementById('bleDeviceName'),
      bleDeviceId: document.getElementById('bleDeviceId'),
      bleLogContainer: document.getElementById('bleLogContainer'),
      btnClearBleLogs: document.getElementById('btnClearBleLogs'),

      // Participant Elements
      participantSelect: document.getElementById('globalParticipantSelect'),
      currentPartIdDisplay: document.getElementById('currentPartIdDisplay'),
      currentPartAliasDisplay: document.getElementById('currentPartAliasDisplay'),
      currentPartAgeDisplay: document.getElementById('currentPartAgeDisplay'),
      currentPartNotesDisplay: document.getElementById('currentPartNotesDisplay'),
      participantTableBody: document.getElementById('participantTableBody'),
      btnNewParticipant: document.getElementById('btnNewParticipant'),
      newPartModal: document.getElementById('newPartModal'),
      btnClosePartModal: document.getElementById('btnClosePartModal'),
      formNewParticipant: document.getElementById('formNewParticipant'),

      // Session History & Export
      sessionHistoryTableBody: document.getElementById('sessionHistoryTableBody'),
      historyModal: document.getElementById('historyModal'),
      historyModalTitle: document.getElementById('historyModalTitle'),
      historyModalMeta: document.getElementById('historyModalMeta'),
      btnCloseHistoryModal: document.getElementById('btnCloseHistoryModal'),

      // Toast Notifications
      toastContainer: document.getElementById('toastContainer')
    };
  }

  initViews() {
    this.dashboardView = new DashboardView(this.els);
    this.bleView = new BleView(this.els, this.bleService);
    this.bleView.init();

    this.participantView = new ParticipantView(this.els, this.storage, (part) => {
      this.showToast(`Active participant set to: ${part.id} (${part.alias})`, 'info');
      this.updateSystemStatus();
    });
    this.participantView.render();

    this.exportView = new ExportView(this.els, this.storage, this.chartManager);
    this.exportView.render();

    // Session update binding
    this.sessionManager.onUpdate((state, stats) => {
      this.dashboardView.updateSessionControls(state, stats, this.storage.getActiveParticipant());
    });
  }

  bindEvents() {
    // Navigation link clicks
    this.els.navLinks.forEach(link => {
      link.addEventListener('click', (e) => {
        e.preventDefault();
        const tab = link.getAttribute('data-tab');
        this.switchTab(tab);
        this.closeMobileSidebar();
      });
    });

    // Mobile sidebar toggle
    if (this.els.mobileMenuBtn) {
      this.els.mobileMenuBtn.addEventListener('click', () => this.openMobileSidebar());
    }
    if (this.els.btnCloseSidebar) {
      this.els.btnCloseSidebar.addEventListener('click', () => this.closeMobileSidebar());
    }
    if (this.els.mobileOverlay) {
      this.els.mobileOverlay.addEventListener('click', () => this.closeMobileSidebar());
    }

    // Demo Mode Toggles
    if (this.els.demoToggleCheckbox) {
      this.els.demoToggleCheckbox.addEventListener('change', (e) => {
        this.toggleDemoMode(e.target.checked);
      });
    }
    if (this.els.btnQuickDemo) {
      this.els.btnQuickDemo.addEventListener('click', () => this.toggleDemoMode(true));
    }
    if (this.els.btnQuickBle) {
      this.els.btnQuickBle.addEventListener('click', () => {
        this.switchTab('bluetooth');
      });
    }
    if (this.els.btnSimulateArousal) {
      this.els.btnSimulateArousal.addEventListener('click', () => {
        if (!this.isDemoMode) {
          this.showToast('Please enable Demo Mode first to simulate arousal response.', 'warn');
          return;
        }
        this.simulator.triggerSimulatedArousal(12);
        this.showToast('Simulating transient sympathetic arousal response (elevated GSR, suppressed RMSSD)...', 'info');
      });
    }

    // Session Control buttons
    if (this.els.btnStartSession) {
      this.els.btnStartSession.addEventListener('click', () => {
        const participant = this.storage.getActiveParticipant();
        this.sessionManager.startSession(participant.id);
        this.showToast(`Started recording session for ${participant.id}`, 'success');
      });
    }
    if (this.els.btnPauseSession) {
      this.els.btnPauseSession.addEventListener('click', () => {
        if (this.sessionManager.state === SESSION_STATES.RECORDING) {
          this.sessionManager.pauseSession();
          this.showToast('Session paused.', 'info');
        } else {
          this.sessionManager.resumeSession();
          this.showToast('Session resumed.', 'info');
        }
      });
    }
    if (this.els.btnStopSession) {
      this.els.btnStopSession.addEventListener('click', () => {
        const finished = this.sessionManager.stopSession();
        if (finished) {
          this.showToast(`Saved session ${finished.sessionId} with ${finished.stats.totalSamples} points.`, 'success');
          this.exportView.render();
        }
      });
    }

    // BLE Connect / Disconnect buttons
    if (this.els.btnConnectBle) {
      this.els.btnConnectBle.addEventListener('click', async () => {
        if (this.isDemoMode) {
          this.toggleDemoMode(false);
        }
        try {
          await this.bleService.connect();
        } catch (e) {
          this.showToast(`Bluetooth: ${e.message}`, 'error');
        }
      });
    }
    if (this.els.btnDisconnectBle) {
      this.els.btnDisconnectBle.addEventListener('click', async () => {
        await this.bleService.disconnect();
        this.showToast('Bluetooth device disconnected.', 'info');
      });
    }
    if (this.els.btnClearBleLogs) {
      this.els.btnClearBleLogs.addEventListener('click', () => this.bleView.clearLogs());
    }

    // Global Participant Dropdown change
    if (this.els.participantSelect) {
      this.els.participantSelect.addEventListener('change', (e) => {
        const id = e.target.value;
        this.storage.setActiveParticipantId(id);
        this.participantView.render();
        this.updateSystemStatus();
        this.showToast(`Active participant set to: ${id}`, 'info');
      });
    }

    // New Participant Modal
    if (this.els.btnNewParticipant) {
      this.els.btnNewParticipant.addEventListener('click', () => {
        if (this.els.newPartModal) this.els.newPartModal.classList.remove('hidden');
      });
    }
    if (this.els.btnClosePartModal) {
      this.els.btnClosePartModal.addEventListener('click', () => {
        if (this.els.newPartModal) this.els.newPartModal.classList.add('hidden');
      });
    }
    if (this.els.formNewParticipant) {
      this.els.formNewParticipant.addEventListener('submit', (e) => {
        e.preventDefault();
        const data = {
          id: document.getElementById('partInputId').value.trim() || undefined,
          alias: document.getElementById('partInputAlias').value.trim(),
          age: parseInt(document.getElementById('partInputAge').value) || null,
          gender: document.getElementById('partInputGender').value,
          notes: document.getElementById('partInputNotes').value.trim()
        };
        this.participantView.saveNewParticipant(data);
        if (this.els.newPartModal) this.els.newPartModal.classList.add('hidden');
        this.els.formNewParticipant.reset();
        this.showToast(`Created participant profile: ${data.id || 'New'}`, 'success');
      });
    }

    // History Modal Close
    if (this.els.btnCloseHistoryModal) {
      this.els.btnCloseHistoryModal.addEventListener('click', () => {
        if (this.els.historyModal) this.els.historyModal.classList.add('hidden');
      });
    }
  }

  switchTab(tabId) {
    this.activeTab = tabId;

    // Update nav links
    this.els.navLinks.forEach(link => {
      if (link.getAttribute('data-tab') === tabId) {
        link.classList.add('active');
      } else {
        link.classList.remove('active');
      }
    });

    // Update panels
    this.els.tabPanels.forEach(panel => {
      if (panel.id === `tab-${tabId}`) {
        panel.classList.remove('hidden');
      } else {
        panel.classList.add('hidden');
      }
    });

    if (tabId === 'sessions') {
      this.exportView.render();
    } else if (tabId === 'participants') {
      this.participantView.render();
    }

    if (window.lucide) {
      window.lucide.createIcons();
    }
  }

  openMobileSidebar() {
    if (this.els.mobileSidebar) this.els.mobileSidebar.classList.remove('-translate-x-full');
    if (this.els.mobileOverlay) this.els.mobileOverlay.classList.remove('hidden');
  }

  closeMobileSidebar() {
    if (this.els.mobileSidebar) this.els.mobileSidebar.classList.add('-translate-x-full');
    if (this.els.mobileOverlay) this.els.mobileOverlay.classList.add('hidden');
  }

  toggleDemoMode(enable) {
    this.isDemoMode = enable;
    if (this.els.demoToggleCheckbox) {
      this.els.demoToggleCheckbox.checked = enable;
    }

    this.dashboardView.setDemoBannerVisible(enable);

    if (enable) {
      // Disconnect BLE if active to avoid mixing streams
      if (this.bleService.state === BLE_STATES.CONNECTED) {
        this.bleService.disconnect();
      }
      this.simulator.start(APP_CONFIG.STREAMING.SAMPLE_INTERVAL_MS);
      this.dashboardView.setDisconnectedState(false);
      this.showToast('DEMO MODE ENABLED: Streaming synthetic bio-signal data.', 'info');
    } else {
      this.simulator.stop();
      if (this.bleService.state !== BLE_STATES.CONNECTED) {
        this.dashboardView.setDisconnectedState(true);
      }
      this.showToast('Demo mode paused. Ready for physical ESP32 connection.', 'info');
    }

    this.updateSystemStatus();
  }

  handleTelemetryData(sample) {
    this.currentSample = sample;

    // 1. Chart feed
    this.chartManager.addLiveSample(sample);

    // 2. Session feed
    this.sessionManager.addSample(sample);

    // 3. Compute experimental autonomic arousal
    const arousalState = this.sessionManager.computeAutonomicArousal(sample);

    // 4. Update Dashboard cards
    const sessionStats = this.sessionManager.getSessionStats();
    this.dashboardView.updateLiveValues(sample, arousalState, sessionStats);

    // Hide disconnected placeholder once data flows
    this.dashboardView.setDisconnectedState(false);
  }

  handleBleStateChange(state, details) {
    this.bleView.updateState(state, details);

    if (state === BLE_STATES.CONNECTED) {
      this.showToast(`Connected to ESP32: ${details?.deviceName || 'Wearable'}`, 'success');
      this.dashboardView.setDisconnectedState(false);
      // Turn off demo mode if running
      if (this.isDemoMode) {
        this.toggleDemoMode(false);
      }
    } else if (state === BLE_STATES.DISCONNECTED) {
      if (!this.isDemoMode) {
        this.dashboardView.setDisconnectedState(true);
      }
    } else if (state === BLE_STATES.ERROR) {
      this.showToast(`Bluetooth Error: ${details}`, 'error');
    }

    this.updateSystemStatus();
  }

  updateSystemStatus() {
    const activePart = this.storage.getActiveParticipant();
    const stats = this.sessionManager.getSessionStats();
    this.dashboardView.updateSessionControls(this.sessionManager.state, stats, activePart);
  }

  seedSampleSessionIfEmpty() {
    const existing = this.storage.getSessions();
    if (existing.length === 0) {
      // Seed one realistic past baseline trial for immediate student evaluation
      const sampleStartTime = new Date(Date.now() - 3600000);
      const seedSession = {
        sessionId: 'SESS-TRIAL-01',
        participantId: 'PART-001',
        title: 'Initial Resting Baseline Calibration',
        startTime: sampleStartTime.toISOString(),
        endTime: new Date(sampleStartTime.getTime() + 180000).toISOString(),
        durationSeconds: 180,
        samples: [],
        stats: {
          totalSamples: 180,
          hr: { min: 66, max: 82, avg: 72, sum: 12960 },
          hrv: { min: 38, max: 62, avg: 49, sum: 8820 },
          spo2: { min: 97.4, max: 99.1, avg: 98.3, sum: 17694 },
          gsr: { min: 3.4, max: 5.8, avg: 4.2, sum: 756 }
        }
      };

      // Generate 180 smooth samples for history chart preview
      for (let i = 0; i < 180; i++) {
        const t = i * 0.1;
        const hr = Math.round(72 + Math.sin(t * 1.5) * 4 + Math.sin(t * 0.6) * 2);
        const hrv = Math.round(49 + Math.cos(t * 1.2) * 6);
        const spo2 = parseFloat((98.3 + Math.sin(t * 0.3) * 0.4).toFixed(1));
        const gsr = parseFloat((4.2 + Math.sin(t * 0.1) * 0.6).toFixed(2));

        seedSession.samples.push({
          timestamp: new Date(sampleStartTime.getTime() + i * 1000).toISOString(),
          timestampLocal: new Date(sampleStartTime.getTime() + i * 1000).toLocaleTimeString(),
          hr,
          hrv,
          spo2,
          gsr,
          source: 'DEMO'
        });
      }

      this.storage.saveCompletedSession(seedSession);
    }
  }

  showToast(message, type = 'info') {
    if (!this.els.toastContainer) return;

    const toast = document.createElement('div');
    const colorClass =
      type === 'success' ? 'border-emerald-500/50 bg-emerald-950/90 text-emerald-200' :
      type === 'error' ? 'border-rose-500/50 bg-rose-950/90 text-rose-200' :
      type === 'warn' ? 'border-amber-500/50 bg-amber-950/90 text-amber-200' :
      'border-cyan-500/50 bg-slate-900/95 text-cyan-200';

    toast.className = `flex items-center px-4 py-3 rounded-lg border shadow-xl backdrop-blur-md text-sm toast-in transition-all ${colorClass}`;
    toast.innerHTML = `
      <div class="mr-2">
        ${type === 'success' ? '✓' : type === 'error' ? '✕' : type === 'warn' ? '⚠️' : 'ℹ'}
      </div>
      <div class="flex-1 font-medium">${message}</div>
    `;

    this.els.toastContainer.appendChild(toast);

    setTimeout(() => {
      toast.style.opacity = '0';
      toast.style.transform = 'translateY(10px)';
      setTimeout(() => toast.remove(), 300);
    }, 4000);
  }
}

// Instantiate and expose globally
window.addEventListener('DOMContentLoaded', () => {
  window.emotiGuardApp = new EmotiGuardApp();
  window.emotiGuardApp.init();
});
