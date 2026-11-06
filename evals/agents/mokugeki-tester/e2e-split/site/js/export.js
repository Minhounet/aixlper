import { tbody, docFromRow } from './list.js';
import { csvCell } from './format.js';
import { t } from './i18n.js';

export function exportCsv() {
  const lines = [['Title', 'Author', 'Date'].join(',')];
  for (const tr of tbody().rows) {
    if (tr.hidden) continue;
    const d = docFromRow(tr);
    lines.push([d.title, d.author, d.date].map(csvCell).join(','));
  }
  const blob = new Blob([lines.join('\n') + '\n'], { type: 'text/csv' });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = t('export.filename');
  a.click();
  URL.revokeObjectURL(a.href);
}
