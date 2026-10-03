import type { Metadata, Viewport } from "next";
import { ToastContainer } from "react-toastify";
import "./globals.css";
import "react-toastify/dist/ReactToastify.css";
import { ThemeProvider } from "@/components/theme-provider";
import { TooltipProvider } from "@/components/ui/tooltip";
import { OfflineBanner } from "@/components/shared/OfflineBanner";
import { LanguageProvider } from "@/components/providers/language-provider";

const publicSiteUrl =
  process.env.NEXT_PUBLIC_SITE_URL?.trim() ||
  (process.env.VERCEL_PROJECT_PRODUCTION_URL
    ? `https://${process.env.VERCEL_PROJECT_PRODUCTION_URL}`
    : process.env.VERCEL_URL
      ? `https://${process.env.VERCEL_URL}`
      : "http://localhost:3000");

export const metadata: Metadata = {
  metadataBase: new URL(publicSiteUrl),
  title: { default: "Outlinerz", template: "%s | Outlinerz" },
  description: "Simple operations for coaching and tuition organizations.",
  applicationName: "Outlinerz",
};

export const viewport: Viewport = {
  themeColor: "#071a45",
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className="font-sans antialiased">
        <ThemeProvider
          attribute="class"
          forcedTheme="dark"
          defaultTheme="dark"
          enableSystem={false}
          disableTransitionOnChange
        >
          <LanguageProvider>
            <TooltipProvider>{children}</TooltipProvider>
            <OfflineBanner />
          </LanguageProvider>
        </ThemeProvider>
        <ToastContainer position="bottom-right" autoClose={3000} />
      </body>
    </html>
  );
}
