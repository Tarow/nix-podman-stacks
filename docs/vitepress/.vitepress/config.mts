import { defineConfig } from "vitepress";

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "Nix Podman Stacks",
  description: "",
  // base: "/mnw/", // Manually pass with --base
  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    search: {
      provider: "local",
    },
    sidebar: [
      {
        items: [
          { text: "Home", link: "/index" },
          { text: "Options", link: "/options" },
        ],
      },
    ],

    socialLinks: [
      { icon: "github", link: "https://github.com/Tarow/nix-podman-stacks" },
    ],

    outline: {
      level: "deep",
    },
  },
  vite: {
    ssr: {
      noExternal: "easy-nix-documentation",
    },
  },
});
