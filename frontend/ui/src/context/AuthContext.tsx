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
