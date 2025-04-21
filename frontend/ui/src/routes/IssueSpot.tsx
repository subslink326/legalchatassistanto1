import React, { useEffect, useState } from 'react';
import { useProjects } from '../context/ProjectContext';
import api from '../hooks/useApi';
import IssueTable, { Issue } from '../components/IssueTable';

export default function IssueSpot() {
  const { projects } = useProjects();
  const [projectId, setProjectId] = useState('');
  const [issues, setIssues] = useState<Issue[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!projectId) return;
    setLoading(true);
    api.post('/intelligence/issue-spotter', { project_id: projectId })
      .then(res => setIssues(res.data.issues))
      .finally(() => setLoading(false));
  }, [projectId]);

  return (
    <div>
      <h1>Issue Spotter</h1>
      <label>
        Project:{' '}
        <select value={projectId} onChange={e => setProjectId(e.target.value)}>
          <option value="">-- choose --</option>
          {projects.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
        </select>
      </label>
      {loading && <p>Loading...</p>}
      {!!issues.length && <IssueTable issues={issues} />}
    </div>
  );
}
