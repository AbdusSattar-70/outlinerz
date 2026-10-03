import type { AppRole } from "@/lib/constants";

export type User = {
  id: string;
  name: string;
  email: string;
  role: AppRole;
  avatar?: string | null;
};

export type UserStore = {
  user: User | null;
  setUser: (user: User) => void;
  clearUser: () => void;
};
