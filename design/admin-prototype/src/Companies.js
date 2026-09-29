// import React from "react";

// const companies = [
//   {
//     initials: "GR",
//     name: "GreenRecycle Ltd.",
//     license: "License #R-DH-9014 • Mirpur Plant",
//     status: "Active",
//     recycled: "24,190 kg",
//     trucks: "4 Trucks",
//     reconcile: "Intake Reconciled: 99.4%",
//     action: "Assign Pickup",
//     actionType: "primary"
//   },
//   {
//     initials: "BP",
//     name: "Bengal Poly-Reclaim Co.",
//     license: "License #R-DH-8221 • Gazipur Depot",
//     status: "Active",
//     recycled: "18,400 kg",
//     trucks: "3 Trucks",
//     reconcile: "Intake Reconciled: 98.8%",
//     action: "Contact Driver",
//     actionType: "secondary"
//   },
//   {
//     initials: "EP",
//     name: "EcoPlast Circular Ltd.",
//     license: "License #R-DH-4402 • Tejgaon Yard",
//     status: "Delayed",
//     recycled: "5,700 kg",
//     trucks: "1 (In Repair)",
//     reconcile: "1 Delayed Pickup Slot",
//     action: "Reroute",
//     actionType: "danger"
//   }
// ];

// export default function Companies() {
//   const action = (company) => {
//     window.alert(`${company.action} for ${company.name}.`);
//   };

//   return (
//     <section className="px-4 pt-3 pb-6 flex flex-col gap-4">
//       <div className="flex items-center justify-between">
//         <div>
//           <h2 className="text-2xl font-bold text-primary">Contracted Recyclers</h2>
//           <p className="text-xs text-on-surface-variant">
//             Active haulers, sorting centers & bulk intake
//           </p>
//         </div>
//         <button
//           onClick={() => window.alert("Creating new dispatch ticket...")}
//           className="py-1.5 px-3 rounded-lg bg-primary text-on-primary text-xs font-bold flex items-center gap-1"
//         >
//           <span className="material-symbols-outlined text-[16px]">add</span>
//           Dispatch
//         </button>
//       </div>

//       <div className="p-3 rounded-xl bg-secondary-container text-on-secondary-container flex items-center justify-between">
//         <div className="flex items-center gap-2">
//           <span className="material-symbols-outlined text-[20px]">local_shipping</span>
//           <span className="text-xs font-bold">8 Recycler Trucks Active on Route</span>
//         </div>
//         <span className="text-[11px] font-extrabold bg-white/80 px-2 py-0.5 rounded-full text-secondary">
//           Dhaka Fleet
//         </span>
//       </div>

//       <div className="flex flex-col gap-3">
//         {companies.map((company) => (
//           <div key={company.name} className="rounded-xl bg-white p-4 shadow-sm flex flex-col gap-2.5">
//             <div className="flex items-center justify-between">
//               <div className="flex items-center gap-2.5">
//                 <div className="w-10 h-10 rounded-lg bg-primary-fixed flex items-center justify-center text-primary font-extrabold">
//                   {company.initials}
//                 </div>
//                 <div>
//                   <h3 className="text-base font-bold text-primary">{company.name}</h3>
//                   <span className="text-xs text-outline">{company.license}</span>
//                 </div>
//               </div>
//               <span
//                 className={`py-0.5 px-2 rounded-full text-[11px] font-bold ${
//                   company.status === "Active"
//                     ? "bg-secondary-container text-on-secondary-container"
//                     : "bg-error-container text-error"
//                 }`}
//               >
//                 {company.status}
//               </span>
//             </div>

//             <div className="grid grid-cols-2 gap-2 bg-surface-container-low p-2.5 rounded-lg text-xs">
//               <div>
//                 Total Recycled:
//                 <strong className="text-primary block text-base">{company.recycled}</strong>
//               </div>
//               <div>
//                 Assigned Trucks:
//                 <strong className="text-secondary block text-base">{company.trucks}</strong>
//               </div>
//             </div>

//             <div className="flex items-center justify-between pt-1">
//               <span
//                 className={`text-[11px] ${
//                   company.status === "Delayed" ? "text-error font-bold" : "text-outline"
//                 }`}
//               >
//                 {company.reconcile}
//               </span>
//               <button
//                 onClick={() => action(company)}
//                 className={`py-1.5 px-3 rounded-lg text-[11px] font-bold ${
//                   company.actionType === "primary"
//                     ? "bg-primary text-on-primary"
//                     : company.actionType === "danger"
//                     ? "bg-error text-on-error"
//                     : "bg-surface-container text-primary"
//                 }`}
//               >
//                 {company.action}
//               </button>
//             </div>
//           </div>
//         ))}
//       </div>
//     </section>
//   );
// }