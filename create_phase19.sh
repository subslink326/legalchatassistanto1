#!/usr/bin/env bash
set -euo pipefail
UI_SRC="frontend/ui/src"
mkdir -p $UI_SRC/components $UI_SRC/routes

echo "Installing react-flow-renderer..."
(cd frontend/ui && npm install react-flow-renderer)

# ArgumentMapCanvas component
cat > $UI_SRC/components/ArgumentMapCanvas.tsx << 'TSX'
import React from 'react';
import ReactFlow, { Node, Edge } from 'react-flow-renderer';

interface Graph {
  nodes: { id: string; label: string }[];
  links: { source: number; target: number }[];
}

export default function ArgumentMapCanvas({ graph }: { graph: Graph }) {
  const nodes: Node[] = graph.nodes.map((n, idx) => ({
    id: n.id,
    data: { label: n.label },
    position: { x: 0, y: idx * 80 },
  }));
  const edges: Edge[] = graph.links.map((l, idx) => ({
    id: \`e_\${idx}\`,
    source: graph.nodes[l.source].id,
    target: graph.nodes[l.target].id,
    animated: true,
    style: { stroke: '#888' },
  }));
  return (
    <div style={{ width: '100%', height: '600px', border: '1px solid #eee' }}>
      <ReactFlow nodes={nodes} edges={edges} fitView />
    </div>
  );
}
TSX

# ArgumentMap page
cat > $UI_SRC/routes/ArgumentMap.tsx << 'TSX'
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
TSX

echo "✅ Phase 19 scaffold created."
