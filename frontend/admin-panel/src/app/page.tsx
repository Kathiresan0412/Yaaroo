"use client";

import { FormEvent, useEffect, useMemo, useState } from "react";

const sessionKey = "yaro0_admin_session";
const apiBaseUrl =
  process.env.NEXT_PUBLIC_ADMIN_API_URL?.replace(/\/$/, "") ??
  "/api/admin";

type Section =
  | "dashboard"
  | "users"
  | "reports"
  | "photos"
  | "analytics"
  | "revenue"
  | "broadcast"
  | "settings"
  | "audit";

type AdminSession = {
  token: string;
  admin: {
    id: string;
    email: string;
    role: string;
  };
};

type Dashboard = {
  totalUsers: number;
  active7d: number;
  active30d: number;
  newToday: number;
  newWeek: number;
  totalMatches: number;
  messagesToday: number;
  pendingReports: number;
  verifiedUsers: number;
  premiumUsers: number;
  revenueMonth: number;
  dailySignups: { date: string; count: number }[];
  genderBreakdown: { gender: string; count: number }[];
  dailyActiveUsers: { date: string; count: number }[];
};

type UserRow = {
  id: string;
  email: string | null;
  phone: string | null;
  displayName: string;
  status: string;
  gender: string | null;
  isVerified: boolean;
  country: string | null;
  premium: { plan: { name: string } } | null;
  createdAt: string;
  lastActiveAt: string | null;
};

type ReportRow = {
  id: string;
  reason: string;
  status: string;
  description: string | null;
  createdAt: string;
  reporter: { id: string; email: string | null; firstName: string | null; lastName: string | null };
  reported: { id: string; email: string | null; firstName: string | null; lastName: string | null; status: string };
};

type PhotoRow = {
  id: string;
  source: string;
  userId: string;
  url: string;
  status: string;
  createdAt: string;
  user: { email: string | null; firstName: string | null; lastName: string | null };
};

type SettingRow = {
  key: string;
  value: string | number | boolean | Record<string, unknown> | null;
  type: string;
  description: string | null;
};

type AuditRow = {
  id: string;
  action: string;
  targetType: string;
  targetId: string | null;
  description: string | null;
  ipAddress: string | null;
  createdAt: string;
  admin: { email: string; role: string } | null;
};

const navItems: { id: Section; label: string }[] = [
  { id: "dashboard", label: "Dashboard" },
  { id: "users", label: "Users" },
  { id: "reports", label: "Reports" },
  { id: "photos", label: "Photos" },
  { id: "analytics", label: "Analytics" },
  { id: "revenue", label: "Revenue" },
  { id: "broadcast", label: "Broadcast" },
  { id: "settings", label: "Settings" },
  { id: "audit", label: "Audit Log" },
];

function formatDate(value: string | null) {
  return value ? new Intl.DateTimeFormat("en", { dateStyle: "medium", timeStyle: "short" }).format(new Date(value)) : "Never";
}

function Badge({ value }: { value: string }) {
  return <span className={`badge badge-${value.replace("_", "-")}`}>{value.replace("_", " ")}</span>;
}

function MiniBars({ data, label }: { data: { date: string; count: number }[]; label: string }) {
  const max = Math.max(1, ...data.map((item) => item.count));
  return (
    <div className="chart" aria-label={label}>
      {data.slice(-14).map((item) => (
        <span key={item.date} title={`${item.date}: ${item.count}`} style={{ height: `${Math.max(8, (item.count / max) * 100)}%` }} />
      ))}
    </div>
  );
}

