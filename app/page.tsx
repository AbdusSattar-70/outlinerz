import Image from "next/image";
import Logo from "./../public/logo.png";
import { Button } from "@/components/ui/button";

export default function Home() {
  return (
    <div>
      <div className="flex">
        <div className="w-10">
          <Image src={Logo} alt="logo" />
        </div>
        <h1 className="text-center text-5xl text-blue-500">Outlinerz!</h1>
      </div>
      <Button className="text-blue-500 bg-slate-300">Shadcn</Button>
    </div>
  );
}
