import type { Metadata } from "next";
import { HomePageContent } from "@/modules/home/page-content";

export const metadata: Metadata = {
  title: "Sohoj Academy | Focused Learning. Visible Progress.",
  description:
    "Sohoj Academy combines small-batch teaching, continuous assessment and clear guardian progress tracking for focused academic support.",
};

export default async function HomePage() {
  return <HomePageContent />;
}
