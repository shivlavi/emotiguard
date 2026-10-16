/**
 * EmotiGuard Dashboard View Controller
 * Handles sensor card updates, autonomic arousal gauge, demo alerts,
 * and session control buttons.
 */

import { APP_CONFIG } from '../config.js';

export class DashboardView {
  constructor(elements) {
    this.els = elements;
  }

  updateLiveValues(sample, arousalState, sessionStats) {
    if (!sample) return;

    // 1. Heart Rate Card
    if (this.els.hrVal) {
      this.els.hrVal.textContent = sample.hr;
      if (this.els.hrMin) this.els.hrMin.textContent = sessionStats.hr.min || '--';
      if (this.els.hrMax) this.els.hrMax.textContent = sessionStats.hr.max || '--';
      if (this.els.hrAvg) this.els.hrAvg.textContent = sessionStats.hr.avg || '--';
    }

    // 2. HRV Card
    if (this.els.hrvVal) {
      this.els.hrvVal.textContent = sample.hrv;
      if (this.els.hrvMin) this.els.hrvMin.textContent = sessionStats.hrv.min || '--';
      if (this.els.hrvMax) this.els.hrvMax.textContent = sessionStats.hrv.max || '--';
      if (this.els.hrvAvg) this.els.hrvAvg.textContent = sessionStats.hrv.avg || '--';
    }

    // 3. SpO2 Card
    if (this.els.spo2Val) {
      this.els.spo2Val.textContent = sample.spo2.toFixed(1);
      if (this.els.spo2Min) this.els.spo2Min.textContent = sessionStats.spo2.min || '--';
      if (this.els.spo2Max) this.els.spo2Max.textContent = sessionStats.spo2.max || '--';
      if (this.els.spo2Avg) this.els.spo2Avg.textContent = sessionStats.spo2.avg || '--';
    }

    // 4. GSR / Skin Conductance Card
    if (this.els.gsrVal) {
      this.els.gsrVal.textContent = sample.gsr.toFixed(2);
      if (this.els.gsrMin) this.els.gsrMin.textContent = sessionStats.gsr.min || '--';
      if (this.els.gsrMax) this.els.gsrMax.textContent = sessionStats.gsr.max || '--';
      if (this.els.gsrAvg) this.els.gsrAvg.textContent = sessionStats.gsr.avg || '--';
    }

    // 5. Autonomic Arousal Gauge / Widget
    if (arousalState && this.els.arousalScore) {
      this.els.arousalScore.textContent = `${arousalState.score}/100`;
      if (this.els.arousalBar) {
        this.els.arousalBar.style.width = `${arousalState.score}%`;
        this.els.arousalBar.style.backgroundColor = arousalState.color;
      }
      if (this.els.arousalBadge) {
        this.els.arousalBadge.textContent = arousalState.badge;
        this.els.arousalBadge.style.color = arousalState.color;
        this.els.arousalBadge.style.borderColor = arousalState.color;
      }
      if (this.els.arousalLevel) {
        this.els.arousalLevel.textContent = arousalState.level;
      }
      if (this.els.arousalDesc) {
        this.els.arousalDesc.textContent = arousalState.description;
      }
    }

    // 6. Source tag
    if (this.els.telemetrySourceTag) {
      if (sample.source === 'DEMO') {
        this.els.telemetrySourceTag.textContent = 'DEMO STREAM';
        this.els.telemetrySourceTag.className = 'text-xs px-2.5 py-0.5 rounded-full font-semibold bg-amber-500/10 text-amber-400 border border-amber-500/30';
      } else {
        this.els.telemetrySourceTag.textContent = 'ESP32 BLE LIVE';
        this.els.telemetrySourceTag.className = 'text-xs px-2.5 py-0.5 rounded-full font-semibold bg-cyan-500/10 text-cyan-400 border border-cyan-500/30';
      }
    }
  }

  updateSessionControls(sessionState, stats, activeParticipant) {
    if (this.els.sessionTimer) {
      this.els.sessionTimer.textContent = stats.durationFormatted;
    }
    if (this.els.sampleCountBadge) {
      this.els.sampleCountBadge.textContent = `${stats.sampleCount} pts`;
    }
    if (this.els.activeParticipantBadge && activeParticipant) {
      this.els.activeParticipantBadge.textContent = `${activeParticipant.id} (${activeParticipant.alias || 'Profile'})`;
    }

    // Toggle button visibility based on session state
    if (sessionState === 'RECORDING') {
      if (this.els.btnStartSession) this.els.btnStartSession.classList.add('hidden');
      if (this.els.btnPauseSession) {
        this.els.btnPauseSession.classList.remove('hidden');
        this.els.btnPauseSession.innerHTML = `<i data-lucide="pause" class="w-4 h-4 mr-1.5 inline"></i> Pause`;
      }
      if (this.els.btnStopSession) this.els.btnStopSession.classList.remove('hidden');
      if (this.els.sessionIndicator) {
        this.els.sessionIndicator.className = 'w-2.5 h-2.5 rounded-full bg-emerald-400 animate-pulse mr-2';
      }
      if (this.els.sessionStatusText) {
        this.els.sessionStatusText.textContent = 'Recording Active';
        this.els.sessionStatusText.className = 'text-xs font-semibold text-emerald-400';
      }
    } else if (sessionState === 'PAUSED') {
      if (this.els.btnStartSession) this.els.btnStartSession.classList.add('hidden');
      if (this.els.btnPauseSession) {
        this.els.btnPauseSession.classList.remove('hidden');
        this.els.btnPauseSession.innerHTML = `<i data-lucide="play" class="w-4 h-4 mr-1.5 inline"></i> Resume`;
      }
      if (this.els.btnStopSession) this.els.btnStopSession.classList.remove('hidden');
      if (this.els.sessionIndicator) {
        this.els.sessionIndicator.className = 'w-2.5 h-2.5 rounded-full bg-amber-400 mr-2';
      }
      if (this.els.sessionStatusText) {
        this.els.sessionStatusText.textContent = 'Recording Paused';
        this.els.sessionStatusText.className = 'text-xs font-semibold text-amber-400';
      }
    } else {
      // IDLE
      if (this.els.btnStartSession) this.els.btnStartSession.classList.remove('hidden');
      if (this.els.btnPauseSession) this.els.btnPauseSession.classList.add('hidden');
      if (this.els.btnStopSession) this.els.btnStopSession.classList.add('hidden');
      if (this.els.sessionIndicator) {
        this.els.sessionIndicator.className = 'w-2.5 h-2.5 rounded-full bg-slate-500 mr-2';
      }
      if (this.els.sessionStatusText) {
        this.els.sessionStatusText.textContent = 'Session Standby';
        this.els.sessionStatusText.className = 'text-xs font-semibold text-slate-400';
      }
    }

    if (window.lucide) window.lucide.createIcons();
  }

  setDemoBannerVisible(visible) {
    if (this.els.demoBanner) {
      if (visible) {
        this.els.demoBanner.classList.remove('hidden');
      } else {
        this.els.demoBanner.classList.add('hidden');
      }
    }
  }

  setDisconnectedState(isDisconnected) {
    if (this.els.disconnectedAlert) {
      if (isDisconnected) {
        this.els.disconnectedAlert.classList.remove('hidden');
      } else {
        this.els.disconnectedAlert.classList.add('hidden');
      }
    }
  }
}
