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
