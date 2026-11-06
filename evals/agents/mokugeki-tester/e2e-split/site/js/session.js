import { t } from './i18n.js';

export const session = {
  role: 'editor',
  canEdit() {
    return this.role !== 'reader';
  },
};

export function initSession() {
  session.role = new URLSearchParams(location.search).get('role') || 'editor';
  document.getElementById('who').textContent =
    t(session.role === 'reader' ? 'session.reader' : 'session.editor');
}
