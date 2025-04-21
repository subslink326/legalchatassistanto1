import React, { useState } from 'react';
import { useProjects } from '../context/ProjectContext';
import { useArgumentMap } from '../hooks/useArgumentMap';
import ArgumentMapCanvas from '../components/ArgumentMapCanvas';

export default function ArgumentMap() {
  const { projects } = useProjects();
  const { graph, generate } = useArgumentMap();
  const [projectId, setProjectId] = useState('');
  const [issue, setIssue] = useState('');

  const handleGenerate = () => {
    if (projectId && issue) {
      generate(projectId, issue);
    }
  };

  return (
    <div>
      <h1>Argument Map</h1>
      <div>
        <label>
          Project:{' '}
          <select value={projectId} onChange={e => setProjectId(e.target.value)}>
            <option value="">-- choose --</option>
            {projects.map(p => (
              <option key={p.id} value={p.id}>{p.name}</option>
            ))}
          </select>
        </label>
      </div>
      <textarea
        placeholder="Enter issue statement..."
        value={issue}
        onChange={e => setIssue(e.target.value)}
        rows={3}
        style={{ width: '100%', margin: '1rem 0' }}
      />
      <button onClick={handleGenerate} disabled={!projectId || !issue}>
        Generate Map
      </button>
      {graph && <ArgumentMapCanvas graph={graph} />}
    </div>
  );
}
