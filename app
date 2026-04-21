import { useState, useEffect, useMemo } from "react";
import { PieChart, Pie, Cell, BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer } from "recharts";

/* ═══ DEFAULTS ═══ */
const DEF_CLIENTS = [
  { id: "froz", name: "Froz", color: "#06B6D4", icon: "🧊" },
  { id: "mipileta", name: "Mi Pileta", color: "#2563EB", icon: "🚿" },
  { id: "antequera", name: "Antequera", color: "#D97706", icon: "🏡" },
  { id: "anm", name: "ANM Content Studio", color: "#7C3AED", icon: "🎬" },
  { id: "avanti", name: "Avanti", color: "#059669", icon: "🚀" },
];
const DEF_TEAM = [
  { id: "santi", name: "Santiago", role: "Fundador", color: "#2563EB" },
  { id: "dio", name: "Diógenes", role: "Fundador", color: "#7C3AED" },
  { id: "luisina", name: "Luisina", role: "Social Media Manager", color: "#EC4899" },
  { id: "lucia", name: "Lucía", role: "Diseñadora", color: "#10B981" },
];

const PRIORITIES = { urgente: "Urgente", alta: "Alta", media: "Media", baja: "Baja" };
const PR = { urgente: { bg: "#FEE2E2", text: "#991B1B", dot: "#DC2626" }, alta: { bg: "#FFEDD5", text: "#9A3412", dot: "#F97316" }, media: { bg: "#FEF3C7", text: "#92400E", dot: "#F59E0B" }, baja: { bg: "#DBEAFE", text: "#1E40AF", dot: "#3B82F6" } };
const CATS = ["Web / eCommerce", "Diseño Gráfico", "Redes Sociales", "Contenido / Copy", "Email Marketing", "SEO / SEM", "Datos / Analytics", "Estrategia", "Reunión", "Otro"];
const STS = [
  { id: "backlog", label: "Backlog", icon: "⊘", color: "#94A3B8" },
  { id: "pendiente", label: "Pendiente", icon: "○", color: "#64748B" },
  { id: "en_progreso", label: "En Progreso", icon: "◐", color: "#3B82F6" },
  { id: "revision", label: "En Revisión", icon: "◑", color: "#F59E0B" },
  { id: "completada", label: "Completada", icon: "●", color: "#10B981" },
];
const BOARD_STS = STS.filter(s => s.id !== "backlog");
const EMOJIS = ["🧊","🚿","🏡","🎬","🚀","🏢","💎","🔥","⚡","🎯","🌟","📱","🛍️","🍕","🎨","💄","👗","🏋️","🌿","🐾"];
const COLORS = ["#2563EB","#7C3AED","#06B6D4","#D97706","#059669","#EC4899","#EF4444","#F59E0B","#10B981","#64748B","#8B5CF6","#14B8A6"];

const SK = { tasks: "anm-tasks-v5", clients: "anm-clients-v5", team: "anm-team-v5" };
const uid = () => Date.now().toString(36) + Math.random().toString(36).substr(2, 6);
const fmtD = d => d ? new Date(d).toLocaleDateString("es-AR", { day: "2-digit", month: "short" }) : "";
const tAgo = iso => { const s = Math.floor((Date.now() - new Date(iso)) / 1000); if (s < 60) return "ahora"; if (s < 3600) return `${Math.floor(s/60)}m`; if (s < 86400) return `${Math.floor(s/3600)}h`; if (s < 604800) return `${Math.floor(s/86400)}d`; return fmtD(iso); };
const isOD = d => d && new Date(d) < new Date(new Date().toDateString());
const isPar = t => { if (t.status==="completada"||t.status==="backlog"||!t.updatedAt) return false; return (Date.now()-new Date(t.updatedAt))/864e5>3; };

function usePersist(key, init) {
  const [s, setS] = useState(init);
  const [ld, setLd] = useState(false);
  useEffect(() => { (async () => { try { const r = await window.storage.get(key); if (r?.value) setS(JSON.parse(r.value)); } catch {} setLd(true); })(); }, [key]);
  useEffect(() => { if (!ld) return; (async () => { try { await window.storage.set(key, JSON.stringify(s)); } catch {} })(); }, [key, s, ld]);
  return [s, setS, ld];
}

/* ═══ ICONS ═══ */
const I = {
  plus:(z=18)=><svg width={z} height={z} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>,
  x:(z=18)=><svg width={z} height={z} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>,
  search:<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>,
  trash:<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a2 2 0 012-2h4a2 2 0 012 2v2"/></svg>,
  edit:<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>,
  board:<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><rect x="3" y="3" width="7" height="9" rx="1"/><rect x="14" y="3" width="7" height="5" rx="1"/><rect x="3" y="16" width="7" height="5" rx="1"/><rect x="14" y="12" width="7" height="9" rx="1"/></svg>,
  list:<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><line x1="8" y1="6" x2="21" y2="6"/><line x1="8" y1="12" x2="21" y2="12"/><line x1="8" y1="18" x2="21" y2="18"/><circle cx="4" cy="6" r="1" fill="currentColor"/><circle cx="4" cy="12" r="1" fill="currentColor"/><circle cx="4" cy="18" r="1" fill="currentColor"/></svg>,
  dash:<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/></svg>,
  comment:<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z"/></svg>,
  clock:<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>,
  alert:<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><path d="M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>,
  back:<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><polyline points="15 18 9 12 15 6"/></svg>,
  portal:<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>,
  gear:<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 00.33 1.82l.06.06a2 2 0 010 2.83 2 2 0 01-2.83 0l-.06-.06a1.65 1.65 0 00-1.82-.33 1.65 1.65 0 00-1 1.51V21a2 2 0 01-4 0v-.09A1.65 1.65 0 009 19.4a1.65 1.65 0 00-1.82.33l-.06.06a2 2 0 01-2.83-2.83l.06-.06A1.65 1.65 0 004.68 15a1.65 1.65 0 00-1.51-1H3a2 2 0 010-4h.09A1.65 1.65 0 004.6 9a1.65 1.65 0 00-.33-1.82l-.06-.06a2 2 0 012.83-2.83l.06.06A1.65 1.65 0 009 4.68a1.65 1.65 0 001-1.51V3a2 2 0 014 0v.09a1.65 1.65 0 001 1.51 1.65 1.65 0 001.82-.33l.06-.06a2 2 0 012.83 2.83l-.06.06A1.65 1.65 0 0019.4 9a1.65 1.65 0 001.51 1H21a2 2 0 010 4h-.09a1.65 1.65 0 00-1.51 1z"/></svg>,
};

function Av({ name, color, size=26 }) { return <div style={{width:size,height:size,borderRadius:"50%",background:color||"#94A3B8",color:"#fff",display:"flex",alignItems:"center",justifyContent:"center",fontSize:size*.42,fontWeight:800,flexShrink:0}}>{(name||"?")[0].toUpperCase()}</div>; }

function Mod({ children, onClose, wide }) {
  return <div onClick={onClose} style={{position:"fixed",inset:0,background:"rgba(5,10,20,.5)",zIndex:1000,display:"flex",alignItems:"flex-start",justifyContent:"center",padding:"40px 16px",overflowY:"auto",backdropFilter:"blur(6px)",animation:"fadeIn .12s ease"}}><div onClick={e=>e.stopPropagation()} style={{background:"var(--card)",borderRadius:16,width:"100%",maxWidth:wide?720:540,padding:"28px 32px",boxShadow:"0 30px 80px rgba(0,0,0,.25), 0 0 0 1px var(--border)",animation:"slideUp .18s ease"}}>{children}</div></div>;
}

