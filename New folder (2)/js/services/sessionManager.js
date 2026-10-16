/**
 * EmotiGuard Session Manager & Physiological Metrics Engine
 * Coordinates active recording sessions, real-time statistics,
 * and academic autonomic arousal trend calculations.
 */

import { APP_CONFIG } from '../config.js';

export const SESSION_STATES = {
  IDLE: 'IDLE',
  RECORDING: 'RECORDING',
  PAUSED: 'PAUSED',
  COMPLETED: 'COMPLETED'
};

export class SessionManager {
  constructor(storageService) {
    this.storage = storageService;
    this.state = SESSION_STATES.IDLE;
    this.currentSession = null;
    this.timerInterval = null;
    this.elapsedSeconds = 0;
    this.onUpdateCallbacks = [];
    
    // Baseline tracker for autonomic arousal calculation
    this.recentGSRBuffer = [];
    this.recentHRVBuffer = [];
  }

  onUpdate(callback) {
    this.onUpdateCallbacks.push(callback);
  }

  notifyUpdate() {
    const summary = this.getSessionStats();
    for (const cb of this.onUpdateCallbacks) {
      cb(this.state, summary);
    }
  }

  startSession(participantId, sessionTitle = '') {
    if (this.state === SESSION_STATES.RECORDING) return;

    const sessionId = 'SESS-' + Date.now().toString(36).toUpperCase();
    const now = new Date();

    this.currentSession = {
      sessionId,
      participantId: participantId || this.storage.getActiveParticipantId(),
      title: sessionTitle || `Session ${new Date().toLocaleDateString()}`,
      startTime: now.toISOString(),
      endTime: null,
      samples: [],
      stats: {
        hr: { min: Infinity, max: -Infinity, avg: 0, sum: 0 },
        hrv: { min: Infinity, max: -Infinity, avg: 0, sum: 0 },
        spo2: { min: Infinity, max: -Infinity, avg: 0, sum: 0 },
        gsr: { min: Infinity, max: -Infinity, avg: 0, sum: 0 },
        totalSamples: 0
      }
    };

    this.elapsedSeconds = 0;
    this.state = SESSION_STATES.RECORDING;

    this.startClock();
    this.notifyUpdate();
    return this.currentSession;
  }

  pauseSession() {
    if (this.state === SESSION_STATES.RECORDING) {
      this.state = SESSION_STATES.PAUSED;
      this.stopClock();
      this.notifyUpdate();
    }
  }

  resumeSession() {
    if (this.state === SESSION_STATES.PAUSED) {
      this.state = SESSION_STATES.RECORDING;
      this.startClock();
      this.notifyUpdate();
    }
  }

  stopSession() {
    if (this.state === SESSION_STATES.IDLE) return null;

    this.stopClock();
    const session = this.currentSession;
    if (session) {
      session.endTime = new Date().toISOString();
      session.durationSeconds = this.elapsedSeconds;
      
      // Finalize averages
      if (session.stats.totalSamples > 0) {
        const n = session.stats.totalSamples;
        session.stats.hr.avg = Math.round(session.stats.hr.sum / n);
        session.stats.hrv.avg = Math.round(session.stats.hrv.sum / n);
        session.stats.spo2.avg = parseFloat((session.stats.spo2.sum / n).toFixed(1));
        session.stats.gsr.avg = parseFloat((session.stats.gsr.sum / n).toFixed(2));
      } else {
        session.stats.hr.min = 0;
        session.stats.hr.max = 0;
        session.stats.hrv.min = 0;
        session.stats.hrv.max = 0;
        session.stats.spo2.min = 0;
        session.stats.spo2.max = 0;
        session.stats.gsr.min = 0;
        session.stats.gsr.max = 0;
      }

      this.storage.saveCompletedSession(session);
    }

    this.state = SESSION_STATES.IDLE;
    const completedSession = this.currentSession;
    this.currentSession = null;
    this.elapsedSeconds = 0;
    this.notifyUpdate();

    return completedSession;
  }

  startClock() {
    this.stopClock();
    this.timerInterval = setInterval(() => {
      this.elapsedSeconds++;
      this.notifyUpdate();
    }, 1000);
  }

  stopClock() {
    if (this.timerInterval) {
      clearInterval(this.timerInterval);
      this.timerInterval = null;
    }
  }

  /**
   * Appends incoming real-time sensor point into active session
   */
  addSample(sample) {
    // Keep rolling buffer for autonomic arousal calculation even outside recorded sessions
    this.recentGSRBuffer.push(sample.gsr);
    if (this.recentGSRBuffer.length > 30) this.recentGSRBuffer.shift();

    this.recentHRVBuffer.push(sample.hrv);
    if (this.recentHRVBuffer.length > 30) this.recentHRVBuffer.shift();

    if (this.state !== SESSION_STATES.RECORDING || !this.currentSession) {
      return;
    }

    this.currentSession.samples.push(sample);
    const stats = this.currentSession.stats;
    stats.totalSamples++;

    // Update HR
    stats.hr.min = Math.min(stats.hr.min, sample.hr);
    stats.hr.max = Math.max(stats.hr.max, sample.hr);
    stats.hr.sum += sample.hr;

    // Update HRV
    stats.hrv.min = Math.min(stats.hrv.min, sample.hrv);
    stats.hrv.max = Math.max(stats.hrv.max, sample.hrv);
    stats.hrv.sum += sample.hrv;

    // Update SpO2
    stats.spo2.min = Math.min(stats.spo2.min, sample.spo2);
    stats.spo2.max = Math.max(stats.spo2.max, sample.spo2);
    stats.spo2.sum += sample.spo2;

    // Update GSR
    stats.gsr.min = Math.min(stats.gsr.min, sample.gsr);
    stats.gsr.max = Math.max(stats.gsr.max, sample.gsr);
    stats.gsr.sum += sample.gsr;

    this.notifyUpdate();
  }

