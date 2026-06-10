# Content Guidelines

This directory contains Astro content collections.

## Collections

- `blog`: public blog posts under `src/content/blog/`.
- `docs`: documentation pages under `src/content/docs/`.
- Collection schemas are defined in `src/content.config.ts`.

## Blog Posts

- Prefer the directory form `src/content/blog/<slug>/index.md` for new posts.
- Use lowercase, hyphen-separated slugs for new article directories.
- Chinese technical articles should normally set `language: 'zh'`.
- Set `draft: false` only when the post is ready to publish.
- Keep `description` concise because it is used in list and SEO metadata.
- Tags are normalized to lowercase by the collection schema; choose stable, reusable tag names.

Required blog frontmatter:

```yaml
---
title: Article title
description: Short article summary under 160 characters
publishDate: 2026-04-29 02:35:00
tags: ['tag-a', 'tag-b']
language: 'zh'
draft: false
comment: true
---
```

Optional blog frontmatter:

- `updatedDate`
- `heroImage`

## Docs

- Docs files live in `src/content/docs/` and use the `docs` collection schema.
- Use `order` to control navigation order when needed.
- Set `draft: true` for unfinished docs.

## Writing Style

- Default to Simplified Chinese for public technical content unless the topic requires otherwise.
- Use clear headings, practical examples, and code blocks that can be copied.
- Prefer concrete project paths and commands over vague wording.
- Keep Markdown ASCII-compatible unless existing content or the topic requires Chinese text.

## Validation

After adding or changing public content, run:

```bash
bun run build
```

Use `bun run format` if you changed many Markdown or Astro files and need formatting normalization.
