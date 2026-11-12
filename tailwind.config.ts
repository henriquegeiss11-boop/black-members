import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        bg: "#080808",
        surface: "#111111",
        card: "#181818",
        line: "#262626",
        gold: { DEFAULT: "#F5C542", dark: "#D6A928" },
        ink: { DEFAULT: "#FFFFFF", muted: "#A0A0A0" },
      },
      fontFamily: {
        sans: ["ui-sans-serif", "system-ui", "-apple-system", "Segoe UI", "Roboto", "Helvetica Neue", "Arial", "sans-serif"],
      },
      borderRadius: { xl2: "1.25rem" },
      keyframes: {
        "fade-up": {
          "0%": { opacity: "0", transform: "translateY(8px)" },
          "100%": { opacity: "1", transform: "translateY(0)" },
        },
      },
      animation: { "fade-up": "fade-up .4s ease-out both" },
    },
  },
  plugins: [],
};

export default config;
