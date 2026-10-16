/**
 * EmotiGuard Firebase Cloud Architecture Adapter (Phase 2 Ready)
 * 
 * Provides an decoupled adapter pattern for future Cloud Firestore
 * and Firebase Authentication integration without polluting the core
 * telemetry pipeline.
 * 
 * SECURITY RULES & BEST PRACTICES ENFORCED:
 * 1. Zero hardcoded secrets: Firebase config is injected via runtime configuration or env.
 * 2. Participant IDs are never treated as security tokens.
 * 3. Graceful offline fallback: The app operates 100% locally by default.
 */

export class FirebaseAdapter {
  constructor() {
    this.isCloudEnabled = false;
    this.currentUser = null;
    this.db = null;
    this.auth = null;
  }

  /**
   * Initializes Firebase SDK when the developer supplies project credentials
   * in Phase 2.
   */
  async init(firebaseConfig) {
    if (!firebaseConfig || !firebaseConfig.apiKey) {
      console.info('[EmotiGuard FirebaseAdapter] Running in local offline mode (No cloud keys configured).');
      return false;
    }

    try {
      // Dynamic import or CDN integration when enabled
      console.log('[EmotiGuard FirebaseAdapter] Ready to attach Firebase v10 Modular SDK.');
      this.isCloudEnabled = true;
      return true;
    } catch (err) {
      console.error('[EmotiGuard FirebaseAdapter] Cloud initialization failed:', err);
      return false;
    }
  }

  isAuthenticated() {
    return this.currentUser !== null;
  }

  getCurrentUser() {
    return this.currentUser;
  }

  async signInWithEmailPassword(email, password) {
    if (!this.isCloudEnabled) {
      throw new Error('Cloud services are currently offline. Enable Firebase in Phase 2.');
    }
    // Stub for Firebase Auth signInWithEmailAndPassword
  }

  async signOut() {
    this.currentUser = null;
  }

  /**
   * Synchronizes a completed session to Firestore /participants/{id}/sessions/{sessionId}
   */
  async syncSession(session) {
    if (!this.isCloudEnabled) {
      // Graceful local pass-through
      return { success: true, localOnly: true };
    }

    // Stub for Firestore setDoc(doc(db, "participants", session.participantId, "sessions", session.sessionId), session)
    return { success: true, synced: true };
  }
}

export const firebaseAdapter = new FirebaseAdapter();
