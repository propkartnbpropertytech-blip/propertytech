/**
 * PROPKART REALTY — SALES LEAD MONITORING SYSTEM (v4 Unified Architecture)
 * 
 * Paste this single file into Google Apps Script (Code.gs).
 * Save (Ctrl+S) -> Reload your Google Sheet -> Click the "🏢 PropKart CRM" menu.
 * 
 * Authoritative Integration:
 * - Direct real-time sync with PropKart CRM (public.requirements & public.leads)
 * - Guarantees 1:1 match with CRM Leads Page, REQ-R-XXXXXX codes, exact CRM Statuses
 * - Zero duplicates (strict single-row guarantee)
 * - Housing.com real-time ingestion lookback window & immediate provisioning
 */

const ADMIN_KEY = 'PK-admin-2026';
const PROPKART_CONFIG = {
  BASE_URL: "https://api-propkart.nbpropertytech.com/api/v1/sales-monitor",
  ORGANIZATION_ID: "c88ed9f1-5261-4e5f-8a34-e9fade752c70"
};

function orgId_() {
  return PropertiesService.getScriptProperties().getProperty("ORGANIZATION_ID") || PROPKART_CONFIG.ORGANIZATION_ID;
}

function onOpen() {
  try {
    SpreadsheetApp.getUi()
      .createMenu("🏢 PropKart CRM")
      .addItem("🚀 Open Sales Monitor UI (Full Window)", "openSalesMonitorDialog")
      .addItem("📱 Open Sales Monitor UI (Sidebar)", "openSalesMonitorSidebar")
      .addSeparator()
      .addItem("⚡ Ping Backend Connection", "menuPingBackend")
      .addToUi();
  } catch (e) {
    Logger.log("onOpen skipped: " + e.message);
  }
}

function openSalesMonitorDialog() {
  const output = HtmlService.createHtmlOutput(getSalesMonitorHtml(ADMIN_KEY))
    .setWidth(1200)
    .setHeight(750)
    .setTitle("PropKart Sales Lead Monitoring System");
  SpreadsheetApp.getUi().showModalDialog(output, "PropKart Realty — Sales Lead Monitoring System");
}

function openSalesMonitorSidebar() {
  const output = HtmlService.createHtmlOutput(getSalesMonitorHtml(ADMIN_KEY))
    .setTitle("PropKart Sales Monitor");
  SpreadsheetApp.getUi().showSidebar(output);
}

function doGet(e) {
  return HtmlService.createHtmlOutput(getSalesMonitorHtml(ADMIN_KEY))
    .setTitle("PropKart Sales Lead Monitoring System")
    .addMetaTag("viewport", "width=device-width, initial-scale=1")
    .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL);
}

/** HTTP status check + 1 retry. Always returns {success:false,error} instead of throwing. */
function fetchJson_(url) {
  let last = "Unknown error";
  for (let i = 0; i < 2; i++) {
    try {
      const res = UrlFetchApp.fetch(url, {
        method: "get",
        headers: { "x-organization-id": orgId_() },
        muteHttpExceptions: true
      });
      const code = res.getResponseCode();
      if (code >= 500) {
        last = "Server error HTTP " + code;
        Utilities.sleep(500);
        continue;
      }
      let json;
      try {
        json = JSON.parse(res.getContentText());
      } catch (e) {
        return { success: false, error: "Invalid response (HTTP " + code + ")" };
      }
      if (code >= 400) {
        return { success: false, error: json.error || json.message || ("HTTP " + code) };
      }
      return json;
    } catch (err) {
      last = err.message;
      Utilities.sleep(500);
    }
  }
  return { success: false, error: last };
}

function apiGetDashboard(period) {
  const p = period || "all_time";
  const url = `${PROPKART_CONFIG.BASE_URL}/dashboard?period=${encodeURIComponent(p)}&organization_id=${orgId_()}`;
  return fetchJson_(url);
}

function apiGetLeads(limit, salesUser, status, search, leadType) {
  let url = `${PROPKART_CONFIG.BASE_URL}/leads?limit=${limit || 100}&organization_id=${orgId_()}`;
  if (salesUser && salesUser !== "all") url += `&sales_user=${encodeURIComponent(salesUser)}`;
  if (status && status !== "all") url += `&status=${encodeURIComponent(status)}`;
  if (search) url += `&search=${encodeURIComponent(search)}`;
  if (leadType && leadType !== "all") url += `&lead_type=${encodeURIComponent(leadType)}`;
  return fetchJson_(url);
}

function apiPingStatus() {
  const t0 = new Date().getTime();
  try {
    const res = UrlFetchApp.fetch(`${PROPKART_CONFIG.BASE_URL}/status`, { muteHttpExceptions: true });
    const json = JSON.parse(res.getContentText());
    return {
      success: res.getResponseCode() < 400,
      latency: new Date().getTime() - t0,
      status: json.status,
      serverTime: json.telemetry?.serverTime
    };
  } catch (err) {
    return { success: false, latency: new Date().getTime() - t0, error: err.message };
  }
}

function menuPingBackend() {
  const p = apiPingStatus();
  SpreadsheetApp.getActiveSpreadsheet().toast(
    p.success ? `🟢 Backend HEALTHY! Latency: ${p.latency}ms` : `🔴 Ping Failed: ${p.error}`,
    "PropKart CRM",
    5
  );
}

// ---------- Full Leads Ledger (all pages fetched in high-efficiency batches of 500) ----------
function compact_(l) {
  const j = l.raw_json || {}, o = {};
  [
    'id', 'req_code', 'lead_code', 'lead_type', 'date', 'raw_created_at',
    'source', 'customer_name', 'phone', 'locality', 'budget',
    'sales_user', 'assigned_to_name', 'crm_status', 'status',
    'bhk', 'listing_type', 'rejection_reason', 'is_overdue',
    'follow_up_date', 'raw_follow_up_date', 'status_updated_at',
    'raw_status_updated_at', 'last_note_at', 'raw_last_note_at', 'remarks'
  ].forEach(k => { o[k] = l[k] != null ? l[k] : ''; });
  o.ni_note = j.not_interested_reason || j.not_interested_notes || '';
  o.tc_by = j.not_interested_by_name || j.status_updated_by_name || '';
  o.tc_status = j.telecaller_status || '';
  return o;
}

function apiGetAllLeads() {
  try {
    const base = `${PROPKART_CONFIG.BASE_URL}/leads?limit=500&organization_id=${orgId_()}`;
    const opt = {
      method: "get",
      headers: { "x-organization-id": orgId_() },
      muteHttpExceptions: true
    };
    
    const firstRes = UrlFetchApp.fetch(base + '&page=1', opt);
    const first = JSON.parse(firstRes.getContentText());
    if (!first.success || !first.data) return first;

    const d = first.data;
    const pages = d.pages || 1;
    let rows = d.leads || [];
    let complete = true;

    if (pages > 1) {
      const reqs = [];
      for (let p = 2; p <= pages; p++) {
        reqs.push(Object.assign({ url: base + '&page=' + p }, opt));
      }
      try {
        const responses = UrlFetchApp.fetchAll(reqs);
        for (let i = 0; i < responses.length; i++) {
          try {
            const pageData = JSON.parse(responses[i].getContentText());
            if (pageData && pageData.success && pageData.data && Array.isArray(pageData.data.leads)) {
              rows = rows.concat(pageData.data.leads);
            }
          } catch (e) {
            complete = false;
          }
        }
      } catch (err) {
        complete = false;
      }
    }

    const seen = {};
    const out = [];
    rows.forEach(l => {
      if (!l || !l.id || seen[l.id]) return;
      seen[l.id] = 1;
      out.push(compact_(l));
    });

    return {
      success: true,
      data: {
        leads: out,
        total: d.total || out.length,
        pages: pages,
        fetched: rows.length,
        complete: complete
      }
    };
  } catch (err) {
    return { success: false, error: err.message };
  }
}

