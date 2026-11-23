# FlexiStock POS

A configurable point-of-sale and inventory app for small stores. Owners can rename the system, turn features on or off (expiry tracking, credit, returns, tax, multiple units), and give each staff role only the permissions it needs.

**Members:** [Member name 1], [Member name 2]

## Project structure
```
flexistock-pos/
├── README.md
├── database/
│   ├── schema.sql        CREATE TABLE statements, triggers, procedures, views (28 tables)
│   └── seed.sql          INSERT sample data
├── docs/
│   ├── 01-brief.md
│   ├── 02-crud-map.md
│   ├── 03-sitemap.png
│   ├── 03-user-flow.png
│   ├── 04-wireframes/    one image per screen
│   ├── 05-style-guide.md
│   └── 05-style-guide.png
└── prototype/
    ├── css/style.css     shared stylesheet (style-guide variables at the top)
    ├── index.html        landing page (extra, placeholders for download and Google sign-in)
    ├── list.html         Products list
    └── form.html         Add product form
```

## Database setup
1. Start MySQL 8.0.16 or later (for example through XAMPP).
2. Import `database/schema.sql` in phpMyAdmin. It drops and recreates the database `flexistock_pos`.
3. Import `database/seed.sql`.

## View the prototype
Open the `prototype/` folder in VS Code and start Live Server on `index.html`, `list.html`, or `form.html`. No PHP or database connection yet (Week 14 is design only).

## Notes
- Stock on hand is not a column. In `list.html` the Stock values are typed in by hand, worked out from `seed.sql`. In Week 15 they will come from a query over `stock_movement`.
- Sign in with Google and the download button are placeholders with no function yet.
