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
