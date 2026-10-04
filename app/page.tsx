import type { Metadata } from "next";
import { getSiteSettings } from "@/modules/crm/site/server";
import { PublicSite } from "@/modules/crm/site/server";
import { HomePageContent } from "@/modules/home/page-content";
import { publicSlug } from "@/modules/crm/public";
export default async function HomePage({
  searchParams,
}: {
  searchParams: Promise<{ organization?: string }>;
}) {
  const params = await searchParams;
  const slug = publicSlug(params.organization);
  return (
    <PublicSite slug={slug}>
      <HomePageContent slug={slug} />
    </PublicSite>
  );
}

export async function generateMetadata({
  searchParams,
}: {
  searchParams: Promise<{ organization?: string }>;
}): Promise<Metadata> {
  const { organization } = await searchParams;
  const site = await getSiteSettings(publicSlug(organization));
  return { title: { absolute: site.nameEn } };
}
