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
