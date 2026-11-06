import { appendRow } from './list.js';
import { newId } from './data.js';
import { isValidDate } from './format.js';

export function initForm() {
  const form = document.getElementById('new-doc');
  form.addEventListener('submit', e => {
    e.preventDefault();
    const f = form.elements;
    if (!isValidDate(f.date.value)) {
      f.date.setCustomValidity('Use dd/mm/yyyy');
      f.date.reportValidity();
      return;
    }
    f.date.setCustomValidity('');
    appendRow({ id: newId(), title: f.title.value, author: f.author.value, date: f.date.value });
    form.reset();
  });
}
