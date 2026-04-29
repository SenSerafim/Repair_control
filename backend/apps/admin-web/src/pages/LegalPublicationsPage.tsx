import { useEffect, useRef, useState } from 'react';
import { api } from '../api';
import { uploadWithProgress } from '../lib/upload';

interface LegalPublication {
  id: string;
  kind: string;
  slug: string;
  title: string;
  fileKey: string;
  mimeType: string;
  sizeBytes: number;
  etag: string;
  version: number;
  isActive: boolean;
  publishedAt: string | null;
  publishedById: string | null;
  createdAt: string;
  updatedAt: string;
}

const KINDS: Array<{ value: string; label: string }> = [
  { value: 'privacy_policy', label: 'Политика конфиденциальности' },
  { value: 'tos', label: 'Пользовательское соглашение' },
  { value: 'data_processing_consent', label: 'Согласие на обработку ПДн' },
  { value: 'other', label: 'Иное' },
];

const SLUG_PATTERN = /^[a-z0-9][a-z0-9-]{1,79}$/;

interface DraftState {
  kind: string;
  slug: string;
  title: string;
}

export function LegalPublicationsPage() {
  const [items, setItems] = useState<LegalPublication[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState<string | null>(null);
  const [progress, setProgress] = useState<number | null>(null);

  const [draft, setDraft] = useState<DraftState>({
    kind: 'privacy_policy',
    slug: '',
    title: '',
  });
  const fileRef = useRef<HTMLInputElement | null>(null);

  const reload = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await api.listLegalPublications();
      setItems(data);
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    reload();
  }, []);

  const slugInvalid = draft.slug.length > 0 && !SLUG_PATTERN.test(draft.slug);
  const fileSelected = fileRef.current?.files?.[0] ?? null;
  const canCreate =
    draft.title.trim().length > 0 &&
    SLUG_PATTERN.test(draft.slug) &&
    !!fileSelected &&
    busy === null;

  const upload = async () => {
    const file = fileRef.current?.files?.[0];
    if (!file) return;
    if (file.type !== 'application/pdf') {
      setError('Файл должен быть PDF (application/pdf).');
      return;
    }
    if (file.size > 25 * 1024 * 1024) {
      setError('Размер файла не должен превышать 25 MB.');
      return;
    }
    setBusy('Создание presigned-URL…');
    setError(null);
    try {
      const presigned = await api.presignUpload({
        originalName: file.name,
        mimeType: 'application/pdf',
        sizeBytes: file.size,
        scope: `legal/${draft.slug}`,
      });

      setBusy('Загрузка PDF в хранилище…');
      await uploadWithProgress(presigned.uploadUrl, file, setProgress);
      setProgress(null);

      setBusy('Регистрация публикации…');
      const created = await api.createLegalPublication({
        kind: draft.kind,
        slug: draft.slug,
        title: draft.title,
        fileKey: presigned.key,
        mimeType: 'application/pdf',
        sizeBytes: file.size,
      });

      setBusy('Публикация…');
      await api.publishLegalPublication(created.id);

      setDraft({ kind: 'privacy_policy', slug: '', title: '' });
      if (fileRef.current) fileRef.current.value = '';
      await reload();
    } catch (e: any) {
      setError(e.message);
    } finally {
      setBusy(null);
      setProgress(null);
    }
  };

  const togglePublish = async (item: LegalPublication) => {
    try {
      if (item.isActive) {
        if (!confirm(`Деактивировать «${item.title}» (slug: ${item.slug})?`)) return;
        await api.deactivateLegalPublication(item.id);
      } else {
        await api.publishLegalPublication(item.id);
      }
      await reload();
    } catch (e: any) {
      setError(e.message);
    }
  };

  if (loading) return <div>Загрузка…</div>;

  return (
    <div>
      <div className="muted" style={{ marginBottom: 16 }}>
        PDF-публикации юридических документов. Открываются на мобайле через
        внешний браузер по публичной ссылке вида
        <code style={{ marginLeft: 4 }}>/legal/public/&lt;slug&gt;.pdf</code> —
        авторизация не требуется. Активная публикация одна на kind.
      </div>

      {error && <div className="error" style={{ marginBottom: 12 }}>{error}</div>}

      <div className="card" style={{ marginBottom: 16 }}>
        <div style={{ fontWeight: 700, marginBottom: 8 }}>Загрузить новый PDF</div>

        <label style={{ display: 'block', marginBottom: 8 }}>
          <div className="muted" style={{ marginBottom: 4 }}>Тип документа</div>
          <select
            value={draft.kind}
            onChange={(e) => setDraft({ ...draft, kind: e.target.value })}
            style={{ width: '100%' }}
          >
            {KINDS.map((k) => (
              <option key={k.value} value={k.value}>{k.label}</option>
            ))}
          </select>
        </label>

        <label style={{ display: 'block', marginBottom: 8 }}>
          <div className="muted" style={{ marginBottom: 4 }}>
            Slug (часть URL, ascii-lowercase + дефис)
          </div>
          <input
            value={draft.slug}
            placeholder="privacy-policy"
            onChange={(e) => setDraft({ ...draft, slug: e.target.value.toLowerCase() })}
            style={{ width: '100%' }}
          />
          {slugInvalid && (
            <div className="error" style={{ fontSize: 13, marginTop: 4 }}>
              2–80 символов, латиница / цифры / дефис, начинается с буквы или цифры
            </div>
          )}
        </label>

        <label style={{ display: 'block', marginBottom: 8 }}>
          <div className="muted" style={{ marginBottom: 4 }}>
            Заголовок (показывается в мобайле)
          </div>
          <input
            value={draft.title}
            placeholder="Политика конфиденциальности (v3)"
            onChange={(e) => setDraft({ ...draft, title: e.target.value })}
            style={{ width: '100%' }}
          />
        </label>

        <label style={{ display: 'block', marginBottom: 8 }}>
          <div className="muted" style={{ marginBottom: 4 }}>PDF-файл (до 25 MB)</div>
          <input ref={fileRef} type="file" accept="application/pdf" />
        </label>

        <div className="row" style={{ marginTop: 12, alignItems: 'center' }}>
          <button onClick={upload} disabled={!canCreate} style={{ flex: 0 }}>
            {busy ?? 'Загрузить и опубликовать'}
          </button>
          {progress !== null && (
            <div className="muted" style={{ fontSize: 13 }}>
              {progress}%
            </div>
          )}
        </div>
      </div>

      <div style={{ fontWeight: 700, marginBottom: 8 }}>
        Опубликовано ({items.length})
      </div>
      {items.length === 0 && <div className="muted">Публикаций нет.</div>}
      {items.map((it) => (
        <div className="card" key={it.id}>
          <div className="row" style={{ alignItems: 'baseline' }}>
            <div className="grow" style={{ fontWeight: 700 }}>{it.title}</div>
            <span
              className="badge"
              style={{
                background: it.isActive ? '#d1fae5' : '#e4e9f7',
                color: it.isActive ? '#065f46' : '#475569',
              }}
            >
              {it.isActive ? 'активна' : 'отключена'}
            </span>
          </div>
          <div className="muted" style={{ fontSize: 13, marginTop: 4 }}>
            kind: <code>{it.kind}</code> · slug: <code>{it.slug}</code> ·
            v{it.version} · {(it.sizeBytes / 1024 / 1024).toFixed(2)} MB
          </div>
          <div className="muted" style={{ fontSize: 12, marginTop: 4 }}>
            {it.publishedAt
              ? `Опубликовано: ${new Date(it.publishedAt).toLocaleString()}`
              : 'Черновик'}
          </div>
          <div className="row" style={{ marginTop: 8, gap: 8 }}>
            <a
              href={`/legal/public/${it.slug}.pdf`}
              target="_blank"
              rel="noopener noreferrer"
              style={{ flex: 0 }}
            >
              <button className="secondary" style={{ flex: 0 }} disabled={!it.isActive}>
                Открыть
              </button>
            </a>
            <button
              onClick={() => togglePublish(it)}
              style={{ flex: 0 }}
              className={it.isActive ? 'secondary' : ''}
            >
              {it.isActive ? 'Деактивировать' : 'Опубликовать'}
            </button>
          </div>
        </div>
      ))}
    </div>
  );
}

