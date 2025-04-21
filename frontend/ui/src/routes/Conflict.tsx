import React, { useEffect, useState } from 'react';
import { useProjects } from '../context/ProjectContext';
import api from '../hooks/useApi';
import ConflictCard, { ConflictCardProps } from '../components/ConflictCard';

export default function Conflict() {
  const { projects } = useProjects();
  const [projectId, setProjectId] = useState('');
  const [conflicts, setConflicts] = useState<ConflictCardProps[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!projectId) return;
    setLoading(true);
    api.post('/intelligence/conflict-detector', { project_id: projectId })
      .then(res => setConflicts(res.data.conflicts))
      .finally(() => setLoading(false));
  }, [projectId]);

  return (
    <div>
      <h1>Conflict Detector</h1>
      <label>
        Project:{' '}
        <select value={projectId} onChange={e => setProjectId(e.target.value)}>
          <option value="">-- choose --</option>
          {projects.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
        </select>
      </label>
      {loading && <p>Loading...</p>}
      {conflicts.map((c, idx) => <ConflictCard key={idx} {...c} />)}
    </div>
  );
}
