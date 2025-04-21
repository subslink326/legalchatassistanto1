import React from 'react';
import { Link } from 'react-router-dom';
import { useProjects } from '../context/ProjectContext';

export default function Dashboard() {
  const { projects } = useProjects();

  return (
    <div>
      <h1>Dashboard</h1>
      {projects.length === 0 ? (
        <p>No projects yet. Create one via the API or register and refresh.</p>
      ) : (
        <ul>
          {projects.map(p => (
            <li key={p.id} style={{ margin: '0.5rem 0' }}>
              <strong>{p.name}</strong><br/>
              {p.description && <em>{p.description}</em>}<br/>
              <Link to="/upload">Upload Docs</Link> |{' '}
              <Link to="/argument-map">Argument Map</Link>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
