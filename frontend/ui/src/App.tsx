import React from 'react'; import { Routes, Route, Link } from 'react-router-dom';
export default function App() {
  return (<div>
    <nav style={{padding:'1rem',borderBottom:'1px solid #ccc'}}>
      <Link to="/">Dashboard</Link> | <Link to="/upload">Upload</Link> | <Link to="/argument-map">Argument Map</Link>
    </nav>
    <main style={{padding:'1rem'}}>
      <Routes>
        <Route path="/" element={<h1>Dashboard (Coming Soon)</h1>} />
        <Route path="/upload" element={<h1>Upload Page</h1>} />
        <Route path="/argument-map" element={<h1>Argument Map</h1>} />
      </Routes>
    </main>
  </div>);
}
