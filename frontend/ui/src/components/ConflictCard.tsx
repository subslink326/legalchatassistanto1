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
