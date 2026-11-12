import Link from "next/link";

export function Logo({ href = "/dashboard", size = "md" }: { href?: string; size?: "md" | "lg" }) {
  return (
    <Link href={href} className="inline-flex items-baseline gap-1.5 font-semibold tracking-[0.2em]">
      <span className={size === "lg" ? "text-2xl" : "text-sm"}>BLACK</span>
      <span className={(size === "lg" ? "text-2xl" : "text-sm") + " text-gold"}>MEMBERS</span>
    </Link>
  );
}
