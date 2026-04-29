import { useEffect, useRef, useState } from 'react';
import { api } from '../api';
import { uploadWithProgress } from '../lib/upload';

interface Category {
  id: string;
  title: string;
  description: string | null;
  iconKey: string | null;
  scope: 'global' | 'project_module';
  moduleSlug: string | null;
  orderIndex: number;
  isPublished: boolean;
  _count?: { articles: number };
}

interface ArticleSummary {
  id: string;
  title: string;
  orderIndex: number;
  etag: string;
  version: number;
  updatedAt: string;
}

interface ArticleDetail {
  id: string;
  categoryId: string;
  title: string;
  body: string;
  etag: string;
  version: number;
  isPublished: boolean;
  orderIndex: number;
  publishedAt: string | null;
  createdAt: string;
  updatedAt: string;
  assets: Asset[];
  category: { id: string; title: string };
}

interface Asset {
  id: string;
  articleId: string;
  kind: 'image' | 'video' | 'file';
  fileKey: string;
  mimeType: string;
  sizeBytes: number;
  durationSec: number | null;
  width: number | null;
  height: number | null;
  thumbKey: string | null;
  caption: string | null;
  orderIndex: number;
}

const MODULE_SLUGS = [
  'stages',
  'approvals',
  'finance',
  'materials',
  'tools',
  'chats',
  'documents',
  'team',
  'console',
];

export function KnowledgeBasePage() {
  const [view, setView] = useState<'list' | 'category' | 'article'>('list');
  const [selectedCategory, setSelectedCategory] = useState<Category | null>(null);
  const [selectedArticleId, setSelectedArticleId] = useState<string | null>(null);

  if (view === 'article' && selectedArticleId && selectedCategory) {
    return (
      <ArticleEditor
        articleId={selectedArticleId}
        onBack={() => {
          setSelectedArticleId(null);
          setView('category');
        }}
      />
    );
  }
  if (view === 'category' && selectedCategory) {
    return (
      <CategoryDetail
        category={selectedCategory}
        onBack={() => {
          setSelectedCategory(null);
          setView('list');
        }}
        onOpenArticle={(id) => {
          setSelectedArticleId(id);
          setView('article');
        }}
      />
    );
  }
  return (
    <CategoryList
      onOpen={(c) => {
        setSelectedCategory(c);
        setView('category');
      }}
    />
  );
}

// ────────── Category list ──────────

function CategoryList({ onOpen }: { onOpen: (c: Category) => void }) {
  const [items, setItems] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showCreate, setShowCreate] = useState(false);

  const reload = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await api.listKnowledgeCategories();
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

  if (loading) return <div>Загрузка…</div>;

  return (
    <div>
      <div className="muted" style={{ marginBottom: 12 }}>
        Категории Базы знаний. Глобальные доступны всем; project_module —
        контекстная справка для конкретного модуля мобайла.
      </div>
      {error && <div className="error" style={{ marginBottom: 12 }}>{error}</div>}

      <div className="row" style={{ marginBottom: 12 }}>
        <button onClick={() => setShowCreate(!showCreate)} style={{ flex: 0 }}>
          {showCreate ? 'Отмена' : '+ Категория'}
        </button>
      </div>

      {showCreate && (
        <CategoryForm
          onSave={async () => {
            setShowCreate(false);
            await reload();
          }}
          onCancel={() => setShowCreate(false)}
        />
      )}

      {items.length === 0 && !showCreate && <div className="muted">Категорий пока нет.</div>}
      {items.map((c) => (
        <div className="card" key={c.id} style={{ cursor: 'pointer' }} onClick={() => onOpen(c)}>
          <div className="row" style={{ alignItems: 'baseline' }}>
            <div className="grow" style={{ fontWeight: 700 }}>{c.title}</div>
            <span
              className="badge"
              style={{
                background: c.isPublished ? '#d1fae5' : '#e4e9f7',
                color: c.isPublished ? '#065f46' : '#475569',
              }}
            >
              {c.isPublished ? 'опубликована' : 'скрыта'}
            </span>
          </div>
          <div className="muted" style={{ fontSize: 13, marginTop: 4 }}>
            scope: <code>{c.scope}</code>
            {c.moduleSlug && (
              <>
                {' '}· module: <code>{c.moduleSlug}</code>
              </>
            )}
            {' '}· статей: {c._count?.articles ?? 0}
          </div>
          {c.description && (
            <div className="muted" style={{ fontSize: 13, marginTop: 4 }}>{c.description}</div>
          )}
        </div>
      ))}
    </div>
  );
}

