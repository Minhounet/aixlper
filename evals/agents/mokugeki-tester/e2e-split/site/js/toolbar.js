import { t } from './i18n.js';
import { run } from './commands.js';
import { exportCsv } from './export.js';

function button(label, onClick) {
  const b = document.createElement('button');
  b.type = 'button';
  b.textContent = label;
  b.addEventListener('click', onClick);
  return b;
}

export function initToolbar() {
  document.getElementById('toolbar').append(
    button(t('toolbar.deleteSelected'), () => run('list.purgeTicked')),
    button(t('toolbar.export'), exportCsv),
  );
}