/* ═══ SETTINGS ═══ */
function Settings({ clients, setClients, team, setTeam, onClose }) {
  const [tab, setTab] = useState("clients");
  const [ef, setEf] = useState(null); // editing form
  const [fm, setFm] = useState({});
  const inp = {width:"100%",padding:"9px 12px",borderRadius:8,border:"1px solid var(--border)",background:"var(--input)",color:"var(--text)",fontSize:13,outline:"none",boxSizing:"border-box",fontFamily:"inherit"};
  const lbl = {fontSize:10,fontWeight:700,color:"var(--muted)",marginBottom:4,display:"block",textTransform:"uppercase",letterSpacing:".04em"};

  const startAdd = () => { setEf({_new:true}); setFm(tab==="clients"?{name:"",color:COLORS[Math.floor(Math.random()*COLORS.length)],icon:EMOJIS[Math.floor(Math.random()*EMOJIS.length)]}:{name:"",role:"",color:COLORS[Math.floor(Math.random()*COLORS.length)]}); };
  const startEdit = (it) => { setEf(it); setFm(tab==="clients"?{name:it.name,color:it.color,icon:it.icon}:{name:it.name,role:it.role,color:it.color}); };
  const save = () => {
    if(!fm.name.trim()) return;
    if(ef._new){
      const ni = tab==="clients"?{id:uid(),name:fm.name.trim(),color:fm.color,icon:fm.icon}:{id:uid(),name:fm.name.trim(),role:fm.role?.trim()||"",color:fm.color};
      tab==="clients"?setClients(p=>[...p,ni]):setTeam(p=>[...p,ni]);
    } else {
      tab==="clients"?setClients(p=>p.map(c=>c.id===ef.id?{...c,name:fm.name.trim(),color:fm.color,icon:fm.icon}:c)):setTeam(p=>p.map(m=>m.id===ef.id?{...m,name:fm.name.trim(),role:fm.role?.trim()||"",color:fm.color}:m));
    }
    setEf(null);
  };
  const del = (id) => { tab==="clients"?setClients(p=>p.filter(c=>c.id!==id)):setTeam(p=>p.filter(m=>m.id!==id)); };

  const items = tab==="clients"?clients:team;
  const tabStyle = (t) => ({padding:"8px 18px",borderRadius:8,border:"none",background:tab===t?"var(--accent)":"var(--surface)",color:tab===t?"#fff":"var(--sub)",fontSize:12,fontWeight:700,cursor:"pointer"});

  return (
    <div>
      <div style={{display:"flex",justifyContent:"space-between",alignItems:"center",marginBottom:20}}>
        <h2 style={{margin:0,fontSize:19,fontWeight:800,color:"var(--text)"}}>⚙️ Configuración</h2>
        <button onClick={onClose} style={{background:"none",border:"none",cursor:"pointer",color:"var(--muted)",padding:4}}>{I.x()}</button>
      </div>

      <div style={{display:"flex",gap:6,marginBottom:20}}>
        <button onClick={()=>{setTab("clients");setEf(null);}} style={tabStyle("clients")}>Clientes</button>
        <button onClick={()=>{setTab("team");setEf(null);}} style={tabStyle("team")}>Equipo</button>
      </div>

      {ef ? (
        <div style={{background:"var(--surface)",borderRadius:12,padding:20}}>
          <div style={{fontSize:13,fontWeight:800,color:"var(--text)",marginBottom:14}}>{ef._new?"Agregar":"Editar"} {tab==="clients"?"cliente":"miembro"}</div>
          <div style={{display:"flex",flexDirection:"column",gap:12}}>
            <div><label style={lbl}>Nombre *</label><input value={fm.name} onChange={e=>setFm(p=>({...p,name:e.target.value}))} style={inp} autoFocus /></div>
            {tab==="team"&&<div><label style={lbl}>Rol</label><input value={fm.role||""} onChange={e=>setFm(p=>({...p,role:e.target.value}))} style={inp} placeholder="Ej: Diseñadora" /></div>}
            <div><label style={lbl}>Color</label>
              <div style={{display:"flex",gap:6,flexWrap:"wrap"}}>
                {COLORS.map(c=><button key={c} onClick={()=>setFm(p=>({...p,color:c}))} style={{width:28,height:28,borderRadius:"50%",background:c,border:fm.color===c?"3px solid var(--text)":"3px solid transparent",cursor:"pointer",transition:"border .1s"}}/>)}
              </div>
            </div>
            {tab==="clients"&&<div><label style={lbl}>Ícono</label>
              <div style={{display:"flex",gap:6,flexWrap:"wrap"}}>
                {EMOJIS.map(e=><button key={e} onClick={()=>setFm(p=>({...p,icon:e}))} style={{width:34,height:34,borderRadius:8,background:fm.icon===e?"var(--accent)":"var(--card)",border:"1px solid var(--border)",fontSize:18,cursor:"pointer",display:"flex",alignItems:"center",justifyContent:"center"}}>{e}</button>)}
              </div>
            </div>}
          </div>
          <div style={{display:"flex",gap:8,marginTop:18,justifyContent:"flex-end"}}>
            <button onClick={()=>setEf(null)} style={{padding:"8px 18px",borderRadius:8,border:"1px solid var(--border)",background:"var(--card)",color:"var(--sub)",fontSize:12,fontWeight:600,cursor:"pointer"}}>Cancelar</button>
            <button onClick={save} disabled={!fm.name.trim()} style={{padding:"8px 22px",borderRadius:8,border:"none",background:fm.name.trim()?"var(--accent)":"var(--border)",color:fm.name.trim()?"#fff":"var(--muted)",fontSize:12,fontWeight:800,cursor:fm.name.trim()?"pointer":"not-allowed"}}>Guardar</button>
          </div>
        </div>
      ) : (
        <div>
          {items.map(it=>(
            <div key={it.id} style={{display:"flex",alignItems:"center",gap:12,padding:"10px 12px",borderRadius:10,marginBottom:4,background:"var(--surface)"}}>
              {tab==="clients"?<span style={{fontSize:20}}>{it.icon}</span>:<Av name={it.name} color={it.color} size={28}/>}
              <div style={{flex:1}}>
                <div style={{fontSize:13,fontWeight:700,color:"var(--text)"}}>{it.name}</div>
                {tab==="team"&&it.role&&<div style={{fontSize:10,color:"var(--muted)"}}>{it.role}</div>}
              </div>
              <div style={{width:14,height:14,borderRadius:"50%",background:it.color,flexShrink:0}}/>
              <button onClick={()=>startEdit(it)} style={{background:"none",border:"none",cursor:"pointer",color:"var(--muted)",padding:4}}>{I.edit}</button>
              <button onClick={()=>del(it.id)} style={{background:"none",border:"none",cursor:"pointer",color:"#EF4444",padding:4}}>{I.trash}</button>
            </div>
          ))}
          <button onClick={startAdd} style={{display:"flex",alignItems:"center",gap:6,marginTop:12,padding:"10px 18px",borderRadius:8,border:"1px dashed var(--border)",background:"transparent",color:"var(--accent)",fontSize:12,fontWeight:700,cursor:"pointer",width:"100%",justifyContent:"center"}}>
            {I.plus(14)} Agregar {tab==="clients"?"cliente":"miembro"}
          </button>
        </div>
      )}
    </div>
  );
}

