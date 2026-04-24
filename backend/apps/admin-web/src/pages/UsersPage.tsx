import { useState } from 'react';
import { UsersList } from './UsersList';
import { UserDetail } from './UserDetail';

export function UsersPage() {
  const [selected, setSelected] = useState<string | null>(null);
  return selected ? (
    <UserDetail userId={selected} onBack={() => setSelected(null)} />
  ) : (
    <UsersList onSelect={setSelected} />
  );
}
