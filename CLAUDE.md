# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a personal blog built with Astro 5 and the `astro-pure` theme. It deploys to GitHub Pages via GitHub Actions from the `next` branch.

## Common Commands

```bash
bun install          # Install dependencies
bun dev              # Start dev server (localhost:4321)
bun run build        # Build for production (runs astro-pure check, astro check, astro build)
bun preview          # Preview production build locally
bun new              # Create a new blog post via astro-pure CLI
bun run lint         # Run ESLint with auto-fix
bun run format       # Format code with Prettier
bun run check        # Run Astro type checking
bun run sync         # Sync Astro content collection types
bun run yijiansilian # Combined: lint + sync + check + format
```

## Architecture

### Core Stack
- **Astro 5** - Static site generator
- **astro-pure** - Theme integration (handles sitemap, MDX, UnoCSS automatically)
- **UnoCSS** - Utility-first CSS with custom typography configuration
- **TypeScript** - Strict mode enabled

### Content Collections (`src/content.config.ts`)
Two collections defined:
- **blog** - Blog posts in `src/content/blog/` (md/mdx)
- **docs** - Documentation in `src/content/docs/` (md/mdx)

Blog frontmatter schema: title, description, publishDate, updatedDate, heroImage, tags, language, draft, comment

### Key Configuration Files
- `astro.config.ts` - Main Astro config with Vercel static adapter, Shiki syntax highlighting, KaTeX math support
- `src/site.config.ts` - Theme configuration (title, author, menu, footer, integrations like pagefind, waline comments)
- `uno.config.ts` - UnoCSS typography customization (blockquote, code blocks, tables)
- `tsconfig.json` - Path aliases defined (`@/components/*`, `@/layouts/*`, `@/utils/*`, `@/site-config`)

### Directory Structure
```
src/
├── assets/          # Static assets (images, icons, styles)
├── components/      # Astro components (BaseHead, home, about, projects, links)
├── content/         # Blog posts and docs (content collections)
├── layouts/         # Page layouts (BaseLayout, BlogPost, ContentLayout, etc.)
├── pages/           # Route pages (index, blog, about, projects, etc.)
├── plugins/         # Custom Shiki transformers and rehype plugins
├── site.config.ts   # Theme and integration config
└── content.config.ts # Content collection schemas
```

### Custom Plugins (`src/plugins/`)
- `shiki-transformers.ts` - Copy button, language badge, title, diff highlighting
- `rehype-auto-link-headings.ts` - Heading anchor links

## Deployment

- Branch: `next`
- GitHub Actions workflow: `.github/workflows/deploy.yml`
- Build command: `bun run build`
- Output directory: `dist/`
- Bun version: 1.2.20
