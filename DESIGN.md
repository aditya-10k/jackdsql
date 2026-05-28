---
name: Cyber-Technic
colors:
  surface: '#10141a'
  surface-dim: '#10141a'
  surface-bright: '#353940'
  surface-container-lowest: '#0a0e14'
  surface-container-low: '#181c22'
  surface-container: '#1c2026'
  surface-container-high: '#262a31'
  surface-container-highest: '#31353c'
  on-surface: '#dfe2eb'
  on-surface-variant: '#baccb0'
  inverse-surface: '#dfe2eb'
  inverse-on-surface: '#2d3137'
  outline: '#85967c'
  outline-variant: '#3c4b35'
  surface-tint: '#2ae500'
  primary: '#efffe3'
  on-primary: '#053900'
  primary-container: '#39ff14'
  on-primary-container: '#107100'
  inverse-primary: '#106e00'
  secondary: '#c2c7d0'
  on-secondary: '#2c3138'
  secondary-container: '#42474f'
  on-secondary-container: '#b1b5bf'
  tertiary: '#fff8f7'
  on-tertiary: '#442927'
  tertiary-container: '#ffd3ce'
  on-tertiary-container: '#7a5955'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#79ff5b'
  primary-fixed-dim: '#2ae500'
  on-primary-fixed: '#022100'
  on-primary-fixed-variant: '#095300'
  secondary-fixed: '#dee2ec'
  secondary-fixed-dim: '#c2c7d0'
  on-secondary-fixed: '#171c23'
  on-secondary-fixed-variant: '#42474f'
  tertiary-fixed: '#ffdad6'
  tertiary-fixed-dim: '#e7bdb8'
  on-tertiary-fixed: '#2c1513'
  on-tertiary-fixed-variant: '#5d3f3c'
  background: '#10141a'
  on-background: '#dfe2eb'
  surface-variant: '#31353c'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 48px
    fontWeight: '700'
    lineHeight: '1.1'
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '600'
    lineHeight: '1.2'
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: '1.2'
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.6'
  code-md:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '400'
    lineHeight: '1.5'
  code-sm:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '400'
    lineHeight: '1.5'
  label-caps:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '700'
    lineHeight: '1'
    letterSpacing: 0.05em
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  unit: 8px
  gutter: 24px
  margin-page: 40px
  sidebar-width: 280px
  container-max: 1440px
---

## Brand & Style

This design system is engineered for high-performance database management and developer workflows. It evokes a "command center" atmosphere—state-of-the-art, precise, and undeniably technical. The visual language bridges the gap between raw terminal efficiency and premium modern software.

The aesthetic follows a **Glassmorphic-Cybernetic** approach. It utilizes deep charcoal backgrounds to eliminate visual noise, allowing the vibrant Neon Green accents to guide the user's focus toward critical data and actions. Components feel like projected interfaces—translucent, layered, and illuminated from within. The emotional response is one of absolute control and sophisticated power.

## Colors

The palette is anchored by a "True Dark" foundation. The primary **Neon Green** is used sparingly but impactfully to denote interactivity, success, and primary navigation. 

- **Backgrounds:** Use `#0D1117` for the base canvas to maximize contrast with neon elements.
- **Glass Surfaces:** Surface layers use `#161B22` with 60% opacity and a `backdrop-filter: blur(12px)`.
- **Status Indicators:** 
    - **Blue (#00A3FF)** represents "Easy" or "Low Latency."
    - **Yellow (#FFD700)** represents "Medium" or "Warning."
    - **Red (#FF3131)** represents "Hard" or "Critical Error."
- **Gradients:** Use the primary-to-transparent gradient for active state indicators or subtle section headers.

## Typography

The typography system prioritizes legibility and technical rigor. 

**Inter** serves as the structural UI typeface, providing a neutral, highly readable canvas for navigation and controls. Use `label-caps` for table headers and section metadata to create a disciplined, organized feel.

**JetBrains Mono** is the workhorse for all data-centric content. Every SQL query, JSON object, or terminal output must use this font. It ensures that characters like `0` and `O` or `l` and `1` are clearly distinguishable, which is critical for debugging and data integrity.

## Layout & Spacing

The layout philosophy is built on a **Modular Grid** system. Content is housed in glassmorphic containers that respond to the viewport width.

1. **Sidebars:** Fixed at 280px to maintain a consistent control plane.
2. **Main Canvas:** A fluid area that accommodates heavy data tables and code editors.
3. **The 8px Rule:** All padding, margins, and component heights must be multiples of 8px (e.g., 8, 16, 24, 32). This creates a rhythmic, mathematical precision across the interface.
4. **Reflow:** On tablet/mobile, sidebars collapse into a "drawer" or a bottom-docked navigation bar, and page margins reduce from 40px to 16px.

## Elevation & Depth

Depth in this design system is achieved through **Luminance and Translucency** rather than traditional heavy shadows.

- **Level 0 (Base):** The #0D1117 background.
- **Level 1 (Panels):** Glassmorphic surfaces with a 1px solid border (`rgba(255, 255, 255, 0.08)`). These should have a subtle background blur to separate them from the base.
- **Level 2 (Popovers/Modals):** Increased opacity and a primary-colored "outer glow." The glow should be soft: `box-shadow: 0 0 20px rgba(57, 255, 20, 0.15)`.
- **Level 3 (Interactive Focus):** Elements like active input fields or selected code lines should feature a sharp 2px Neon Green left-border or a subtle inner glow to indicate "Active" status.

## Shapes

The shape language is **Soft-Technical**. We avoid aggressive roundedness to maintain a professional, tool-like feel, but utilize subtle 0.25rem (4px) radii to keep the interface from feeling "brutal" or dated.

- **Small Components (Buttons, Inputs):** 4px radius.
- **Medium Components (Cards, Panels):** 8px radius (`rounded-lg`).
- **Large Components (Modals):** 12px radius (`rounded-xl`).
- **Status Pips:** Always circular (full rounding) to contrast against the rectangular grid.

## Components

### Buttons
- **Primary:** Solid Neon Green fill with black text. On hover, add a 10px outer glow of the same color.
- **Ghost:** Neon Green border (1px), transparent background. Text is Neon Green.

### Code Blocks
- Background: `#05070A` (slightly darker than base).
- Syntax Highlighting: Use the Status colors (Blue for keywords, Yellow for strings, Red for errors).
- Font: JetBrains Mono (Medium).

### Input Fields
- Dark background with a subtle bottom-border only in the inactive state. 
- On focus, the border becomes Neon Green and a subtle radial gradient glow appears behind the field.

### Glass Cards
- Used for grouping related metrics or query results.
- Must include the `backdrop-filter: blur(12px)` and the subtle 1px border to ensure content is legible against background noise.

### Status Chips
- Small, pill-shaped elements. 
- Utilize a "dot" icon of the status color alongside `label-caps` typography. For example: A blue dot for "Easy" difficulty.