function CategoryForm({
  initial,
  onSave,
  onCancel,
  onDelete,
}: {
  initial?: Category;
  onSave: () => void | Promise<void>;
  onCancel: () => void;
  onDelete?: () => void | Promise<void>;
}) {
  const [title, setTitle] = useState(initial?.title ?? '');
  const [description, setDescription] = useState(initial?.description ?? '');
  const [scope, setScope] = useState<'global' | 'project_module'>(
    initial?.scope ?? 'global',
  );
  const [moduleSlug, setModuleSlug] = useState(initial?.moduleSlug ?? '');
  const [orderIndex, setOrderIndex] = useState(initial?.orderIndex ?? 0);
  const [isPublished, setIsPublished] = useState(initial?.isPublished ?? true);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const save = async () => {
    if (!title.trim()) {
      setError('Заголовок обязателен');
      return;
    }
    if (scope === 'project_module' && !moduleSlug) {
      setError('Для project_module нужен moduleSlug');
      return;
    }
    setBusy(true);
    setError(null);
    try {
      if (initial) {
        await api.updateKnowledgeCategory(initial.id, {
          title,
          description: description || undefined,
          scope,
          moduleSlug: scope === 'project_module' ? moduleSlug : null,
          orderIndex,
          isPublished,
        });
      } else {
        await api.createKnowledgeCategory({
          title,
          description: description || undefined,
          scope,
          moduleSlug: scope === 'project_module' ? moduleSlug : undefined,
          orderIndex,
        });
      }
      await onSave();
    } catch (e: any) {
      setError(e.message);
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="card">
      <div style={{ fontWeight: 700, marginBottom: 8 }}>
        {initial ? 'Редактировать категорию' : 'Новая категория'}
      </div>
      {error && <div className="error" style={{ marginBottom: 8 }}>{error}</div>}
      <label style={{ display: 'block', marginBottom: 8 }}>
        <div className="muted">Заголовок</div>
        <input value={title} onChange={(e) => setTitle(e.target.value)} style={{ width: '100%' }} />
      </label>
      <label style={{ display: 'block', marginBottom: 8 }}>
        <div className="muted">Описание (опционально)</div>
        <input
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          style={{ width: '100%' }}
        />
      </label>
      <label style={{ display: 'block', marginBottom: 8 }}>
        <div className="muted">Scope</div>
        <select
          value={scope}
          onChange={(e) => setScope(e.target.value as any)}
          style={{ width: '100%' }}
        >
          <option value="global">global — для всех экранов мобайла</option>
          <option value="project_module">project_module — для конкретного модуля</option>
        </select>
      </label>
      {scope === 'project_module' && (
        <label style={{ display: 'block', marginBottom: 8 }}>
          <div className="muted">Module slug</div>
          <select
            value={moduleSlug}
            onChange={(e) => setModuleSlug(e.target.value)}
            style={{ width: '100%' }}
          >
            <option value="">— выбрать —</option>
            {MODULE_SLUGS.map((s) => (
              <option key={s} value={s}>{s}</option>
            ))}
          </select>
        </label>
      )}
      <label style={{ display: 'block', marginBottom: 8 }}>
        <div className="muted">Order index</div>
        <input
          type="number"
          value={orderIndex}
          onChange={(e) => setOrderIndex(Number(e.target.value))}
          style={{ width: '100%' }}
        />
      </label>
      {initial && (
        <label style={{ display: 'block', marginBottom: 8 }}>
          <input
            type="checkbox"
            checked={isPublished}
            onChange={(e) => setIsPublished(e.target.checked)}
          />{' '}
          Опубликована (видна на мобайле)
        </label>
      )}
      <div className="row" style={{ marginTop: 12, gap: 8 }}>
        <button onClick={save} disabled={busy} style={{ flex: 0 }}>
          {busy ? 'Сохранение…' : 'Сохранить'}
        </button>
        <button className="secondary" onClick={onCancel} style={{ flex: 0 }}>
          Отмена
        </button>
        {initial && onDelete && (
          <button
            className="secondary"
            style={{ flex: 0, marginLeft: 'auto', color: '#b91c1c' }}
            onClick={async () => {
              if (!confirm(`Удалить категорию «${initial.title}»? Все статьи и медиа будут удалены.`))
                return;
              await onDelete();
            }}
          >
            Удалить
          </button>
        )}
      </div>
    </div>
  );
}

// ────────── Category detail (со списком статей) ──────────

function CategoryDetail({
  category,
  onBack,
  onOpenArticle,
}: {
  category: Category;
  onBack: () => void;
  onOpenArticle: (id: string) => void;
}) {
  const [articles, setArticles] = useState<ArticleSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showCreate, setShowCreate] = useState(false);
  const [showEdit, setShowEdit] = useState(false);

  const reload = async () => {
    setLoading(true);
    setError(null);
    try {
      const cat = await api.getKnowledgeCategory(category.id);
      setArticles(cat.articles ?? []);
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    reload();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [category.id]);

  return (
    <div>
      <div className="row" style={{ marginBottom: 12 }}>
        <button className="secondary" onClick={onBack} style={{ flex: 0 }}>← Категории</button>
        <div className="grow" style={{ marginLeft: 12, fontWeight: 700, fontSize: 18 }}>
          {category.title}
        </div>
        <button onClick={() => setShowEdit(!showEdit)} style={{ flex: 0 }}>
          {showEdit ? 'Закрыть' : 'Edit'}
        </button>
      </div>

      {showEdit && (
        <CategoryForm
          initial={category}
          onSave={async () => {
            setShowEdit(false);
            // reload родителя — категория мутировала; для простоты возвращаемся в список
            onBack();
          }}
          onCancel={() => setShowEdit(false)}
          onDelete={async () => {
            await api.deleteKnowledgeCategory(category.id);
            onBack();
          }}
        />
      )}

      {error && <div className="error" style={{ marginBottom: 12 }}>{error}</div>}
      {loading && <div className="muted">Загрузка…</div>}

      <div className="row" style={{ marginBottom: 12 }}>
        <button onClick={() => setShowCreate(!showCreate)} style={{ flex: 0 }}>
          {showCreate ? 'Отмена' : '+ Статья'}
        </button>
      </div>

      {showCreate && (
        <NewArticleForm
          categoryId={category.id}
          onSave={async () => {
            setShowCreate(false);
            await reload();
          }}
          onCancel={() => setShowCreate(false)}
        />
      )}

      {articles.length === 0 && !showCreate && (
        <div className="muted">Статей пока нет.</div>
      )}
      {articles.map((a) => (
        <div
          className="card"
          key={a.id}
          style={{ cursor: 'pointer' }}
          onClick={() => onOpenArticle(a.id)}
        >
          <div className="row" style={{ alignItems: 'baseline' }}>
            <div className="grow" style={{ fontWeight: 700 }}>{a.title}</div>
            <div className="muted" style={{ fontSize: 12 }}>v{a.version}</div>
          </div>
          <div className="muted" style={{ fontSize: 13, marginTop: 4 }}>
            обновлена: {new Date(a.updatedAt).toLocaleString()}
          </div>
        </div>
      ))}
    </div>
  );
}

function NewArticleForm({
  categoryId,
  onSave,
  onCancel,
}: {
  categoryId: string;
  onSave: () => void | Promise<void>;
  onCancel: () => void;
}) {
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const save = async () => {
    if (!title.trim() || !body.trim()) {
      setError('Заполните заголовок и тело статьи');
      return;
    }
    setBusy(true);
    setError(null);
    try {
      await api.createKnowledgeArticle({ categoryId, title, body });
      await onSave();
    } catch (e: any) {
      setError(e.message);
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="card">
      <div style={{ fontWeight: 700, marginBottom: 8 }}>Новая статья</div>
      {error && <div className="error" style={{ marginBottom: 8 }}>{error}</div>}
      <input
        value={title}
        onChange={(e) => setTitle(e.target.value)}
        placeholder="Заголовок"
        style={{ width: '100%', marginBottom: 8 }}
      />
      <textarea
        value={body}
        onChange={(e) => setBody(e.target.value)}
        placeholder="Markdown-тело статьи"
        rows={8}
        style={{ width: '100%' }}
      />
      <div className="row" style={{ marginTop: 12, gap: 8 }}>
        <button onClick={save} disabled={busy} style={{ flex: 0 }}>
          {busy ? 'Сохранение…' : 'Создать'}
        </button>
        <button className="secondary" onClick={onCancel} style={{ flex: 0 }}>
          Отмена
        </button>
      </div>
    </div>
  );
}

// ────────── Article editor ──────────

function ArticleEditor({
  articleId,
  onBack,
}: {
  articleId: string;
  onBack: () => void;
}) {
  const [article, setArticle] = useState<ArticleDetail | null>(null);
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [isPublished, setIsPublished] = useState(true);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  const reload = async () => {
    setLoading(true);
    setError(null);
    try {
      const a = await api.getKnowledgeArticle(articleId);
      setArticle(a);
      setTitle(a.title);
      setBody(a.body);
      setIsPublished(a.isPublished);
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    reload();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [articleId]);

  const save = async () => {
    if (!article) return;
    setSaving(true);
    setError(null);
    try {
      await api.updateKnowledgeArticle(articleId, { title, body, isPublished });
      await reload();
    } catch (e: any) {
      setError(e.message);
    } finally {
      setSaving(false);
    }
  };

  const remove = async () => {
    if (!confirm('Удалить статью со всеми ассетами?')) return;
    try {
      await api.deleteKnowledgeArticle(articleId);
      onBack();
    } catch (e: any) {
      setError(e.message);
    }
  };

  if (loading) return <div>Загрузка…</div>;
  if (!article) return <div className="error">{error ?? 'Статья не найдена'}</div>;

  return (
    <div>
      <div className="row" style={{ marginBottom: 12 }}>
        <button className="secondary" onClick={onBack} style={{ flex: 0 }}>
          ← Категория
        </button>
        <div className="grow" style={{ marginLeft: 12, fontWeight: 700, fontSize: 18 }}>
          {article.title}
        </div>
        <div className="muted" style={{ flex: 0, fontSize: 12 }}>v{article.version}</div>
      </div>

      {error && <div className="error" style={{ marginBottom: 12 }}>{error}</div>}

      <div className="card">
        <input
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          style={{ width: '100%', marginBottom: 8, fontWeight: 700 }}
        />
        <textarea
          value={body}
          onChange={(e) => setBody(e.target.value)}
          rows={14}
          style={{ width: '100%' }}
        />
        <label style={{ display: 'block', marginTop: 8 }}>
          <input
            type="checkbox"
            checked={isPublished}
            onChange={(e) => setIsPublished(e.target.checked)}
          />{' '}
          Опубликована (видна на мобайле)
        </label>
        <div className="row" style={{ marginTop: 12, gap: 8 }}>
          <button onClick={save} disabled={saving} style={{ flex: 0 }}>
            {saving ? 'Сохранение…' : 'Сохранить'}
          </button>
          <button
            className="secondary"
            style={{ flex: 0, marginLeft: 'auto', color: '#b91c1c' }}
            onClick={remove}
          >
            Удалить статью
          </button>
        </div>
      </div>

      <h3 style={{ marginTop: 24 }}>Медиа ({article.assets.length})</h3>
      <AssetUploader articleId={articleId} onUploaded={reload} />

      {article.assets.map((a) => (
        <AssetCard key={a.id} asset={a} onChange={reload} />
      ))}
    </div>
  );
}

function AssetUploader({
  articleId,
  onUploaded,
}: {
  articleId: string;
  onUploaded: () => Promise<void> | void;
}) {
  const [kind, setKind] = useState<'image' | 'video' | 'file'>('image');
  const [caption, setCaption] = useState('');
  const [busy, setBusy] = useState<string | null>(null);
  const [progress, setProgress] = useState<number | null>(null);
  const [error, setError] = useState<string | null>(null);
  const fileRef = useRef<HTMLInputElement | null>(null);

  const limitMb = 200;
  const accept = (() => {
    if (kind === 'image') return 'image/jpeg,image/png';
    if (kind === 'video') return 'video/mp4,video/quicktime';
    return 'application/pdf';
  })();

  const upload = async () => {
    const file = fileRef.current?.files?.[0];
    if (!file) {
      setError('Выберите файл');
      return;
    }
    if (file.size > limitMb * 1024 * 1024) {
      setError(`Файл больше ${limitMb} MB`);
      return;
    }
    setBusy('Создание presigned URL…');
    setError(null);
    try {
      const presigned = await api.presignUpload({
        originalName: file.name,
        mimeType: file.type,
        sizeBytes: file.size,
        scope: `knowledge/articles/${articleId}`,
      });
      setBusy('Загрузка…');
      await uploadWithProgress(presigned.uploadUrl, file, setProgress);
      setProgress(null);
      setBusy('Регистрация…');
      await api.confirmKnowledgeAsset(articleId, {
        kind,
        fileKey: presigned.key,
        mimeType: file.type,
        sizeBytes: file.size,
        caption: caption || undefined,
      });
      setCaption('');
      if (fileRef.current) fileRef.current.value = '';
      await onUploaded();
    } catch (e: any) {
      setError(e.message);
    } finally {
      setBusy(null);
      setProgress(null);
    }
  };

  return (
    <div className="card">
      <div style={{ fontWeight: 700, marginBottom: 8 }}>Добавить медиа</div>
      {error && <div className="error" style={{ marginBottom: 8 }}>{error}</div>}
      <div className="row" style={{ gap: 8, marginBottom: 8, flexWrap: 'wrap' }}>
        {(['image', 'video', 'file'] as const).map((k) => (
          <button
            key={k}
            className={kind === k ? '' : 'secondary'}
            onClick={() => setKind(k)}
            style={{ flex: 0 }}
          >
            {k === 'image' ? 'Фото' : k === 'video' ? 'Видео' : 'PDF'}
          </button>
        ))}
      </div>
      <input ref={fileRef} type="file" accept={accept} style={{ marginBottom: 8 }} />
      <input
        placeholder="Подпись (опционально)"
        value={caption}
        onChange={(e) => setCaption(e.target.value)}
        style={{ width: '100%', marginBottom: 8 }}
      />
      <div className="row" style={{ alignItems: 'center', gap: 8 }}>
        <button onClick={upload} disabled={busy !== null} style={{ flex: 0 }}>
          {busy ?? 'Загрузить'}
        </button>
        {progress !== null && <span className="muted">{progress}%</span>}
      </div>
    </div>
  );
}

function AssetCard({
  asset,
  onChange,
}: {
  asset: Asset;
  onChange: () => Promise<void> | void;
}) {
  const [busy, setBusy] = useState(false);
  const thumbRef = useRef<HTMLInputElement | null>(null);

  const remove = async () => {
    if (!confirm('Удалить медиа?')) return;
    setBusy(true);
    try {
      await api.deleteKnowledgeAsset(asset.articleId, asset.id);
      await onChange();
    } finally {
      setBusy(false);
    }
  };

  const setThumb = async () => {
    const file = thumbRef.current?.files?.[0];
    if (!file) return;
    if (!['image/jpeg', 'image/png'].includes(file.type)) {
      alert('Только JPG / PNG');
      return;
    }
    setBusy(true);
    try {
      const presigned = await api.presignUpload({
        originalName: file.name,
        mimeType: file.type,
        sizeBytes: file.size,
        scope: `knowledge/articles/${asset.articleId}`,
      });
      await uploadWithProgress(presigned.uploadUrl, file, () => {});
      await api.setKnowledgeAssetThumbnail(asset.articleId, asset.id, presigned.key);
      if (thumbRef.current) thumbRef.current.value = '';
      await onChange();
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="card">
      <div className="row" style={{ alignItems: 'baseline' }}>
        <div className="grow">
          <strong>{asset.kind}</strong>
          {asset.caption && <span className="muted"> · {asset.caption}</span>}
        </div>
        <div className="muted" style={{ fontSize: 12 }}>
          {(asset.sizeBytes / 1024 / 1024).toFixed(2)} MB
        </div>
      </div>
      <div className="muted" style={{ fontSize: 12, marginTop: 4 }}>
        <code>{asset.fileKey}</code>
      </div>
      {asset.kind === 'video' && (
        <div className="row" style={{ marginTop: 8, alignItems: 'center', gap: 8 }}>
          <span className="muted" style={{ fontSize: 13 }}>
            Обложка: {asset.thumbKey ? '✓ загружена' : '— нет'}
          </span>
          <input ref={thumbRef} type="file" accept="image/jpeg,image/png" />
          <button className="secondary" onClick={setThumb} disabled={busy} style={{ flex: 0 }}>
            Обновить
          </button>
        </div>
      )}
      <div className="row" style={{ marginTop: 8, gap: 8 }}>
        <button
          className="secondary"
          onClick={remove}
          disabled={busy}
          style={{ flex: 0, color: '#b91c1c' }}
        >
          Удалить
        </button>
      </div>
    </div>
  );
}