/* ═══ TASK FORM ═══ */
function TaskForm({task,onSave,onClose,onDelete,isClient,fixedCid,clients,team}){
  const isE=!!task?.id;
  const [f,sF]=useState({title:task?.title||"",description:task?.description||"",priority:task?.priority||"media",category:task?.category||CATS[0],assigneeId:task?.assigneeId||"",clientId:task?.clientId||fixedCid||clients[0]?.id||"",dueDate:task?.dueDate||"",status:task?.status||"pendiente"});
  const set=(k,v)=>sF(p=>({...p,[k]:v}));
  const inp={width:"100%",padding:"10px 14px",borderRadius:8,border:"1px solid var(--border)",background:"var(--input)",color:"var(--text)",fontSize:13,outline:"none",boxSizing:"border-box",fontFamily:"inherit"};
  const lbl={fontSize:11,fontWeight:700,color:"var(--muted)",marginBottom:5,display:"block",textTransform:"uppercase",letterSpacing:".04em"};
  return(
    <div>
      <div style={{display:"flex",justifyContent:"space-between",alignItems:"center",marginBottom:24}}>
        <h2 style={{margin:0,fontSize:19,fontWeight:800,color:"var(--text)"}}>{isE?"Editar tarea":isClient?"Enviar solicitud":"Nueva tarea"}</h2>
        <button onClick={onClose} style={{background:"none",border:"none",cursor:"pointer",color:"var(--muted)",padding:4}}>{I.x()}</button>
      </div>
      <div style={{display:"flex",flexDirection:"column",gap:14}}>
        <div><label style={lbl}>Título *</label><input value={f.title} onChange={e=>set("title",e.target.value)} placeholder={isClient?"¿Qué necesitás?":"¿Qué hay que hacer?"} style={inp} autoFocus/></div>
        <div><label style={lbl}>Descripción</label><textarea value={f.description} onChange={e=>set("description",e.target.value)} placeholder="Detallá..." rows={3} style={{...inp,resize:"vertical"}}/></div>
        <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:12}}>
          {!isClient&&<div><label style={lbl}>Cliente</label><select value={f.clientId} onChange={e=>set("clientId",e.target.value)} style={inp}>{clients.map(c=><option key={c.id} value={c.id}>{c.icon} {c.name}</option>)}</select></div>}
          <div><label style={lbl}>Categoría</label><select value={f.category} onChange={e=>set("category",e.target.value)} style={inp}>{CATS.map(c=><option key={c} value={c}>{c}</option>)}</select></div>
          {isClient&&<div><label style={lbl}>Prioridad</label><select value={f.priority} onChange={e=>set("priority",e.target.value)} style={inp}>{Object.entries(PRIORITIES).map(([k,v])=><option key={k} value={k}>{v}</option>)}</select></div>}
        </div>
        {!isClient&&<div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:12}}>
          <div><label style={lbl}>Prioridad</label><select value={f.priority} onChange={e=>set("priority",e.target.value)} style={inp}>{Object.entries(PRIORITIES).map(([k,v])=><option key={k} value={k}>{v}</option>)}</select></div>
          <div><label style={lbl}>Responsable</label><select value={f.assigneeId} onChange={e=>set("assigneeId",e.target.value)} style={inp}><option value="">Sin asignar</option>{team.map(m=><option key={m.id} value={m.id}>{m.name}</option>)}</select></div>
        </div>}
        {!isClient&&<div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:12}}>
          <div><label style={lbl}>Fecha límite</label><input type="date" value={f.dueDate} onChange={e=>set("dueDate",e.target.value)} style={inp}/></div>
          {isE&&<div><label style={lbl}>Estado</label><select value={f.status} onChange={e=>set("status",e.target.value)} style={inp}>{STS.map(s=><option key={s.id} value={s.id}>{s.icon} {s.label}</option>)}</select></div>}
        </div>}
      </div>
      <div style={{display:"flex",gap:10,marginTop:26,justifyContent:"flex-end",flexWrap:"wrap"}}>
        {isE&&!isClient&&<button onClick={()=>{onDelete(task.id);onClose();}} style={{padding:"9px 16px",borderRadius:8,border:"1px solid #FCA5A5",background:"#FEF2F2",color:"#DC2626",fontSize:12,fontWeight:700,cursor:"pointer",display:"flex",alignItems:"center",gap:5}}>{I.trash} Eliminar</button>}
        <div style={{flex:1}}/>
        <button onClick={onClose} style={{padding:"9px 20px",borderRadius:8,border:"1px solid var(--border)",background:"var(--card)",color:"var(--sub)",fontSize:12,fontWeight:600,cursor:"pointer"}}>Cancelar</button>
        <button disabled={!f.title.trim()} onClick={()=>{onSave({...(task||{}),...f,clientId:isClient?fixedCid:f.clientId,id:task?.id||uid(),createdAt:task?.createdAt||new Date().toISOString(),updatedAt:new Date().toISOString(),comments:task?.comments||[],activity:[...(task?.activity||[]),{type:isE?"edited":"created",at:new Date().toISOString(),by:isClient?"Cliente":"Equipo"}]});onClose();}} style={{padding:"9px 24px",borderRadius:8,border:"none",background:f.title.trim()?"var(--accent)":"var(--border)",color:f.title.trim()?"#fff":"var(--muted)",fontSize:12,fontWeight:800,cursor:f.title.trim()?"pointer":"not-allowed"}}>
          {isE?"Guardar":isClient?"Enviar solicitud":"Crear tarea"}
        </button>
      </div>
    </div>
  );
}

/* ═══ TASK DETAIL ═══ */
function TaskDetail({task,onClose,onUpdate,onDelete,isClient,clients,team}){
  const [editing,setEditing]=useState(false);
  const [comment,setComment]=useState("");
  const st=STS.find(s=>s.id===task.status);const pr=PR[task.priority];const cl=clients.find(c=>c.id===task.clientId);const as=team.find(m=>m.id===task.assigneeId);
  const addC=()=>{if(!comment.trim())return;onUpdate({...task,comments:[...(task.comments||[]),{id:uid(),text:comment.trim(),at:new Date().toISOString(),by:isClient?cl?.name||"Cliente":"Equipo"}],activity:[...(task.activity||[]),{type:"comment",at:new Date().toISOString(),by:isClient?"Cliente":"Equipo"}],updatedAt:new Date().toISOString()});setComment("");};
  if(editing)return<TaskForm task={task} onSave={onUpdate} onClose={()=>setEditing(false)} onDelete={onDelete} isClient={isClient} fixedCid={task.clientId} clients={clients} team={team}/>;
  return(
    <div>
      <div style={{display:"flex",justifyContent:"space-between",alignItems:"flex-start",marginBottom:16}}>
        <div style={{display:"flex",gap:6,flexWrap:"wrap"}}>
          <span style={{fontSize:11,fontWeight:700,background:`${st.color}15`,color:st.color,padding:"3px 10px",borderRadius:6}}>{st.icon} {st.label}</span>
          <span style={{fontSize:11,fontWeight:700,background:pr.bg,color:pr.text,padding:"3px 10px",borderRadius:6}}>{PRIORITIES[task.priority]}</span>
          {!isClient&&cl&&<span style={{fontSize:11,fontWeight:700,background:`${cl.color}12`,color:cl.color,padding:"3px 10px",borderRadius:6}}>{cl.icon} {cl.name}</span>}
        </div>
        <div style={{display:"flex",gap:2}}>
          {!isClient&&<button onClick={()=>setEditing(true)} style={{background:"none",border:"none",cursor:"pointer",color:"var(--muted)",padding:6}}>{I.edit}</button>}
          <button onClick={onClose} style={{background:"none",border:"none",cursor:"pointer",color:"var(--muted)",padding:6}}>{I.x()}</button>
        </div>
      </div>
      <h2 style={{margin:"0 0 6px",fontSize:21,fontWeight:800,color:"var(--text)",lineHeight:1.3}}>{task.title}</h2>
      <div style={{fontSize:12,color:"var(--muted)",marginBottom:16}}>{task.category}</div>
      {task.description&&<p style={{fontSize:13.5,color:"var(--sub)",lineHeight:1.7,margin:"0 0 20px",whiteSpace:"pre-wrap"}}>{task.description}</p>}
      <div style={{display:"flex",flexWrap:"wrap",gap:20,fontSize:12,color:"var(--sub)",marginBottom:20,padding:"14px 0",borderTop:"1px solid var(--border)",borderBottom:"1px solid var(--border)"}}>
        {as&&<div style={{display:"flex",alignItems:"center",gap:6}}><Av name={as.name} color={as.color} size={22}/> {as.name}</div>}
        {task.dueDate&&<div style={{display:"flex",alignItems:"center",gap:4,color:isOD(task.dueDate)?"#DC2626":"var(--sub)"}}>{I.clock} {fmtD(task.dueDate)}{isOD(task.dueDate)?" (vencida)":""}</div>}
        <div>Creada {tAgo(task.createdAt)}</div>
      </div>
      {!isClient&&<div style={{marginBottom:20}}>
        <div style={{fontSize:11,fontWeight:700,color:"var(--muted)",marginBottom:8,textTransform:"uppercase"}}>Mover a</div>
        <div style={{display:"flex",gap:5,flexWrap:"wrap"}}>
          {STS.filter(s=>s.id!==task.status).map(s=><button key={s.id} onClick={()=>onUpdate({...task,status:s.id,updatedAt:new Date().toISOString(),activity:[...(task.activity||[]),{type:"moved",to:s.label,at:new Date().toISOString(),by:"Equipo"}]})} style={{padding:"5px 12px",borderRadius:6,border:`1px solid ${s.color}33`,background:`${s.color}0A`,color:s.color,fontSize:11,fontWeight:700,cursor:"pointer"}}>{s.icon} {s.label}</button>)}
        </div>
      </div>}
      {task.activity?.length>0&&<div style={{marginBottom:20}}>
        <div style={{fontSize:11,fontWeight:700,color:"var(--muted)",marginBottom:8,textTransform:"uppercase"}}>Actividad</div>
        {task.activity.slice(-6).reverse().map((a,i)=><div key={i} style={{fontSize:11,color:"var(--muted)",display:"flex",gap:8,alignItems:"center",marginBottom:3}}><span style={{width:5,height:5,borderRadius:"50%",background:"var(--border)",flexShrink:0}}/>{a.by}: {a.type==="created"?"Creada":a.type==="edited"?"Editada":a.type==="moved"?`Movida a ${a.to}`:"Comentario"} · {tAgo(a.at)}</div>)}
      </div>}
      <div>
        <div style={{fontSize:11,fontWeight:700,color:"var(--muted)",marginBottom:10,textTransform:"uppercase"}}>Comentarios ({task.comments?.length||0})</div>
        {(task.comments||[]).map(c=><div key={c.id} style={{padding:"10px 14px",background:"var(--surface)",borderRadius:8,marginBottom:6,fontSize:13}}><div style={{display:"flex",justifyContent:"space-between",marginBottom:3}}><span style={{fontWeight:700,color:"var(--text)",fontSize:11}}>{c.by}</span><span style={{color:"var(--muted)",fontSize:10}}>{tAgo(c.at)}</span></div><div style={{color:"var(--sub)",lineHeight:1.5}}>{c.text}</div></div>)}
        <div style={{display:"flex",gap:8,marginTop:8}}>
          <input value={comment} onChange={e=>setComment(e.target.value)} onKeyDown={e=>e.key==="Enter"&&addC()} placeholder="Escribí un comentario..." style={{flex:1,padding:"9px 14px",borderRadius:8,border:"1px solid var(--border)",background:"var(--input)",color:"var(--text)",fontSize:12,outline:"none",fontFamily:"inherit"}}/>
          <button onClick={addC} style={{padding:"9px 18px",borderRadius:8,border:"none",background:"var(--accent)",color:"#fff",fontSize:12,fontWeight:700,cursor:"pointer"}}>Enviar</button>
        </div>
      </div>
    </div>
  );
}

