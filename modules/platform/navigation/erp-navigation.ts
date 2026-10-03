import type { ErpContext, ErpNavGroup } from "@/types/erp";
import { erpRouteRegistry } from "@/modules/platform/navigation/erp-route-registry";

export function getNavigation(context: ErpContext): ErpNavGroup[] {
  const grouped = new Map<string, ErpNavGroup>();

  for (const route of erpRouteRegistry) {
    if (!context.permissions.includes(route.permission)) continue;

    const group = grouped.get(route.navGroup) ?? {
      title: route.navGroup,
      items: [],
    };

    group.items.push({
      id: route.id,
      title: route.title,
      href: route.href,
      permission: route.permission,
      icon: route.icon,
    });

    grouped.set(route.navGroup, group);
  }

  return Array.from(grouped.values());
}
