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
