import React, { useMemo, useState } from "react";

const initialUsers = [
  {
    initials: "TK",
    name: "Tariqul Karim",
    phone: "+880 1711-209481 • bKash Verified",
    tier: "FLAGGED",
    tokens: "",
    disbursed: "",
    flagged: true,
    reason: "Rapid Depo Spike"
  },
  {
    initials: "FA",
    name: "Farhana Ahmed",
    phone: "+880 1822-994320 • bKash #...9943",
    tier: "PLATINUM",
    tokens: "1,420 tk",
    disbursed: "৳284 Disbursed"
  },
  {
    initials: "MR",
    name: "Mahmudur Rahman",
    phone: "+880 1913-772184 • Nagad #...2184",
    tier: "GOLD",
    tokens: "890 tk",
    disbursed: "৳178 Disbursed"
  },
  {
    initials: "SZ",
    name: "Sadia Zaman",
    phone: "+880 1612-440931 • bKash #...0931",
    tier: "SILVER",
    tokens: "310 tk",
    disbursed: "৳62 Disbursed"
  }
];

export default function Users() {
  const [search, setSearch] = useState("");
  const [fraudOnly, setFraudOnly] = useState(false);

  const users = useMemo(() => {
    return initialUsers.filter((user) => {
      const matchesSearch =
        user.name.toLowerCase().includes(search.toLowerCase()) ||
        user.phone.toLowerCase().includes(search.toLowerCase());

      const matchesFraud = fraudOnly ? user.flagged : true;
      return matchesSearch && matchesFraud;
    });
  }, [search, fraudOnly]);

  return (
    <section className="px-4 pt-3 pb-6 flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-primary">Citizen Directory</h2>
          <p className="text-xs text-on-surface-variant">
            6,812 registered recyclable depositors
          </p>
        </div>
        <button
          onClick={() => window.alert("Exporting CSV User Report...")}
          className="py-1.5 px-3 rounded-lg bg-surface-container text-primary text-xs font-bold flex items-center gap-1"
        >
          <span className="material-symbols-outlined text-[16px]">download</span>
          Export
        </button>
      </div>

      <div className="flex gap-2">
        <div className="relative flex-1">
          <span className="material-symbols-outlined absolute left-3 top-2.5 text-outline text-[18px]">
            search
          </span>
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-9 pr-3 py-2 bg-white rounded-xl border-none ring-1 ring-outline-variant text-sm outline-none"
            placeholder="Search bKash phone or citizen name..."
          />
        </div>
        <button
          onClick={() => setFraudOnly(!fraudOnly)}
          className={`px-3 py-2 rounded-xl text-xs font-bold flex items-center gap-1 ${
            fraudOnly
              ? "bg-error text-on-error"
              : "bg-error-container text-on-error-container"
          }`}
        >
          <span className="material-symbols-outlined text-[16px]">flag</span>
          Flagged (5)
        </button>
      </div>

      <div className="grid grid-cols-3 gap-2">
        {[
          ["Verified", "6,240", "text-primary"],
          ["Avg Tokens", "384 tk", "text-secondary"],
          ["Disbursed", "৳324k", "text-primary"]
        ].map(([label, value, color]) => (
          <div key={label} className="p-2.5 rounded-xl bg-white shadow-sm flex flex-col">
            <span className="text-[11px] text-on-surface-variant">{label}</span>
            <span className={`text-base font-extrabold ${color}`}>{value}</span>
          </div>
        ))}
      </div>

      <div className="flex flex-col gap-2.5">
        {users.map((user) =>
          user.flagged ? (
            <div
              key={user.name}
              className="rounded-xl bg-white p-3 shadow-sm border-l-4 border-error flex flex-col gap-2"
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2.5">
                  <div className="w-10 h-10 rounded-full bg-error-container text-error flex items-center justify-center font-bold text-sm">
                    {user.initials}
                  </div>
                  <div>
                    <div className="flex items-center gap-1.5">
                      <span className="text-sm font-bold">{user.name}</span>
                      <span className="px-1.5 py-0.5 rounded text-[10px] font-bold bg-error-container text-error">
                        FLAGGED
                      </span>
                    </div>
                    <span className="text-xs text-outline">{user.phone}</span>
                  </div>
                </div>
                <span className="text-xs font-extrabold text-error">{user.reason}</span>
              </div>

              <div className="flex items-center justify-between text-xs bg-surface-container-low p-2 rounded-lg">
                <span>Deposits: <strong>320 bottles in 15m</strong></span>
                <span>Claim: <strong>৳640 pending</strong></span>
              </div>

              <div className="flex gap-2">
                <button
                  onClick={() => window.alert(`Fraud hold confirmed for ${user.name}.`)}
                  className="flex-1 py-1.5 rounded-lg bg-error text-on-error text-xs font-bold"
                >
                  Freeze Wallet
                </button>
                <button
                  onClick={() => window.alert("Auditing camera logs for booth #SB-104...")}
                  className="flex-1 py-1.5 rounded-lg bg-surface-container text-primary text-xs font-bold"
                >
                  Inspect CCTV
                </button>
              </div>
            </div>
          ) : (
            <div
              key={user.name}
              className="rounded-xl bg-white p-3 shadow-sm flex items-center justify-between"
            >
              <div className="flex items-center gap-2.5">
                <div className="w-10 h-10 rounded-full bg-secondary-container text-on-secondary-container flex items-center justify-center font-bold text-sm">
                  {user.initials}
                </div>
                <div>
                  <div className="flex items-center gap-1.5">
                    <span className="text-sm font-bold">{user.name}</span>
                    <span className="px-1.5 py-0.5 rounded text-[10px] font-bold bg-primary-fixed text-primary">
                      {user.tier}
                    </span>
                  </div>
                  <span className="text-xs text-outline">{user.phone}</span>
                </div>
              </div>
              <div className="flex flex-col items-end">
                <span className="text-base font-bold text-primary">{user.tokens}</span>
                <span className="text-[11px] text-secondary font-bold">{user.disbursed}</span>
              </div>
            </div>
          )
        )}
      </div>
    </section>
  );
}