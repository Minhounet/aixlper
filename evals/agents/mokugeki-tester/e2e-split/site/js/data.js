// Seed data until the backend endpoint exists.
export function seedDocuments() {
  return [
    { id: 'd1', title: 'Quarterly Report', author: 'Ana Lima', date: '05/03/2026' },
    { id: 'd2', title: 'Minutes of the Board', author: 'Bo Chen', date: '12/01/2026' },
    { id: 'd3', title: 'Heating contract', author: 'Cy Diaz', date: '28/02/2026' },
    { id: 'd4', title: 'Budget plan', author: 'Di Eko', date: '19/11/2025' },
  ];
}

let next = 100;
export function newId() {
  next += 1;
  return 'd' + next;
}
