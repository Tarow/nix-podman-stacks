---
title: Options
---

# {{ $frontmatter.title }}

<script setup>
import { data } from "./nps.data.ts";
import { RenderDocs } from "easy-nix-documentation";
</script>

## Settings

<RenderDocs :options="data" :exclude="/nps\.stacks\.*|nps\.containers\.*|services\.podman\.*/" />

## Stack Options

<RenderDocs :options="data" :include="/nps\.stacks\.*/" />

## Container Options

<RenderDocs :options="data" :include="/services\.podman\.containers\.*/" />
