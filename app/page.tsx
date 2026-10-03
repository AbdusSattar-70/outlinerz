import { HomePageContent } from "@/modules/home/page-content";
import { publicSlug } from "@/modules/crm/public";
export default async function HomePage({
  searchParams,
}: {
  searchParams: Promise<{ organization?: string }>;
}) {
  const params = await searchParams;
  return <HomePageContent slug={publicSlug(params.organization)} />;
}
