import React, { useState } from "react";

export default function Rewards() {
  const [rate, setRate] = useState(0.2);

  const changeRate = () => {
    const value = window.prompt(
      `Enter new Eco-Token to BDT rate (currently ৳${rate.toFixed(2)}):`,
      rate.toFixed(2)
    );

    if (value && !Number.isNaN(Number(value))) {
      const newRate = Number(value);
      setRate(newRate);
      window.alert(
        `Token exchange rate successfully updated to ৳${newRate.toFixed(2)} / Eco-Token!`
      );
    }
  };

  return (
    <section className="px-4 pt-3 pb-6 flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-primary">Rewards & Rates</h2>
          <p className="text-xs text-on-surface-variant">
            bKash payouts, tokens & merchant partnerships
          </p>
        </div>
        <button
          onClick={changeRate}
          className="py-1.5 px-3 rounded-lg bg-secondary text-on-secondary text-xs font-bold flex items-center gap-1"
        >
          <span className="material-symbols-outlined text-[16px]">edit</span>
          Change Rate
        </button>
      </div>

      <div className="rounded-xl bg-gradient-to-br from-primary to-primary-container p-4 text-on-primary shadow-sm flex flex-col gap-3">
        <div className="flex items-center justify-between">
          <span className="text-[11px] uppercase tracking-wider text-secondary-fixed">
            Current Live Peg
          </span>
          <span className="px-2 py-0.5 rounded bg-white/20 text-[11px] font-bold">
            Auto-Sync ON
          </span>
        </div>

        <div className="flex items-baseline gap-2">
          <span className="text-[32px] font-extrabold tracking-tight">
            ৳{rate.toFixed(2)}
          </span>
          <span className="text-on-primary-container text-xs">per 1 Eco-Token</span>
        </div>

        <p className="text-xs text-on-primary-container">
          Citizens earn 5 Eco-Tokens per standard 500ml PET bottle (= ৳1.00 bKash).
        </p>
      </div>

      <div className="p-3.5 rounded-xl bg-white shadow-sm flex flex-col gap-2">
        <div className="flex items-center justify-between">
          <span className="text-xs font-bold text-primary">Dhaka Bank Escrow Pool</span>
          <span className="text-[11px] text-secondary font-bold">Active & Funded</span>
        </div>
        <div className="flex items-baseline justify-between">
          <span className="text-[28px] font-extrabold text-primary">৳1,450,000</span>
          <span className="text-[11px] text-outline">Available Cap</span>
        </div>
        <button
          onClick={() => window.alert("Simulated ৳50,000 top-up request sent to Treasury!")}
          className="w-full mt-1 py-2 rounded-lg bg-surface-container text-primary text-xs font-bold"
        >
          Top Up Escrow Account
        </button>
      </div>

      <h4 className="text-base font-bold text-primary">Retail Voucher Partners</h4>

      <div className="flex flex-col gap-2.5">
        {[
          ["SP", "Shwapno Superstore", "100tk = ৳25 Off Coupon", "3,420 Redeemed"],
          ["AL", "Aarong Green Life", "250tk = ৳60 Off Coupon", "1,890 Redeemed"]
        ].map(([initials, name, deal, redeemed]) => (
          <div key={name} className="p-3 rounded-xl bg-white shadow-sm flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-lg bg-secondary-container text-on-secondary-container flex items-center justify-center font-bold">
                {initials}
              </div>
              <div>
                <h4 className="text-sm font-bold text-on-surface">{name}</h4>
                <span className="text-xs text-outline">{deal}</span>
              </div>
            </div>
            <span className="text-xs font-bold text-secondary">{redeemed}</span>
          </div>
        ))}
      </div>
    </section>
  );
}