  /**
   * Calculates an experimental physiological arousal estimate based on
   * autonomic nervous system markers: electrodermal skin conductance (GSR)
   * and cardiac vagal tone (HRV RMSSD).
   * 
   * NOTE: Strictly for research / academic demonstration.
   * Does not diagnose emotions or psychiatric states.
   */
  computeAutonomicArousal(currentSample) {
    if (!currentSample) {
      return {
        level: 'Standby',
        score: 0,
        color: '#64748B',
        badge: 'No Data',
        description: 'Awaiting physiological sensor inputs...'
      };
    }

    const gsr = currentSample.gsr;
    const hrv = currentSample.hrv;
    const hr = currentSample.hr;

    // Calculate baseline drift from buffer
    const avgGSR = this.recentGSRBuffer.length > 0 
      ? this.recentGSRBuffer.reduce((a, b) => a + b, 0) / this.recentGSRBuffer.length 
      : gsr;

    // High arousal = High GSR + Elevated HR + Low HRV RMSSD
    // Low arousal / relaxed = Lower GSR + Moderate HR + High HRV RMSSD
    const gsrRatio = Math.min(2.5, Math.max(0.4, gsr / (avgGSR || 4.0)));
    const hrvInverted = Math.max(0, 1 - (hrv / 80)); // 0 when HRV high, 1 when HRV low
    const hrContribution = Math.min(1, Math.max(0, (hr - 65) / 45));

    // Weighted physiological arousal index (0 to 100)
    let score = Math.round((gsrRatio * 40) + (hrvInverted * 35) + (hrContribution * 25));
    score = Math.max(5, Math.min(98, score));

    if (score < 40) {
      return {
        score,
        level: 'Baseline / Restful Autonomic State',
        color: '#10B981', // Emerald
        badge: 'Low Reactivity',
        description: 'Vagal parasympathetic dominance; stable electrodermal response.'
      };
    } else if (score < 70) {
      return {
        score,
        level: 'Moderate Autonomic Tone',
        color: '#F59E0B', // Amber
        badge: 'Moderate Reactivity',
        description: 'Balanced autonomic activity; mild sympathetic innervation.'
      };
    } else {
      return {
        score,
        level: 'Elevated Autonomic Response',
        color: '#F43F5E', // Rose/Violet
        badge: 'Elevated Reactivity',
        description: 'Prominent sympathetic activation (elevated EDA and vagal withdrawal).'
      };
    }
  }

  getSessionStats() {
    if (!this.currentSession) {
      return {
        isActive: false,
        durationFormatted: '00:00:00',
        sampleCount: 0,
        hr: { current: 0, min: 0, max: 0, avg: 0 },
        hrv: { current: 0, min: 0, max: 0, avg: 0 },
        spo2: { current: 0, min: 0, max: 0, avg: 0 },
        gsr: { current: 0, min: 0, max: 0, avg: 0 }
      };
    }

    const stats = this.currentSession.stats;
    const n = stats.totalSamples;

    return {
      isActive: this.state === SESSION_STATES.RECORDING,
      isPaused: this.state === SESSION_STATES.PAUSED,
      sessionId: this.currentSession.sessionId,
      participantId: this.currentSession.participantId,
      elapsedSeconds: this.elapsedSeconds,
      durationFormatted: this.formatTime(this.elapsedSeconds),
      sampleCount: n,
      hr: {
        min: n > 0 && stats.hr.min !== Infinity ? stats.hr.min : 0,
        max: n > 0 && stats.hr.max !== -Infinity ? stats.hr.max : 0,
        avg: n > 0 ? Math.round(stats.hr.sum / n) : 0
      },
      hrv: {
        min: n > 0 && stats.hrv.min !== Infinity ? stats.hrv.min : 0,
        max: n > 0 && stats.hrv.max !== -Infinity ? stats.hrv.max : 0,
        avg: n > 0 ? Math.round(stats.hrv.sum / n) : 0
      },
      spo2: {
        min: n > 0 && stats.spo2.min !== Infinity ? stats.spo2.min : 0,
        max: n > 0 && stats.spo2.max !== -Infinity ? stats.spo2.max : 0,
        avg: n > 0 ? parseFloat((stats.spo2.sum / n).toFixed(1)) : 0
      },
      gsr: {
        min: n > 0 && stats.gsr.min !== Infinity ? stats.gsr.min : 0,
        max: n > 0 && stats.gsr.max !== -Infinity ? stats.gsr.max : 0,
        avg: n > 0 ? parseFloat((stats.gsr.sum / n).toFixed(2)) : 0
      }
    };
  }

  formatTime(totalSeconds) {
    const hrs = String(Math.floor(totalSeconds / 3600)).padStart(2, '0');
    const mins = String(Math.floor((totalSeconds % 3600) / 60)).padStart(2, '0');
    const secs = String(totalSeconds % 60).padStart(2, '0');
    return `${hrs}:${mins}:${secs}`;
  }
}
