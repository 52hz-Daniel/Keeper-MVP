/** @type {import('tailwindcss').Config} */
module.exports = {
  presets: [require("nativewind/preset")],
  content: ["./app/**/*.{js,jsx,ts,tsx}", "./components/**/*.{js,jsx,ts,tsx}"],
  theme: {
    extend: {
      colors: {
        midnight: "#0F172A",
        lavender: "#818CF8",
        cream: "#F1F5F9",
        coral: "#FB7185",
      },
    },
  },
  plugins: [],
}
