import React from 'react';
import EncryptForm from './components/EncryptForm';
import DecryptForm from './components/DecryptForm';

function App() {
  return (
    <div style={{ padding: '2rem', fontFamily: 'sans-serif' }}>
      <h1>Secure Flask Backend Demo</h1>
      <EncryptForm />
      <hr />
      <DecryptForm />
    </div>
  );
}

export default App;
