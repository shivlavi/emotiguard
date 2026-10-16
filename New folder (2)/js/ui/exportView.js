/**
 * EmotiGuard Export & Session History View Controller
 * Generates standards-compliant CSV exports and manages historical telemetry records.
 */

export class ExportView {
  constructor(elements, storageService, chartManager) {
    this.els = elements;
    this.storage = storageService;
    this.chartManager = chartManager;
  }

  render() {
    const sessions = this.storage.getSessions();
    if (!this.els.sessionHistoryTableBody) return;

    if (sessions.length === 0) {
      this.els.sessionHistoryTableBody.innerHTML = `
        <tr>
          <td colspan="7" class="py-8 text-center text-slate-500 italic">
            No recorded sessions found yet. Start a session from the Dashboard to record physiological telemetry.
          </td>
        </tr>
      `;
      return;
    }

    this.els.sessionHistoryTableBody.innerHTML = '';

    sessions.forEach(sess => {
      const stats = sess.stats || {};
      const durationFormatted = this.formatDuration(sess.durationSeconds || 0);
      const dateFormatted = new Date(sess.startTime).toLocaleString();

      const row = document.createElement('tr');
      row.className = 'border-b border-slate-800/80 hover:bg-slate-800/30 transition-colors text-sm';
      
      row.innerHTML = `
        <td class="py-3 px-4 font-mono font-medium text-cyan-400">${sess.sessionId}</td>
        <td class="py-3 px-4 font-mono text-slate-300">${sess.participantId}</td>
        <td class="py-3 px-4 text-slate-300">${dateFormatted}</td>
        <td class="py-3 px-4 text-slate-400 font-mono">${durationFormatted} (${sess.samples ? sess.samples.length : 0} pts)</td>
        <td class="py-3 px-4">
          <div class="flex items-center space-x-2 text-xs">
            <span class="text-rose-400 font-mono" title="Avg HR">${stats.hr?.avg || '--'} BPM</span>
            <span class="text-slate-600">|</span>
            <span class="text-purple-400 font-mono" title="Avg HRV">${stats.hrv?.avg || '--'} ms</span>
            <span class="text-slate-600">|</span>
            <span class="text-cyan-400 font-mono" title="Avg GSR">${stats.gsr?.avg || '--'} µS</span>
          </div>
        </td>
        <td class="py-3 px-4 text-right space-x-2">
          <button data-view-id="${sess.sessionId}" class="btn-view-sess px-2.5 py-1 text-xs rounded bg-slate-800 hover:bg-slate-700 text-slate-200 border border-slate-700 transition-colors inline-flex items-center">
            <i data-lucide="line-chart" class="w-3.5 h-3.5 mr-1 inline"></i> Graph
          </button>
          <button data-export-id="${sess.sessionId}" class="btn-export-sess px-2.5 py-1 text-xs rounded bg-cyan-950/80 hover:bg-cyan-900 text-cyan-300 border border-cyan-500/30 transition-colors inline-flex items-center">
            <i data-lucide="download" class="w-3.5 h-3.5 mr-1 inline"></i> CSV
          </button>
          <button data-del-id="${sess.sessionId}" class="btn-del-sess px-2 py-1 text-xs rounded bg-rose-950/40 hover:bg-rose-900/60 text-rose-400 border border-rose-500/20 transition-colors">
            <i data-lucide="trash-2" class="w-3.5 h-3.5 inline"></i>
          </button>
        </td>
      `;
      this.els.sessionHistoryTableBody.appendChild(row);
    });

    // Bind action listeners
    this.els.sessionHistoryTableBody.querySelectorAll('.btn-export-sess').forEach(btn => {
      btn.addEventListener('click', (e) => {
        const id = e.currentTarget.getAttribute('data-export-id');
        this.exportSessionToCSV(id);
      });
    });

    this.els.sessionHistoryTableBody.querySelectorAll('.btn-view-sess').forEach(btn => {
      btn.addEventListener('click', (e) => {
        const id = e.currentTarget.getAttribute('data-view-id');
        this.openHistoricalGraphModal(id);
      });
    });

    this.els.sessionHistoryTableBody.querySelectorAll('.btn-del-sess').forEach(btn => {
      btn.addEventListener('click', (e) => {
        const id = e.currentTarget.getAttribute('data-del-id');
        if (confirm(`Are you sure you want to delete session record ${id}?`)) {
          this.storage.deleteSession(id);
          this.render();
        }
      });
    });

    if (window.lucide) window.lucide.createIcons();
  }

  formatDuration(sec) {
    const mins = Math.floor(sec / 60);
    const secs = sec % 60;
    return `${mins}m ${secs}s`;
  }

  exportSessionToCSV(sessionId) {
    const session = this.storage.getSessionById(sessionId);
    if (!session || !session.samples || session.samples.length === 0) {
      alert(`Session ${sessionId} has no recorded data points to export.`);
      return;
    }

    const headers = [
      'Timestamp_ISO',
      'Timestamp_Local',
      'Participant_ID',
      'Session_ID',
      'Heart_Rate_BPM',
      'HRV_RMSSD_ms',
      'SpO2_Percent',
      'Skin_Conductance_uS',
      'Telemetry_Source'
    ];

    const rows = session.samples.map(s => [
      `"${s.timestamp || ''}"`,
      `"${s.timestampLocal || ''}"`,
      `"${session.participantId}"`,
      `"${session.sessionId}"`,
      s.hr,
      s.hrv,
      s.spo2,
      s.gsr,
      `"${s.source || 'UNKNOWN'}"`
    ]);

    const csvContent = [headers.join(','), ...rows.map(r => r.join(','))].join('\r\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);

    const link = document.createElement('a');
    link.setAttribute('href', url);
    const sanitizedTitle = (session.title || 'Session').replace(/[^a-zA-Z0-9_-]/g, '_');
    link.setAttribute('download', `EmotiGuard_${session.participantId}_${session.sessionId}_${sanitizedTitle}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
  }

  openHistoricalGraphModal(sessionId) {
    const session = this.storage.getSessionById(sessionId);
    if (!session) return;

    if (this.els.historyModal) {
      this.els.historyModal.classList.remove('hidden');
      if (this.els.historyModalTitle) {
        this.els.historyModalTitle.textContent = `${session.title || 'Session Analysis'} (${session.sessionId})`;
      }
      if (this.els.historyModalMeta) {
        this.els.historyModalMeta.textContent = `Participant: ${session.participantId} • Duration: ${this.formatDuration(session.durationSeconds || 0)} • Recorded: ${new Date(session.startTime).toLocaleString()}`;
      }
      this.chartManager.renderHistoricalSession('historyModalChart', session, 'all');
    }
  }
}
