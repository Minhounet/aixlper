const STRINGS = {
  en: {
    'session.reader': 'a reader (read-only)',
    'session.editor': 'an editor',
    'toolbar.deleteSelected': 'Delete selected',
    'toolbar.export': 'Export CSV',
    'row.delete': 'Delete',
    'row.duplicate': 'Duplicate',
    'row.select': 'Select',
    'tip.keyboard': 'Tip: tick documents and press the Delete key to remove them.',
    'export.filename': 'documents.csv',
  },
};

const lang = (navigator.language || 'en').slice(0, 2);

export function t(key) {
  const table = STRINGS[lang] || STRINGS.en;
  return table[key] ?? STRINGS.en[key] ?? key;
}

export function applyStrings() {
  document.getElementById('tip').textContent = t('tip.keyboard');
}