/* ═══ CARD / COLUMN / LISTVIEW ═══ */
function TCard({task,onOpen,onDragStart,isClient,clients,team}){
  const pr=PR[task.priority];const cl=clients.find(c=>c.id===task.clientId);const as=team.find(m=>m.id===task.assigneeId);const od=isOD(task.dueDate);
  return(
    <div draggable={!isClient} onDragStart={e=>{e.dataTransfer.setData("text/plain",task.id);onDragStart?.(task.id);}} onClick={()=>onOpen(task)}
      style={{background:"var(--card)",borderRadius:10,padding:"13px 15px",marginBottom:7,cursor:isClient?"pointer":"grab",border:"1px solid var(--border)",borderLeft:`3px solid ${isClient?pr.dot:cl?.color||"var(--border)"}`,transition:"box-shadow .12s, transform .12s"}}
      onMouseEnter={e=>{e.currentTarget.style.boxShadow="0 4px 16px rgba(0,0,0,.07)";e.currentTarget.style.transform="translateY(-1px)";}}
      onMouseLeave={e=>{e.currentTarget.style.boxShadow="none";e.currentTarget.style.transform="none";}}>
      <div style={{display:"flex",alignItems:"center",gap:6,marginBottom:7}}>
        <span style={{fontSize:9,fontWeight:800,textTransform:"uppercase",letterSpacing:".06em",background:pr.bg,color:pr.text,padding:"2px 7px",borderRadius:4}}>{PRIORITIES[task.priority]}</span>
        {!isClient&&cl&&<span style={{fontSize:10,color:cl.color,fontWeight:700}}>{cl.icon}</span>}
        <span style={{fontSize:10,color:"var(--muted)",marginLeft:"auto"}}>{task.category?.split(" / ")[0]}</span>
      </div>
      <div style={{fontSize:13,fontWeight:700,color:"var(--text)",lineHeight:1.35,marginBottom:8}}>{task.title}</div>
      {isClient&&task.description&&<div style={{fontSize:11,color:"var(--sub)",lineHeight:1.5,marginBottom:8,display:"-webkit-box",WebkitLineClamp:2,WebkitBoxOrient:"vertical",overflow:"hidden"}}>{task.description}</div>}
      <div style={{display:"flex",alignItems:"center",gap:8,fontSize:10,color:"var(--muted)"}}>
        {as&&<Av name={as.name} color={as.color} size={20}/>}
        {task.dueDate&&<span style={{display:"flex",alignItems:"center",gap:3,color:od?"#DC2626":"var(--muted)",fontWeight:od?700:500}}>{od?I.alert:I.clock} {fmtD(task.dueDate)}</span>}
        {task.comments?.length>0&&<span style={{display:"flex",alignItems:"center",gap:3}}>{I.comment} {task.comments.length}</span>}
        <span style={{marginLeft:"auto"}}>{tAgo(task.createdAt)}</span>
      </div>
    </div>
  );
}

function Col({col,tasks,onOpen,onDragStart,onDrop,isClient,clients,team}){
  const [over,setOver]=useState(false);
  return(
    <div onDragOver={e=>{e.preventDefault();setOver(true);}} onDragLeave={()=>setOver(false)} onDrop={e=>{e.preventDefault();setOver(false);onDrop(e.dataTransfer.getData("text/plain"),col.id);}}
      style={{flex:"1 1 260px",minWidth:250,maxWidth:340,background:over?"var(--col-hover)":"var(--surface)",borderRadius:14,padding:"10px 10px 6px",display:"flex",flexDirection:"column",transition:"background .1s"}}>
      <div style={{display:"flex",alignItems:"center",gap:7,padding:"6px 6px 12px"}}>
        <span style={{width:8,height:8,borderRadius:"50%",background:col.color}}/><span style={{fontSize:12,fontWeight:800,color:"var(--text)"}}>{col.label}</span>
        <span style={{marginLeft:"auto",fontSize:10,fontWeight:800,color:col.color,background:`${col.color}14`,padding:"2px 8px",borderRadius:8}}>{tasks.length}</span>
      </div>
      <div style={{flex:1,overflowY:"auto",minHeight:40}}>{tasks.map(t=><TCard key={t.id} task={t} onOpen={onOpen} onDragStart={onDragStart} isClient={isClient} clients={clients} team={team}/>)}</div>
    </div>
  );
}

function LView({tasks,onOpen,isClient,clients,team}){
  return <div style={{overflowX:"auto"}}><table style={{width:"100%",borderCollapse:"separate",borderSpacing:0,fontSize:12}}>
    <thead><tr>{["Tarea",...(isClient?[]:["Cliente"]),"Estado","Prioridad","Categoría",...(isClient?[]:["Responsable"]),"Fecha",""].map((h,i)=><th key={i} style={{textAlign:"left",padding:"9px 12px",borderBottom:"2px solid var(--border)",fontSize:10,fontWeight:800,color:"var(--muted)",textTransform:"uppercase",position:"sticky",top:0,background:"var(--bg)"}}>{h}</th>)}</tr></thead>
    <tbody>{tasks.map(t=>{const st=STS.find(s=>s.id===t.status);const pr=PR[t.priority];const cl=clients.find(c=>c.id===t.clientId);const as=team.find(m=>m.id===t.assigneeId);
      return <tr key={t.id} onClick={()=>onOpen(t)} style={{cursor:"pointer"}} onMouseEnter={e=>e.currentTarget.style.background="var(--surface)"} onMouseLeave={e=>e.currentTarget.style.background="transparent"}>
        <td style={{padding:"11px 12px",borderBottom:"1px solid var(--border)",fontWeight:700,color:"var(--text)",maxWidth:260}}><div style={{overflow:"hidden",textOverflow:"ellipsis",whiteSpace:"nowrap"}}>{t.title}</div></td>
        {!isClient&&<td style={{padding:"11px 12px",borderBottom:"1px solid var(--border)"}}>{cl&&<span style={{fontSize:10,fontWeight:700,color:cl.color}}>{cl.icon} {cl.name}</span>}</td>}
        <td style={{padding:"11px 12px",borderBottom:"1px solid var(--border)"}}><span style={{fontSize:10,fontWeight:700,color:st.color,background:`${st.color}14`,padding:"2px 8px",borderRadius:5}}>{st.icon} {st.label}</span></td>
        <td style={{padding:"11px 12px",borderBottom:"1px solid var(--border)"}}><span style={{fontSize:10,fontWeight:700,color:pr.text,background:pr.bg,padding:"2px 7px",borderRadius:4}}>{PRIORITIES[t.priority]}</span></td>
        <td style={{padding:"11px 12px",borderBottom:"1px solid var(--border)",color:"var(--sub)",fontSize:11}}>{t.category}</td>
        {!isClient&&<td style={{padding:"11px 12px",borderBottom:"1px solid var(--border)"}}>{as?<div style={{display:"flex",alignItems:"center",gap:5}}><Av name={as.name} color={as.color} size={18}/><span style={{fontSize:11,color:"var(--sub)"}}>{as.name}</span></div>:<span style={{color:"var(--muted)"}}>—</span>}</td>}
        <td style={{padding:"11px 12px",borderBottom:"1px solid var(--border)",color:isOD(t.dueDate)&&t.status!=="completada"?"#DC2626":"var(--muted)",fontSize:11}}>{t.dueDate?fmtD(t.dueDate):"—"}</td>
        <td style={{padding:"11px 12px",borderBottom:"1px solid var(--border)"}}>{t.comments?.length>0&&<span style={{display:"inline-flex",alignItems:"center",gap:3,color:"var(--muted)",fontSize:11}}>{I.comment} {t.comments.length}</span>}</td>
      </tr>;})}</tbody>
  </table></div>;
}

