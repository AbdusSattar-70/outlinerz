"use client";
import { Button } from "@/components/ui/button";
export function PrintAdmissionButton() {
  return (
    <Button className="print:hidden" onClick={() => window.print()}>
      Print / Save PDF
    </Button>
  );
}
