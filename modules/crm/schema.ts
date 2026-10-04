import { z } from "zod";
import { prospectStatuses } from "@/modules/crm/prospect-status";

export const recordProspectFollowupSchema = z.object({
  prospectId: z.string().uuid(),
  followupType: z.enum(["CALL", "WHATSAPP", "IN_PERSON", "COUNSELLING", "TRIAL", "OTHER"]),
  notes: z.string().trim().min(2, "Describe what happened during the follow-up.").max(1200),
  outcome: z.string().trim().max(500).optional(),
  newStatus: z.enum(prospectStatuses),
  nextFollowUpAt: z.string().optional(),
  lostReason: z.string().trim().max(500).optional(),
}).superRefine((value, ctx) => {
  if (value.newStatus === "LOST" && !value.lostReason?.trim()) {
    ctx.addIssue({
      code: "custom",
      path: ["lostReason"],
      message: "Lost reason is required when the prospect is marked LOST.",
    });
  }

  if (value.newStatus === "FUTURE_FOLLOW_UP" && !value.nextFollowUpAt) {
    ctx.addIssue({
      code: "custom",
      path: ["nextFollowUpAt"],
      message: "Select the next follow-up date and time.",
    });
  }
});

export type RecordProspectFollowupInput = z.infer<typeof recordProspectFollowupSchema>;
