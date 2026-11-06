import { t } from './i18n.js';

export function tbody() {
  return document.querySelector('#documents tbody');
}

export function rowFor(doc) {
  const tr = document.createElement('tr');
  tr.dataset.id = doc.id;
  tr.dataset.author = doc.author;

  const sel = document.createElement('td');
  const box = document.createElement('input');
  box.type = 'checkbox';
  box.className = 'tick';
  box.setAttribute('aria-label', t('row.select') + ' ' + doc.title);
  sel.append(box);

  const title = document.createElement('td');
  title.className = 'title';
  title.textContent = doc.title;

  const date = document.createElement('td');
  date.className = 'date';
  date.textContent = doc.date;

  const actions = document.createElement('td');
  for (const [action, label] of [['duplicate', 'row.duplicate'], ['delete', 'row.delete']]) {
    const b = document.createElement('button');
    b.type = 'button';
    b.dataset.action = action;
    b.textContent = t(label);
    actions.append(b);
  }

  tr.append(sel, title, date, actions);
  return tr;
}

export function renderRows(docs) {
  const body = tbody();
  body.replaceChildren(...docs.map(rowFor));
}

export function appendRow(doc) {
  tbody().append(rowFor(doc));
}

export function docFromRow(tr) {
  return {
    id: tr.dataset.id,
    title: tr.querySelector('.title').textContent,
    author: tr.dataset.author,
    date: tr.querySelector('.date').textContent,
  };
}
