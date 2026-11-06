import { tbody } from './list.js';

const registry = new Map();

export function register(name, fn) {
  registry.set(name, fn);
}

export function run(name) {
  const fn = registry.get(name);
  if (!fn) throw new Error('unknown command: ' + name);
  return fn();
}

register('list.purgeTicked', () => {
  for (const box of tbody().querySelectorAll('input.tick:checked')) box.closest('tr').remove();
});

register('list.tickAll', () => {
  for (const box of tbody().querySelectorAll('input.tick')) {
    if (!box.closest('tr').hidden) box.checked = true;
  }
});

register('list.untickAll', () => {
  for (const box of tbody().querySelectorAll('input.tick')) box.checked = false;
});
