import React, { useState } from 'react';

export default function DecryptForm() {
  const [token, setToken] = useState('');
  const [decrypted, setDecrypted] = useState('');

  const handleDecrypt = async () => {
    try {
      const res = await fetch('https://localhost:5000/decrypt', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ encrypted: token })
      });
      const json = await res.json();
      setDecrypted(json.decrypted);
    } catch (err) {
      console.error(err);
      alert('Decryption failed. Backend might be unreachable.');
    }
  };

  return (
    <div>
      <h2>Decrypt</h2>
      <input value={token} onChange={e => setToken(e.target.value)} />
      <button onClick={handleDecrypt}>Decrypt</button>
      <p><b>Decrypted:</b> {decrypted}</p>
    </div>
  );
}