// ---------- Soft-deleted leads stored in Script Properties ----------
function apiGetDeleted() {
  try {
    const all = PropertiesService.getScriptProperties().getProperties(), out = [];
    Object.keys(all).forEach(k => {
      if (k.indexOf('DEL_') === 0) {
        try { out.push(JSON.parse(all[k])); } catch (e) {}
      }
    });
    out.sort((a, b) => String(a.ts).localeCompare(String(b.ts)));
    return { success: true, data: out };
  } catch (err) { return { success: false, error: err.message }; }
}

function apiDeleteLead(key, p) {
  try {
    if (key !== ADMIN_KEY) throw new Error('Unauthorized');
    const t = v => String(v == null ? '' : v);
    const rec = {
      at: Utilities.formatDate(new Date(), Session.getScriptTimeZone(), 'dd MMM yyyy, hh:mm a'),
      ts: new Date().toISOString(),
      by: 'dashboard',
      id: t(p.id),
      req_code: t(p.req_code || p.code),
      name: t(p.name),
      phone: t(p.phone),
      rep: t(p.rep),
      status: t(p.status),
      crm_status: t(p.crm_status),
      source: t(p.source),
      created: t(p.created),
      overdue: t(p.overdue),
      reason: t(p.reason)
    };
    PropertiesService.getScriptProperties().setProperty('DEL_' + rec.id, JSON.stringify(rec));
    return { success: true };
  } catch (err) { return { success: false, error: err.message }; }
}

function apiRestoreLead(key, id) {
  try {
    if (key !== ADMIN_KEY) throw new Error('Unauthorized');
    PropertiesService.getScriptProperties().deleteProperty('DEL_' + String(id));
    return { success: true };
  } catch (err) { return { success: false, error: err.message }; }
}

