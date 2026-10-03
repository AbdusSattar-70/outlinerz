# Lean EduOps — মালিক ও অপারেটরের প্রস্তাবিত কাজের ধারা

এটি নতুন product-এর target workflow; বর্তমান ERP-তে সব ধাপ এখনো এইভাবে available নয়।
[Blueprint](LEAN_EDUOPS_BLUEPRINT.md) | [বাস্তবায়ন পরিকল্পনা](LEAN_EDUOPS_IMPLEMENTATION_PLAN.md)

## প্রথম setup

প্রতিষ্ঠানের নাম/লোগো, timezone ও currency দিন → default branch ও academic year → class/group/subjects → staff ও permissions → প্রথম course → টাকা গ্রহণের account।
ছোট প্রতিষ্ঠান default branch ব্যবহার করবে। Teacher invite না করেও owner নিজের class চালাতে পারবেন। Accounting chart setup daily operation শুরুর শর্ত নয়। Setup progress সংরক্ষিত থাকবে; অসম্পূর্ণ অংশ পরে পূরণযোগ্য।

## Course তৈরি ও পুনর্ব্যবহার

উদাহরণ: Class 8 Mathematics, 2026, Gopalpur, মাসিক ৳1,500; Evening A, capacity 15, রবিবার/মঙ্গলবার/বৃহস্পতিবার।
এক wizard-এ course information, fee এবং optional batch দিন। Review করে Draft বা Admission Open বেছে নিন। পরের বছরে একই programme বেছে নতুন offering করুন। Programme-এর reusable পরিচয় থাকবে; বছরের fee/student/batch নতুন offering-এর হবে।

ভর্তি খোলা মানেই website-এ প্রকাশ নয়। Public visibility আলাদা control। Free course হলে স্পষ্টভাবে fee 0 দিন। পুরোনো ছাত্রের agreed fee নতুন course fee edit-এ বদলাবে না।

## CRM থেকে ভর্তি

Guardian-এর ফোন → New enquiry → Contacted → Interested/Follow-up → admission conversion অথবা Lost।
Follow-up একটি dated task; pipeline-এর stage ও next action এক অর্থ নয়। Lost reason রাখুন; প্রয়োজন হলে reopen করুন।

Prospect থেকে Admit করুন অথবা সরাসরি admission খুলুন। Student/guardian, class/school, course, selected subjects, batch, fee/discount ও date review করুন। Existing student match হলে যাচাই করে reuse করুন; shared guardian phone মানেই duplicate student নয়।

একবার confirm করলে permanent student ID, enrollment ও প্রযোজ্য first invoice তৈরি হবে। Prospect-এর Admitted status সফল conversion-এর ফল; status click দিয়ে fake student নয়। Invoice তৈরি মানে টাকা পাওয়া নয়। Pay now optional; বাকি রেখেও policy অনুমোদন করলে enrollment active হবে। Capacity পূর্ণ হলে নতুন batch/waitlist বেছে নিতে হবে। Consent বা digital signature default prerequisite নয়।

## শিক্ষক প্রতিদিন কী করবেন

Today থেকে assigned session খুলুন। Planned topic দেখুন; উপস্থিতি নিন; actual topic coverage ও homework লিখুন; draft বা complete save করুন।
উদাহরণ: Algebra 1.2-এর 80% পড়ানো হয়েছে; বাকি অংশ next class-এ। System বাকি 20% pending রাখবে।
Cancelled class বা absent student-কে complete/present করে দেখাবে না।

পরের class-এ homework Done/Partial/Not Done দিন; এখনও যাচাই না করা হলে Unreviewed রাখুন। বিশেষ সাহায্য দরকার এমন student note academic director দেখতে পারবেন। Question preparation ও script checking task-এ deadline, assigned person ও accepted quantity থাকবে।

## পরীক্ষা ও অগ্রগতি

