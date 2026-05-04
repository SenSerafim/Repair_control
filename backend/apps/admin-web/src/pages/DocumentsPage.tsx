import { useEffect, useState } from 'react';
import { api } from '../api';
import { PageHelp } from '../lib/PageHelp';

export function DocumentsPage() {
  const [items, setItems] = useState<any[]>([]);
  const [total, setTotal] = useState(0);
  const [q, setQ] = useState('');
  const [projectId, setProjectId] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const reload = async () => {
    setLoading(true);
    setError(null);
    try {
      const r = await api.listDocuments({
        q: q || undefined,
        projectId: projectId || undefined,
        limit: 100,
      });
      setItems(r.items);
      setTotal(r.total);
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    reload();
  }, []);

  const sizeLabel = (b: number) => {
    if (b < 1024) return `${b} Б`;
    if (b < 1024 * 1024) return `${(b / 1024).toFixed(0)} КБ`;
    return `${(b / 1024 / 1024).toFixed(1)} МБ`;
  };

  return (
    <div>
      <PageHelp
        storageKey="documents"
        title="Документы проектов"
        summary="Все файлы, прикреплённые к проектам через раздел «Документы» в мобайле. Файлы хранятся в MinIO/S3, в БД — только метаданные. Категория задаётся пользователем при загрузке (договор, смета, акт и т. п.)."
        bullets={[
          'Категория — одна из 7 предопределённых: contract / estimate / act / specification / drawing / photo / other.',
          'Размер выводится в Б/КБ/МБ. Жёсткий лимит на размер — определяется политикой FilesService на бекенде.',
          'Кто загрузил — UUID (или имя) Membership-пользователя проекта; админка видит всех, заказчик — только то, что разрешено его правами в проекте.',
          'Эта страница read-only: документы загружаются/удаляются только в мобайле под RBAC проекта.',
        ]}
      />
      <div className="filters">
        <input
          placeholder="Поиск по названию"
          value={q}
          onChange={(e) => setQ(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && reload()}
        />
        <input
          placeholder="UUID проекта"
          value={projectId}
          onChange={(e) => setProjectId(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && reload()}
        />
        <button onClick={reload}>Применить</button>
        <span className="muted">Всего: {total}</span>
      </div>
      {error && <div className="error">{error}</div>}
      {loading ? (
        <div className="muted">Загрузка…</div>
      ) : (
        <table className="table">
          <thead>
            <tr>
              <th>Название</th>
              <th>Категория</th>
              <th>Размер</th>
              <th>Проект</th>
              <th>Кто загрузил</th>
              <th>Создан</th>
            </tr>
          </thead>
          <tbody>
            {items.map((d) => (
              <tr key={d.id}>
                <td>
                  <strong>{d.title}</strong>
                  <div className="muted" style={{ fontSize: 11 }}>
                    {d.mimeType}
                  </div>
                </td>
                <td>
                  <span className="badge">{d.category}</span>
                </td>
                <td>{sizeLabel(d.sizeBytes)}</td>
                <td>{d.project?.title ?? d.projectId}</td>
                <td>
                  {d.uploader
                    ? `${d.uploader.firstName} ${d.uploader.lastName}`
                    : d.uploadedById}
                </td>
                <td className="muted">
                  {new Date(d.createdAt).toLocaleString()}
                </td>
              </tr>
            ))}
            {items.length === 0 && (
              <tr>
                <td colSpan={6} className="muted" style={{ textAlign: 'center' }}>
                  Записей нет
                </td>
              </tr>
            )}
          </tbody>
        </table>
      )}
    </div>
  );
}