/* ═══ CUSTOM TOOLTIP ═══ */
const CTooltip = ({active,payload,label})=>{
  if(!active||!payload?.length) return null;
  return <div style={{background:"#181A23",border:"1px solid #2A2D3A",borderRadius:8,padding:"8px 12px",fontSize:11}}>
    <div style={{fontWeight:700,color:"#E8ECF4",marginBottom:4}}>{label}</div>
    {payload.map((p,i)=><div key={i} style={{color:p.color,display:"flex",gap:8,justifyContent:"space-between"}}><span>{p.name}</span><span style={{fontWeight:800}}>{p.value}</span></div>)}
  </div>;
};

/* ═══ DASHBOARD ═══ */
function Dashboard({tasks,clients,team,onOpenClient}){
  const cd=clients.map(c=>{const ct=tasks.filter(t=>t.clientId===c.id);return{...c,total:ct.length,activas:ct.filter(t=>t.status==="en_progreso"||t.status==="revision").length,terminadas:ct.filter(t=>t.status==="completada").length,sinArrancar:ct.filter(t=>t.status==="backlog"||t.status==="pendiente").length,paradas:ct.filter(t=>isPar(t)).length,overdue:ct.filter(t=>isOD(t.dueDate)&&t.status!=="completada").length};});
  const tA=tasks.filter(t=>t.status==="en_progreso"||t.status==="revision").length;
  const tD=tasks.filter(t=>t.status==="completada").length;
  const tP=tasks.filter(t=>t.status==="backlog"||t.status==="pendiente").length;
  const tO=tasks.filter(t=>isOD(t.dueDate)&&t.status!=="completada").length;
  const tPa=tasks.filter(t=>isPar(t)).length;
  const bm=team.map(m=>({...m,count:tasks.filter(t=>t.assigneeId===m.id).length,done:tasks.filter(t=>t.assigneeId===m.id&&t.status==="completada").length,active:tasks.filter(t=>t.assigneeId===m.id&&(t.status==="en_progreso"||t.status==="revision")).length}));

  const card={background:"var(--card)",borderRadius:12,padding:"18px 20px",border:"1px solid var(--border)"};
  const sN={fontSize:28,fontWeight:900,color:"var(--text)",lineHeight:1,letterSpacing:"-0.03em"};
  const sL={fontSize:11,color:"var(--muted)",fontWeight:600,marginTop:4,textTransform:"uppercase",letterSpacing:".04em"};
  const SC=[{key:"activas",label:"Activas",color:"#3B82F6",icon:"◐"},{key:"terminadas",label:"Terminadas",color:"#10B981",icon:"●"},{key:"sinArrancar",label:"Sin arrancar",color:"#64748B",icon:"○"},{key:"paradas",label:"Paradas",color:"#F59E0B",icon:"⏸"}];

  // Chart data
  const pieData = STS.map(s=>({name:s.label,value:tasks.filter(t=>t.status===s.id).length,color:s.color})).filter(d=>d.value>0);
  const barData = cd.map(c=>({name:c.name.length>12?c.name.substring(0,12)+"…":c.name,Activas:c.activas,Terminadas:c.terminadas,"Sin arrancar":c.sinArrancar,Paradas:c.paradas}));

  return(
    <div style={{display:"flex",flexDirection:"column",gap:16}}>
      {/* KPIs */}
      <div style={{display:"grid",gridTemplateColumns:"repeat(auto-fit, minmax(130px, 1fr))",gap:10}}>
        <div style={card}><div style={sN}>{tasks.length}</div><div style={sL}>Total</div></div>
        <div style={card}><div style={{...sN,color:"#3B82F6"}}>{tA}</div><div style={sL}>Activas</div></div>
        <div style={card}><div style={{...sN,color:"#10B981"}}>{tD}</div><div style={sL}>Terminadas</div></div>
        <div style={card}><div style={{...sN,color:"#64748B"}}>{tP}</div><div style={sL}>Sin arrancar</div></div>
        <div style={card}><div style={{...sN,color:tPa>0?"#F59E0B":"var(--text)"}}>{tPa}</div><div style={sL}>Paradas</div></div>
        <div style={card}><div style={{...sN,color:tO>0?"#DC2626":"var(--text)"}}>{tO}</div><div style={sL}>Vencidas</div></div>
      </div>

      {/* Charts row */}
      <div style={{display:"grid",gridTemplateColumns:"1fr 2fr",gap:12}}>
        {/* Pie */}
        <div style={card}>
          <div style={{fontSize:13,fontWeight:800,color:"var(--text)",marginBottom:8}}>Estado general</div>
          {pieData.length>0?<ResponsiveContainer width="100%" height={200}>
            <PieChart><Pie data={pieData} cx="50%" cy="50%" innerRadius={45} outerRadius={75} paddingAngle={3} dataKey="value" stroke="none">
              {pieData.map((d,i)=><Cell key={i} fill={d.color}/>)}
            </Pie><Tooltip content={<CTooltip/>}/></PieChart>
          </ResponsiveContainer>:<div style={{height:200,display:"flex",alignItems:"center",justifyContent:"center",color:"var(--muted)",fontSize:13}}>Sin datos</div>}
          <div style={{display:"flex",flexWrap:"wrap",gap:8,justifyContent:"center"}}>
            {pieData.map(d=><span key={d.name} style={{fontSize:10,color:"var(--muted)",display:"flex",alignItems:"center",gap:4}}><span style={{width:7,height:7,borderRadius:"50%",background:d.color}}/>{d.name}: {d.value}</span>)}
          </div>
        </div>
        {/* Bar */}
        <div style={card}>
          <div style={{fontSize:13,fontWeight:800,color:"var(--text)",marginBottom:8}}>Tareas por cliente</div>
          {barData.length>0?<ResponsiveContainer width="100%" height={230}>
            <BarChart data={barData} barCategoryGap="20%">
              <XAxis dataKey="name" tick={{fill:"#5C6278",fontSize:10}} axisLine={false} tickLine={false}/>
              <YAxis tick={{fill:"#5C6278",fontSize:10}} axisLine={false} tickLine={false} allowDecimals={false}/>
              <Tooltip content={<CTooltip/>} cursor={{fill:"rgba(255,255,255,.03)"}}/>
              <Bar dataKey="Activas" fill="#3B82F6" radius={[3,3,0,0]} stackId="a"/>
              <Bar dataKey="Terminadas" fill="#10B981" radius={[0,0,0,0]} stackId="a"/>
              <Bar dataKey="Sin arrancar" fill="#64748B" radius={[0,0,0,0]} stackId="a"/>
              <Bar dataKey="Paradas" fill="#F59E0B" radius={[0,0,3,3]} stackId="a"/>
            </BarChart>
          </ResponsiveContainer>:<div style={{height:230,display:"flex",alignItems:"center",justifyContent:"center",color:"var(--muted)",fontSize:13}}>Sin datos</div>}
        </div>
      </div>

      {/* Client table */}
      <div style={{...card,padding:0,overflow:"hidden"}}>
        <div style={{padding:"16px 20px 12px",borderBottom:"1px solid var(--border)"}}>
          <div style={{fontSize:14,fontWeight:800,color:"var(--text)"}}>Resumen por cliente</div>
          <div style={{fontSize:11,color:"var(--muted)",marginTop:2}}>Click en un cliente para abrir su portal</div>
        </div>
        <div style={{overflowX:"auto"}}><table style={{width:"100%",borderCollapse:"separate",borderSpacing:0}}>
          <thead><tr>
            <th style={{textAlign:"left",padding:"10px 20px",fontSize:10,fontWeight:800,color:"var(--muted)",textTransform:"uppercase",borderBottom:"1px solid var(--border)"}}>Cliente</th>
            <th style={{textAlign:"center",padding:"10px 12px",fontSize:10,fontWeight:800,color:"var(--muted)",textTransform:"uppercase",borderBottom:"1px solid var(--border)"}}>Total</th>
            {SC.map(sc=><th key={sc.key} style={{textAlign:"center",padding:"10px 12px",fontSize:10,fontWeight:800,color:sc.color,textTransform:"uppercase",borderBottom:"1px solid var(--border)"}}>{sc.icon} {sc.label}</th>)}
            <th style={{textAlign:"center",padding:"10px 12px",fontSize:10,fontWeight:800,color:"#DC2626",textTransform:"uppercase",borderBottom:"1px solid var(--border)"}}>⚠ Vencidas</th>
            <th style={{textAlign:"left",padding:"10px 20px",fontSize:10,fontWeight:800,color:"var(--muted)",textTransform:"uppercase",borderBottom:"1px solid var(--border)"}}>Progreso</th>
          </tr></thead>
          <tbody>
            {cd.map((c,idx)=>{const pct=c.total>0?Math.round((c.terminadas/c.total)*100):0;return(
              <tr key={c.id} onClick={()=>onOpenClient(c.id)} style={{cursor:"pointer",background:idx%2===0?"transparent":"var(--surface)"}} onMouseEnter={e=>e.currentTarget.style.background="var(--col-hover)"} onMouseLeave={e=>e.currentTarget.style.background=idx%2===0?"transparent":"var(--surface)"}>
                <td style={{padding:"14px 20px",borderBottom:"1px solid var(--border)"}}><div style={{display:"flex",alignItems:"center",gap:10}}><span style={{fontSize:20}}>{c.icon}</span><div><div style={{fontSize:13,fontWeight:800,color:"var(--text)"}}>{c.name}</div><div style={{fontSize:10,color:"var(--muted)"}}>{c.total} tareas</div></div></div></td>
                <td style={{padding:"14px 12px",borderBottom:"1px solid var(--border)",textAlign:"center",fontSize:16,fontWeight:900,color:"var(--text)"}}>{c.total}</td>
                {SC.map(sc=><td key={sc.key} style={{padding:"14px 12px",borderBottom:"1px solid var(--border)",textAlign:"center"}}><div style={{display:"inline-flex",alignItems:"center",justifyContent:"center",minWidth:36,height:32,borderRadius:8,background:c[sc.key]>0?`${sc.color}15`:"transparent",color:c[sc.key]>0?sc.color:"var(--muted)",fontSize:15,fontWeight:900,padding:"0 10px"}}>{c[sc.key]}</div></td>)}
                <td style={{padding:"14px 12px",borderBottom:"1px solid var(--border)",textAlign:"center"}}><div style={{display:"inline-flex",alignItems:"center",justifyContent:"center",minWidth:36,height:32,borderRadius:8,background:c.overdue>0?"#DC262615":"transparent",color:c.overdue>0?"#DC2626":"var(--muted)",fontSize:15,fontWeight:900,padding:"0 10px"}}>{c.overdue}</div></td>
                <td style={{padding:"14px 20px",borderBottom:"1px solid var(--border)"}}><div style={{display:"flex",alignItems:"center",gap:10}}><div style={{flex:1,height:7,borderRadius:4,background:"var(--surface)",overflow:"hidden",minWidth:80}}><div style={{height:"100%",borderRadius:4,width:`${pct}%`,background:pct===100?"#10B981":pct>=50?"#3B82F6":pct>0?"#F59E0B":"var(--border)",transition:"width .4s"}}/></div><span style={{fontSize:12,fontWeight:800,color:pct===100?"#10B981":"var(--sub)",minWidth:36}}>{pct}%</span></div></td>
              </tr>);})}
            <tr style={{background:"var(--surface)"}}>
              <td style={{padding:"14px 20px",fontWeight:900,fontSize:12,color:"var(--text)",textTransform:"uppercase"}}>TOTAL</td>
              <td style={{padding:"14px 12px",textAlign:"center",fontWeight:900,fontSize:16,color:"var(--text)"}}>{tasks.length}</td>
              {SC.map(sc=><td key={sc.key} style={{padding:"14px 12px",textAlign:"center",fontWeight:900,fontSize:16,color:sc.color}}>{cd.reduce((s,c)=>s+c[sc.key],0)}</td>)}
              <td style={{padding:"14px 12px",textAlign:"center",fontWeight:900,fontSize:16,color:"#DC2626"}}>{tO}</td>
              <td style={{padding:"14px 20px"}}><span style={{fontSize:12,fontWeight:800,color:"var(--sub)"}}>{tasks.length>0?Math.round((tD/tasks.length)*100):0}% completado</span></td>
            </tr>
          </tbody>
        </table></div>
      </div>

      {/* Team workload */}
      <div style={card}>
        <div style={{fontSize:13,fontWeight:800,color:"var(--text)",marginBottom:14}}>Carga del equipo</div>
        {bm.map(m=>(
          <div key={m.id} style={{display:"flex",alignItems:"center",gap:10,marginBottom:12}}>
            <Av name={m.name} color={m.color} size={30}/>
            <div style={{flex:1}}>
              <div style={{fontSize:12,fontWeight:700,color:"var(--text)"}}>{m.name} <span style={{fontWeight:400,color:"var(--muted)"}}>· {m.role}</span></div>
              <div style={{display:"flex",gap:4,marginTop:5}}>
                <div style={{height:5,flex:m.active||0.01,background:"#3B82F6",borderRadius:3}} title={`Activas: ${m.active}`}/>
                <div style={{height:5,flex:m.done||0.01,background:"#10B981",borderRadius:3}} title={`Terminadas: ${m.done}`}/>
                <div style={{height:5,flex:Math.max(m.count-m.active-m.done,0)||0.01,background:"#64748B",borderRadius:3}}/>
              </div>
            </div>
            <div style={{textAlign:"right"}}><div style={{fontSize:14,fontWeight:900,color:"var(--text)"}}>{m.count}</div><div style={{fontSize:9,color:"var(--muted)"}}>{m.active} activas</div></div>
          </div>
        ))}
      </div>
    </div>
  );
}

