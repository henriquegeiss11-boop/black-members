import { requireUser } from "@/lib/auth";
import { StudentHeader } from "@/components/student/StudentHeader";

export default async function StudentLayout({ children }: { children: React.ReactNode }) {
  const { profile } = await requireUser();
  return (
    <div className="min-h-screen">
      <StudentHeader profile={profile} />
      <main className="mx-auto max-w-6xl px-4 py-8 sm:px-6 sm:py-10">{children}</main>
    </div>
  );
}
