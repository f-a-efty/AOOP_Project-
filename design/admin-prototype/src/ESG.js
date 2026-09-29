import React from "react";

export default function ESG() {
  return (
    <section className="px-4 pt-3 pb-6 flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-primary">ESG Environmental Impact</h2>
          <p className="text-xs text-on-surface-variant">
            Audited carbon offsets & circular analytics
          </p>
        </div>
        <button
          onClick={() => window.alert("Downloading Certified ESG Compliance PDF...")}
          className="py-1.5 px-3 rounded-lg bg-primary text-on-primary text-xs font-bold flex items-center gap-1"
        >
          <span className="material-symbols-outlined text-[16px]">print</span>
          Report
        </button>
      </div>

      <div className="rounded-xl overflow-hidden bg-primary text-on-primary p-4 shadow-sm flex flex-col gap-3">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <span className="material-symbols-outlined text-secondary-fixed text-[24px]">
              forest
            </span>
            <span className="text-base font-bold">Dhaka City Offset Total</span>
          </div>
          <span className="px-2 py-0.5 rounded bg-secondary text-on-secondary text-[11px] font-bold">
            Q3 Certified
          </span>
        </div>

        <div className="grid grid-cols-2 gap-3 mt-1">
          <div className="p-3 rounded-lg bg-primary-container/70 flex flex-col">
            <span className="text-2xl font-extrabold text-secondary-fixed">72.4 Tons</span>
            <span className="text-xs text-on-primary-container">CO₂ GHG Avoided</span>
          </div>
          <div className="p-3 rounded-lg bg-primary-container/70 flex flex-col">
            <span className="text-2xl font-extrabold text-secondary-fixed">965,800</span>
            <span className="text-xs text-on-primary-container">Bottles Diverted</span>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-2.5">
        <div className="p-3.5 rounded-xl bg-white shadow-sm flex flex-col gap-1">
          <span className="material-symbols-outlined text-secondary text-[22px]">water_drop</span>
          <span className="text-[28px] font-extrabold text-primary">184,200 L</span>
          <span className="text-xs text-on-surface-variant">Groundwater Protected</span>
        </div>
        <div className="p-3.5 rounded-xl bg-white shadow-sm flex flex-col gap-1">
          <span className="material-symbols-outlined text-tertiary-fixed-dim text-[22px]">
            solar_power
          </span>
          <span className="text-[28px] font-extrabold text-primary">12.8 MWh</span>
          <span className="text-xs text-on-surface-variant">Solar Energy Yield</span>
        </div>
      </div>

      <div className="rounded-xl bg-white p-3.5 shadow-sm flex flex-col gap-2">
        <h4 className="text-sm font-bold text-primary">UN Sustainable Development Goals (SDG)</h4>
        <div className="flex flex-col gap-2 mt-1">
          {[
            ["SDG 11: Sustainable Cities", "98% Target"],
            ["SDG 12: Responsible Consumption", "100% Target"],
            ["SDG 14: Life Below Water", "94% Target"]
          ].map(([goal, target]) => (
            <div
              key={goal}
              className="flex items-center justify-between p-2 rounded-lg bg-surface-container-low"
            >
              <span className="text-xs font-semibold">{goal}</span>
              <span className="text-[11px] font-bold text-secondary">{target}</span>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}