export default function AdminHomePage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [session, setSession] = useState<AdminSession | null>(null);
  const [section, setSection] = useState<Section>("dashboard");
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [dashboard, setDashboard] = useState<Dashboard | null>(null);
  const [users, setUsers] = useState<UserRow[]>([]);
  const [reports, setReports] = useState<ReportRow[]>([]);
  const [photos, setPhotos] = useState<PhotoRow[]>([]);
  const [settings, setSettings] = useState<SettingRow[]>([]);
  const [audit, setAudit] = useState<AuditRow[]>([]);
  const [userSearch, setUserSearch] = useState("");
  const [selectedUser, setSelectedUser] = useState<Record<string, unknown> | null>(null);
  const [broadcast, setBroadcast] = useState({ title: "Yaaro0 update", body: "", audience: "all", country: "" });

  const authHeaders = useMemo(
    () => ({
      "Content-Type": "application/json",
      Authorization: `Bearer ${session?.token ?? ""}`,
    }),
    [session],
  );

  useEffect(() => {
    const storedSession = window.localStorage.getItem(sessionKey);
    if (storedSession) {
      try {
        setSession(JSON.parse(storedSession) as AdminSession);
      } catch {
        window.localStorage.removeItem(sessionKey);
      }
    }
  }, []);

  async function apiGet<T>(path: string) {
    const response = await fetch(`${apiBaseUrl}${path}`, { headers: authHeaders });
    const data = await response.json();
    if (!response.ok || !data.success) {
      throw new Error(data.message ?? "Request failed.");
    }
    return data as T;
  }

  async function apiMutate<T>(path: string, method: "POST" | "PUT" | "PATCH", body: unknown) {
    const response = await fetch(`${apiBaseUrl}${path}`, {
      method,
      headers: authHeaders,
      body: JSON.stringify(body),
    });
    const data = await response.json();
    if (!response.ok || !data.success) {
      throw new Error(data.message ?? "Request failed.");
    }
    return data as T;
  }

  async function loadSection(nextSection = section) {
    if (!session) return;
    setError("");
    try {
      if (nextSection === "dashboard" || nextSection === "analytics" || nextSection === "revenue") {
        const data = await apiGet<{ dashboard: Dashboard }>("/dashboard");
        setDashboard(data.dashboard);
      }
      if (nextSection === "users") {
        const data = await apiGet<{ users: UserRow[] }>(`/users?search=${encodeURIComponent(userSearch)}`);
        setUsers(data.users);
      }
      if (nextSection === "reports") {
        const data = await apiGet<{ reports: ReportRow[] }>("/reports?status=pending");
        setReports(data.reports);
      }
      if (nextSection === "photos") {
        const data = await apiGet<{ photos: PhotoRow[] }>("/photos/pending");
        setPhotos(data.photos);
      }
      if (nextSection === "settings") {
        const data = await apiGet<{ settings: SettingRow[] }>("/settings");
        setSettings(data.settings);
      }
      if (nextSection === "audit") {
        const data = await apiGet<{ logs: AuditRow[] }>("/audit-log");
        setAudit(data.logs);
      }
    } catch (caughtError) {
      setError(caughtError instanceof Error ? caughtError.message : "Could not load admin data.");
    }
  }

  useEffect(() => {
    loadSection(section);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [session, section]);

  async function handleLogin(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError("");
    setIsSubmitting(true);

    try {
      const response = await fetch(`${apiBaseUrl}/auth/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password }),
      });
      const data = await response.json();

      if (!response.ok || !data.success) {
        throw new Error(data.message ?? "Login failed.");
      }

      const nextSession = { token: data.token, admin: data.admin } satisfies AdminSession;
      window.localStorage.setItem(sessionKey, JSON.stringify(nextSession));
      setSession(nextSession);
      setPassword("");
    } catch (caughtError) {
      setError(caughtError instanceof Error ? caughtError.message : "Could not sign in right now.");
    } finally {
      setIsSubmitting(false);
    }
  }

  function handleLogout() {
    window.localStorage.removeItem(sessionKey);
    setSession(null);
    setDashboard(null);
  }

  async function updateUserStatus(userId: string, status: string) {
    const suspendUntil = status === "suspended" ? new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString() : undefined;
    await apiMutate(`/users/${userId}/status`, "PATCH", { status, suspendUntil });
    setNotice(`User ${status}.`);
    loadSection("users");
  }

  async function loadUserDetail(userId: string) {
    const data = await apiGet<{ user: Record<string, unknown> }>(`/users/${userId}`);
    setSelectedUser(data.user);
  }

  async function reviewReport(reportId: string, action: string) {
    await apiMutate(`/reports/${reportId}`, "PATCH", {
      status: action === "dismiss" ? "dismissed" : "action_taken",
      actionTaken: action,
    });
    setNotice("Report updated.");
    loadSection("reports");
  }

  async function moderatePhoto(photo: PhotoRow, status: "approved" | "rejected") {
    await apiMutate(`/photos/${photo.id}`, "PATCH", { source: photo.source, status });
    setNotice(`Photo ${status}.`);
    loadSection("photos");
  }

  async function saveSetting(setting: SettingRow, value: string) {
    const nextValue =
      setting.type === "integer" ? Number(value) : setting.type === "boolean" ? value === "true" : value;
    await apiMutate("/settings", "PUT", { [setting.key]: nextValue });
    setNotice("Setting saved.");
    loadSection("settings");
  }

  async function sendBroadcast(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const data = await apiMutate<{ matchedUsers: number; pushSent: number }>("/broadcast", "POST", broadcast);
    setNotice(`Broadcast queued for ${data.matchedUsers} users.`);
    setBroadcast((current) => ({ ...current, body: "" }));
  }

  if (!session) {
    return (
      <main className="login-shell">
        <section className="login-panel" aria-labelledby="login-title">
          <div className="login-copy">
            <p className="eyebrow">Admin portal</p>
            <h1 id="login-title">Sign in</h1>
            <p className="muted">Operations, moderation, revenue, and settings.</p>
          </div>

          <form className="login-form" onSubmit={handleLogin}>
            <label>
              Email
              <input autoComplete="email" onChange={(event) => setEmail(event.target.value)} required type="email" value={email} />
            </label>
            <label>
              Password
              <input autoComplete="current-password" onChange={(event) => setPassword(event.target.value)} required type="password" value={password} />
            </label>
            {error ? <p className="error-message">{error}</p> : null}
            <button disabled={isSubmitting} type="submit">{isSubmitting ? "Signing in..." : "Sign in"}</button>
          </form>
        </section>
      </main>
    );
  }

  const kpis = dashboard
    ? [
        ["Users", dashboard.totalUsers],
        ["Active 7d", dashboard.active7d],
        ["Active 30d", dashboard.active30d],
        ["New today", dashboard.newToday],
        ["Matches", dashboard.totalMatches],
        ["Messages today", dashboard.messagesToday],
        ["Pending reports", dashboard.pendingReports],
        ["Revenue month", `LKR ${dashboard.revenueMonth.toLocaleString()}`],
      ]
    : [];

  return (
    <main className="admin-shell">
      <aside className="sidebar">
        <div>
          <p className="eyebrow">Yaaro0</p>
          <h1>Admin</h1>
          <p className="muted">{session.admin.email}</p>
        </div>
        <nav>
          {navItems.map((item) => (
            <button className={section === item.id ? "nav-active" : ""} key={item.id} onClick={() => setSection(item.id)} type="button">
              {item.label}
            </button>
          ))}
        </nav>
        <button className="secondary-button" onClick={handleLogout} type="button">Sign out</button>
      </aside>

      <section className="workspace">
        <header className="topbar">
          <div>
            <p className="eyebrow">{session.admin.role.replace("_", " ")}</p>
            <h2>{navItems.find((item) => item.id === section)?.label}</h2>
          </div>
          <button className="secondary-button" onClick={() => loadSection(section)} type="button">Refresh</button>
        </header>

        {error ? <p className="error-message">{error}</p> : null}
        {notice ? <p className="notice-message">{notice}</p> : null}

        {section === "dashboard" && dashboard ? (
          <>
            <div className="kpi-grid">
              {kpis.map(([label, value]) => (
                <article className="kpi" key={label}>
                  <span>{label}</span>
                  <strong>{value}</strong>
                </article>
              ))}
            </div>
            <div className="two-column">
              <section className="panel">
                <h3>Signups</h3>
                <MiniBars data={dashboard.dailySignups} label="Daily signups" />
              </section>
              <section className="panel">
                <h3>Gender</h3>
                <div className="stack-list">
                  {dashboard.genderBreakdown.map((item) => <p key={item.gender}><span>{item.gender}</span><strong>{item.count}</strong></p>)}
                </div>
              </section>
            </div>
          </>
        ) : null}

        {section === "users" ? (
          <section className="panel">
            <div className="table-toolbar">
              <input placeholder="Search users" value={userSearch} onChange={(event) => setUserSearch(event.target.value)} />
              <button type="button" onClick={() => loadSection("users")}>Search</button>
            </div>
            <div className="table-wrap">
              <table>
                <thead><tr><th>User</th><th>Status</th><th>Tier</th><th>Verified</th><th>Last active</th><th>Actions</th></tr></thead>
                <tbody>
                  {users.map((user) => (
                    <tr key={user.id}>
                      <td><strong>{user.displayName || user.email || user.phone}</strong><span>{user.country ?? "No country"}</span></td>
                      <td><Badge value={user.status} /></td>
                      <td>{user.premium?.plan.name ?? "Free"}</td>
                      <td>{user.isVerified ? "Yes" : "No"}</td>
                      <td>{formatDate(user.lastActiveAt)}</td>
                      <td className="actions">
                        <button type="button" onClick={() => loadUserDetail(user.id)}>View</button>
                        <button type="button" onClick={() => updateUserStatus(user.id, "suspended")}>Suspend</button>
                        <button type="button" onClick={() => updateUserStatus(user.id, "banned")}>Ban</button>
                        <button type="button" onClick={() => updateUserStatus(user.id, "deleted")}>Delete</button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </section>
        ) : null}

        {selectedUser ? (
          <section className="drawer">
            <button className="secondary-button" onClick={() => setSelectedUser(null)} type="button">Close</button>
            <h3>{String(selectedUser.displayName || selectedUser.email || "User detail")}</h3>
            <pre>{JSON.stringify(selectedUser, null, 2)}</pre>
          </section>
        ) : null}

        {section === "reports" ? (
          <section className="panel table-wrap">
            <table>
              <thead><tr><th>Reason</th><th>Reported</th><th>Reporter</th><th>Created</th><th>Actions</th></tr></thead>
              <tbody>
                {reports.map((report) => (
                  <tr key={report.id}>
                    <td><strong>{report.reason}</strong><span>{report.description ?? "No details"}</span></td>
                    <td>{report.reported.email ?? report.reported.id}</td>
                    <td>{report.reporter.email ?? report.reporter.id}</td>
                    <td>{formatDate(report.createdAt)}</td>
                    <td className="actions">
                      <button type="button" onClick={() => reviewReport(report.id, "warn")}>Warn</button>
                      <button type="button" onClick={() => reviewReport(report.id, "suspend_3d")}>Suspend 3d</button>
                      <button type="button" onClick={() => reviewReport(report.id, "suspend_7d")}>Suspend 7d</button>
                      <button type="button" onClick={() => reviewReport(report.id, "ban")}>Ban</button>
                      <button type="button" onClick={() => reviewReport(report.id, "dismiss")}>Dismiss</button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </section>
        ) : null}

        {section === "photos" ? (
          <section className="photo-grid">
            {photos.map((photo) => (
              <article className="photo-tile" key={`${photo.source}-${photo.id}`}>
                <img alt="" src={photo.url} />
                <div>
                  <strong>{photo.user.email ?? photo.userId}</strong>
                  <span>{photo.source}</span>
                </div>
                <div className="actions">
                  <button type="button" onClick={() => moderatePhoto(photo, "approved")}>Approve</button>
                  <button type="button" onClick={() => moderatePhoto(photo, "rejected")}>Reject</button>
                </div>
              </article>
            ))}
          </section>
        ) : null}

        {section === "analytics" && dashboard ? (
          <div className="two-column">
            <section className="panel"><h3>Daily Active Users</h3><MiniBars data={dashboard.dailyActiveUsers} label="Daily active users" /></section>
            <section className="panel"><h3>Match Rate Inputs</h3><p className="metric-line"><span>Total matches</span><strong>{dashboard.totalMatches}</strong></p><p className="metric-line"><span>Active 30d</span><strong>{dashboard.active30d}</strong></p></section>
          </div>
        ) : null}

        {section === "revenue" && dashboard ? (
          <div className="kpi-grid">
            <article className="kpi"><span>Revenue this month</span><strong>LKR {dashboard.revenueMonth.toLocaleString()}</strong></article>
            <article className="kpi"><span>Premium users</span><strong>{dashboard.premiumUsers}</strong></article>
            <article className="kpi"><span>Verified users</span><strong>{dashboard.verifiedUsers}</strong></article>
          </div>
        ) : null}

        {section === "broadcast" ? (
          <form className="panel form-grid" onSubmit={sendBroadcast}>
            <label>Title<input value={broadcast.title} onChange={(event) => setBroadcast({ ...broadcast, title: event.target.value })} /></label>
            <label>Audience<select value={broadcast.audience} onChange={(event) => setBroadcast({ ...broadcast, audience: event.target.value })}><option value="all">All</option><option value="free">Free</option><option value="premium">Premium</option></select></label>
            <label>Country<input value={broadcast.country} onChange={(event) => setBroadcast({ ...broadcast, country: event.target.value })} placeholder="Optional" /></label>
            <label className="wide">Message<textarea required value={broadcast.body} onChange={(event) => setBroadcast({ ...broadcast, body: event.target.value })} /></label>
            <button type="submit">Send broadcast</button>
          </form>
        ) : null}

        {section === "settings" ? (
          <section className="settings-list">
            {settings.map((setting) => (
              <form className="setting-row" key={setting.key} onSubmit={(event) => { event.preventDefault(); const form = new FormData(event.currentTarget); saveSetting(setting, String(form.get("value") ?? "")); }}>
                <div><strong>{setting.key}</strong><span>{setting.description}</span></div>
                <input name="value" defaultValue={typeof setting.value === "object" ? JSON.stringify(setting.value) : String(setting.value ?? "")} />
                <button type="submit">Save</button>
              </form>
            ))}
          </section>
        ) : null}

        {section === "audit" ? (
          <section className="panel table-wrap">
            <table>
              <thead><tr><th>Admin</th><th>Action</th><th>Target</th><th>IP</th><th>Time</th></tr></thead>
              <tbody>
                {audit.map((log) => (
                  <tr key={log.id}>
                    <td>{log.admin?.email ?? "System"}</td>
                    <td><strong>{log.action}</strong><span>{log.description}</span></td>
                    <td>{log.targetType}{log.targetId ? `:${log.targetId}` : ""}</td>
                    <td>{log.ipAddress ?? "unknown"}</td>
                    <td>{formatDate(log.createdAt)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </section>
        ) : null}
      </section>
    </main>
  );
}
