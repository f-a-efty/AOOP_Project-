import React from "react";
import { useNavigate } from "react-router-dom";

export default function Dashboard() {
  const navigate = useNavigate();

  const go = (path) => navigate(path);

  return (
    <section className="px-4 pt-3 pb-6 flex flex-col gap-6">
      <div className="flex flex-col gap-2">
        <div className="flex items-center justify-between">
          <button
            onClick={() => go("/booths")}
            className="flex items-center gap-1.5 py-1 px-3 rounded-full bg-secondary-container text-on-secondary-container shadow-sm"
          >
            <span className="w-2 h-2 rounded-full bg-secondary animate-ping" />
            <span className="text-[11px] uppercase tracking-wider font-bold">
              Live Network Operational
            </span>
            <span className="text-[10px]">•</span>
            <span className="text-[11px] font-semibold">24 Booths</span>
          </button>
          <span className="text-xs text-outline font-semibold">Dhaka Central</span>
        </div>

        <div>
          <div className="flex items-baseline gap-2">
            <h2 className="text-[26px] leading-[34px] text-primary font-extrabold tracking-tight">
              Welcome back, Nusrat
            </h2>
            <span className="text-xl">👋</span>
          </div>
          <div className="flex items-center gap-1 mt-1">
            <span className="material-symbols-outlined text-secondary text-[18px]">
              verified_user
            </span>
            <p className="text-xs text-on-surface-variant font-semibold">
              Chief Operations Lead <span className="text-outline-variant">|</span>{" "}
              Dhaka Metro Fleet
            </p>
          </div>
        </div>
      </div>

      <div className="flex flex-col gap-4">
        <button
          onClick={() => go("/users")}
          className="text-left relative overflow-hidden rounded-xl bg-gradient-to-br from-primary via-primary-container to-secondary p-6 text-on-primary shadow-lg"
        >
          <div className="relative z-10">
            <div className="flex items-center justify-between mb-3">
              <div className="w-12 h-12 rounded-lg bg-white/10 flex items-center justify-center text-primary-fixed">
                <span className="material-symbols-outlined text-[28px]">groups</span>
              </div>
              <span className="flex items-center gap-1.5 py-1 px-2.5 rounded-full bg-white/10 text-xs font-bold">
                <span className="w-2 h-2 rounded-full bg-secondary-fixed" />
                4,210 Active
              </span>
            </div>

            <h3 className="text-2xl font-bold">Users Info & Wallet Audits</h3>
            <p className="text-sm text-on-primary-container mt-1 leading-relaxed">
              Inspect 6,812 registered citizens, verify bKash wallets, loyalty
              tiers & deposit transaction integrity.
            </p>

            <div className="flex items-center justify-between mt-4 pt-3 -mx-6 -mb-6 px-6 py-3 bg-primary/30">
              <div className="flex items-center gap-1.5 text-error-container text-xs font-bold">
                <span className="material-symbols-outlined text-[18px]">
                  drive_file_rename_outline
                </span>
                5 Flagged Fraud Audits
              </div>
              <span className="flex items-center gap-1 text-secondary-fixed font-bold text-sm">
                Inspect Users
                <span className="material-symbols-outlined text-[18px]">arrow_forward</span>
              </span>
            </div>
          </div>
        </button>

        <div className="rounded-xl bg-surface-container-lowest p-6 shadow-md">
          <div className="flex items-center justify-between mb-3">
            <div className="w-12 h-12 rounded-lg bg-secondary-container flex items-center justify-center text-on-secondary-container">
              <span className="material-symbols-outlined text-[28px]">
                local_shipping
              </span>
            </div>
            <span className="flex items-center gap-1.5 py-1 px-2.5 rounded-full bg-surface-container-high text-xs font-bold text-secondary">
              <span className="w-2 h-2 rounded-full bg-secondary" />
              6 Certified Fleets
            </span>
          </div>

          <h3 className="text-2xl font-bold text-primary">Plastic Collection Companies</h3>
          <p className="text-sm text-on-surface-variant mt-1 leading-relaxed">
            Manage contracted recyclers, live pickup dispatch queue, sorting
            weights & intake reconciliations.
          </p>

          <div className="grid grid-cols-2 gap-2 mt-4">
            <div className="rounded-lg bg-surface-container-low p-3 flex items-center gap-2">
              <span className="w-2.5 h-2.5 rounded-full bg-error" />
              <div>
                <span className="text-xs font-extrabold text-error block">5 Urgent</span>
                <span className="text-[11px] text-on-surface-variant">Booth Pickups</span>
              </div>
            </div>
            <div className="rounded-lg bg-surface-container-low p-3 flex items-center gap-2">
              <span className="w-2.5 h-2.5 rounded-full bg-secondary" />
              <div>
                <span className="text-xs font-extrabold text-secondary block">8 En Route</span>
                <span className="text-[11px] text-on-surface-variant">Hauler Trucks</span>
              </div>
            </div>
          </div>

          <button
            onClick={() => go("/companies")}
            className="w-full mt-4 py-2.5 px-4 rounded-lg bg-primary text-on-primary font-bold flex items-center justify-center gap-2"
          >
            View Recyclers Queue
            <span className="material-symbols-outlined text-[18px]">arrow_forward</span>
          </button>
        </div>
      </div>

      <div className="rounded-xl bg-error-container p-4 shadow-sm">
        <div className="flex items-start gap-3">
          <div className="w-9 h-9 rounded-full bg-on-error text-error flex items-center justify-center shrink-0">
            <span className="material-symbols-outlined text-[22px]">warning</span>
          </div>
          <div className="flex-1">
            <div className="flex items-center justify-between">
              <span className="text-[11px] uppercase tracking-wider font-extrabold text-error">
                Critical Capacity 96%
              </span>
              <span className="text-[11px] text-on-error-container/80">3m ago</span>
            </div>
            <p className="text-base font-bold text-on-error-container mt-0.5">
              Booth #SB-104 (Dhanmondi 27)
            </p>
            <p className="text-xs text-on-error-container/90 mt-1">
              Auto-dispatch triggered to GreenRecycle Ltd. Driver assigned: Kabir H.
            </p>
            <div className="flex gap-2 mt-3">
              <button
                onClick={() => go("/companies")}
                className="flex-1 py-2 rounded-lg bg-on-error text-error text-xs font-bold"
              >
                Track Van
              </button>
              <button
                onClick={() => go("/booths")}
                className="flex-1 py-2 rounded-lg bg-error text-on-error text-xs font-bold"
              >
                Telemetry Log
              </button>
            </div>
          </div>
        </div>
      </div>

      <div>
        <div className="flex items-center justify-between mb-2">
          <h4 className="text-base font-bold text-primary">Fleet Metrics Overview</h4>
          <span className="text-[11px] font-bold text-secondary">Dhaka Metro • Today</span>
        </div>

        <div className="grid grid-cols-2 gap-2">
          <button onClick={() => go("/esg")} className="text-left rounded-xl bg-white p-4 shadow-sm">
            <div className="flex justify-between">
              <div className="w-8 h-8 rounded-lg bg-surface-container flex items-center justify-center text-primary">
                <span className="material-symbols-outlined text-[18px]">recycling</span>
              </div>
              <span className="text-[11px] font-bold text-secondary bg-surface-container-low px-1.5 py-0.5 rounded-full">
                +14.2%
              </span>
            </div>
            <div className="mt-3">
              <span className="text-[28px] font-extrabold text-primary leading-none block">
                48,290<span className="text-xs text-outline ml-1">kg</span>
              </span>
              <span className="text-xs text-on-surface-variant block mt-1">
                Total Plastic Collected
              </span>
            </div>
          </button>

          <button onClick={() => go("/rewards")} className="text-left rounded-xl bg-white p-4 shadow-sm">
            <div className="flex justify-between">
              <div className="w-8 h-8 rounded-lg bg-secondary-container flex items-center justify-center text-on-secondary-container">
                <span className="material-symbols-outlined text-[18px]">account_balance_wallet</span>
              </div>
              <span className="text-[11px] font-bold text-outline">42.1k tx</span>
            </div>
            <div className="mt-3">
              <span className="text-[28px] font-extrabold text-primary leading-none block">
                ৳324.5<span className="text-xs text-outline ml-1">k</span>
              </span>
              <span className="text-xs text-on-surface-variant block mt-1">bKash Disbursed</span>
            </div>
          </button>

          <button onClick={() => go("/rewards")} className="text-left rounded-xl bg-white p-4 shadow-sm">
            <div className="flex justify-between">
              <div className="w-8 h-8 rounded-lg bg-surface-container-high flex items-center justify-center text-tertiary">
                <span className="material-symbols-outlined text-[18px]">toll</span>
              </div>
              <span className="text-[11px] font-bold text-on-tertiary-container bg-surface-container-low px-1.5 py-0.5 rounded-full">
                50tk=৳10
              </span>
            </div>
            <div className="mt-3">
              <span className="text-[28px] font-extrabold text-primary leading-none block">
                2.41<span className="text-xs text-outline ml-1">M</span>
              </span>
              <span className="text-xs text-on-surface-variant block mt-1">Active Eco-Tokens</span>
            </div>
          </button>

          <button onClick={() => go("/booths")} className="text-left rounded-xl bg-white p-4 shadow-sm">
            <div className="flex justify-between">
              <div className="w-8 h-8 rounded-lg bg-surface-container-highest flex items-center justify-center text-secondary">
                <span className="material-symbols-outlined text-[18px]">sensors</span>
              </div>
              <span className="text-[11px] font-extrabold text-error bg-error-container px-1.5 py-0.5 rounded-full">
                2 Urgent
              </span>
            </div>
            <div className="mt-3">
              <div className="flex items-baseline justify-between">
                <span className="text-[28px] font-extrabold text-primary leading-none">68%</span>
                <span className="text-[11px] text-outline">avg fill</span>
              </div>
              <div className="w-full h-1.5 bg-surface-container rounded-full mt-2">
                <div className="h-full bg-secondary rounded-full w-[68%]" />
              </div>
            </div>
          </button>
        </div>
      </div>

      <div>
        <h4 className="text-base font-bold text-primary mb-2">Operational Controls</h4>
        <div className="flex flex-col gap-2">
          {[
            ["currency_exchange", "Update Token Exchange Rate", "Current: ৳0.20 per EcoToken", "/rewards"],
            ["payments", "Disburse bKash Auto-Pool", "Dhaka Bank escrow: ৳1,450,000 ready", "/rewards"],
            ["system_update", "Fleet Telemetry OTA v2.4", "22/24 booths synced • 2 pending", "/booths"]
          ].map(([icon, title, sub, path]) => (
            <button
              key={title}
              onClick={() => go(path)}
              className="flex items-center justify-between w-full p-3 rounded-xl bg-white shadow-sm text-left"
            >
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-lg bg-surface-container flex items-center justify-center text-secondary">
                  <span className="material-symbols-outlined text-[20px]">{icon}</span>
                </div>
                <div>
                  <span className="text-sm font-bold text-on-surface block">{title}</span>
                  <span className="text-xs text-on-surface-variant">{sub}</span>
                </div>
              </div>
              <span className="material-symbols-outlined text-outline">chevron_right</span>
            </button>
          ))}
        </div>
      </div>

      <button
        onClick={() => go("/esg")}
        className="rounded-xl overflow-hidden shadow-sm bg-white text-left"
      >
        <div
          className="h-28 w-full bg-cover bg-center"
          style={{
            backgroundImage:
              "url('https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?auto=format&fit=crop&w=1200&q=80')"
          }}
        />
        <div className="p-3 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <span className="material-symbols-outlined text-secondary">park</span>
            <span className="text-xs font-bold text-primary">Dhaka Green Metro Hub #01</span>
          </div>
          <span className="text-[11px] text-secondary font-bold">100% Carbon Neutral →</span>
        </div>
      </button>
    </section>
  );
}