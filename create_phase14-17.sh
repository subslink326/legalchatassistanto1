#!/usr/bin/env bash
# create_phase14-17.sh  – unit‑tests + Electron shell + React scaffold + shared hooks
set -euo pipefail

### ---------------------------------------------------------------------------
### Phase 14 – pytest fixtures & service unit tests
### ---------------------------------------------------------------------------
echo "▶️  Phase 14 – tests…"
mkdir -p tests

cat > tests/conftest.py <<'PY'
import pytest
from fastapi.testclient import TestClient
from backend.app import app
from backend.config import settings

@pytest.fixture(autouse=True)
def disable_openai(monkeypatch):
    monkeypatch.setattr(settings, "openai_api_key", None)

@pytest.fixture
def client():
    return TestClient(app)
PY

cat > tests/test_argument_mapper.py <<'PY'
from backend.modules.argument_mapper.service import extract_elements
from backend.modules.argument_mapper import graph

def test_extract_elements_fallback():
    issue = "Whether the trial court abused its discretion and erred"
    elems = extract_elements(issue, "federal")
    assert isinstance(elems, list) and all(isinstance(e, str) for e in elems)

def test_build_graph_structure():
    g = graph.build_graph("ISSUE", ["E1"], {"E1":[("C1","snippet")]})
    assert "nodes" in g and "links" in g
    assert any(n["label"]=="ISSUE" for n in g["nodes"])
    assert any(l for l in g["links"] if l["source"] == 0)
PY

cat > tests/test_issue_spotter.py <<'PY'
from backend.modules.issue_spotter.service import extract_issues
def test_extract_issues_fallback_on_objection():
    hits = extract_issues("The attorney lodged an objection at sidebar.")
    assert isinstance(hits, list) and any(h.get("issue_label") for h in hits)
PY

cat > tests/test_conflict_detector.py <<'PY'
from backend.modules.conflict_detector.nlp import extract_facts, contradicts
def test_extract_facts_detects_entities():
    facts = extract_facts("John Doe testified that he saw the defendant.")
    assert any("John Doe" in f for f in facts)
def test_contradiction_heuristic():
    assert contradicts("He never entered the warehouse.",
                       "He entered the warehouse at midnight.")
PY

cat > tests/test_brief_skeleton.py <<'PY'
import asyncio, datetime
from backend.modules.brief_skeleton.service import BriefRequest, generate_brief
def test_generate_brief_markdown_only():
    req = BriefRequest(case_title="X v Y", motion_type="Rule 59 Motion",
                       issues=["A","B"], party="Defendant", prayer="a new trial")
    resp = asyncio.run(generate_brief(req))
    assert "### I. Issues Presented" in resp.outline_markdown
    assert resp.docx_filename is None
PY

cat > tests/test_strength_score.py <<'PY'
import asyncio
from backend.modules.strength_score.service import StrengthRequest, score_issue
def test_score_issue_range_and_breakdown():
    req = StrengthRequest(project_id="0"*32, issue="Sample", standard_of_review="de novo", k=0)
    resp = asyncio.run(score_issue(req))
    assert 0 <= resp.score <= 100 and len(resp.breakdown)==4
PY

cat > tests/test_counter_authority.py <<'PY'
import asyncio
from backend.modules.counter_authority.service import CounterRequest, generate_counter
def test_generate_counter_fallback_stub():
    resp = asyncio.run(generate_counter(
        CounterRequest(project_id="0"*32, draft="Error admitting hearsay"), None))
    assert "Government counsel" in resp.rebuttal
PY

echo "✅  Tests created."

### ---------------------------------------------------------------------------
### Phase 15 – Electron bootstrap
### ---------------------------------------------------------------------------
echo "▶️  Phase 15 – Electron scaffold…"
mkdir -p frontend/electron/icons

cat > frontend/electron/package.json <<'JSON'
{
  "name": "legal-assistant-ai-electron",
  "version": "0.1.0",
  "main": "dist/main.js",
  "scripts": {
    "build:ts": "tsc",
    "start": "npm run build:ts && electron ."
  },
  "devDependencies": {
    "electron": "^29.0.0",
    "electron-builder": "^23.6.0",
    "typescript": "^5.1.6"
  }
}
JSON

