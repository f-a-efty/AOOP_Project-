import React, { useMemo, useState } from "react";

const booths = [
  {
    id: "#SB-104",
    location: "Dhanmondi 27",
    fill: 96,
    status: "CRITICAL",
    category: "urgent",
    temp: "26°C (Normal)",
    amount: "480/500 kg"
  },
  {
    id: "#SB-112",
    location: "Gulshan 2 Circle",
    fill: 88,
    status: "HIGH",
    category: "urgent",
    temp: "24°C (Normal)",
    amount: "440/500 kg"
  },
  {
    id: "#SB-101",
    location: "Dhaka Univ TSC",
    fill: 42,
    status: "OPTIMAL",
    category: "normal",
    temp: "22°C (Cool)",
    amount: "210/500 kg"
  },
  {
    id: "#SB-109",
    location: "Uttara Sector 7",
    fill: 58,
    status: "NORMAL",
    category: "normal",
    temp: "25°C (Normal)",
    amount: "290/500 kg"
  }
];

export default function Booths() {
  const [filter, setFilter] = useState("all");

  const visibleBooths = useMemo(() => {
    if (filter === "urgent") return booths.filter((b) => b.category === "urgent");
    return booths;
  }, [filter]);

  const pingAll = () => {
    window.alert("Pinging all 24 IoT booth nodes... All responding within 120ms");
  };

  return (
    <section className="px-4 pt-3 pb-6 flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-primary">Booth Telemetry</h2>
          <p className="text-xs text-on-surface-variant">24 IoT Smart Vending Kiosks Online</p>
        </div>
        <button
          onClick={pingAll}
          className="py-1.5 px-3 rounded-lg bg-primary-fixed text-on-primary-fixed text-xs font-bold flex items-center gap-1"
        >
          <span className="material-symbols-outlined text-[16px]">sync</span>
          Ping All
        </button>
      </div>

      <div className="flex gap-2 overflow-x-auto pb-1">
        {[
          ["all", "All (24)"],
          ["urgent", "Urgent Fill (2)"],
          ["dhanmondi", "Dhanmondi"],
          ["gulshan", "Gulshan"]
        ].map(([key, label]) => (
          <button
            key={key}
            onClick={() => setFilter(key)}
            className={`px-3 py-1 rounded-full text-[11px] font-bold whitespace-nowrap ${
              filter === key
                ? "bg-primary text-on-primary"
                : "bg-surface-container text-on-surface-variant"
            }`}
          >
            {label}
          </button>
        ))}
      </div>

      <div className="flex flex-col gap-3">
        {visibleBooths.map((booth) => (
          <div
            key={booth.id}
            className={`rounded-xl bg-white p-4 shadow-sm flex flex-col gap-2 ${
              booth.fill >= 90 ? "border border-error/30" : ""
            }`}
          >
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <span
                  className={`w-3 h-3 rounded-full ${
                    booth.fill >= 90 ? "bg-error animate-pulse" : "bg-secondary"
                  }`}
                />
                <span className="text-sm font-bold text-primary">
                  {booth.id} • {booth.location}
                </span>
              </div>

              <span
                className={`px-2 py-0.5 rounded-full text-[11px] font-extrabold ${
                  booth.fill >= 90
                    ? "bg-error text-on-error"
                    : booth.fill >= 80
                    ? "bg-tertiary-fixed text-on-tertiary-fixed"
                    : "bg-secondary-container text-on-secondary-container"
                }`}
              >
                {booth.fill}% {booth.status}
              </span>
            </div>

            <div className="w-full h-2 bg-surface-container rounded-full overflow-hidden">
              <div
                className={`h-full rounded-full ${
                  booth.fill >= 90
                    ? "bg-error"
                    : booth.fill >= 80
                    ? "bg-tertiary-fixed-dim"
                    : "bg-secondary"
                }`}
                style={{ width: `${booth.fill}%` }}
              />
            </div>

            <div className="grid grid-cols-3 gap-2 text-xs text-on-surface-variant pt-1">
              <div>
                Fill:
                <strong className="text-on-surface font-semibold block">{booth.amount}</strong>
              </div>
              <div>
                Temp:
                <strong className="text-on-surface font-semibold block">{booth.temp}</strong>
              </div>
              <div>
                Compactor:
                <strong className="text-secondary font-semibold block">OK (v2.4)</strong>
              </div>
            </div>

            {booth.fill >= 80 && (
              <div className="flex gap-2 pt-2">
                <button
                  onClick={() =>
                    window.alert(
                      booth.fill >= 90
                        ? `Dispatched emergency hauler truck for ${booth.location}`
                        : `Queue updated for ${booth.location}`
                    )
                  }
                  className={`flex-1 py-1.5 rounded-lg text-xs font-bold ${
                    booth.fill >= 90
                      ? "bg-error text-on-error"
                      : "bg-primary text-on-primary"
                  }`}
                >
                  {booth.fill >= 90 ? "Dispatch Truck" : "Schedule Pickup"}
                </button>

                {booth.fill >= 90 && (
                  <button
                    onClick={() => window.alert(`Diagnostics triggered for ${booth.id}`)}
                    className="flex-1 py-1.5 rounded-lg bg-surface-container text-primary text-xs font-bold"
                  >
                    Run Diagnostic
                  </button>
                )}
              </div>
            )}
          </div>
        ))}
      </div>
    </section>
  );
}