---
name: Urban Crisis Intelligence
colors:
  surface: '#fcf9f8'
  surface-dim: '#dcd9d9'
  surface-bright: '#fcf9f8'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f6f3f2'
  surface-container: '#f0eded'
  surface-container-high: '#eae7e7'
  surface-container-highest: '#e5e2e1'
  on-surface: '#1c1b1b'
  on-surface-variant: '#474740'
  inverse-surface: '#313030'
  inverse-on-surface: '#f3f0ef'
  outline: '#78776f'
  outline-variant: '#c9c7bd'
  surface-tint: '#5f5e58'
  primary: '#5f5e58'
  on-primary: '#ffffff'
  primary-container: '#f4f1e9'
  on-primary-container: '#6f6d67'
  inverse-primary: '#c9c6bf'
  secondary: '#b32a00'
  on-secondary: '#ffffff'
  secondary-container: '#fd5f35'
  on-secondary-container: '#591000'
  tertiary: '#5d5f5f'
  on-tertiary: '#ffffff'
  tertiary-container: '#f1f1f1'
  on-tertiary-container: '#6c6e6e'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e5e2da'
  primary-fixed-dim: '#c9c6bf'
  on-primary-fixed: '#1c1c17'
  on-primary-fixed-variant: '#474741'
  secondary-fixed: '#ffdbd2'
  secondary-fixed-dim: '#ffb4a1'
  on-secondary-fixed: '#3c0800'
  on-secondary-fixed-variant: '#891e00'
  tertiary-fixed: '#e2e2e2'
  tertiary-fixed-dim: '#c6c6c7'
  on-tertiary-fixed: '#1a1c1c'
  on-tertiary-fixed-variant: '#454747'
  background: '#fcf9f8'
  on-background: '#1c1b1b'
  surface-variant: '#e5e2e1'
typography:
  headline-xl:
    fontFamily: Plus Jakarta Sans
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  xs: 8px
  sm: 12px
  md: 16px
  lg: 24px
  xl: 32px
  xxl: 48px
  container-margin: 20px
  gutter: 16px
---

## Brand & Style

The design system is engineered for high-stakes urban intelligence, balancing the urgency of crisis management with a calm, trustworthy aesthetic. It serves as a bridge between complex AI data and actionable human response in the context of Pakistani infrastructure.

The visual direction follows a **Modern Minimalist** approach with subtle **Glassmorphism** overlays. By utilizing a warm, organic base color paired with high-energy accents, the interface feels rooted and local yet technologically advanced. The style emphasizes clarity through generous whitespace, soft depth, and a "clean-tech" finish that prioritizes legibility during high-stress scenarios.

## Colors

The palette is anchored by a warm off-white primary background (`#f4f1e9`), which reduces eye strain compared to pure white while providing a sophisticated, paper-like foundation. 

- **Accent/CTA:** The "Coral-Orange" (`#ff6036`) is used sparingly for primary actions and critical alerts to ensure immediate visual hierarchy.
- **Typography:** Primary text uses a near-black (`#1a1a1a`) for maximum contrast, while secondary information uses a muted gray (`#6b6b6b`).
- **Semantic Colors:** Standardized green, amber, and red are utilized for system status and crisis levels, ensuring high recognizability during emergencies.

## Typography

This design system utilizes **Plus Jakarta Sans** for headings to provide a modern, friendly, yet authoritative geometric feel. **Inter** is used for all body and UI text to ensure exceptional legibility across varying pixel densities and data-heavy environments.

Headlines should use tight letter spacing to maintain a "fixed" and urgent look. Body text maintains standard tracking for optimal readability during extended use. Mobile scaling reduces the largest display sizes to ensure content remains above the fold on smaller urban-utility devices.

## Layout & Spacing

The layout follows a **Fluid Grid** model with a base-4 tracking system. For mobile devices, a 4-column grid is used with 20px side margins. Tablets and Desktops utilize a 12-column grid with a maximum container width of 1280px.

Spacing is used to create clear logical groupings. Components like cards and map overlays should maintain a minimum of 16px (md) distance from each other to prevent visual clutter. During crisis mode, vertical padding in lists can be compressed to `sm` (12px) to allow more information density, while "Peace" mode defaults to `lg` (24px) for a more relaxed, editorial feel.

## Elevation & Depth

Hierarchy is established through a combination of **Ambient Shadows** and **Glassmorphism**.

1.  **Standard Cards:** Pure white background with a soft, diffused shadow (`0 4px 12px rgba(0,0,0,0.08)`). These sit at the lowest elevation above the background.
2.  **Map Overlays:** Glassmorphic surfaces using `rgba(255,255,255,0.85)` with a 12px backdrop blur. These feature a subtle 1px inner border (10% white) to define the edge against the map's complex visual data.
3.  **Active/Floating Elements:** Modals and floating action buttons (FABs) use a higher shadow intensity to suggest physical proximity to the user.

## Shapes

The design system employs a "Soft-Tech" shape language. 
- **Cards and Buttons:** A consistent 16px radius (`rounded-lg` in this system) is applied to provide a friendly, modern silhouette that contrasts with the technical nature of AI data.
- **Inputs:** A slightly tighter 12px radius is used to differentiate form elements from primary containers.
- **Navigation:** The bottom navigation bar uses a full pill-shape (999px) to emphasize its role as a floating, easily reachable utility.

## Components

### Buttons
- **Primary:** 52px height, Coral (`#ff6036`) background, white text, 16px radius.
- **Secondary:** 52px height, White background, 1px border (`#1a1a1a`), 16px radius.
- **Ghost:** Minimal padding, coral text, no background.

### Input Fields
- **Default:** 52px height, white background, 12px radius. Border is a soft neutral-200.
- **Focus State:** 2px border in Coral (`#ff6036`) with a subtle glow.

### Cards & Map Overlays
- **Information Cards:** White background, 16px padding, soft shadow.
- **Map Overlays:** Semi-transparent glass (85% white), 12px blur, 16px radius. Used for floating map controls and quick-stats.

### Navigation & Transitions
- **Navigation Bar:** Present on each screen. Bottom Nav is a white pill-shaped bar floating 20px from the bottom. 
- **Buttons:** HOME, MAP, AI ASSISTANT CHAT, Agent Logs (old runs).
- **Active State:** The active icon and label transition to Coral (`#ff6036`) with a subtle background "blob" indicator.
- **Top App Bar:** Each screen must have a Back Button on the top left corner.
- **Transitions:** Smooth transitions must be applied when switching between screens.

### Loading States & Agent Interactions
- **Skeleton Loading:** Use skeleton loading placeholders across the whole app while fetching data or initializing. Avoid basic spinners for general data loading.
- **Agent Processing:** When an Agent is processing a response, the app must show a loading circle accompanied by the specific Agent's name.

### Map Elements
- **Incident Markers:** Incidents on the Map screen must be color-coded by category:
  - **RED**: High severity / Critical
  - **ORANGE**: Medium severity / Warnings
  - **PURPLE**: Specific categories (e.g., AI Assessed / Unknown)

### Clean Premium Look
- Always prioritize a clean, premium visual aesthetic. Maintain high contrast, elegant typography, generous whitespace, and a high-end "Soft-Tech" glassmorphic feel. No hardcoded mock data on UI—everything must be functional, fetching from the FastAPI backend.