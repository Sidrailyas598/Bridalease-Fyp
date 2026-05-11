// src/index.js ya main entry point
import './index.css';
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import { supabase } from './supabaseClient';

// Check session on app start
supabase.auth.getSession().then(({ data: { session } }) => {
  console.log("App started with session:", session ? "Yes" : "No");
});

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);