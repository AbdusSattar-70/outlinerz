import { Metadata } from "next";
import { ReactNode } from "react";

export const metadata: Metadata = {
  title: "Auth | Sohoj Academy",
  description: "A student management app for a coaching centre",
};
export default async function AuthLayout({
  children,
}: {
  children: ReactNode;
}) {
  return <>{children}</>;
}
