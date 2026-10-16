/**
 * EmotiGuard Participant Profile Controller
 * Manages participant metadata, data separation tags, and experimental baselines.
 */

import { APP_CONFIG } from '../config.js';

export class ParticipantView {
  constructor(elements, storageService, onActiveParticipantChange) {
    this.els = elements;
    this.storage = storageService;
    this.onActiveParticipantChange = onActiveParticipantChange || (() => {});
  }

  render() {
    this.renderActiveParticipant();
    this.renderParticipantsList();
  }

  renderActiveParticipant() {
    const active = this.storage.getActiveParticipant();
    if (!active) return;

    if (this.els.currentPartIdDisplay) this.els.currentPartIdDisplay.textContent = active.id;
    if (this.els.currentPartAliasDisplay) this.els.currentPartAliasDisplay.textContent = active.alias || 'Unnamed';
    if (this.els.currentPartAgeDisplay) this.els.currentPartAgeDisplay.textContent = active.age ? `${active.age} yrs` : 'Not set';
    if (this.els.currentPartNotesDisplay) this.els.currentPartNotesDisplay.textContent = active.notes || 'No baseline notes recorded.';
  }

  renderParticipantsList() {
    const list = this.storage.getParticipants();
    const activeId = this.storage.getActiveParticipantId();

    // 1. Populate Dropdown in Top Nav / Session header
    if (this.els.participantSelect) {
      this.els.participantSelect.innerHTML = '';
      list.forEach(p => {
        const opt = document.createElement('option');
        opt.value = p.id;
        opt.textContent = `${p.id} - ${p.alias || 'Participant'}`;
        if (p.id === activeId) opt.selected = true;
        this.els.participantSelect.appendChild(opt);
      });
    }

    // 2. Populate Management Table / Cards in Participant Tab
    if (this.els.participantTableBody) {
      this.els.participantTableBody.innerHTML = '';
      
      list.forEach(p => {
        const sessions = this.storage.getSessionsForParticipant(p.id);
        const isActive = p.id === activeId;

        const row = document.createElement('tr');
        row.className = `border-b border-slate-800/80 hover:bg-slate-800/30 transition-colors ${isActive ? 'bg-cyan-950/20' : ''}`;
        
        row.innerHTML = `
          <td class="py-3 px-4 font-mono font-medium text-cyan-400">
            ${p.id}
            ${isActive ? '<span class="ml-2 text-[10px] bg-cyan-500/20 text-cyan-300 border border-cyan-500/40 px-1.5 py-0.5 rounded-full">ACTIVE</span>' : ''}
          </td>
          <td class="py-3 px-4 font-medium text-slate-200">${p.alias || 'Participant'}</td>
          <td class="py-3 px-4 text-slate-400">${p.age || '--'}</td>
          <td class="py-3 px-4 text-slate-400 text-sm max-w-xs truncate">${p.notes || '--'}</td>
          <td class="py-3 px-4 text-slate-300 font-mono">${sessions.length} sessions</td>
          <td class="py-3 px-4 text-right">
            ${isActive ? `
              <span class="text-xs text-slate-500 italic">Selected</span>
            ` : `
              <button data-select-id="${p.id}" class="btn-select-part text-xs px-2.5 py-1 rounded bg-slate-800 hover:bg-cyan-600/30 text-cyan-400 border border-cyan-500/20 transition-colors">
                Select
              </button>
            `}
          </td>
        `;
        this.els.participantTableBody.appendChild(row);
      });

      // Bind select buttons
      this.els.participantTableBody.querySelectorAll('.btn-select-part').forEach(btn => {
        btn.addEventListener('click', (e) => {
          const id = e.currentTarget.getAttribute('data-select-id');
          this.storage.setActiveParticipantId(id);
          this.render();
          this.onActiveParticipantChange(this.storage.getActiveParticipant());
        });
      });
    }
  }

  saveNewParticipant(formData) {
    if (!formData.id) {
      formData.id = 'PART-' + Math.floor(100 + Math.random() * 900);
    }
    this.storage.addOrUpdateParticipant(formData);
    this.storage.setActiveParticipantId(formData.id);
    this.render();
    this.onActiveParticipantChange(this.storage.getActiveParticipant());
  }
}
