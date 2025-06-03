
import React from 'react';
import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';

// Import your page components
import BetterSchoolBilling from './pages/mainpage';
import AboutPage from './pages/about';

function App() {
  return (
    <Router>
      <nav>
        <Link to="/">Home</Link> |{" "}
        <Link to="/about">About</Link> |{" "}
        
      </nav>

      <Routes>
        <Route path="/" element={<BetterSchoolBilling />} />
        <Route path="/about" element={<AboutPage />} />
        
      </Routes>
    </Router>
  );
}

export default App;
