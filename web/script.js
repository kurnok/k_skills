const APP   = document.getElementById('app');
const GRID  = document.getElementById('grid');
const CLOSE = document.getElementById('closeBtn');

const RES_NAME = (typeof GetParentResourceName === 'function')
  ? GetParentResourceName()
  : 'k_skills';

// helpers
function capitalize(s){ return (s||'').replace(/^\w/, c => c.toUpperCase()); }
function iconFor(id){
  switch (id){
    // case 'mining':   return '⚒️';
    // case 'crafting': return '🛠️';
    // case 'robbery':  return '⚒️';
    // case 'hacking':  return '📖';
    default:         return '📖';
  }
}

function closeUI(){
  // Visually hide
  APP.classList.add('hidden');
  APP.style.display = 'none';
  try { fetch(`https://${RES_NAME}/close`, { method: 'POST', body: '{}' }); } catch {}
}

function openUI(skills){
  GRID.innerHTML = '';
  (skills || []).forEach(s => {
    const id   = s.id || 'Skill';
    const lvl  = Number(s.level||0) || 0;
    const cur  = Number(s.cur||s.totalXP||0) || 0;
    const next = Number(s.next||s.nextLevelXP||0) || 0;
    const pct  = next > 0 ? Math.max(0, Math.min(100, Math.floor((cur/next)*100))) : 100;

    const card = document.createElement('div');
    card.className = 'card';
    card.innerHTML = `
      <h3>${iconFor(id)} ${capitalize(id)}</h3>
      <div class="muted">Level ${lvl}</div>
      <div class="muted">${ next > 0 ? `${cur} / ${next} XP` : `${cur} XP • Maxed` }</div>
      <div class="progress"><div class="fill" style="width:${pct}%;"></div></div>
      <div style="margin-top:8px"><span class="badge">${pct}%</span></div>
    `;
    GRID.appendChild(card);
  });

  // Make sure it actually shows
  APP.classList.remove('hidden');
  APP.style.display = 'flex';
}

CLOSE.addEventListener('click', closeUI);
window.addEventListener('keyup', e => { if (e.key === 'Escape') closeUI(); });

// Only open/close when Lua tells us to
window.addEventListener('message', (e) => {
  const data = e.data || {};
  if (data.action === 'open')  openUI(data.skills || []);
  if (data.action === 'close') closeUI();
});

// Force closed on first load so `ensure k_skills` never shows it
document.addEventListener('DOMContentLoaded', closeUI);