Class/Weekly/Monthly/Model test → topics, total marks, date → question draft → review → exam → marks entry → result।
Absent, not marked এবং zero marks আলাদা। Question-এর topic tag থাকলে ওই topic-এর achieved/possible marks থেকে analysis হবে; শুধু total score থেকে weak topic অনুমান করা হবে না।

Student profile-এ attendance, homework, topic evidence, test trend, teacher comments ও fee due দেখুন। Overall syllabus progress batch delivery বোঝায়; individual mastery test evidence বোঝায়।

## ফি আদায়

October invoice ৳1,500। Cash-এ ৳1,000 গ্রহণ করুন → invoice-এ ৳1,000 allocation → receipt → due ৳500।
আবার একই cash collection Income screen-এ লিখবেন না। Student receipt ও cash inflow linked record হবে।
Discount থাকলে authorized reason ও amount দিন; original invoice/adjustment history থাকবে। অতিরিক্ত payment হলে credit/unallocated balance দেখাবে; negative due নয়।
Refund হলে original payment reference, refundable balance, reason ও payout account দিন। টাকা ফেরত না দেওয়া credit adjustment actual cash refund নয়।

Accounting বন্ধ থাকলেও এই workflow চলবে। Accounting চালু থাকলে pending sync operator-এর receipt validity নষ্ট করবে না; exception finance-authorized user পরে reconcile করবেন।

## শিক্ষক ও কর্মীর পাওনা

চুক্তি অনুযায়ী fixed/hourly/per-class/per-script rule দিন। উদাহরণ: accepted 18 classes × ৳400 + 72 scripts × ৳10 + 3 question sets × ৳200 = ৳8,520।
একই কাজ fixed salary এবং per-class component-এ অনিচ্ছাকৃতভাবে দুইবার গণনা হবে না; hybrid হলে explicit agreement দরকার।
Preview দেখে অনুমোদিত liability তৈরি করুন; ৳5,000 দিলে remaining payable ৳3,520। Preview estimate, posted payable ও paid amount আলাদা।
Advance দিলে account outflow এবং staff advance record থাকবে; পরে settlement-এ advance adjust করলে আবার cash outflow হবে না।

## খরচ, কেনাকাটা ও assets

Rent: category, amount, date, supplier/payee, account ও evidence দিয়ে paid expense লিখুন। Unpaid expense payable তৈরি করবে; পরে actual payment দিন।

৩টি fan ৳12,000: purchase draft → received quantity/condition confirm → asset classification → branch/location/assignee → paid-now অথবা supplier payable।
যদি fan-গুলো individually tracked হয়, তিনটি asset record মোট cost ৳12,000 ভাগ করে পাবে। Purchase payment আবার Expense হিসেবে লিখবেন না। Asset maintenance আলাদা expense; transfer location cash transaction নয়। Disposal sale হলে proceeds money record হবে, asset history সংরক্ষিত থাকবে। Depreciation Accounting Pro-এর বিষয়; basic register চালাতে সেটি দরকার নেই।

## দিনের হিসাব

Opening cash + actual receipts − actual payouts ± transfers = expected closing cash।
Cash গুনে actual balance দিন; difference থাকলে investigation/recount করুন। Balance মিলানোর জন্য পুরোনো payment edit/delete নয়।
Bank/MFS account-এ statement comparison আলাদা। Cash surplus = actual collections minus selected actual operating payouts; এটি accrual profit নয়। Due collection forecast এবং cash balance আলাদা দেখুন।

## ভুল, retry ও access

Save চললে দ্বিতীয়বার নতুন request দেবেন না। Network outcome অনিশ্চিত হলে আগে register/receipt দেখুন; unchanged retry একই request identity ব্যবহার করবে।
Posted ভুল reversal/adjustment/refund দিয়ে ঠিক করুন; draft edit করা যাবে।
Owner staff-কে প্রয়োজনীয় permission দেবেন। Teacher academic access পেলেই fees/assets পড়তে পারবেন না। অন্য organization-এর কোনো record, attachment বা export দেখা যাবে না।
