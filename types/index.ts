import { STATUS } from "@/lib/constants";

export type Status = (typeof STATUS)[keyof typeof STATUS];
