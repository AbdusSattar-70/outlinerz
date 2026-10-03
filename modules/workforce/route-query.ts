import {z} from "zod";
export function workforceQuery(q:{month?:string;person?:string;page?:string}){const raw=q.month&&/^\d{4}-(0[1-9]|1[0-2])$/.test(q.month)?`${q.month}-01`:undefined;const person=z.string().uuid().safeParse(q.person);return {month:raw,person:person.success?person.data:undefined,page:Math.max(1,Math.min(10000,Number.parseInt(q.page??"1",10)||1))};}
