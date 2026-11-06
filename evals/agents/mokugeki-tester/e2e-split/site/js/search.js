import { tbody } from './list.js';

function matches(tr, query) {
  return tr.querySelector('.title').textContent.toLowerCase().includes(query);
}

export function initSearch() {
  const input = document.getElementById('search');
  input.addEventListener('input', () => {
    const q = input.value.trim().toLowerCase();
    for (const tr of tbody().rows) tr.hidden = q !== '' && !matches(tr, q);
  });
}
