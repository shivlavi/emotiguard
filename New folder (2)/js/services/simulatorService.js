/**
 * EmotiGuard Synthetic Bio-Signal Simulator (Demo Mode)
 * Provides realistic physiological telemetry for testing and verification
 * without requiring active ESP32 hardware.
 * 
 * NOTE: All generated data packets are explicitly tagged source: 'DEMO'
 * to strictly prevent confounding synthetic values with real clinical sensor inputs.
 */

export class SimulatorService {
  constructor(onDataCallback) {
    this.onData = onDataCallback;
    this.timerId = null;
    this.isRunning = false;
    this.tickCount = 0;

    // Physiological baseline state
    this.baselineHR = 72;
    this.baselineHRV = 48;
    this.baselineSpO2 = 98.2;
    this.baselineGSR = 4.2;

    // Phasic arousal state (simulating transient sympathetic stimulation)
    this.arousalActive = false;
    this.arousalIntensity = 0.0;
  }

  start(intervalMs = 1000) {
    if (this.isRunning) return;
    this.isRunning = true;
    this.tickCount = 0;

    this.timerId = setInterval(() => {
      this.generateSample();
    }, intervalMs);

    // Generate initial point immediately
    this.generateSample();
  }

  stop() {
    if (this.timerId) {
      clearInterval(this.timerId);
      this.timerId = null;
    }
    this.isRunning = false;
  }

  /**
   * Triggers a temporary simulated autonomic activation (e.g. cognitive load or startle response)
   * This temporarily raises GSR and HR while suppressing HRV RMSSD.
   */
  triggerSimulatedArousal(durationSeconds = 15) {
    this.arousalActive = true;
    this.arousalIntensity = 1.0;

    let elapsed = 0;
    const decayInterval = setInterval(() => {
      elapsed += 1;
      this.arousalIntensity = Math.max(0, 1.0 - (elapsed / durationSeconds));
      if (elapsed >= durationSeconds) {
        clearInterval(decayInterval);
        this.arousalActive = false;
        this.arousalIntensity = 0.0;
      }
    }, 1000);
  }

  generateSample() {
    this.tickCount++;
    const t = this.tickCount * 0.1;

    // Biological rhythm modulations:
    // Respiratory Sinus Arrhythmia (RSA ~ 0.25 Hz, approx 12-16 breaths/min)
    const rsaEffect = Math.sin(t * 1.5) * 3.5;
    
    // Slow vasomotor waves (Mayer wave ~ 0.1 Hz)
    const mayerWave = Math.sin(t * 0.6) * 1.8;

    // Sympathetic arousal boost
    const hrArousalBoost = this.arousalIntensity * 22; // Up to +22 BPM under peak arousal
    const hrvSuppression = this.arousalIntensity * 24; // Suppressed RMSSD
    const gsrArousalBoost = this.arousalIntensity * 6.5; // Sharp rise in skin conductance

    // Heart Rate (BPM)
    const rawHR = this.baselineHR + rsaEffect + mayerWave + hrArousalBoost + (Math.random() * 1.2 - 0.6);
    const hr = Math.round(Math.min(160, Math.max(50, rawHR)));

    // HRV RMSSD (ms) - inversely correlated with acute sympathetic arousal
    const rawHRV = this.baselineHRV - hrvSuppression + (Math.sin(t * 0.8) * 6) + (Math.random() * 3 - 1.5);
    const hrv = Math.round(Math.min(120, Math.max(12, rawHRV)));

    // SpO2 (%) - healthy saturation with subtle 0.2% natural drift
    const rawSpO2 = this.baselineSpO2 + (Math.sin(t * 0.2) * 0.4) - (this.arousalIntensity * 0.3) + (Math.random() * 0.2 - 0.1);
    const spo2 = Math.min(100, Math.max(92, parseFloat(rawSpO2.toFixed(1))));

    // GSR / Skin Conductance (µS) - tonic drift + transient phasic spikes
    const tonicGSR = this.baselineGSR + (Math.sin(t * 0.08) * 0.4);
    const phasicNoise = Math.abs(Math.sin(t * 0.4)) * 0.3;
    const rawGSR = tonicGSR + phasicNoise + gsrArousalBoost;
    const gsr = parseFloat(Math.max(0.5, rawGSR).toFixed(2));

    const sample = {
      timestamp: new Date().toISOString(),
      timestampLocal: new Date().toLocaleTimeString(),
      hr,
      hrv,
      spo2,
      gsr,
      source: 'DEMO',
      arousalSimulationActive: this.arousalActive
    };

    if (this.onData) {
      this.onData(sample);
    }

    return sample;
  }
}