cat > frontend/electron/tsconfig.json <<'JSON'
{ "compilerOptions": { "target":"ES2020","module":"commonjs","outDir":"dist",
  "rootDir":".","strict":true,"esModuleInterop":true }, "include":["*.ts"] }
JSON

cat > frontend/electron/main.ts <<'TS'
import { app, BrowserWindow } from "electron";
import path from "path";
function createWindow() {
  const win = new BrowserWindow({
    width:1200,height:800,
    webPreferences:{ preload:path.join(__dirname,"preload.js"),
                     contextIsolation:true,nodeIntegration:false }
  });
  win.loadURL("http://localhost:5173");
}
app.whenReady().then(() => { createWindow();
  app.on("activate",()=>{ if(BrowserWindow.getAllWindows().length===0) createWindow();});
});
app.on("window-all-closed",()=>{ if(process.platform!=="darwin") app.quit(); });
TS

cat > frontend/electron/preload.ts <<'TS'
import { contextBridge, ipcRenderer } from "electron";
contextBridge.exposeInMainWorld("electronAPI",{
  invoke:(c:string,a:any)=>ipcRenderer.invoke(c,a),
  on:(c:string,l:any)=>ipcRenderer.on(c,(_e,...args)=>l(...args)),
});
TS

cat > frontend/electron/electron-builder.json <<'JSON'
{
  "appId": "com.legalassistant.ai",
  "productName": "Legal Assistant AI",
  "directories": { "output": "dist", "buildResources": "icons" },
  "files": ["dist/**/*"]
}
JSON

echo "<add your 512×512 PNG here>" > frontend/electron/icons/icon.png
echo "✅  Electron files written."

### ---------------------------------------------------------------------------
### Phase 16 – React + Vite scaffold
### ---------------------------------------------------------------------------
echo "▶️  Phase 16 – UI scaffold…"
mkdir -p frontend/ui/src

cat > frontend/ui/package.json <<'JSON'
{
  "name": "legal-assistant-ai-ui",
  "version": "0.1.0",
  "private": true,
  "scripts": { "dev": "vite", "build": "vite build", "preview": "vite preview" },
  "dependencies": {
    "react": "^18.2.0","react-dom":"^18.2.0","react-router-dom":"^6.14.0"
  },
  "devDependencies": {
    "vite":"^5.1.3","@vitejs/plugin-react":"^4.0.5","typescript":"^5.1.6"
  }
}
JSON

cat > frontend/ui/tsconfig.json <<'JSON'
{ "compilerOptions": { "target":"ESNext","lib":["DOM","ESNext"],"strict":true,
  "module":"ESNext","moduleResolution":"Node","jsx":"react-jsx","noEmit":true },
  "include":["src"] }
JSON

cat > frontend/ui/vite.config.ts <<'TS'
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
export default defineConfig({ plugins:[react()], server:{port:5173},
  resolve:{ alias:{ "@":"/src" } }});
TS

cat > frontend/ui/index.html <<'HTML'
<!DOCTYPE html><html lang="en"><head>
<meta charset="UTF-8"/><meta name="viewport" content="width=device-width,initial-scale=1.0"/>
<title>Legal Assistant AI</title></head><body><div id="root"></div>
<script type="module" src="/src/main.tsx"></script></body></html>
HTML

cat > frontend/ui/src/main.tsx <<'TSX'
import React from 'react'; import { createRoot } from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom'; import App from './App';
import './index.css';
createRoot(document.getElementById('root')!).render(
  <React.StrictMode><BrowserRouter><App/></BrowserRouter></React.StrictMode>);
TSX

cat > frontend/ui/src/App.tsx <<'TSX'
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
TSX

