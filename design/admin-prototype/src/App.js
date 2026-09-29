import React from "react";
import { BrowserRouter, Routes, Route, NavLink, useLocation, useNavigate } from "react-router-dom";

import Dashboard from "./Dashboard";
import Users from "./Users";
import Companies from "./Companies";
import Booths from "./Booths";
import Rewards from "./Rewards";
import ESG from "./ESG";
import Settings from "./Settings";

const pageTitles = {
  "/": "Dashboard",
  "/users": "Users & Wallets",
  "/companies": "Recycler Fleets",
  "/booths": "Booth Telemetry",
  "/rewards": "Rewards & Pegs",
  "/esg": "ESG Carbon Hub",
  "/settings": "Admin Settings"
};

const navItems = [
  { path: "/", label: "Home", icon: "dashboard" },
  { path: "/users", label: "Users", icon: "group" },
  { path: "/companies", label: "Companies", icon: "local_shipping" },
  { path: "/booths", label: "Booths", icon: "sensors" },
  { path: "/settings", label: "Settings", icon: "settings" }
];

function Layout({ children }) {
  const location = useLocation();
  const navigate = useNavigate();
  const title = pageTitles[location.pathname] || "Dashboard";

  const notify = () => {
    window.alert("Notification Center: 3 new alerts received");
  };

  return (
    <div className="min-h-screen bg-surface text-on-surface">
      <header className="fixed top-0 left-0 right-0 z-50 bg-surface/90 backdrop-blur-xl shadow-[0_1px_8px_rgba(0,0,0,0.04)]">
        <div className="h-16 px-4 flex items-center justify-between">
          <button
            onClick={() => navigate("/")}
            className="flex items-center gap-2 text-left"
          >
            <div className="h-8 w-8 rounded-lg bg-primary text-secondary-fixed flex items-center justify-center font-extrabold">
              G
            </div>
            <div className="flex flex-col">
              <span className="text-xs text-secondary font-bold uppercase tracking-wider">
                Greenify
              </span>
              <h1 className="text-base text-primary leading-tight font-semibold">
                {title}
              </h1>
            </div>
          </button>

          <div className="flex items-center gap-2">
            <button
              aria-label="Notifications"
              onClick={notify}
              className="w-10 h-10 flex items-center justify-center rounded-full text-on-surface-variant hover:text-primary"
            >
              <span className="material-symbols-outlined text-[22px]">
                notifications
              </span>
              <span className="absolute top-2.5 right-12 w-2 h-2 rounded-full bg-secondary" />
            </button>

            <button
              onClick={() => navigate("/settings")}
              className="w-9 h-9 rounded-full bg-primary text-secondary-fixed ring-2 ring-primary-fixed flex items-center justify-center font-bold"
            >
              NJ
            </button>
          </div>
        </div>
      </header>

      <main className="pt-16 pb-20 min-h-screen">{children}</main>

      <nav className="fixed bottom-0 left-0 right-0 z-50 bg-surface/90 backdrop-blur-xl shadow-[0_-2px_12px_rgba(6,78,59,0.06)]">
        <div className="flex justify-around items-center h-16 px-1 max-w-md mx-auto">
          {navItems.map((item) => (
            <NavLink
              key={item.path}
              to={item.path}
              end={item.path === "/"}
              className={({ isActive }) =>
                `flex flex-col items-center justify-center gap-0.5 min-w-[56px] min-h-[44px] ${
                  isActive
                    ? "text-secondary font-bold"
                    : "text-on-surface-variant hover:text-secondary"
                }`
              }
            >
              <span className="material-symbols-outlined text-[22px]">
                {item.icon}
              </span>
              <span className="text-[11px] font-bold tracking-tight">
                {item.label}
              </span>
            </NavLink>
          ))}
        </div>
      </nav>
    </div>
  );
}

export default function App() {
  return (
    <BrowserRouter>
      <Layout>
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/users" element={<Users />} />
          <Route path="/companies" element={<Companies />} />
          <Route path="/booths" element={<Booths />} />
          <Route path="/rewards" element={<Rewards />} />
          <Route path="/esg" element={<ESG />} />
          <Route path="/settings" element={<Settings />} />
        </Routes>
      </Layout>
    </BrowserRouter>
  );
}