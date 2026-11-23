# Style Guide: FlexiStock POS

## Colors
| Role | Hex | Used for |
|------|-----|----------|
| Primary | `#185fa5` | Primary buttons, links, headings, active menu item |
| Background | `#f5f7fa` | Page background |
| Text | `#1b2733` | Body text |
| Success | `#2f6f3e` | "Saved" messages, in-stock labels |
| Error | `#a8352a` | Error messages, required-field problems, low-stock warnings |

Helper neutrals: surface `#ffffff` (cards, inputs), border `#c9d1db`, muted text `#5b6776`, primary hover `#0f4577`.

## Contrast check (WCAG AA needs 4.5:1 or higher)
| Combination | Ratio | Result |
|-------------|-------|--------|
| Text `#1b2733` on background `#f5f7fa` | 14.1:1 | Pass |
| Text on white `#ffffff` | 15.2:1 | Pass |
| White text on primary `#185fa5` (buttons) | 6.5:1 | Pass |
| Primary `#185fa5` on background (links) | 6.1:1 | Pass |
| Error `#a8352a` on background | 6.1:1 | Pass |
| Success `#2f6f3e` on background | 5.6:1 | Pass |
| Muted `#5b6776` on background | 5.4:1 | Pass |

## Fonts
- Headings: **Poppins** (600 weight)
- Body: **Inter** (400 and 600 weights)
- Base font size: **16px**, line height 1.5. Headings: h1 28px, h2 22px, h3 18px.
- Fallback: Arial, sans-serif

## Components
- **Primary button:** primary background, white text, 8px radius, 10px 20px padding, bold. Hover: darker blue `#0f4577`.
- **Secondary button:** white background, primary-colored text and 2px primary border, same size and radius. Used for Cancel, View, and Edit.
- **Text input:** white background, 1.5px border `#c9d1db`, 8px radius, 10px 12px padding, 16px text. Focus: 2px primary outline.
- **Error message:** error-colored text, 14px, bold, placed directly under the field with a warning icon. The field's border turns error red.

## CSS variables
```css
:root {
  --color-primary: #185fa5;      /* buttons, links, headings */
  --color-primary-dark: #0f4577; /* button hover */
  --color-bg: #f5f7fa;           /* page background. Text on it: 14.1:1 */
  --color-surface: #ffffff;      /* cards, inputs */
  --color-text: #1b2733;         /* body text */
  --color-muted: #5b6776;        /* secondary text */
  --color-border: #c9d1db;
  --color-success: #2f6f3e;
  --color-error: #a8352a;
  --font-heading: "Poppins", Arial, sans-serif;
  --font-body: "Inter", Arial, sans-serif;
  --font-size-base: 16px;
  --radius: 8px;
}
```

Google Fonts link for the `<head>` of every page:
```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600&family=Poppins:wght@600&display=swap" rel="stylesheet">
```
