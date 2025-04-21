import { useState } from 'react'; import api from './useApi';
export function useArgumentMap(){
  const [graph,setGraph]=useState<any>(null);
  const generate=async(pid:string,issue:string)=>{
    const res=await api.post('/intelligence/argument-map',{ project_id:pid, issue, jurisdiction:'federal' });
    setGraph(res.data.graph); return res.data.graph;
  };
  return { graph, generate };
}
