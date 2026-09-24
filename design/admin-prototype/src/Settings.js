import React, { useState } from "react";
import { useNavigate } from "react-router-dom";

export default function Settings() {
  const navigate = useNavigate();
  const [autoDispatch, setAutoDispatch] = useState(true);
  const [antiFraud, setAntiFraud] = useState(true);
  const [smsDigest, setSmsDigest] = useState(true);

  return (
    <section className="px-4 pt-3 pb-6 flex flex-col gap-4">
      <div>
        <h2 className="text-2xl font-bold text-primary">Admin & System</h2>
        <p className="text-xs text-on-surface-variant">
          Fleet preferences, security & access rules
        </p>
      </div>

      <div className="rounded-xl bg-white p-4 shadow-sm flex items-center gap-3">
        <div className="w-14 h-14 rounded-full bg-primary text-secondary-fixed ring-2 ring-secondary flex items-center justify-center font-bold">
          NJ
        </div>
        <div>
          <h3 className="text-base font-bold text-primary">Nusrat Jahan</h3>
          <span className="text-xs text-on-surface-variant">
            Chief Operations Lead • Dhaka Fleet
          </span>
          <span className="text-[11px] text-secondary font-bold block">
            nusrat.jahan@ecoreward.gov.bd
          </span>
        </div>
      </div>

      <div className="rounded-xl bg-white p-4 shadow-sm flex flex-col gap-3">
        <h4 className="text-sm font-bold text-primary">Fleet Notifications</h4>

        {[
          [
            "Auto-dispatch at 90% fill",
            "Immediately alert nearby contracted hauler",
            autoDispatch,
            setAutoDispatch
          ],
          [
            "Anti-Fraud Camera AI",
            "Flag bottle deposit velocity anomalies",
            antiFraud,
            setAntiFraud
          ],
          [
            "Daily Treasury SMS Digest",
            "Receive 8:00 PM bKash disbursement ledger",
            smsDigest,
            setSmsDigest
          ]
        ].map(([title, sub, value, setValue]) => (
          <div
            key={title}
            className="flex items-center justify-between py-1 border-b border-surface-container last:border-b-0"
          >
            <div className="flex flex-col pr-3">
              <span className="text-xs font-bold text-on-surface">{title}</span>
              <span className="text-xs text-outline">{sub}</span>
            </div>
            <input
              checked={value}
              onChange={(e) => setValue(e.target.checked)}
              className="w-5 h-5 rounded text-primary focus:ring-primary"
              type="checkbox"
            />
          </div>
        ))}
      </div>

      <div className="flex flex-col gap-2">
        <button
          onClick={() => navigate("/rewards")}
          className="p-3 rounded-xl bg-white shadow-sm flex items-center justify-between text-left"
        >
          <div className="flex items-center gap-3">
            <span className="material-symbols-outlined text-secondary">payments</span>
            <span className="text-sm font-bold">Manage bKash API & Escrow</span>
          </div>
          <span className="material-symbols-outlined text-outline">chevron_right</span>
        </button>

        <button
          onClick={() => navigate("/esg")}
          className="p-3 rounded-xl bg-white shadow-sm flex items-center justify-between text-left"
        >
          <div className="flex items-center gap-3">
            <span className="material-symbols-outlined text-secondary">eco</span>
            <span className="text-sm font-bold">ESG & Carbon Certification Hub</span>
          </div>
          <span className="material-symbols-outlined text-outline">chevron_right</span>
        </button>

        <button
          onClick={() => {
            window.alert("Session secured. Logging out...");
            navigate("/");
          }}
          className="p-3 rounded-xl bg-error-container text-error text-sm font-bold flex items-center justify-center gap-2"
        >
          <span className="material-symbols-outlined text-[20px]">logout</span>
          Log Out of Operations Hub
        </button>
      </div>
    </section>
  );
}