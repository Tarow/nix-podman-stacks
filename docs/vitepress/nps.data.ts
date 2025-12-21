import { loadOptions, stripNixStore } from "easy-nix-documentation/loader";
export default {
  async load() {
    const optionsJSON = process.env.NPS_OPTIONS_JSON;
    if (optionsJSON === undefined) {
      console.log("NPS_OPTIONS_JSON is undefined");
      exit(1);
    }
    return await loadOptions(optionsJSON, {
      include: [/^(?!.*_module)/],
      mapDeclarations: (declaration) => {
        const relDecl = stripNixStore(declaration);
        return `<a href="https://github.com/Tarow/nix-podman-stacks/tree/main/${relDecl}">&lt;nps/${relDecl}&gt;</a>`;
      },
    });
  },
};
