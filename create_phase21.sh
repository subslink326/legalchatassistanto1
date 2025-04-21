#!/usr/bin/env bash
set -euo pipefail
UI_SRC="frontend/ui/src"
mkdir -p $UI_SRC/components/ChatBox $UI_SRC/routes

# ChatBox.tsx
cat > $UI_SRC/components/ChatBox/ChatBox.tsx << 'TSX'
import React, { useState, FormEvent } from 'react';
import api from '../../hooks/useApi';
import MessageBubble from './MessageBubble';

export default function ChatBox({ projectId }: { projectId: string }) {
  const [messages, setMessages] = useState<{ role: string; content: string }[]>([]);
  const [input, setInput] = useState('');

  const sendMessage = async (e: FormEvent) => {
    e.preventDefault();
    if (!input) return;
    const userMsg = { role: 'user', content: input };
    setMessages(prev => [...prev, userMsg]);
    setInput('');
    const res = await api.post('/intelligence/counter-authority', {
      project_id: projectId,
      draft: input,
    });
    const botMsg = { role: 'assistant', content: res.data.rebuttal };
    setMessages(prev => [...prev, botMsg]);
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', maxWidth: '600px' }}>
      <div style={{ flex: 1, overflowY: 'auto', marginBottom: '1rem' }}>
        {messages.map((m, i) => <MessageBubble key={i} message={m} />)}
      </div>
      <form onSubmit={sendMessage} style={{ display: 'flex' }}>
        <input
          value={input}
          onChange={e => setInput(e.target.value)}
          placeholder="Type your draft argument..."
          style={{ flex: 1, marginRight: '0.5rem' }}
        />
        <button type="submit">Send</button>
      </form>
    </div>
  );
}
TSX

# MessageBubble.tsx
cat > $UI_SRC/components/ChatBox/MessageBubble.tsx << 'TSX'
import React from 'react';

export interface Message {
  role: string;
  content: string;
}

export default function MessageBubble({ message }: { message: Message }) {
  const align = message.role === 'user' ? 'flex-end' : 'flex-start';
  const bg = message.role === 'user' ? '#DCF8C6' : '#F1F0F0';
  return (
    <div style={{
      alignSelf: align,
      backgroundColor: bg,
      padding: '0.5rem',
      borderRadius: '5px',
      margin: '0.3rem 0',
      maxWidth: '80%',
    }}>
      {message.content}
    </div>
  );
}
TSX

# Drafting page
cat > $UI_SRC/routes/Drafting.tsx << 'TSX'
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
TSX

echo "✅ Phase 21 scaffold created."
