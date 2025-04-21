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
