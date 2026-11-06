import { run } from './commands.js';

// key -> command name; see commands.js
const KEYMAP = {
  Delete: 'list.purgeTicked',
  'Ctrl+a': 'list.tickAll',
  Escape: 'list.untickAll',
};

function keyName(e) {
  return (e.ctrlKey || e.metaKey ? 'Ctrl+' : '') + e.key;
}

function isTyping(target) {
  return target.tagName === 'TEXTAREA' || (target.tagName === 'INPUT' && target.type !== 'checkbox');
}

export function initShortcuts() {
  document.addEventListener('keydown', e => {
    if (isTyping(e.target)) return;
    const command = KEYMAP[keyName(e)];
    if (!command) return;
    e.preventDefault();
    run(command);
  });
}
