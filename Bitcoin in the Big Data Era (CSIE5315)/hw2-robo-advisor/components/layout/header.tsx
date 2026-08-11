"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

export function Header() {
  const pathname = usePathname();

  return (
    <header className="border-b border-gray-200 bg-white dark:border-gray-800 dark:bg-gray-900">
      <div className="mx-auto flex h-14 max-w-7xl items-center gap-6 px-4">
        <Link href="/" className="text-lg font-bold tracking-tight">
          Palantir.fi
        </Link>
        <nav className="flex gap-4 text-sm">
          <Link
            href="/"
            className={
              pathname === "/"
                ? "font-medium text-foreground"
                : "text-gray-500 hover:text-foreground dark:text-gray-400"
            }
          >
            Overview
          </Link>
        </nav>
      </div>
    </header>
  );
}