cat > frontend/ui/src/index.css <<'CSS'
body{margin:0;font-family:sans-serif;} a{text-decoration:none;color:#0366d6;}
CSS

echo "✅  React scaffold written."

### ---------------------------------------------------------------------------
### Phase 17 – Shared React hooks & contexts
### ---------------------------------------------------------------------------
echo "▶️  Phase 17 – hooks & contexts…"
UI_SRC="frontend/ui/src"
mkdir -p "$UI_SRC/hooks" "$UI_SRC/context"

cat > $UI_SRC/hooks/useApi.ts <<'TS'
import axios from 'axios';
const api = axios.create({ baseURL: import.meta.env.VITE_API_URL || 'http://localhost:8000' });
api.interceptors.request.use(cfg => {
  const t = localStorage.getItem('token'); if(t && cfg.headers){ cfg.headers.Authorization=`Bearer ${t}`;}
  return cfg;
});
export default api;
TS

cat > $UI_SRC/hooks/useUpload.ts <<'TS'
import { useState } from 'react'; import api from './useApi';
export function useUpload(){
  const [progress,setProgress]=useState(0);
  const upload=async(pid:string,file:File)=>{
    const form=new FormData(); form.append('pdf',file);
    const res=await api.post(`/files/${pid}/upload`,form,{
      headers:{'Content-Type':'multipart/form-data'},
      onUploadProgress:e=>setProgress(Math.round((e.loaded/e.total!)*100))
    });
    return res.data;
  };
  return { upload, progress };
}
TS

cat > $UI_SRC/hooks/useArgumentMap.ts <<'TS'
import { useState } from 'react'; import api from './useApi';
export function useArgumentMap(){
  const [graph,setGraph]=useState<any>(null);
  const generate=async(pid:string,issue:string)=>{
    const res=await api.post('/intelligence/argument-map',{ project_id:pid, issue, jurisdiction:'federal' });
    setGraph(res.data.graph); return res.data.graph;
  };
  return { graph, generate };
}
TS

cat > $UI_SRC/context/AuthContext.tsx <<'TSX'
import React,{createContext,useContext,useState,ReactNode} from 'react';
import api from '../hooks/useApi';
interface Ctx{ token:string|null; userEmail:string|null;
  login:(e:string,p:string)=>Promise<void>; logout:()=>void;}
const AuthContext=createContext<Ctx|undefined>(undefined);
export function AuthProvider({children}:{children:ReactNode}){
  const [token,setToken]=useState<string|null>(localStorage.getItem('token'));
  const [userEmail,setUserEmail]=useState<string|null>(localStorage.getItem('userEmail'));
  const login=async(email:string,password:string)=>{
    const {data}=await api.post('/auth/token',{username:email,password});
    localStorage.setItem('token',data.access_token); localStorage.setItem('userEmail',email);
    setToken(data.access_token); setUserEmail(email);
  };
  const logout=()=>{localStorage.clear(); setToken(null); setUserEmail(null);};
  return <AuthContext.Provider value={{token,userEmail,login,logout}}>{children}</AuthContext.Provider>;
}
export function useAuth(){const c=useContext(AuthContext);if(!c)throw new Error('useAuth in provider');return c;}
TSX

cat > $UI_SRC/context/ProjectContext.tsx <<'TSX'
import React,{createContext,useContext,useState,useEffect,ReactNode} from 'react';
import api from '../hooks/useApi'; import { useAuth } from './AuthContext';
interface Project{ id:string; name:string; description?:string;}
interface Ctx{ projects:Project[]; refresh:()=>Promise<void>;}
const ProjectContext=createContext<Ctx|undefined>(undefined);
export function ProjectProvider({children}:{children:ReactNode}){
  const {token}=useAuth(); const [projects,setProjects]=useState<Project[]>([]);
  const refresh=async()=>{
    if(!token){setProjects([]);return;}
    const {data}=await api.get('/projects'); setProjects(data);
  };
  useEffect(()=>{refresh();},[token]);
  return <ProjectContext.Provider value={{projects,refresh}}>{children}</ProjectContext.Provider>;
}
export function useProjects(){const c=useContext(ProjectContext);if(!c)throw new Error('useProjects in provider');return c;}
TSX

echo "✅  Hooks & contexts written."

echo -e "\n🎉  Phases 14–17 complete. Next steps:"
echo "  • Run: pytest"
echo "  • In another terminal: (cd frontend/ui && npm install && npm run dev)"
echo "  • Then: (cd frontend/electron && npm install && npm run start)"