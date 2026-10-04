import type { Metadata, Viewport } from "next";
import localFont from "next/font/local";
import { ToastContainer } from "react-toastify";
import "./globals.css";
import "react-toastify/dist/ReactToastify.css";
import { ThemeProvider } from "@/components/theme-provider";
import { TooltipProvider } from "@/components/ui/tooltip";
import { OfflineBanner } from "@/components/shared/OfflineBanner";
import { LanguageProvider } from "@/components/providers/language-provider";

const montserrat = localFont({src:"../public/fonts/montserrat-latin.woff2",variable:"--font-en",display:"swap"});
const notoBengali = localFont({src:"../public/fonts/noto-sans-bengali.woff2",variable:"--font-bn",display:"swap"});

const publicSiteUrl =
  process.env.NEXT_PUBLIC_SITE_URL?.trim() ||
  (process.env.VERCEL_PROJECT_PRODUCTION_URL
    ? `https://${process.env.VERCEL_PROJECT_PRODUCTION_URL}`
    : process.env.VERCEL_URL
      ? `https://${process.env.VERCEL_URL}`
      : "http://localhost:3000");

export const metadata: Metadata = {
  metadataBase: new URL(publicSiteUrl),
  title: { default: "Sohoj Academy", template: "%s | Sohoj Academy" },
  description:
    "Sohoj Academy Digital Campus for students, guardians, teachers and academy operations. Learning made easy & fun.",
  applicationName: "Sohoj Academy",
  icons: {
    icon: [
      { url: "/favicons/favicon.ico", sizes: "any" },
      {
        url: "/favicons/favicon-32x32.png",
        type: "image/png",
        sizes: "32x32",
      },
      {
        url: "/favicons/favicon-16x16.png",
        type: "image/png",
        sizes: "16x16",
      },
    ],
    shortcut: ["/favicons/favicon.ico"],
    apple: [
      {
        url: "/branding/sohoj-academy-icon-192.webp",
        sizes: "192x192",
        type: "image/webp",
      },
    ],
  },
  manifest: "/favicons/site.webmanifest",
  openGraph: {
    type: "website",
    siteName: "Sohoj Academy",
    title: "Sohoj Academy",
    description: "Learning made easy & fun",
    images: [
      {
        url: "/branding/sohoj-academy-logo.webp",
        width: 192,
        height: 192,
        alt: "Sohoj Academy",
      },
    ],
  },
};

export const viewport: Viewport = {
  themeColor: "#071a45",
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className={`${montserrat.variable} ${notoBengali.variable} font-sans antialiased`}>
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
