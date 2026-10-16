/**
 * EmotiGuard Bluetooth Low Energy UI View
 * Manages ESP32 connection dashboard, live GATT telemetry log,
 * and diagnostic troubleshooting helpers.
 */

import { BLE_STATES } from '../services/bluetoothService.js';
import { APP_CONFIG } from '../config.js';

export class BleView {
  constructor(elements, bleService) {
    this.els = elements;
    this.bleService = bleService;
    this.logMessages = [];
  }

  init() {
    this.checkBrowserCompatibility();
  }

  checkBrowserCompatibility() {
    const support = this.bleService.getSupportDetails();
    if (!support.supported) {
      if (this.els.bleSupportBanner) {
        this.els.bleSupportBanner.classList.remove('hidden');
        this.els.bleSupportBannerText.textContent = support.message;
      }
      if (this.els.btnConnectBle) {
        this.els.btnConnectBle.disabled = true;
        this.els.btnConnectBle.classList.add('opacity-50', 'cursor-not-allowed');
      }
    } else {
      if (this.els.bleSupportBanner) {
        this.els.bleSupportBanner.classList.add('hidden');
      }
    }
  }

  updateState(state, details) {
    const statusTextEl = this.els.bleStatusText;
    const statusBadgeEl = this.els.bleStatusBadge;
    const btnConnect = this.els.btnConnectBle;
    const btnDisconnect = this.els.btnDisconnectBle;

    if (state === BLE_STATES.CONNECTED) {
      if (statusTextEl) statusTextEl.textContent = `Connected: ${details?.deviceName || 'ESP32'}`;
      if (statusBadgeEl) {
        statusBadgeEl.textContent = 'CONNECTED';
        statusBadgeEl.className = 'px-3 py-1 text-xs font-semibold rounded-full bg-emerald-500/20 text-emerald-400 border border-emerald-500/30';
      }
      if (btnConnect) btnConnect.classList.add('hidden');
      if (btnDisconnect) btnDisconnect.classList.remove('hidden');

      if (this.els.bleDeviceInfoCard) {
        this.els.bleDeviceInfoCard.classList.remove('hidden');
        if (this.els.bleDeviceName) this.els.bleDeviceName.textContent = details?.deviceName || 'EmotiGuard Wearable';
        if (this.els.bleDeviceId) this.els.bleDeviceId.textContent = details?.deviceId || 'ESP32-GATT';
      }
    } else if (state === BLE_STATES.CONNECTING) {
      if (statusTextEl) statusTextEl.textContent = 'Establishing GATT Handshake...';
      if (statusBadgeEl) {
        statusBadgeEl.textContent = 'CONNECTING';
        statusBadgeEl.className = 'px-3 py-1 text-xs font-semibold rounded-full bg-cyan-500/20 text-cyan-400 border border-cyan-500/30 animate-pulse';
      }
    } else if (state === BLE_STATES.SCANNING) {
      if (statusTextEl) statusTextEl.textContent = 'Scanning for Bluetooth Peripherals...';
      if (statusBadgeEl) {
        statusBadgeEl.textContent = 'SCANNING';
        statusBadgeEl.className = 'px-3 py-1 text-xs font-semibold rounded-full bg-blue-500/20 text-blue-400 border border-blue-500/30 animate-pulse';
      }
    } else if (state === BLE_STATES.ERROR) {
      if (statusTextEl) statusTextEl.textContent = `Connection Error: ${details || 'Unknown issue'}`;
      if (statusBadgeEl) {
        statusBadgeEl.textContent = 'ERROR';
        statusBadgeEl.className = 'px-3 py-1 text-xs font-semibold rounded-full bg-rose-500/20 text-rose-400 border border-rose-500/30';
      }
      if (btnConnect) {
        btnConnect.classList.remove('hidden');
        btnConnect.disabled = false;
        btnConnect.classList.remove('opacity-50', 'cursor-not-allowed');
      }
      if (btnDisconnect) btnDisconnect.classList.add('hidden');
    } else {
      // DISCONNECTED
      if (statusTextEl) statusTextEl.textContent = 'ESP32 Device Disconnected';
      if (statusBadgeEl) {
        statusBadgeEl.textContent = 'DISCONNECTED';
        statusBadgeEl.className = 'px-3 py-1 text-xs font-semibold rounded-full bg-slate-500/20 text-slate-400 border border-slate-500/30';
      }
      if (btnConnect) {
        btnConnect.classList.remove('hidden');
        btnConnect.disabled = false;
        btnConnect.classList.remove('opacity-50', 'cursor-not-allowed');
      }
      if (btnDisconnect) btnDisconnect.classList.add('hidden');
      if (this.els.bleDeviceInfoCard) this.els.bleDeviceInfoCard.classList.add('hidden');
    }
  }

  appendLog(message, type = 'info') {
    this.logMessages.push({ message, type });
    if (this.logMessages.length > 50) this.logMessages.shift();

    if (this.els.bleLogContainer) {
      const line = document.createElement('div');
      line.className = `py-0.5 text-xs font-mono ${
        type === 'error' ? 'text-rose-400' :
        type === 'warn' ? 'text-amber-400' :
        type === 'success' ? 'text-emerald-400' : 'text-slate-300'
      }`;
      line.textContent = message;
      this.els.bleLogContainer.appendChild(line);
      this.els.bleLogContainer.scrollTop = this.els.bleLogContainer.scrollHeight;
    }
  }

  clearLogs() {
    this.logMessages = [];
    if (this.els.bleLogContainer) {
      this.els.bleLogContainer.innerHTML = '<div class="text-xs text-slate-500 italic py-1">Console logs cleared. Ready for next Bluetooth event.</div>';
    }
  }
}
