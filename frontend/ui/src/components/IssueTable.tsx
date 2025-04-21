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
