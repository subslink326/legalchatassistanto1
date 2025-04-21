import React, { useState } from 'react';
import { useProjects } from '../context/ProjectContext';
import ChatBox from '../components/ChatBox/ChatBox';

export default function Drafting() {
  const { projects } = useProjects();
  const [projectId, setProjectId] = useState('');

  return (
    <div>
      <h1>Drafting Workspace</h1>
      <label>
        Project:{' '}
        <select value={projectId} onChange={e => setProjectId(e.target.value)}>
          <option value="">-- choose --</option>
          {projects.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
        </select>
      </label>
      {projectId && <ChatBox projectId={projectId} />}
    </div>
  );
}
