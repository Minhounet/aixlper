import { tbody, appendRow, docFromRow } from './list.js';
import { newId } from './data.js';

const handlers = {
  delete(tr) {
    tr.remove();
  },
  duplicate(tr) {
    const doc = docFromRow(tr);
    appendRow({ ...doc, id: newId(), title: doc.title + ' (copy)' });
  },
};

export function initRowActions() {
  tbody().addEventListener('click', e => {
    const button = e.target.closest('button[data-action]');
    if (!button) return;
    handlers[button.dataset.action]?.(button.closest('tr'));
  });
}
