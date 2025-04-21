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
