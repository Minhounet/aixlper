// Dates travel as dd/mm/yyyy strings, as the backend sends them.
export function isValidDate(text) {
  const m = /^(\d{2})\/(\d{2})\/(\d{4})$/.exec(text);
  if (!m) return false;
  const [, d, mo] = m.map(Number);
  return mo >= 1 && mo <= 12 && d >= 1 && d <= 31;
}

export function csvCell(text) {
  return /[",\n]/.test(text) ? '"' + text.replace(/"/g, '""') + '"' : text;
}