/* ═══ CLIENT PORTAL ═══ */
function ClientPortal({client,tasks,onBack,onOpen,onDrop,setShowForm,search,setSearch,clients,team}){
  const ct=tasks.filter(t=>t.clientId===client.id);
  const sf=ct.filter(t=>!search||t.title.toLowerCase().includes(search.toLowerCase())||(t.description||"").toLowerCase().includes(search.toLowerCase()));
  const ac=ct.filter(t=>t.status==="en_progreso"||t.status==="revision").length;
  const te=ct.filter(t=>t.status==="completada").length;
  const sa=ct.filter(t=>t.status==="backlog"||t.status==="pendiente").length;
  const pa=ct.filter(t=>isPar(t)).length;
  const ms=(l,v,c)=><div style={{textAlign:"center",padding:"12px 16px",background:"var(--surface)",borderRadius:10,flex:"1 1 90px"}}><div style={{fontSize:22,fontWeight:900,color:c,letterSpacing:"-0.03em"}}>{v}</div><div style={{fontSize:10,fontWeight:700,color:"var(--muted)",marginTop:2,textTransform:"uppercase",letterSpacing:".04em"}}>{l}</div></div>;
  return(
    <div style={{display:"flex",flexDirection:"column",height:"100vh"}}>
      <div style={{padding:"16px 24px",borderBottom:"1px solid var(--border)",background:"var(--card)"}}>
        <div style={{display:"flex",alignItems:"center",gap:12,marginBottom:14,flexWrap:"wrap"}}>
          <button onClick={onBack} style={{background:"var(--surface)",border:"1px solid var(--border)",borderRadius:8,padding:"6px 10px",cursor:"pointer",color:"var(--sub)",display:"flex",alignItems:"center",gap:4,fontSize:11,fontWeight:600}}>{I.back} Agencia</button>
          <span style={{fontSize:24}}>{client.icon}</span>
          <div><h1 style={{margin:0,fontSize:20,fontWeight:900,color:"var(--text)",letterSpacing:"-0.02em"}}>{client.name}</h1><div style={{fontSize:11,color:"var(--muted)"}}>Portal del cliente</div></div>
          <div style={{marginLeft:"auto",display:"flex",gap:8,alignItems:"center"}}>
            <div style={{position:"relative"}}><span style={{position:"absolute",left:10,top:"50%",transform:"translateY(-50%)",color:"var(--muted)"}}>{I.search}</span><input value={search} onChange={e=>setSearch(e.target.value)} placeholder="Buscar..." style={{padding:"8px 10px 8px 32px",borderRadius:8,border:"1px solid var(--border)",background:"var(--input)",color:"var(--text)",fontSize:12,outline:"none",width:180,fontFamily:"inherit"}}/></div>
            <button onClick={()=>setShowForm(true)} style={{display:"flex",alignItems:"center",gap:6,padding:"9px 20px",borderRadius:9,border:"none",background:client.color,color:"#fff",fontSize:12,fontWeight:800,cursor:"pointer"}}>{I.plus(16)} Nueva solicitud</button>
          </div>
        </div>
        <div style={{display:"flex",gap:8}}>{ms("Activas",ac,"#3B82F6")}{ms("Terminadas",te,"#10B981")}{ms("Sin arrancar",sa,"#64748B")}{ms("Paradas",pa,pa>0?"#F59E0B":"var(--muted)")}{ms("Total",ct.length,"var(--text)")}</div>
      </div>
      <div style={{flex:1,overflow:"auto",padding:"20px 24px"}}>
        {sf.length===0&&ct.length===0?<div style={{textAlign:"center",padding:"80px 20px",color:"var(--muted)"}}><div style={{fontSize:44,marginBottom:14}}>📋</div><div style={{fontSize:17,fontWeight:800,color:"var(--sub)",marginBottom:8}}>No hay tareas todavía</div><div style={{fontSize:13,marginBottom:24}}>Enviá tu primera solicitud</div><button onClick={()=>setShowForm(true)} style={{padding:"11px 28px",borderRadius:9,border:"none",background:client.color,color:"#fff",fontSize:13,fontWeight:700,cursor:"pointer"}}>{I.plus(16)} Nueva solicitud</button></div>
        :sf.length===0?<div style={{textAlign:"center",padding:"60px 20px",color:"var(--muted)"}}><div style={{fontSize:32,marginBottom:10}}>🔍</div><div style={{fontSize:14,fontWeight:600}}>No se encontraron tareas</div></div>
        :<div style={{display:"flex",gap:12,overflowX:"auto",paddingBottom:16}}>{BOARD_STS.map(col=><Col key={col.id} col={col} tasks={sf.filter(t=>t.status===col.id)} onOpen={onOpen} onDrop={onDrop} isClient clients={clients} team={team}/>)}</div>}
      </div>
    </div>
  );
}

