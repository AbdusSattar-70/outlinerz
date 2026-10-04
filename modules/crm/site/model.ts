export type SiteSettings = {
  nameEn: string;
  nameBn: string;
  logo: string;
  mark: string;
  heroImage: string;
  learningImage: string;
  phone: string;
  email: string;
  addressEn: string;
  addressBn: string;
  copy: Record<string, { en: string; bn: string }>;
};
export type SiteRecord = { revision: number; settings: SiteSettings };
export const defaultSite: SiteSettings = {
  nameEn: "Sohoj Academy",
  nameBn: "সহজ একাডেমি",
  logo: "/branding/sohoj-academy-logo.webp",
  mark: "/branding/sohoj-academy-mark.webp",
  heroImage: "/images/sohoj-classroom.webp",
  learningImage: "/images/sohoj-learning.webp",
  phone: "",
  email: "",
  addressEn: "",
  addressBn: "",
  copy: {},
};
