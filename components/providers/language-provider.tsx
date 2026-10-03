"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useSyncExternalStore,
  type ReactNode,
} from "react";

export type AppLocale = "en" | "bn";

const STORAGE_KEY = "sohoj-locale";
const CHANGE_EVENT = "sohoj-locale-change";

const dictionary = {
  en: {
    language: "Language",
    theme: "Theme",
    english: "English",
    bengali: "বাংলা",
    light: "Light",
    dark: "Dark",
    system: "System",
    programs: "Programs",
    learningMethod: "Learning Method",
    whySohoj: "Why Sohoj",
    aboutUs: "About",
    faq: "FAQ",
    journal: "Journal",
    digitalCampus: "Digital Campus",
    registerInterest: "Register Interest",
    openDigitalCampus: "Open Digital Campus",
    skipToContent: "Skip to main content",
    dashboard: "Dashboard",
    sohojDigitalCampus: "Sohoj Academy Digital Campus",
    academic: "Academic",
    finance: "Finance",
    communication: "Communication",
    management: "Management",
    settingsGroup: "System",
    admissions: "Admissions",
    students: "Students",
    guardians: "Guardians",
    attendance: "Attendance",
    assessments: "Assessments",
    progress: "Progress",
    feeStructure: "Fee Structure",
    feeCollection: "Fee Collection",
    parentCommunication: "Parent Communication",
    notices: "Notices",
    staff: "Staff",
    teachers: "Teachers",
    settings: "Settings",
    openModule: "Open module",
    activeStudents: "Active Students",
    attendanceToday: "Attendance Marked Today",
    feesCollected: "Fees Collected",
    upcomingTests: "Upcoming Tests",
    operations: "Operations",
  },
  bn: {
    language: "ভাষা",
    theme: "থিম",
    english: "English",
    bengali: "বাংলা",
    light: "লাইট",
    dark: "ডার্ক",
    system: "সিস্টেম",
    programs: "প্রোগ্রামসমূহ",
    learningMethod: "শেখার পদ্ধতি",
    whySohoj: "কেন সহজ",
    aboutUs: "আমাদের সম্পর্কে",
    faq: "প্রশ্নোত্তর",
    journal: "শিক্ষা-জার্নাল",
    digitalCampus: "ডিজিটাল ক্যাম্পাস",
    registerInterest: "আগ্রহ নিবন্ধন",
    openDigitalCampus: "ডিজিটাল ক্যাম্পাস খুলুন",
    skipToContent: "মূল কনটেন্টে যান",
    dashboard: "ড্যাশবোর্ড",
    sohojDigitalCampus: "সহজ একাডেমি ডিজিটাল ক্যাম্পাস",
    academic: "একাডেমিক",
    finance: "ফাইন্যান্স",
    communication: "যোগাযোগ",
    management: "ম্যানেজমেন্ট",
    settingsGroup: "সিস্টেম",
    admissions: "ভর্তি",
    students: "শিক্ষার্থী",
    guardians: "অভিভাবক",
    attendance: "উপস্থিতি",
    assessments: "মূল্যায়ন",
    progress: "অগ্রগতি",
    feeStructure: "ফি কাঠামো",
    feeCollection: "ফি সংগ্রহ",
    parentCommunication: "অভিভাবক যোগাযোগ",
    notices: "নোটিশ",
    staff: "কর্মীবৃন্দ",
    teachers: "শিক্ষক",
    settings: "সেটিংস",
    openModule: "মডিউল খুলুন",
    activeStudents: "সক্রিয় শিক্ষার্থী",
    attendanceToday: "আজ উপস্থিতি নেয়া হয়েছে",
    feesCollected: "সংগৃহীত ফি",
    upcomingTests: "আসন্ন পরীক্ষা",
    operations: "অপারেশনসমূহ",
  },
} as const;

export type TranslationKey = keyof typeof dictionary.en;

type LanguageContextValue = {
  locale: AppLocale;
  setLocale: (locale: AppLocale) => void;
  toggleLocale: () => void;
  t: (key: TranslationKey) => string;
};

const LanguageContext = createContext<LanguageContextValue | null>(null);

function getStoredLocale(): AppLocale {
  if (typeof window === "undefined") return "en";
  const stored = window.localStorage.getItem(STORAGE_KEY);
  if (stored === "bn" || stored === "en") return stored;
  return navigator.language.toLowerCase().startsWith("bn") ? "bn" : "en";
}

function subscribe(callback: () => void) {
  window.addEventListener(CHANGE_EVENT, callback);
  window.addEventListener("storage", callback);
  return () => {
    window.removeEventListener(CHANGE_EVENT, callback);
    window.removeEventListener("storage", callback);
  };
}

function getServerSnapshot(): AppLocale {
  return "en";
}

export function LanguageProvider({ children }: { children: ReactNode }) {
  const locale = useSyncExternalStore(subscribe, getStoredLocale, getServerSnapshot);

  useEffect(() => {
    document.documentElement.lang = locale === "bn" ? "bn-BD" : "en";
  }, [locale]);

  const setLocale = useCallback((next: AppLocale) => {
    window.localStorage.setItem(STORAGE_KEY, next);
    window.dispatchEvent(new Event(CHANGE_EVENT));
  }, []);

  const toggleLocale = useCallback(() => {
    setLocale(locale === "en" ? "bn" : "en");
  }, [locale, setLocale]);

  const value = useMemo<LanguageContextValue>(
    () => ({
      locale,
      setLocale,
      toggleLocale,
      t: (key) => dictionary[locale][key],
    }),
    [locale, setLocale, toggleLocale]
  );

  return (
    <LanguageContext.Provider value={value}>
      <div data-locale={locale}>{children}</div>
    </LanguageContext.Provider>
  );
}

export function useLanguage() {
  const context = useContext(LanguageContext);
  if (!context) {
    throw new Error("useLanguage must be used within LanguageProvider.");
  }
  return context;
}
