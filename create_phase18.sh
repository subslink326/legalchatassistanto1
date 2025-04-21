#!/usr/bin/env bash
set -euo pipefail
# Run from repo root: bash create_phase18.sh

UI_SRC="frontend/ui/src"
mkdir -p $UI_SRC/routes $UI_SRC/components

# 1) UploadDropzone component
cat > $UI_SRC/components/UploadDropzone.tsx <<'TSX'
import React, { ChangeEvent } from 'react';

interface UploadDropzoneProps {
  onFileSelected: (file: File) => void;
}

export default function UploadDropzone({ onFileSelected }: UploadDropzoneProps) {
  const handleChange = (e: ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      onFileSelected(e.target.files[0]);
    }
  };

  return (
    <div style={{
      border: '2px dashed #ccc',
      padding: '1rem',
      textAlign: 'center',
      cursor: 'pointer'
    }}>
      <input
        type="file"
        accept="application/pdf"
        onChange={handleChange}
        style={{ display: 'none' }}
        id="pdf-upload"
      />
      <label htmlFor="pdf-upload" style={{ cursor: 'pointer' }}>
        Click to select a PDF or drag it here
      </label>
    </div>
  );
}
TSX

# 2) Upload page
cat > $UI_SRC/routes/Upload.tsx <<'TSX'
import React, { useState } from 'react';
import { useProjects } from '../context/ProjectContext';
import { useUpload } from '../hooks/useUpload';
import UploadDropzone from '../components/UploadDropzone';

export default function Upload() {
  const { projects, refresh } = useProjects();
  const { upload, progress } = useUpload();
  const [selectedProject, setSelectedProject] = useState<string>('');
  const [file, setFile] = useState<File | null>(null);
  const [message, setMessage] = useState<string>('');

  const handleUpload = async () => {
    if (!selectedProject || !file) return;
    try {
      const res = await upload(selectedProject, file);
      setMessage(`Uploaded ${res.chunks} chunks (doc ID ${res.document_id})`);
      refresh();
    } catch (err: any) {
      setMessage(`Error: ${err.response?.data?.detail || err.message}`);
    }
  };

  return (
    <div>
      <h1>Upload Document</h1>
      <div>
        <label>
          Select Project:{' '}
          <select
            value={selectedProject}
            onChange={e => setSelectedProject(e.target.value)}
          >
            <option value="">-- choose --</option>
            {projects.map(p => (
              <option key={p.id} value={p.id}>{p.name}</option>
            ))}
          </select>
        </label>
      </div>
      <div style={{ margin: '1rem 0' }}>
        <UploadDropzone onFileSelected={setFile} />
      </div>
      <button onClick={handleUpload} disabled={!file || !selectedProject}>
        Upload PDF
      </button>
      {progress > 0 && progress < 100 && (
        <p>Uploading: {progress}%</p>
      )}
      {message && <p>{message}</p>}
    </div>
  );
}
TSX

# 3) Dashboard page
cat > $UI_SRC/routes/Dashboard.tsx <<'TSX'
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
TSX

echo "✅ Phase 18 scaffold created!"