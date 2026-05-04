import { useEffect, useState } from 'react';

interface PageHelpProps {
  title: string;
  summary: string;
  bullets?: string[];
  storageKey?: string;
}

export function PageHelp({ title, summary, bullets, storageKey }: PageHelpProps) {
  const fullKey = storageKey ? `pagehelp:${storageKey}` : null;
  const [open, setOpen] = useState<boolean>(true);

  useEffect(() => {
    if (!fullKey) return;
    try {
      const stored = localStorage.getItem(fullKey);
      if (stored === '0') setOpen(false);
    } catch {
      // ignore
    }
  }, [fullKey]);

  const toggle = () => {
    const next = !open;
    setOpen(next);
    if (fullKey) {
      try {
        localStorage.setItem(fullKey, next ? '1' : '0');
      } catch {
        // ignore
      }
    }
  };

  return (
    <div className="page-help">
      <div className="page-help-head">
        <div>
          <div className="page-help-title">{title}</div>
          <div className="page-help-summary">{summary}</div>
        </div>
        <button className="ghost page-help-toggle" onClick={toggle} type="button">
          {open ? 'Скрыть подсказку' : 'Показать подсказку'}
        </button>
      </div>
      {open && bullets && bullets.length > 0 && (
        <ul className="page-help-list">
          {bullets.map((b, i) => (
            <li key={i}>{b}</li>
          ))}
        </ul>
      )}
    </div>
  );
}