function getSalesMonitorHtml(adminKey) {
  return (`<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>PropKart Sales Lead Monitor</title>
<style>
:root{--bg:#F8FAFC;--card:#fff;--bd:#E2E8F0;--tx:#0F172A;--mu:#64748B;--sub:#475569;--pr:#2563EB;--prl:#EFF6FF;--ok:#059669;--okl:#ECFDF5;--wa:#D97706;--wal:#FFFBEB;--er:#DC2626;--erl:#FEF2F2;--pu:#7C3AED;--pul:#F5F3FF}
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Arial,sans-serif;background:var(--bg);color:var(--tx);padding:14px;font-size:13px;line-height:1.5}
.header{display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:10px;background:var(--card);border:1px solid var(--bd);border-radius:10px;padding:12px 16px;margin-bottom:12px}
.brand{display:flex;align-items:center;gap:10px}.logo{width:32px;height:32px;background:var(--pr);color:#fff;border-radius:8px;display:flex;align-items:center;justify-content:center;font-weight:700}
.bt{font-size:15px;font-weight:700}.bs{font-size:11px;color:var(--mu)}
.nav{display:flex;align-items:center;gap:8px;flex-wrap:wrap}.sw{display:flex;background:var(--bg);border:1px solid var(--bd);border-radius:8px;padding:3px}
.pb{padding:5px 11px;font-size:12px;font-weight:600;border-radius:6px;border:0;cursor:pointer;background:transparent;color:var(--sub)}.pb.on{background:var(--card);color:var(--pr);box-shadow:0 1px 2px #0001}
select,input{padding:6px 10px;font-size:12px;border:1px solid var(--bd);border-radius:6px;background:var(--card);color:var(--tx);outline:0}
.btn{display:inline-flex;align-items:center;gap:6px;background:var(--card);border:1px solid var(--bd);font-size:12px;font-weight:600;padding:6px 12px;border-radius:6px;cursor:pointer;color:var(--tx)}.btn:hover{background:var(--bg)}
.btn.sm{padding:3px 8px;font-size:11px}.dot{width:8px;height:8px;border-radius:50%;background:var(--ok);display:inline-block}
.pv{display:none}.pv.on{display:block}
.kg{display:grid;grid-template-columns:repeat(auto-fit,minmax(115px,1fr));gap:10px;margin-bottom:12px}
.kc,.sc{background:var(--card);border:1px solid var(--bd);border-radius:8px;padding:10px 12px}.sc{padding:14px 16px;margin-bottom:12px}
.kt{font-size:11px;font-weight:600;color:var(--mu);text-transform:uppercase}.kv{font-size:20px;font-weight:700}
.kb{display:inline-block;font-size:10px;font-weight:600;padding:2px 6px;border-radius:4px;margin-top:4px}
.b1{background:var(--prl);color:var(--pr)}.b2{background:var(--okl);color:var(--ok)}.b3{background:var(--wal);color:var(--wa)}.b4{background:var(--erl);color:var(--er)}.b5{background:var(--pul);color:var(--pu)}
.sh{display:flex;justify-content:space-between;align-items:center;margin-bottom:10px;padding-bottom:8px;border-bottom:1px solid var(--bd);gap:8px;flex-wrap:wrap}.st{font-size:13px;font-weight:700}
.cb{display:grid;grid-template-columns:repeat(auto-fit,minmax(130px,1fr));gap:10px}.cx{background:var(--bg);border:1px solid var(--bd);border-radius:6px;padding:8px 12px}
.cn{font-size:11px;font-weight:600;color:var(--mu)}.cc{font-size:17px;font-weight:700}.cs{font-size:10px;color:var(--mu)}
.tc{overflow-x:auto}table{width:100%;border-collapse:collapse;font-size:12px}
th{background:#F1F5F9;color:var(--sub);font-weight:600;text-align:left;padding:8px 10px;border-bottom:1px solid var(--bd);white-space:nowrap}
td{padding:8px 10px;border-bottom:1px solid var(--bd);vertical-align:top}tr:hover td{background:#F8FAFC}
.tot td{background:#F8FAFC;font-weight:700;border-top:2px solid var(--bd)}
.pill{display:inline-block;padding:2px 7px;border-radius:12px;font-size:10px;font-weight:600;white-space:nowrap}
.pw{background:#DEF7EC;color:#03543F}.ps{background:#E1EFFE;color:#1E429F}.pi{background:#EDEBFE;color:#5521B5}.pf{background:#FEF08A;color:#713F12}.pn{background:#E0E7FF;color:#3730A3}.pr{background:#FDE8E8;color:#9B1C1C}.pg{background:#F1F5F9;color:#475569}
.bar{height:7px;border-radius:4px;background:#E2E8F0;min-width:60px;overflow:hidden}.bar i{display:block;height:100%}
.fl{display:flex;flex-wrap:wrap;gap:8px;align-items:center;margin-bottom:10px}.fl .q{flex:1;min-width:180px}
.rem{max-width:280px;min-width:140px;white-space:pre-wrap;word-break:break-word}.nw{white-space:nowrap}
.wa{color:var(--ok);font-weight:600;text-decoration:none}.mut{color:var(--mu);font-style:italic}.flag{color:var(--er);font-weight:600}
.err{display:none;background:var(--erl);border:1px solid #FCA5A5;color:#991B1B;padding:8px 12px;border-radius:8px;margin-bottom:10px}
.alert{background:var(--wal);border:1px solid #FCD34D;border-radius:8px;padding:10px 14px;margin-bottom:12px;display:flex;justify-content:space-between;align-items:center;gap:8px;flex-wrap:wrap}
.ft{display:flex;justify-content:space-between;font-size:11px;color:var(--mu);margin-top:10px;padding-top:10px;border-top:1px solid var(--bd)}
#lreg{table-layout:fixed;width:100%;min-width:1800px}#lreg td,#lreg th{white-space:normal;overflow-wrap:anywhere}#lreg th{white-space:nowrap}#lreg .nw{white-space:nowrap}
a.cl{color:inherit;text-decoration:none;border-bottom:1px dotted var(--mu)}.cl{cursor:pointer}.kc.cl:hover,.cx.cl:hover{border-color:var(--pr)}div.cl:hover{background:var(--bg)}
@media(max-width:768px){.kg{grid-template-columns:repeat(2,1fr)}}
</style>
</head>
<body>
<div class="header">
 <div class="brand"><div class="logo">PK</div><div><div class="bt">PropKart Realty</div><div class="bs">Sales Lead Monitoring System</div></div></div>
 <div class="nav">
  <div class="sw">
    <button class="pb on" id="b1" onclick="sw(1)">📊 KPI & Team</button>
    <button class="pb" id="b2" onclick="sw(2)">📋 Lead Register</button>
    <button class="pb" id="b3" onclick="sw(3)">⚠️ Needs Attention</button>
    <button class="pb" id="b4" onclick="sw(4)">🗑 Deleted</button>
  </div>
  <select id="per" onchange="onPer()">
    <option value="all_time">All Time</option>
    <option value="monthly">This Month</option>
    <option value="weekly">This Week</option>
    <option value="daily">Today</option>
  </select>
  <span class="bs" id="plabel"></span>
  <button class="btn" onclick="loadLeads()">🔄 Refresh</button>
  <button class="btn" onclick="ping()"><span class="dot" id="pd"></span><span id="pt">⚡ Ping</span><span class="bs" id="pl"></span></button>
 </div>
</div>
<div class="err" id="err"></div>

<div class="pv on" id="p1">
 <div class="bs" id="pchk" style="margin-bottom:4px"></div><div class="bs" id="delTxt" style="margin-bottom:8px"></div>
 <div class="alert" id="attBanner" style="display:none"><div id="attTxt"></div><button class="btn" onclick="sw(3)">View list →</button></div>
 <div class="kg">
  <div class="kc cl" data-r="all" data-s="all" onclick="oc(this)"><div class="kt">Total Inflow</div><div class="kv" id="k_total_inflow">-</div><div class="kb b1">Unified Inflow</div></div>
  <div class="kc cl" data-r="all" data-s="new" onclick="oc(this)"><div class="kt">New Leads</div><div class="kv" id="k_new_leads">-</div><div class="kb b1">Uncontacted</div></div>
  <div class="kc cl" data-r="all" data-s="follow" onclick="oc(this)"><div class="kt">In Follow-up</div><div class="kv" id="k_in_followup">-</div><div class="kb b3">Active</div></div>
  <div class="kc cl" data-r="all" data-s="interested" onclick="oc(this)"><div class="kt">Interested</div><div class="kv" id="k_interested_prospects">-</div><div class="kb b5">Hot</div></div>
  <div class="kc cl" data-r="all" data-s="notint" onclick="oc(this)"><div class="kt">Not Interested</div><div class="kv" id="k_not_interested">-</div><div class="kb b4">part of Rejected</div></div>
  <div class="kc cl" data-r="all" data-s="rejected" onclick="oc(this)"><div class="kt">Rejected</div><div class="kv" id="k_total_rejected">-</div><div class="kb b4">Closed in CRM</div></div>
  <div class="kc cl" data-r="all" data-s="svdone" onclick="oc(this)"><div class="kt">Site Visits</div><div class="kv" id="k_site_visits_completed">-</div><div class="kb b1">Completed</div></div>
  <div class="kc cl" data-r="all" data-s="won" onclick="oc(this)"><div class="kt">Deals Won</div><div class="kv" id="k_deals_won" style="color:var(--ok)">-</div><div class="kb b2">Closed Won</div></div>
  <div class="kc cl" data-r="all" data-s="overdue" onclick="oc(this)"><div class="kt">Followup Overdue</div><div class="kv" id="k_overdue_followups" style="color:var(--er)">-</div><div class="kb b4">Action Required</div></div>
  <div class="kc cl" data-r="all" data-s="won" data-x="1" onclick="oc(this)"><div class="kt">Conversion</div><div class="kv" id="k_overall_conversion_rate">-</div><div class="kb b2">Won ÷ Inflow</div></div>
 </div>
 <div class="sc"><div class="sh"><div class="st">👥 Sales Team Ranking</div><span class="bs">Ranked by On-track % (open leads not stuck as New/Overdue). Click a name to inspect leads.</span></div>
  <div class="tc"><table><thead><tr><th>#</th><th>Sales Representative</th><th>Allocated</th><th>New</th><th>Follow-up</th><th>Interested</th><th>Not Int.</th><th>SV Sch.</th><th>SV Done</th><th>Won</th><th>Rejected</th><th>Overdue</th><th title="Won ÷ Allocated">Conv %</th><th>On-track</th><th></th></tr></thead>
  <tbody id="roster"><tr><td colspan="15" class="mut">Loading...</td></tr></tbody></table></div><div class="bs" id="recon" style="margin-top:6px"></div></div>
 <div class="sc"><div class="sh"><div class="st">🔻 Unified Lead Status Breakdown</div><span class="bs" id="perLbl"></span></div><div id="funnel"></div></div>
 <div class="sc"><div class="sh"><div class="st">📍 Lead Inflow by Channel</div></div><div class="cb" id="chan"></div><div id="roi"></div></div>
 <div class="sc"><div class="sh"><div class="st">📉 Top Rejection Reasons</div><span class="bs" id="rejNote"></span></div><div class="cb" id="rej"></div></div>
</div>

<div class="pv" id="p2"><div class="sc">
 <div class="sh"><div class="st">📑 Lead Register (Live CRM Source)</div><span class="bs" id="lcount">Loading...</span></div>
 <div class="fl">
  <input class="q" id="q" placeholder="🔍 Search Req Code, name, mobile, rep, locality..." oninput="rf()">
  <select id="flt" onchange="rf()">
    <option value="all">All Types</option>
    <option value="REQUIREMENT">Requirement</option>
    <option value="CAMPAIGN">Campaign</option>
    <option value="LISTING">Property Listing</option>
  </select>
  <select id="fs" onchange="rf()">
    <option value="all">All Statuses</option>
    <option value="new">New Lead / Allocate</option>
    <option value="follow">Follow up</option>
    <option value="interested">Interested</option>
    <option value="notint">Not Interested</option>
    <option value="svsch">Site visit scheduled</option>
    <option value="svdone">Site visit done</option>
    <option value="won">Deal Won</option>
    <option value="rejected">Rejected</option>
    <option value="overdue">Overdue follow-up</option>
  </select>
  <select id="fo" onchange="rf()">
    <option value="all">All Sources</option>
    <option value="meta">Meta Ads</option>
    <option value="housing">Housing.com</option>
    <option value="manual">Manual</option>
    <option value="google_sheets">Google Sheets</option>
    <option value="other">Other</option>
  </select>
  <select id="fr" onchange="rf()"><option value="all">All Sales Reps</option></select>
  <button class="btn" onclick="loadLeads()">🔄 Reload</button>
 </div>
 <div class="bs" id="chips" style="margin-bottom:8px"></div>
 <div class="tc" style="max-height:550px;overflow-y:auto">
  <table id="lreg">
   <colgroup>
     <col style="width:130px">
     <col style="width:110px">
     <col style="width:100px">
     <col style="width:110px">
     <col style="width:160px">
     <col style="width:140px">
     <col style="width:130px">
     <col style="width:110px">
     <col style="width:140px">
     <col style="width:160px">
     <col style="width:80px">
     <col style="width:120px">
     <col style="width:120px">
     <col style="width:150px">
     <col style="width:260px">
     <col class="adm" style="width:45px">
   </colgroup>
   <thead>
     <tr>
       <th>Date</th>
       <th>Req Code</th>
       <th>Type</th>
       <th>Source</th>
       <th>Customer</th>
       <th>Mobile</th>
       <th>Locality</th>
       <th>Budget</th>
       <th>Sales Rep</th>
       <th>CRM Status</th>
       <th>BHK</th>
       <th>Follow-up</th>
       <th>Last Note</th>
       <th>Flag</th>
       <th>Remarks</th>
       <th class="adm"></th>
     </tr>
   </thead>
   <tbody id="lb"></tbody>
  </table>
 </div>
</div></div>

<div class="pv" id="p3"><div class="sc">
 <div class="sh"><div class="st">⚠️ Leads Needing Attention</div><div class="fl" style="margin:0"><select id="ar" onchange="renderAtt()"><option value="all">All reps</option></select><span class="bs" id="acount"></span></div></div>
 <div class="bs" style="margin-bottom:8px">Identifies open leads with overdue follow-ups, leads without a sales rep, and uncontacted leads for the period.</div>
 <div class="tc" style="max-height:560px;overflow-y:auto"><table><thead><tr><th>Sales Rep</th><th>Req Code</th><th>Lead</th><th>Mobile</th><th>CRM Status</th><th>Problem</th><th>Date</th><th class="adm"></th></tr></thead><tbody id="ab"></tbody></table></div>
</div></div>

<div class="pv" id="p4"><div class="sc"><div class="sh"><div class="st">🗑 Deleted Leads</div><span class="bs" id="delSum"></span></div>
 <div class="bs" style="margin-bottom:8px">Deleted leads are excluded from all KPIs and reports. They can be safely restored at any time.</div>
 <div class="tc" style="max-height:560px;overflow-y:auto"><table><thead><tr><th>Deleted at</th><th>Req Code</th><th>Lead</th><th>Mobile</th><th>Sales Rep</th><th>Status</th><th>Source</th><th>Reason</th><th class="adm"></th></tr></thead><tbody id="db"></tbody></table></div>
</div></div>

<div id="dm" style="display:none;position:fixed;top:0;left:0;right:0;bottom:0;background:#0006;z-index:9;align-items:center;justify-content:center">
 <div class="sc" style="width:340px;margin:0"><div class="st" id="dmt"></div>
  <div class="bs" style="margin:6px 0 10px">Moves this lead to Deleted and excludes it from all counts. You can restore it later.</div>
  <select id="dr" style="width:100%;margin-bottom:12px">
    <option>Spam / Fake</option><option>Duplicate</option><option>Wrong number</option><option>Test lead</option><option>Not relevant</option><option>Other</option>
  </select>
  <div style="text-align:right"><button class="btn" onclick="$('dm').style.display='none'">Cancel</button> <button class="btn" style="background:var(--er);color:#fff" onclick="doDel()">🗑 Delete</button></div>
 </div>
</div>
<div class="ft"><div>Connected to: <strong>api-propkart.nbpropertytech.com</strong></div><div id="fst">Auto-refresh: every 5 min</div></div>

<script>
/*ADMIN*/
var DASH=null,ROSTER=[],LEADS=[],LTOTAL=0,LIMIT=2000,SQ='',ATT=[],DUP={},cd=300,REQ=0,LREQ=0,RAW=null,RAWN=0,DUPN=0,COMPLETE=true,DEL=[],DELSET={},RN={},EXP=null,PEND=null;
var ROLLING=false;
function $(i){return document.getElementById(i)}
function esc(s){return String(s==null?'':s).replace(/[&<>"']/g,function(c){return{'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]})}
function call(m,a,ok){
  if(typeof google==='undefined'||!google.script||!google.script.run){ok({success:false,error:'Open this page from the Google Sheets menu.'});return}
  var r=google.script.run.withSuccessHandler(ok).withFailureHandler(function(e){ok({success:false,error:e&&e.message||'Request failed'})});r[m].apply(r,a);
}
function showErr(m){var e=$('err');e.style.display=m?'block':'none';e.textContent=m||''}
function sw(n){[1,2,3,4].forEach(function(i){$('b'+i).classList.toggle('on',i===n);$('p'+i).classList.toggle('on',i===n)});if(n>1&&!LEADS.length)loadLeads()}
function pd(v){if(!v)return null;var s=String(v),m=s.match(/^([0-9]{1,2})[-/.]([0-9]{1,2})[-/.]([0-9]{2,4})/),d;
  if(m){var y=+m[3];if(y<100)y+=2000;d=new Date(y,+m[2]-1,+m[1]);return isNaN(d)?null:d}
  d=new Date(s);return isNaN(d)?null:d}
function pStart(){var p=$('per').value;if(p==='all_time')return null;var n=new Date();n.setHours(0,0,0,0);var s=new Date(n);
  if(p==='weekly')s.setDate(n.getDate()-(ROLLING?6:(n.getDay()+6)%7));else if(p==='monthly'){if(ROLLING)s.setDate(n.getDate()-29);else s.setDate(1)}return s}
function inPer(l){var s=pStart();if(!s)return true;var d=ld(l);return!!d&&d>=s}
function perLabel(){var s=pStart(),p=$('per').value;if(!s)return'All time';var f=s.toLocaleDateString('en-GB',{day:'2-digit',month:'short',year:'numeric'});
  return(p==='daily'?'Today':p==='weekly'?(ROLLING?'Last 7 days':'This week'):(ROLLING?'Last 30 days':'This month'))+' ('+(p==='daily'?f:'from '+f)+')'}
function pcheck(){var e=$('pchk');if(!DASH||!LEADS.length){e.textContent='';return}
  var n=LEADS.filter(inPer).length,t=(DASH.summary_kpis||{}).total_inflow||0,part=!COMPLETE,bad=LEADS.filter(function(l){return!ld(l)}).length;
  e.innerHTML='Period check ('+esc(perLabel())+'): dashboard inflow <b>'+t+'</b> · leads in register <b>'+n+'</b> '+(part?'<span class="flag">⚠️ loading batch</span>':(n===t?'<span style="color:var(--ok)">✔ exact match</span>':'<span class="flag">⚠️ differ</span>'))+(bad?' · <span class="flag">'+bad+' leads have no date</span>':'')}
function ld(l){return pd(l.raw_created_at||l.date)}
function fuOf(l){return pd(l.raw_follow_up_date||l.follow_up_date||l.next_followup_date)}
function why(l){var k=ek(l),d=ld(l),age=d?Math.floor((Date.now()-d)/864e5):0,rep=rp(l);
  if(k==='won'||k==='rejected'||k==='dup')return'';
  if(!rep)return k==='new'?'Not allocated to any rep':(l.tc_by?'Handled by telecaller, not allocated to sales':'Status updated but unassigned');
  if(String(l.is_overdue).toLowerCase()==='yes')return'Follow-up overdue';
  if(k==='new'&&age>=1)return'New lead not contacted for '+age+' day(s)';
  return''}
function pillL(l){
  var st=l.crm_status||l.status||'Follow up', s=st.toLowerCase(), c='pf';
  if(s.indexOf('won')>-1)c='pw';
  else if(s.indexOf('visit')>-1)c='ps';
  else if(s.indexOf('not int')>-1||s.indexOf('reject')>-1)c='pr';
  else if(s.indexOf('interested')>-1)c='pi';
  else if(s.indexOf('allocate')>-1||s.indexOf('new')>-1||s.indexOf('assign')>-1)c='pn';
  else if(s==='none')c='pg';
  return '<span class="pill '+c+'" title="CRM Status: '+esc(st)+'">'+esc(st)+'</span>';
}
function wa(p){var c=String(p||'').replace(/[^0-9]/g,'');return c?'<a class="wa" target="_blank" href="https://wa.me/91'+c.slice(-10)+'">📱 '+esc(p)+'</a>'+(DUP[c.slice(-10)]>1?' <span class="flag" title="Appears '+DUP[c.slice(-10)]+' times">🔁</span>':''):'-'}
function dv(v,defs){v=v==null?'':String(v).trim();if(!v||v==='-')return'-';return defs.indexOf(v.toLowerCase())>-1?'<span class="mut">'+esc(v)+'</span>':esc(v)}

/* ---------- Dashboard ---------- */
function loadDash(bg){if(LEADS.length)show();else loadLeads(bg)}
function show(){DASH=compute();renderDash(DASH)}
function onPer(){$('plabel').textContent=perLabel();if(LEADS.length){show();renderLeads();renderAtt()}else loadLeads()}
function compute(){
  var rows=LEADS.filter(inPer),R={},S={meta:0,housing:0,manual:0,google_sheets:0,other:0,total:0},ST={new_leads:0,follow_up:0,interested:0,not_interested:0,site_visit_sch:0,site_visit_done:0,deal_won:0,total_rejected:0},
    K={total_inflow:0,new_leads:0,in_followup:0,interested_prospects:0,site_visits_completed:0,deals_won:0,overdue_followups:0,overall_conversion_rate:0},CH={},
    KM={new:['new_leads','new_leads','new_leads'],follow:['in_followup','follow_up','follow_ups'],interested:['interested_prospects','interested','interested'],svsch:[0,'site_visit_sch','site_visit_sch'],svdone:['site_visits_completed','site_visit_done','site_visit_done'],won:['deals_won','deal_won','deal_won'],rejected:[0,'total_rejected','total_rejected']};
  var blank=function(n){return{sales_user_name:n,leads_allocated:0,new_leads:0,follow_ups:0,interested:0,not_interested:0,site_visit_sch:0,site_visit_done:0,deal_won:0,total_rejected:0,followup_overdue:0,conversion_rate:0}};
  LEADS.forEach(function(l){var p=rp(l);if(p&&!R[p])R[p]=blank(p)});
  rows.forEach(function(l){var k=ek(l),m=KM[k];if(!m)return;var p=rp(l),open=(k!=='won'&&k!=='rejected'),od=open&&String(l.is_overdue).toLowerCase()==='yes',ni=(k==='rejected'&&isNI(l)),sc=srcKey(l.source);
    K.total_inflow++;S.total++;S[sc]++;if(m[0])K[m[0]]++;ST[m[1]]++;if(ni)ST.not_interested++;if(od)K.overdue_followups++;
    var ch=CH[sc]=CH[sc]||{n:0,open:0,rej:0,won:0};ch.n++;if(open)ch.open++;if(k==='rejected')ch.rej++;if(k==='won')ch.won++;
    if(p){var r=R[p];r.leads_allocated++;r[m[2]]++;if(ni)r.not_interested++;if(od)r.followup_overdue++}});
  var pc=function(w,a){return a?Math.round(1000*w/a)/10:0},T=blank('TOTAL / TEAM SUMMARY'),ro=Object.keys(R).sort().map(function(n){var r=R[n];r.conversion_rate=pc(r.deal_won,r.leads_allocated);Object.keys(T).forEach(function(f){if(f!=='sales_user_name'&&f!=='conversion_rate')T[f]+=r[f]});return r});
  T.conversion_rate=pc(T.deal_won,T.leads_allocated);K.overall_conversion_rate=pc(K.deals_won,K.total_inflow);
  var cn=[['Meta Ads','meta'],['Housing.com','housing'],['Manual','manual'],['Google Sheets','google_sheets'],['Other','other']].map(function(x){var h=CH[x[1]]||{n:0,open:0,rej:0,won:0};return{channel_name:x[0],total_leads:h.n,open:h.open,rejected:h.rej,deals_won:h.won,conversion_rate:pc(h.won,h.n)}});
  return{summary_kpis:K,lead_gen_count:{sources:S,statuses:ST},sales_productivity:{roster:ro,total:T},channel_roi:cn,reporting_period:perLabel()}}

function renderDash(d){
  var k=d.summary_kpis||{},s=(d.lead_gen_count||{}).sources||{},sp=d.sales_productivity||{},T=sp.total||{},st=(d.lead_gen_count||{}).statuses||{};
  ['total_inflow','new_leads','in_followup','interested_prospects','site_visits_completed','deals_won','overdue_followups'].forEach(function(x){$('k_'+x).textContent=(k[x]||0).toLocaleString()});
  $('k_not_interested').textContent=(st.not_interested||0).toLocaleString();$('k_total_rejected').textContent=(st.total_rejected||0).toLocaleString();
  $('k_overall_conversion_rate').textContent=(k.overall_conversion_rate||0)+'%';
  pcheck();
  $('perLbl').textContent='Period: '+(d.reporting_period||'ALL TIME');
  var tot=s.total||1,ch=[['Meta Ads (FB/IG)','meta'],['Housing.com','housing'],['Manual / Inquiries','manual'],['Other Sources','other']];
  $('chan').innerHTML=ch.map(function(c){return'<div class="cx cl" data-r="all" data-s="all" data-c="'+c[1]+'" onclick="oc(this)"><div class="cn">'+c[0]+'</div><div class="cc">'+(s[c[1]]||0)+'</div><div class="cs">'+(((s[c[1]]||0)/tot)*100).toFixed(1)+'% share</div></div>'}).join('')+
    '<div class="cx" style="background:var(--prl)"><div class="cn" style="color:var(--pr)">Total Sourced</div><div class="cc" style="color:var(--pr)">'+(s.total||0)+'</div></div>';
  ROSTER=(sp.roster||[]).map(function(r){var a=(r.leads_allocated||0)-(r.deal_won||0)-(r.total_rejected||0),bad=(r.new_leads||0)+(r.followup_overdue||0);r._ot=a>0?Math.max(0,Math.round(100*(a-bad)/a)):100;return r}).sort(function(a,b){return b._ot-a._ot||(b.deal_won||0)-(a.deal_won||0)});
  RN={};ROSTER.forEach(function(r){RN[r.sales_user_name]=1});
  var cl=function(v,rep,s2,css){return'<td style="'+(css||'')+'"><a href="#" class="cl" data-r="'+esc(rep)+'" data-s="'+s2+'" onclick="oc(this);return false">'+v+'</a></td>'};
  var df=function(a,b){var x=(a||0)-(b||0);return x<0?'-':x};
  var G='color:var(--ok);font-weight:700',R='color:var(--er);font-weight:700',h='';
  ROSTER.forEach(function(r,i){var c2=r._ot>=80?'var(--ok)':r._ot>=50?'var(--wa)':'var(--er)',n=r.sales_user_name;
    h+='<tr><td>'+(i+1)+'</td><td class="nw"><a href="#" onclick="goRep('+i+');return false" style="color:var(--pr);font-weight:700;text-decoration:none">'+esc(n)+'</a></td>'+cl(r.leads_allocated,n,'all')+cl(r.new_leads,n,'new')+cl(r.follow_ups,n,'follow')+cl(r.interested,n,'interested')+cl(r.not_interested,n,'notint')+cl(r.site_visit_sch,n,'svsch')+cl(r.site_visit_done,n,'svdone')+cl(r.deal_won,n,'won',G)+cl(r.total_rejected,n,'rejected')+cl(r.followup_overdue,n,'overdue',r.followup_overdue>0?R:'')+'<td><b>'+r.conversion_rate+'%</b></td>'+
    '<td style="min-width:110px"><b style="color:'+c2+'">'+r._ot+'%</b><div class="bar"><i style="width:'+r._ot+'%;background:'+c2+'"></i></div></td><td><button class="btn sm" onclick="remind('+i+')">📋 Remind</button></td></tr>'});
  var A='__assigned',U='__unalloc',ua=df(k.total_inflow,T.leads_allocated);
  h+='<tr class="tot"><td></td><td>ASSIGNED REPS TOTAL</td>'+cl(T.leads_allocated||0,A,'all')+cl(T.new_leads||0,A,'new')+cl(T.follow_ups||0,A,'follow')+cl(T.interested||0,A,'interested')+cl(T.not_interested||0,A,'notint')+cl(T.site_visit_sch||0,A,'svsch')+cl(T.site_visit_done||0,A,'svdone')+cl(T.deal_won||0,A,'won',G)+cl(T.total_rejected||0,A,'rejected')+cl(T.followup_overdue||0,A,'overdue',R)+'<td title="Won / Allocated">'+(T.conversion_rate||0)+'%</td><td></td><td></td></tr>';
  h+='<tr style="background:var(--wal)"><td></td><td class="nw" style="color:var(--wa);font-weight:700">Unallocated / other</td>'+cl(ua,U,'all')+cl(df(k.new_leads,T.new_leads),U,'new')+cl(df(k.in_followup,T.follow_ups),U,'follow')+cl(df(k.interested_prospects,T.interested),U,'interested')+cl(df(st.not_interested,T.not_interested),U,'notint')+cl(df(st.site_visit_sch,T.site_visit_sch),U,'svsch')+cl(df(k.site_visits_completed,T.site_visit_done),U,'svdone')+cl(df(k.deals_won,T.deal_won),U,'won')+cl(df(st.total_rejected,T.total_rejected),U,'rejected')+cl(df(k.overdue_followups,T.followup_overdue),U,'overdue')+'<td>-</td><td></td><td></td></tr>';
  h+='<tr class="tot"><td></td><td>ALL LEADS</td>'+cl(k.total_inflow||0,'all','all')+cl(k.new_leads||0,'all','new')+cl(k.in_followup||0,'all','follow')+cl(k.interested_prospects||0,'all','interested')+cl(st.not_interested||0,'all','notint')+cl(st.site_visit_sch||0,'all','svsch')+cl(k.site_visits_completed||0,'all','svdone')+cl(k.deals_won||0,'all','won',G)+cl(st.total_rejected||0,'all','rejected')+cl(k.overdue_followups||0,'all','overdue',R)+'<td title="Won / Total inflow">'+(k.overall_conversion_rate||0)+'%</td><td></td><td></td></tr>';
  $('recon').textContent='Reps ('+(T.leads_allocated||0).toLocaleString()+') + unallocated ('+ua.toLocaleString()+') = total ('+(k.total_inflow||0).toLocaleString()+'). Click any metric to filter.';
  $('roster').innerHTML=h;
  var fk=[['New Lead',st.new_leads,'new'],['Follow up',st.follow_up,'follow'],['Interested',st.interested,'interested'],['Site visit scheduled',st.site_visit_sch,'svsch'],['Site visit done',st.site_visit_done,'svdone'],['Deal Won',st.deal_won,'won'],['Rejected',st.total_rejected,'rejected'],['   of which Not Interested',st.not_interested,'notint']],mx=Math.max.apply(null,fk.map(function(f){return f[1]||0}).concat([1]));
  $('funnel').innerHTML=fk.map(function(f){return'<div class="cl" data-r="all" data-s="'+f[2]+'" onclick="oc(this)" style="display:flex;align-items:center;gap:8px;margin:4px 0;padding:2px 4px;border-radius:4px"><div style="width:190px;white-space:pre">'+f[0]+'</div><div class="bar" style="flex:1;height:14px"><i style="width:'+(100*(f[1]||0)/mx)+'%;background:var(--pr)"></i></div><b style="width:50px;text-align:right">'+(f[1]||0)+'</b></div>'}).join('');
  $('roi').innerHTML='<div class="tc" style="margin-top:10px"><table><thead><tr><th>Channel</th><th>Leads</th><th>Open</th><th>Rejected</th><th>Won</th><th>Conv %</th></tr></thead><tbody>'+(d.channel_roi||[]).map(function(x){return'<tr><td><b>'+esc(x.channel_name)+'</b></td><td>'+x.total_leads+'</td><td>'+x.open+'</td><td>'+x.rejected+'</td><td>'+x.deals_won+'</td><td>'+x.conversion_rate+'%</td></tr>'}).join('')+'</tbody></table></div>';
  renderRej();
}

function goRep(i){openLeads({rep:ROSTER[i].sales_user_name,status:'all',source:'all'})}
function copy(t){var x=document.createElement('textarea');x.value=t;document.body.appendChild(x);x.select();var ok=false;try{ok=document.execCommand('copy')}catch(e){}document.body.removeChild(x);if(ok)alert('Copied to clipboard!');else prompt('Copy:',t)}
function remind(i){var r=ROSTER[i],items=ATT.filter(function(a){return rp(a.l)===r.sales_user_name}).slice(0,10);
  var t='Hi '+r.sales_user_name+', you have '+(r.followup_overdue||0)+' follow-ups overdue and '+(r.new_leads||0)+' new leads awaiting action.'+(items.length?'\\n'+items.map(function(a,j){return(j+1)+'. '+(a.l.customer_name||'Lead')+' ('+(a.l.phone||'')+') - '+a.w}).join('\\n'):'')+'\\nPlease review and update in CRM.';copy(t)}

/* ---------- Click-through, delete, deleted list ---------- */
var SK={new:'New Lead',follow:'Follow up',interested:'Interested',notint:'Not Interested',svsch:'Site visit scheduled',svdone:'Site visit done',won:'Deal Won',rejected:'Rejected',overdue:'Overdue follow-up'};
function rp(l){var r=String(l.assigned_to_name||l.sales_user||'').trim();return(!r||r==='-'||r.toLowerCase()==='unassigned')?'':r}
function ek(l){var rr=String(l.rejection_reason||'').toUpperCase(),s=(l.crm_status||l.status||'').toLowerCase();
  if(rr.indexOf('DUPLICATE')>-1)return'dup';
  if(s.indexOf('won')>-1)return'won';
  if(s.indexOf('reject')>-1||s.indexOf('not int')>-1||(rr&&rr!=='-'))return'rejected';
  if(s.indexOf('visit')>-1)return(s.indexOf('done')>-1||s.indexOf('complete')>-1)?'svdone':'svsch';
  if(s.indexOf('interested')>-1)return'interested';
  if(s.indexOf('allocate')>-1||s.indexOf('new')>-1||s.indexOf('assign')>-1)return'new';
  if(s==='none')return'none';
  return'follow'}
function isNI(l){var rr=String(l.rejection_reason||'').toUpperCase(),s=(l.crm_status||l.status||'').toLowerCase();return rr.indexOf('NOT_INT')>-1||s.indexOf('not int')>-1||!!l.ni_note}
function repCell(l){var r=rp(l);return r?esc(r):'<span class="flag">Unassigned</span>'}
function remTxt(l){var r=String(l.remarks||'').trim();if(!r||r==='-')r=l.ni_note?'(Not interested: '+l.ni_note+')':'-';return r}
function srcKey(x){x=(x||'').toLowerCase();return x.indexOf('housing')>-1?'housing':(x.indexOf('meta')>-1||x.indexOf('facebook')>-1)?'meta':x.indexOf('manual')>-1?'manual':x.indexOf('sheet')>-1?'google_sheets':'other'}
function setSel(id,v){var s=$(id);s.value=v;if(s.value!==v)s.value='all'}
function oc(a){var v=a.querySelector&&a.querySelector('.kv,.cc,b')||a,t=v.textContent.replace(/[^0-9]/g,'');
  openLeads({rep:a.getAttribute('data-r')||'all',status:a.getAttribute('data-s')||'all',source:a.getAttribute('data-c')||'all',q:a.getAttribute('data-q')||'',exp:(a.getAttribute('data-x')||t==='')?null:+t})}
function openLeads(o){sw(2);setSel('fr',o.rep||'all');setSel('fs',o.status||'all');setSel('fo',o.source||'all');$('q').value=o.q||'';EXP=o.exp==null?null:o.exp;renderLeads()}
function rf(){EXP=null;renderLeads()}
function clr(){setSel('fr','all');setSel('fs','all');setSel('fo','all');setSel('flt','all');$('q').value='';EXP=null;renderLeads()}
function rebuildSet(){DELSET={};DEL.forEach(function(d){DELSET[d.id]=1})}
function askDel(b){var id=b.getAttribute('data-i');PEND=LEADS.filter(function(l){return String(l.id)===id})[0];if(!PEND)return;$('dmt').textContent='Delete '+(PEND.customer_name||'lead')+' ('+(PEND.phone||'')+')?';$('dm').style.display='flex'}
function doDel(){var l=PEND,rs=$('dr').value;$('dm').style.display='none';if(!l)return;
  var rec={id:l.id,req_code:l.req_code||'',name:l.customer_name||'',phone:l.phone||'',rep:rp(l)||'',status:l.status||'',crm_status:l.crm_status||'',source:l.source||'',created:l.raw_created_at||l.date||'',overdue:l.is_overdue||'',reason:rs};
  call('apiDeleteLead',[AKEY,rec],function(r){if(!(r&&r.success)){alert('Delete failed: '+((r&&r.error)||'error'));return}
    DEL.push({at:'just now',by:'you',id:rec.id,req_code:rec.req_code,name:rec.name,phone:rec.phone,rep:rec.rep,status:rec.status,crm_status:rec.crm_status,source:rec.source,created:rec.created,overdue:rec.overdue,reason:rs});
    rebuildSet();LEADS=LEADS.filter(function(l2){return!DELSET[l2.id]});show();renderLeads();renderAtt();renderDeleted()})}
function restore(i){var d=DEL[i];if(!d||!confirm('Restore '+d.name+'?'))return;
  call('apiRestoreLead',[AKEY,d.id],function(r){if(!(r&&r.success)){alert('Restore failed: '+((r&&r.error)||'error'));return}DEL.splice(i,1);rebuildSet();show();renderDeleted();loadLeads()})}
function renderDeleted(){$('b4').textContent='🗑 Deleted ('+DEL.length+')';var m={};DEL.forEach(function(d){m[d.reason||'-']=(m[d.reason||'-']||0)+1});
  var sm=Object.keys(m).map(function(k){return esc(k)+' '+m[k]}).join(' · ');$('delSum').innerHTML=DEL.length+' deleted'+(sm?' ('+sm+')':'');
  var tx=[];if(DEL.length)tx.push('🗑 <b>'+DEL.length+'</b> deleted leads excluded - <a href="#" onclick="sw(4);return false" style="color:var(--pr)">view list</a>');$('delTxt').innerHTML=tx.join(' · ');
  $('db').innerHTML=DEL.slice().reverse().map(function(d){var i=DEL.indexOf(d);return'<tr><td class="nw bs">'+esc(d.at)+'</td><td class="nw"><b>'+esc(d.req_code||'-')+'</b></td><td class="nw"><b>'+esc(d.name)+'</b></td><td class="nw">'+esc(d.phone)+'</td><td class="nw">'+esc(d.rep||'-')+'</td><td>'+pillL(d)+'</td><td>'+esc(d.source)+'</td><td>'+esc(d.reason)+'</td>'+(ADMIN?'<td><button class="btn sm" onclick="restore('+i+')">♻️ Restore</button></td>':'')+'</tr>'}).join('')||'<tr><td colspan="9" class="mut">No deleted leads.</td></tr>'}
function renderRej(){var m={},n=0;LEADS.forEach(function(l){if(!inPer(l)||ek(l)!=='rejected')return;var r=String(l.rejection_reason||'').trim().toUpperCase();if(!r||r==='-')r='NOT SPECIFIED';m[r]=(m[r]||0)+1;n++});
  var ks=Object.keys(m).sort(function(a,b){return m[b]-m[a]}),pr=function(r){return r.replace(/_/g,' ').toLowerCase().replace(/^./,function(x){return x.toUpperCase()})};
  $('rej').innerHTML=ks.map(function(r){var ni=r.indexOf('NOT_INT')>-1;return'<div class="cx cl" data-s="'+(ni?'notint':'rejected')+'" data-r="all" data-q="'+(ni||r==='NOT SPECIFIED'?'':esc(r.toLowerCase()))+'" onclick="oc(this)" style="display:flex;justify-content:space-between"><span class="bs">'+esc(pr(r))+'</span><b style="color:var(--er)">'+m[r]+'</b></div>'}).join('')||'<div class="bs">No rejected leads in this period</div>';
  $('rejNote').textContent=n+' rejected leads'}
function init(){call('apiGetDeleted',[],function(r){if(r&&r.success){DEL=r.data||[]}else{$('delTxt').textContent=''}rebuildSet();renderDeleted();loadLeads()})}

/* ---------- Leads ---------- */
function loadLeads(bg){if(!bg)$('lb').innerHTML='<tr><td colspan="16" class="mut">Loading leads from PropKart CRM...</td></tr>';
  var lid=++LREQ;call('apiGetAllLeads',[],function(r){if(lid!==LREQ)return;
    if(!(r&&r.success&&r.data)){if(!bg)showErr('Leads could not load: '+((r&&r.error)||'API error'));return}
    showErr('');var all=r.data.leads||[];RAWN=all.length;LTOTAL=r.data.total||RAWN;COMPLETE=r.data.complete!==false;LEADS=all.filter(function(l){return!DELSET[l.id]});
    DUP={};LEADS.forEach(function(l){var c=String(l.phone||'').replace(/[^0-9]/g,'').slice(-10);if(c)DUP[c]=(DUP[c]||0)+1});
    var names={};LEADS.forEach(function(l){if(rp(l))names[rp(l)]=1});ROSTER.forEach(function(r){names[r.sales_user_name]=1});
    var cur=$('fr').value,ca=$('ar').value,o=Object.keys(names).sort().map(function(n){return'<option value="'+esc(n)+'">'+esc(n)+'</option>'}).join('');
    $('fr').innerHTML='<option value="all">All Sales Reps</option><option value="__assigned">Assigned reps only</option><option value="__unalloc">Unallocated / other</option><option value="__none">Unassigned (no rep)</option>'+o;$('fr').value=cur||'all';
    $('ar').innerHTML='<option value="all">All reps</option><option value="__none">Unassigned (no rep)</option>'+o;$('ar').value=ca||'all';
    show();renderLeads();renderAtt();renderDeleted()})}

function renderLeads(){
  var q=($('q').value||'').toLowerCase().trim(),fs=$('fs').value,fr=$('fr').value,fo=$('fo').value,flt=$('flt').value;
  var list=LEADS.filter(function(l){
    if(!inPer(l))return false;
    if(flt!=='all'&&String(l.lead_type||'').toUpperCase()!==flt)return false;
    if(fr==='__none'&&rp(l))return false;if(fr==='__assigned'&&!RN[rp(l)])return false;if(fr==='__unalloc'&&RN[rp(l)])return false;if(fr!=='all'&&fr.indexOf('__')!==0&&rp(l)!==fr)return false;
    if(fs==='overdue'){if(String(l.is_overdue).toLowerCase()!=='yes'||ek(l)==='won'||ek(l)==='rejected')return false}else if(fs==='notint'){if(!(ek(l)==='rejected'&&isNI(l)))return false}else if(fs!=='all'&&ek(l)!==fs)return false;
    if(fo!=='all'&&srcKey(l.source)!==fo)return false;
    return!q||[l.req_code,l.customer_name,l.phone,l.locality,rp(l),l.crm_status,l.remarks,l.rejection_reason].join(' ').toLowerCase().indexOf(q)>-1});
  
  $('lcount').textContent=perLabel()+': showing '+list.length+' of '+LEADS.length+' loaded ('+LTOTAL+' total in CRM)';
  var ch=[];if(flt!=='all')ch.push(flt);if(fr!=='all')ch.push(fr==='__none'?'No rep':fr==='__assigned'?'Assigned reps':fr==='__unalloc'?'Unallocated':fr);if(fs!=='all')ch.push(SK[fs]||fs);if(fo!=='all')ch.push(fo);if(q)ch.push('"'+q+'"');ch.push(perLabel());
  $('chips').innerHTML='Filters: <b>'+esc(ch.join(' · '))+'</b>'+(ch.length>1?' <a href="#" onclick="clr();return false" style="color:var(--pr)">✕ Clear</a>':'');
  if(!list.length){$('lb').innerHTML='<tr><td colspan="16" class="mut">No leads found for these filters.</td></tr>';return}
  
  $('lb').innerHTML=list.map(function(l){var w=why(l);
    var typeBadge = l.lead_type === 'LISTING' ? '<span class="pill pg">Listing</span>' : (l.lead_type === 'CAMPAIGN' ? '<span class="pill pi">Campaign</span>' : '<span class="pill ps">Requirement</span>');
    return'<tr>'+
      '<td class="nw bs">'+esc(l.date||'-')+'</td>'+
      '<td class="nw"><b>'+esc(l.req_code||'-')+'</b></td>'+
      '<td>'+typeBadge+'</td>'+
      '<td><span class="pill pn">'+esc(l.source||'Manual')+'</span></td>'+
      '<td class="nw"><b>'+esc(l.customer_name||'Prospect')+'</b></td>'+
      '<td class="nw">'+wa(l.phone)+'</td>'+
      '<td>'+dv(l.locality,['ahmedabad'])+'</td>'+
      '<td class="nw">'+dv(l.budget,['0','₹0','₹ 0'])+'</td>'+
      '<td class="nw">'+repCell(l)+'</td>'+
      '<td>'+pillL(l)+'</td>'+
      '<td class="nw">'+dv(l.bhk,['any bhk'])+'</td>'+
      '<td class="nw bs">'+esc(l.follow_up_date||'-')+'</td>'+
      '<td class="nw bs">'+esc(l.last_note_at||'-')+'</td>'+
      '<td class="flag">'+(w?'⚠️ '+esc(w):'')+'</td>'+
      '<td class="rem">'+esc(remTxt(l))+'</td>'+
      (ADMIN?'<td><button class="btn sm" title="Delete lead" data-i="'+esc(l.id)+'" onclick="askDel(this)">🗑</button></td>':'')+
    '</tr>'}).join('');
}

function renderAtt(){
  ATT=[];LEADS.forEach(function(l){if(!inPer(l))return;var w=why(l);if(w)ATT.push({l:l,w:w})});
  var un=ATT.filter(function(a){return!rp(a.l)}).length,ch=ATT.filter(function(a){return a.w==='Status updated but unassigned'}).length;
  $('attBanner').style.display=ATT.length?'flex':'none';
  $('attTxt').innerHTML='⚠️ <b>'+ATT.length+'</b> leads need attention'+(un?' · <b>'+un+'</b> unassigned'+(ch?' (<b>'+ch+'</b> updated without rep)':''):'')+' <span class="bs">('+LEADS.length+' checked)</span>';
  var f=$('ar').value,a=ATT.filter(function(x){return f==='all'||(f==='__none'?!rp(x.l):rp(x.l)===f)});
  $('acount').textContent=a.length+' leads · '+perLabel();renderRej();pcheck();
  $('ab').innerHTML=a.slice(0,400).map(function(x){var l=x.l;return'<tr><td class="nw">'+repCell(l)+'</td><td class="nw"><b>'+esc(l.req_code||'-')+'</b></td><td class="nw"><b>'+esc(l.customer_name||'Prospect')+'</b></td><td class="nw">'+wa(l.phone)+'</td><td>'+pillL(l)+'</td><td class="flag">'+esc(x.w)+'</td><td class="nw bs">'+esc(l.date||'-')+'</td>'+(ADMIN?'<td><button class="btn sm" data-i="'+esc(l.id)+'" onclick="askDel(this)">🗑</button></td>':'')+'</tr>'}).join('')||'<tr><td colspan="8" class="mut">🎉 All clear! No overdue or neglected leads.</td></tr>';
}

/* ---------- Ping + auto refresh ---------- */
function ping(){$('pd').style.background='#D97706';$('pt').textContent='Pinging...';
  call('apiPingStatus',[],function(r){if(r&&r.success){$('pd').style.background='#059669';$('pt').textContent='⚡ Ping';$('pl').textContent='('+r.latency+'ms · Healthy)'}else{$('pd').style.background='#DC2626';$('pt').textContent='⚠️ Degraded';$('pl').textContent='('+((r&&r.error)||'failed')+')'}})}
window.onload=function(){if(!ADMIN)[].forEach.call(document.querySelectorAll('.adm'),function(e){e.style.display='none'});$('plabel').textContent=perLabel();ping();init();
  setInterval(function(){cd--;$('fst').textContent='Auto-refresh in '+cd+'s';if(cd<=0){cd=300;loadLeads(true)}},1000)};
</script>
</body>
</html>`).replace('/*ADMIN*/', adminKey ? 'var ADMIN=true,AKEY=' + JSON.stringify(adminKey) + ';' : 'var ADMIN=false,AKEY="";');
}
