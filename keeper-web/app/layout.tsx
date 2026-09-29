import type { Metadata, Viewport } from "next";
import { Inter } from "next/font/google";
import "./globals.css";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
    title: "Keeper",
    description: "The Silent Guardian",
    manifest: "/manifest.json",
};

export const viewport: Viewport = {
    width: "device-width",
    initialScale: 1,
    maximumScale: 1,
    userScalable: false, // Prevent zooming to feel like a native app
    themeColor: "#0F172A",
};

export default function RootLayout({
    children,
}: Readonly<{
    children: React.ReactNode;
}>) {
    return (
        <html lang="en">
            <body className={`${inter.className} bg-slate-900 text-slate-50 antialiased overscroll-none`}>
                <div className="mx-auto max-w-md h-[100dvh] bg-slate-900 flex flex-col shadow-2xl overflow-hidden">
                    {children}
                </div>
            </body>
        </html>
    );
}