/* ═══ SIDEBAR ═══ */
function Sidebar({clientFilter,setClientFilter,tasks,view,setView,onOpenClient,clients,team,onSettings}){
  const nb=(id,icon,label)=><button key={id} onClick={()=>{setView(id);setClientFilter("all");}} style={{display:"flex",alignItems:"center",gap:9,width:"100%",padding:"8px 12px",borderRadius:8,border:"none",background:view===id?"var(--accent-soft)":"transparent",color:view===id?"var(--accent)":"var(--sub)",fontSize:12,fontWeight:view===id?700:500,cursor:"pointer",textAlign:"left"}}>{icon} {label}</button>;
  return(
    <div style={{width:220,flexShrink:0,padding:"20px 14px",borderRight:"1px solid var(--border)",background:"var(--card)",display:"flex",flexDirection:"column",gap:4,overflowY:"auto"}}>
      <div style={{display:"flex",alignItems:"center",gap:10,padding:"4px 8px 20px"}}>
        <div style={{width:32,height:32,borderRadius:9,background:"linear-gradient(135deg,#7C3AED,#2563EB)",display:"flex",alignItems:"center",justifyContent:"center",color:"#fff",fontWeight:900,fontSize:11}}>ANM</div>
        <div><div style={{fontSize:14,fontWeight:900,color:"var(--text)"}}>ANM Studio</div><div style={{fontSize:10,color:"var(--muted)"}}>Task Manager</div></div>
      </div>
      {nb("dashboard",I.dash,"Dashboard")}
      {nb("board",I.board,"Tablero")}
      {nb("list",I.list,"Lista")}
      <div style={{marginTop:20,padding:"0 8px",marginBottom:6}}><div style={{fontSize:10,fontWeight:800,color:"var(--muted)",textTransform:"uppercase",letterSpacing:".06em"}}>Clientes</div></div>
      <button onClick={()=>{setClientFilter("all");setView("board");}} style={{display:"flex",alignItems:"center",gap:9,width:"100%",padding:"7px 12px",borderRadius:8,border:"none",background:clientFilter==="all"&&view!=="dashboard"?"var(--surface)":"transparent",color:clientFilter==="all"?"var(--text)":"var(--sub)",fontSize:12,fontWeight:clientFilter==="all"?700:500,cursor:"pointer",textAlign:"left"}}>📁 Todos <span style={{marginLeft:"auto",fontSize:10,color:"var(--muted)"}}>{tasks.length}</span></button>
      {clients.map(c=>{const n=tasks.filter(t=>t.clientId===c.id).length;return(
        <div key={c.id} style={{display:"flex",gap:2}}>
          <button onClick={()=>{setClientFilter(c.id);setView("board");}} style={{display:"flex",alignItems:"center",gap:9,flex:1,padding:"7px 12px",borderRadius:"8px 0 0 8px",border:"none",background:clientFilter===c.id?`${c.color}10`:"transparent",color:clientFilter===c.id?c.color:"var(--sub)",fontSize:12,fontWeight:clientFilter===c.id?700:500,cursor:"pointer",textAlign:"left"}}>{c.icon} {c.name} <span style={{marginLeft:"auto",fontSize:10,color:"var(--muted)"}}>{n}</span></button>
          <button onClick={()=>onOpenClient(c.id)} title={`Portal de ${c.name}`} style={{padding:"7px 8px",borderRadius:"0 8px 8px 0",border:"none",background:clientFilter===c.id?`${c.color}10`:"transparent",color:"var(--muted)",cursor:"pointer",display:"flex",alignItems:"center"}}>{I.portal}</button>
        </div>
      );})}
      <div style={{marginTop:20,padding:"0 8px",marginBottom:6}}><div style={{fontSize:10,fontWeight:800,color:"var(--muted)",textTransform:"uppercase",letterSpacing:".06em"}}>Equipo</div></div>
      {team.map(m=><div key={m.id} style={{display:"flex",alignItems:"center",gap:8,padding:"5px 12px"}}><Av name={m.name} color={m.color} size={22}/><div><div style={{fontSize:11,fontWeight:700,color:"var(--text)"}}>{m.name}</div><div style={{fontSize:9,color:"var(--muted)"}}>{m.role}</div></div></div>)}
      <div style={{marginTop:"auto",paddingTop:20}}>
        <button onClick={onSettings} style={{display:"flex",alignItems:"center",gap:9,width:"100%",padding:"8px 12px",borderRadius:8,border:"none",background:"transparent",color:"var(--muted)",fontSize:12,fontWeight:500,cursor:"pointer",textAlign:"left"}}>{I.gear} Configuración</button>
      </div>
    </div>
  );
}

