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
