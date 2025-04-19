import React, { useState } from 'react';

export default function EncryptForm() {
  const [plaintext, setPlaintext] = useState('');
  const [encrypted, setEncrypted] = useState('');

  const handleEncrypt = async () => {
    try {
      const res = await fetch('https://localhost:5000/encrypt', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ data: plaintext })
      });
      const json = await res.json();
      setEncrypted(json.encrypted);
    } catch (err) {
      console.error(err);
      alert('Encryption failed. Make sure backend is running and trusted.');
    }
  };

  return (
    <div>
      <h2>Encrypt</h2>
      <input value={plaintext} onChange={e => setPlaintext(e.target.value)} />
      <button onClick={handleEncrypt}>Encrypt</button>
      <p><b>Encrypted:</b> {encrypted}</p>
    </div>
  );
}
