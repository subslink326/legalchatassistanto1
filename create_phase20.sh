#!/usr/bin/env bash
set -euo pipefail
UI_SRC="frontend/ui/src"
mkdir -p $UI_SRC/components $UI_SRC/routes

# IssueTable component
cat > $UI_SRC/components/IssueTable.tsx << 'TSX'
import React from 'react';

export interface Issue {
  label: string;
  preserved: boolean;
  citations: string[];
  frequency: number;
}

export default function IssueTable({ issues }: { issues: Issue[] }) {
  return (
    <table style={{ width: '100%', borderCollapse: 'collapse' }}>
      <thead>
        <tr>
          <th>Issue</th><th>Preserved</th><th>Citations</th><th>Frequency</th>
        </tr>
      </thead>
      <tbody>
        {issues.map((i, idx) => (
          <tr key={idx}>
            <td>{i.label}</td>
            <td>{i.preserved ? 'Yes' : 'No'}</td>
            <td>{i.citations.join(', ')}</td>
            <td>{i.frequency}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
TSX

# ConflictCard component
cat > $UI_SRC/components/ConflictCard.tsx << 'TSX'
import React from 'react';

export interface ConflictCardProps {
  statement_a: string;
  source_a: string;
  statement_b: string;
  source_b: string;
  explanation: string;
}

export default function ConflictCard({ statement_a, source_a, statement_b, source_b, explanation }: ConflictCardProps) {
  return (
    <div style={{ border: '1px solid #ddd', padding: '1rem', marginBottom: '1rem' }}>
      <p><strong>A:</strong> {statement_a} <em>({source_a})</em></p>
      <p><strong>B:</strong> {statement_b} <em>({source_b})</em></p>
      <p style={{ fontStyle: 'italic' }}>{explanation}</p>
    </div>
  );
}
TSX

# IssueSpot page
cat > $UI_SRC/routes/IssueSpot.tsx << 'TSX'
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
TSX

# Conflict page
cat > $UI_SRC/routes/Conflict.tsx << 'TSX'
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
TSX

echo "✅ Phase 20 scaffold created."
