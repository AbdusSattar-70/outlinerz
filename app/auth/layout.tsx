import { Metadata } from "next";
import { ReactNode } from "react";

export const metadata: Metadata = {
  title: "Account | Outlinerz",
  description: "Account access for Outlinerz organizations",
};
export default async function AuthLayout({
  children,
}: {
  children: ReactNode;
}) {
  return <>{children}</>;
}
