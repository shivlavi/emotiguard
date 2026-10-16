/**
 * EmotiGuard Storage Service
 * Manages participant profiles, session records, and physiological telemetry persistence.
 * 
 * IMPORTANT ARCHITECTURE NOTE:
 * Participant IDs are used strictly for local data separation and experimental tagging.
 * As highlighted in the project specifications, this field must NEVER be treated as
 * secure user authentication. In later iterations, this service connects to Firebase Auth/Firestore.
 */

import { APP_CONFIG } from '../config.js';

export class StorageService {
  constructor() {
    this.initDefaults();
  }

  initDefaults() {
    if (!this.getParticipants() || this.getParticipants().length === 0) {
      const defaultParticipant = {
        id: 'PART-001',
        alias: 'Participant Alpha',
        age: 22,
        gender: 'Not Disclosed',
        baselineState: 'Resting / Normal',
        notes: 'Initial test participant for IoT physiological telemetry.',
        created: new Date().toISOString()
      };
      this.saveParticipants([defaultParticipant]);
      this.setActiveParticipantId(defaultParticipant.id);
    }
  }

  // --- PARTICIPANTS MANAGEMENT ---

  getParticipants() {
    try {
      const data = localStorage.getItem(APP_CONFIG.STORAGE_KEYS.PARTICIPANTS);
      return data ? JSON.parse(data) : [];
    } catch (e) {
      console.error('Failed reading participants from storage:', e);
      return [];
    }
  }

  saveParticipants(list) {
    try {
      localStorage.setItem(APP_CONFIG.STORAGE_KEYS.PARTICIPANTS, JSON.stringify(list));
    } catch (e) {
      console.error('Failed saving participants:', e);
    }
  }

  getParticipantById(id) {
    const list = this.getParticipants();
    return list.find(p => p.id === id) || null;
  }

  addOrUpdateParticipant(participant) {
    const list = this.getParticipants();
    const index = list.findIndex(p => p.id === participant.id);
    if (index >= 0) {
      list[index] = { ...list[index], ...participant, updated: new Date().toISOString() };
    } else {
      list.push({ ...participant, created: new Date().toISOString() });
    }
    this.saveParticipants(list);
  }

  getActiveParticipantId() {
    return localStorage.getItem(APP_CONFIG.STORAGE_KEYS.ACTIVE_PARTICIPANT) || 'PART-001';
  }

  setActiveParticipantId(id) {
    localStorage.setItem(APP_CONFIG.STORAGE_KEYS.ACTIVE_PARTICIPANT, id);
  }

  getActiveParticipant() {
    const id = this.getActiveParticipantId();
    return this.getParticipantById(id) || {
      id: 'ANON',
      alias: 'Anonymous Participant',
      notes: 'Ephemeral participant tag'
    };
  }

  // --- SESSIONS MANAGEMENT ---

  getSessions() {
    try {
      const data = localStorage.getItem(APP_CONFIG.STORAGE_KEYS.SESSIONS);
      return data ? JSON.parse(data) : [];
    } catch (e) {
      console.error('Failed reading sessions from storage:', e);
      return [];
    }
  }

  saveSessions(list) {
    try {
      localStorage.setItem(APP_CONFIG.STORAGE_KEYS.SESSIONS, JSON.stringify(list));
    } catch (e) {
      console.error('Failed saving sessions:', e);
    }
  }

  getSessionsForParticipant(participantId) {
    return this.getSessions().filter(s => s.participantId === participantId);
  }

  getSessionById(sessionId) {
    return this.getSessions().find(s => s.sessionId === sessionId) || null;
  }

  saveCompletedSession(sessionRecord) {
    const sessions = this.getSessions();
    sessions.unshift(sessionRecord); // Add newest at top
    // Enforce max storage retention of recent 25 sessions locally to respect quota
    if (sessions.length > 25) {
      sessions.pop();
    }
    this.saveSessions(sessions);
  }

  deleteSession(sessionId) {
    const sessions = this.getSessions().filter(s => s.sessionId !== sessionId);
    this.saveSessions(sessions);
  }

  clearAllData() {
    localStorage.removeItem(APP_CONFIG.STORAGE_KEYS.PARTICIPANTS);
    localStorage.removeItem(APP_CONFIG.STORAGE_KEYS.ACTIVE_PARTICIPANT);
    localStorage.removeItem(APP_CONFIG.STORAGE_KEYS.SESSIONS);
    this.initDefaults();
  }
}
