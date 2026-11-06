const KEY = 'documents.compact';

function load() {
  try {
    return localStorage.getItem(KEY) === '1';
  } catch {
    return false;
  }
}

function save(on) {
  try {
    localStorage.setItem(KEY, on ? '1' : '0');
  } catch {
    // storage blocked: the preference just doesn't persist
  }
}

export function initPrefs() {
  const box = document.getElementById('compact');
  box.checked = load();
  document.body.classList.toggle('compact', box.checked);
  box.addEventListener('change', () => {
    document.body.classList.toggle('compact', box.checked);
    save(box.checked);
  });
}