/* ═══ MAIN APP ═══ */
export default function App(){
  const [tasks,setTasks,ld1]=usePersist(SK.tasks,[]);
  const [clients,setClients,ld2]=usePersist(SK.clients,DEF_CLIENTS);
  const [team,setTeam,ld3]=usePersist(SK.team,DEF_TEAM);
  const [view,setView]=useState("dashboard");
  const [cf,setCf]=useState("all");
  const [cp,setCp]=useState(null);
  const [search,setSearch]=useState("");
  const [fp,setFp]=useState("all");
  const [fa,setFa]=useState("all");
  const [sf,setSf]=useState(false);
  const [st,setSt]=useState(null);
  const [showSettings,setShowSettings]=useState(false);

  const loaded=ld1&&ld2&&ld3;
  const filtered=useMemo(()=>tasks.filter(t=>{if(cf!=="all"&&t.clientId!==cf)return false;if(search&&!t.title.toLowerCase().includes(search.toLowerCase())&&!(t.description||"").toLowerCase().includes(search.toLowerCase()))return false;if(fp!=="all"&&t.priority!==fp)return false;if(fa!=="all"&&t.assigneeId!==fa)return false;return true;}),[tasks,cf,search,fp,fa]);

  const save=task=>{setTasks(p=>{const i=p.findIndex(t=>t.id===task.id);if(i>=0){const c=[...p];c[i]=task;return c;}return[task,...p];});if(st?.id===task.id)setSt(task);};
  const del=id=>{setTasks(p=>p.filter(t=>t.id!==id));setSt(null);};
  const mov=(id,ns)=>{setTasks(p=>p.map(t=>t.id===id?{...t,status:ns,updatedAt:new Date().toISOString(),activity:[...(t.activity||[]),{type:"moved",to:STS.find(s=>s.id===ns)?.label,at:new Date().toISOString(),by:cp?"Cliente":"Equipo"}]}:t));};
  const openP=id=>{setCp(id);setSearch("");};
  const closeP=()=>{setCp(null);setSearch("");};

  const pc=clients.find(c=>c.id===cp);
  const selS={padding:"7px 12px",borderRadius:7,border:"1px solid var(--border)",background:"var(--input)",color:"var(--sub)",fontSize:11,outline:"none",cursor:"pointer",fontFamily:"inherit"};
  const ac=clients.find(c=>c.id===cf);

  if(!loaded) return(
    <div style={{minHeight:"100vh",background:"#0F1117",display:"flex",alignItems:"center",justifyContent:"center",flexDirection:"column",gap:16,fontFamily:"'Outfit',system-ui,sans-serif"}}>
      <style>{`@import url('https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800;900&display=swap');@keyframes spin{to{transform:rotate(360deg)}}`}</style>
      <div style={{width:40,height:40,border:"3px solid #2A2D3A",borderTopColor:"#4F8CFF",borderRadius:"50%",animation:"spin .8s linear infinite"}}/>
      <div style={{color:"#5C6278",fontSize:13,fontWeight:600}}>Cargando...</div>
    </div>
  );

  return(
    <div style={{"--bg":"#0F1117","--card":"#181A23","--surface":"#1E2029","--col-hover":"#252731","--border":"#2A2D3A","--text":"#E8ECF4","--sub":"#9CA3B4","--muted":"#5C6278","--accent":"#4F8CFF","--accent-soft":"#4F8CFF18","--accent-hover":"#3A75E8","--input":"#1A1C26",fontFamily:"'Outfit','Satoshi',system-ui,sans-serif",minHeight:"100vh",background:"var(--bg)",color:"var(--text)",display:"flex"}}>
      <style>{`@import url('https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800;900&display=swap');@keyframes fadeIn{from{opacity:0}to{opacity:1}}@keyframes slideUp{from{opacity:0;transform:translateY(16px)}to{opacity:1;transform:translateY(0)}}@keyframes spin{to{transform:rotate(360deg)}}*{box-sizing:border-box}::-webkit-scrollbar{width:5px;height:5px}::-webkit-scrollbar-track{background:transparent}::-webkit-scrollbar-thumb{background:var(--border);border-radius:3px}select{appearance:auto}`}</style>

      {cp&&pc?(
        <div style={{flex:1}}>
          <ClientPortal client={pc} tasks={tasks} onBack={closeP} onOpen={setSt} onDrop={mov} setShowForm={setSf} search={search} setSearch={setSearch} clients={clients} team={team}/>
          {sf&&<Mod onClose={()=>setSf(false)}><TaskForm onSave={save} onClose={()=>setSf(false)} isClient fixedCid={cp} clients={clients} team={team}/></Mod>}
          {st&&<Mod onClose={()=>setSt(null)} wide><TaskDetail task={st} onClose={()=>setSt(null)} onUpdate={t=>{save(t);setSt(t);}} onDelete={del} isClient clients={clients} team={team}/></Mod>}
        </div>
      ):(
        <>
          <Sidebar clientFilter={cf} setClientFilter={setCf} tasks={tasks} view={view} setView={setView} onOpenClient={openP} clients={clients} team={team} onSettings={()=>setShowSettings(true)}/>
          <div style={{flex:1,display:"flex",flexDirection:"column",overflow:"hidden"}}>
            <div style={{padding:"16px 24px",borderBottom:"1px solid var(--border)",background:"var(--card)",display:"flex",alignItems:"center",gap:12,flexWrap:"wrap"}}>
              <div style={{flex:"1 1 auto",display:"flex",alignItems:"center",gap:12}}>
                <h1 style={{margin:0,fontSize:17,fontWeight:800,letterSpacing:"-0.02em"}}>{view==="dashboard"?"Dashboard":ac?`${ac.icon} ${ac.name}`:"Todas las tareas"}</h1>
                {view!=="dashboard"&&<>
                  <div style={{position:"relative"}}><span style={{position:"absolute",left:10,top:"50%",transform:"translateY(-50%)",color:"var(--muted)"}}>{I.search}</span><input value={search} onChange={e=>setSearch(e.target.value)} placeholder="Buscar..." style={{padding:"7px 10px 7px 32px",borderRadius:7,border:"1px solid var(--border)",background:"var(--input)",color:"var(--text)",fontSize:12,outline:"none",width:180,fontFamily:"inherit"}}/></div>
                  <select value={fp} onChange={e=>setFp(e.target.value)} style={selS}><option value="all">Prioridad</option>{Object.entries(PRIORITIES).map(([k,v])=><option key={k} value={k}>{v}</option>)}</select>
                  <select value={fa} onChange={e=>setFa(e.target.value)} style={selS}><option value="all">Responsable</option>{team.map(m=><option key={m.id} value={m.id}>{m.name}</option>)}</select>
                </>}
              </div>
              <button onClick={()=>setSf(true)} style={{display:"flex",alignItems:"center",gap:6,padding:"9px 20px",borderRadius:9,border:"none",background:"var(--accent)",color:"#fff",fontSize:12,fontWeight:800,cursor:"pointer"}} onMouseEnter={e=>e.currentTarget.style.background="var(--accent-hover)"} onMouseLeave={e=>e.currentTarget.style.background="var(--accent)"}>{I.plus(16)} Nueva tarea</button>
            </div>
            <div style={{flex:1,overflow:"auto",padding:"20px 24px"}}>
              {view==="dashboard"?<Dashboard tasks={cf==="all"?tasks:tasks.filter(t=>t.clientId===cf)} clients={clients} team={team} onOpenClient={openP}/>
              :filtered.length===0&&tasks.length===0?<div style={{textAlign:"center",padding:"80px 20px",color:"var(--muted)"}}><div style={{fontSize:44,marginBottom:14}}>📋</div><div style={{fontSize:17,fontWeight:800,color:"var(--sub)",marginBottom:8}}>Sin tareas todavía</div><button onClick={()=>setSf(true)} style={{padding:"11px 28px",borderRadius:9,border:"none",background:"var(--accent)",color:"#fff",fontSize:13,fontWeight:700,cursor:"pointer"}}>{I.plus(16)} Crear tarea</button></div>
              :filtered.length===0?<div style={{textAlign:"center",padding:"60px 20px",color:"var(--muted)"}}><div style={{fontSize:32,marginBottom:10}}>🔍</div><div style={{fontSize:14,fontWeight:600}}>No hay tareas con esos filtros</div></div>
              :view==="board"?<div style={{display:"flex",gap:12,overflowX:"auto",paddingBottom:16}}>{BOARD_STS.map(col=><Col key={col.id} col={col} tasks={filtered.filter(t=>t.status===col.id)} onOpen={setSt} onDrop={mov} clients={clients} team={team}/>)}</div>
              :<LView tasks={filtered} onOpen={setSt} clients={clients} team={team}/>}
            </div>
          </div>
          {sf&&<Mod onClose={()=>setSf(false)}><TaskForm onSave={save} onClose={()=>setSf(false)} clients={clients} team={team}/></Mod>}
          {st&&<Mod onClose={()=>setSt(null)} wide><TaskDetail task={st} onClose={()=>setSt(null)} onUpdate={t=>{save(t);setSt(t);}} onDelete={del} clients={clients} team={team}/></Mod>}
          {showSettings&&<Mod onClose={()=>setShowSettings(false)} wide><Settings clients={clients} setClients={setClients} team={team} setTeam={setTeam} onClose={()=>setShowSettings(false)}/></Mod>}
        </>
      )}
    </div>
  );
}
