import { useEffect, useState } from 'react';
import { api } from '../api';

export function FaqEditor() {
  const [sections, setSections] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [newSectionTitle, setNewSectionTitle] = useState('');
  const [newItem, setNewItem] = useState<{ sectionId: string; question: string; answer: string }>({
    sectionId: '',
    question: '',
    answer: '',
  });

  const reload = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await api.listFaq();
      setSections(data);
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    reload();
  }, []);

  const createSection = async () => {
    if (!newSectionTitle.trim()) return;
    await api.createSection(newSectionTitle, sections.length);
    setNewSectionTitle('');
    reload();
  };

  const createItem = async () => {
    if (!newItem.sectionId || !newItem.question.trim()) return;
    const section = sections.find((s) => s.id === newItem.sectionId);
    await api.createItem(
      newItem.sectionId,
      newItem.question,
      newItem.answer,
      section?.items.length ?? 0,
    );
    setNewItem({ sectionId: '', question: '', answer: '' });
    reload();
  };

  const deleteItem = async (id: string) => {
    if (!confirm('Удалить вопрос?')) return;
    await api.deleteItem(id);
    reload();
  };

  if (loading) return <div>Загрузка…</div>;
  if (error) return <div className="error">{error}</div>;

  return (
    <div>
      <div className="card">
        <strong>Новая секция</strong>
        <div className="row" style={{ marginTop: 8 }}>
          <input
            value={newSectionTitle}
            onChange={(e) => setNewSectionTitle(e.target.value)}
            placeholder="Например: Оплата"
          />
          <button onClick={createSection} style={{ flex: 0 }}>
            Добавить
          </button>
        </div>
      </div>

      <div className="card">
        <strong>Новый вопрос</strong>
        <div className="row" style={{ marginTop: 8 }}>
          <select
            value={newItem.sectionId}
            onChange={(e) => setNewItem({ ...newItem, sectionId: e.target.value })}
          >
            <option value="">— секция —</option>
            {sections.map((s) => (
              <option key={s.id} value={s.id}>
                {s.title}
              </option>
            ))}
          </select>
        </div>
        <input
          style={{ marginTop: 8 }}
          value={newItem.question}
          onChange={(e) => setNewItem({ ...newItem, question: e.target.value })}
          placeholder="Вопрос"
        />
        <textarea
          style={{ marginTop: 8 }}
          value={newItem.answer}
          onChange={(e) => setNewItem({ ...newItem, answer: e.target.value })}
          placeholder="Ответ"
          rows={3}
        />
        <button style={{ marginTop: 8 }} onClick={createItem}>
          Добавить
        </button>
      </div>

      {sections.map((s) => (
        <div className="card" key={s.id}>
          <h3 style={{ margin: '0 0 12px 0' }}>{s.title}</h3>
          {s.items.length === 0 && <div className="muted">Вопросов ещё нет.</div>}
          {s.items.map((it: any) => (
            <div key={it.id} style={{ borderTop: '1px solid #eef', padding: '12px 0' }}>
              <div className="row">
                <div className="grow">
                  <strong>{it.question}</strong>
                </div>
                <button className="ghost" onClick={() => deleteItem(it.id)} style={{ flex: 0 }}>
                  Удалить
                </button>
              </div>
              <div style={{ marginTop: 6, whiteSpace: 'pre-wrap' }}>{it.answer}</div>
            </div>
          ))}
        </div>
      ))}
    </div>
  );
}
