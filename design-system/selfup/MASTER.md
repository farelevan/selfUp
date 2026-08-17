# SelfUp Design System

> Native SwiftUI source of truth. Page overrides in `pages/` take precedence.

## Product direction

- **Product:** private, offline-first self-improvement workspace with habits, tasks, XP, rewards, insights, and personal cash-flow tracking.
- **Style:** calm, optimistic, modern, and functional. Use flat semantic surfaces with restrained depth; playful feedback belongs to progress moments, not every card.
- **Design dials:** variance 4/10, motion 4/10, density 6/10.
- **Principle:** clarity first, motivation second, decoration last.

## Semantic color roles

The skill matches two relevant product profiles: Habit Tracker and Personal Finance Tracker. SelfUp combines their role-based palettes without assigning unrelated colors screen by screen.

| Role | Light | Dark | Usage |
|---|---:|---:|---|
| Brand foreground | `#1E40AF` | `#9DB9FF` | Links, icons, selected labels |
| Brand fill | `#1E40AF` | `#3159B8` | Primary buttons and filled controls |
| Success foreground | `#047857` | `#6EE7B7` | Completed habits, income, positive state |
| Success fill | `#047857` | `#047857` | Filled confirmation controls |
| Warning foreground | `#A16207` | `#FCD34D` | Spending pace and caution |
| Warning fill | `#A16207` | `#92400E` | Warning badges with white text |
| Danger foreground | `#B91C1C` | `#FCA5A5` | Expenses, destructive/over-budget state |
| Danger fill | `#B91C1C` | `#991B1B` | Destructive filled controls |
| Info foreground | `#0369A1` | `#7DD3FC` | Neutral metrics and supporting status |
| Info fill | `#0369A1` | `#075985` | Filled neutral controls with white content |
| Achievement | `#A16207` | `#FCD34D` | XP, levels, rewards, streak milestones |
| Background | system grouped | system grouped | Screen canvas |
| Surface | secondary grouped | secondary grouped | Cards and grouped rows |
| Border | separator @ 55% | separator @ 55% | Quiet containment |

Rules:

- Never use color as the only state signal; pair it with text and/or an SF Symbol.
- Filled colors use their matching `on-*` foreground, normally white.
- Charts use the same semantic success/danger/brand roles as their summaries.
- Raw RGB values belong only in `SelfUpStyle`; feature views consume semantic tokens.

## Typography

- Use San Francisco through SwiftUI semantic text styles (`.largeTitle`, `.title2`, `.headline`, `.body`, `.caption`).
- Support Dynamic Type. Avoid fixed point sizes for user-facing information.
- Prefer rounded design only for level/XP numerals and short motivational metrics.
- Body text is at least `.body`; `.caption` is supplementary and never the sole carrier of a critical value.
- Maintain 4.5:1 contrast for normal text and 3:1 for large text/non-text controls.

## Spacing and shape

| Token | Value | Usage |
|---|---:|---|
| `xs` | 4 | Tight internal grouping |
| `sm` | 8 | Icon-to-label and compact rows |
| `md` | 12 | Related controls |
| `lg` | 16 | Card padding and page gutters |
| `xl` | 20 | Section gaps |
| `xxl` | 24 | Major separation |

- Card radius: 18pt; compact controls: 12pt; pills: capsule.
- Minimum interactive target: 44×44pt with at least 8pt between adjacent targets.
- Use one card primitive: adaptive system surface, 0.5pt semantic border, subtle light-mode shadow, no glow.
- Grids are adaptive: one column for accessibility sizes/compact widths, two or more only when content remains readable.

## Navigation and hierarchy

- Five primary tabs maximum: Today, Habits, Money, Tasks, Progress.
- Insights is a secondary route from Progress.
- Settings uses one predictable toolbar pattern and every presented sheet has an explicit dismiss action.
- Screen titles, toolbar placement, empty states, and add actions remain consistent.

## Motion and feedback

- Motion communicates completion, level progression, or navigation; it is not ambient decoration.
- Typical state transition: 180–300ms. Spring motion is reserved for direct manipulation or success.
- Respect `accessibilityReduceMotion`; render final state immediately when enabled.
- Haptics only confirm meaningful actions (complete, redeem, save), not every press.
- Loading, success, warning, and failure states must have visible text feedback.

## Core component rules

### Progress / XP

- Show level name, XP within the current level, XP remaining, and an accurate 0…100% bar.
- Lifetime XP and spendable XP are distinct labels.
- Achievements show icon, title, requirement, progress, and locked/unlocked state.
- Reward redemption must be guarded in the domain layer and surface a clear error.

### Money and fun budget

- Income = success, expense = danger, net/neutral navigation = brand.
- The Fun Budget card always names its tracked category: Entertainment.
- Show spent, limit, remaining, percentage, days context, and text status.
- Notify once per month at the 80% threshold; never rely on color or notification alone—the in-app warning remains visible.

### Charts

- Provide accessible summary labels/values.
- Legends must map each series/category to its actual color.
- Do not use red/green alone to distinguish data; include labels or symbols.

## Pre-delivery checklist

- [ ] Five or fewer primary tabs
- [ ] Dynamic Type layouts do not clip at accessibility sizes
- [ ] All controls are at least 44×44pt and have accessible labels/values
- [ ] Light/dark semantic colors meet contrast expectations
- [ ] No raw color literals in feature views
- [ ] Reduced Motion renders stable final states
- [ ] Empty, validation, warning, success, and denied-permission states are visible
- [ ] Progress bars are accurate at 0%, boundaries, and completion
- [ ] Budget warning is deterministic, deduplicated, and tested across month boundaries
- [ ] iPhone and iPad layouts have no horizontal overflow
