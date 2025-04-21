import { contextBridge, ipcRenderer } from "electron";
contextBridge.exposeInMainWorld("electronAPI",{
  invoke:(c:string,a:any)=>ipcRenderer.invoke(c,a),
  on:(c:string,l:any)=>ipcRenderer.on(c,(_e,...args)=>l(...args)),
});
