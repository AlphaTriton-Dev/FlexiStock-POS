# Project Brief: FlexiStock POS

## 1. The problem
Small store owners (grocery, hardware, pharmacy) still write receipts by hand and record stock in and out on paper. This wastes time, causes counting mistakes, and makes it hard to know the day's sales, profit, and what is running low. Existing POS apps are fixed: owners cannot turn off features they do not need, such as expiry tracking for a hardware store.

## 2. Users and what they need to do
| User role           | What they need to do in the app                                                                               |
|---------------------|---------------------------------------------------------------------------------------------------------------|
| Visitor (guest)     | Read about FlexiStock on the landing page, download the app, sign in                                          |
| Owner               | Manage products, suppliers, and customers. Turn modules on or off. Create roles and staff accounts.           | 
|                     | View sales, profit, and stock reports                                                                         |
| Staff (custom role) | Do only what the owner's permissions allow, e.g. process sales, receive stock, or record returns              |

## 3. The database behind it
Database: `flexistock_pos`, 28 tables (MySQL).

| Group | Table | What it stores |
|-------|-------|----------------|
| Store setup | store_profile | The one store's name, address, currency, and receipt footer |
| | module | Optional features (credit, returns, tax, expiry...) the owner can turn on or off |
| Access | permission | Each action a user may be allowed to do, linked to a module |
| | role | A custom role created by the owner |
| | role_permission | Which permissions each role has |
| | staff | Login accounts for the owner's staff, each with one role |
| Catalog | category | Product groups such as Groceries or Hardware |
| | unit | Units of measure (piece, box, pack, kg) |
| | tax_rate | Tax rates such as VAT 12% |
| | product | Items for sale: SKU, barcode, name, price, reorder level |
| | product_unit | Other ways a product is sold (box of 24) with a conversion and price |
| | custom_field | Extra fields the owner defines for products |
| | product_custom_value | The value of each custom field for each product |
| People | supplier | Companies the store buys from |
| | supplier_contact | Phone, mobile, or email of a supplier |
| | customer | Customers, including their credit limit |
| | customer_contact | Phone, mobile, or email of a customer |
| Buying and stock | purchase_order | An order placed with a supplier |
| | purchase_order_item | Products and quantities on an order |
| | stock_batch | Stock received, with batch number and expiry date |
| | stock_movement | Every stock in or out (receive, sale, void, return, damage) |
| Selling | discount | Percent or fixed discounts |
| | payment_method | Cash, e-wallet, etc. |
| | sale | One transaction with a receipt number |
| | sale_item | Products and quantities on a sale |
| | payment | Payments made on a sale (also used for credit/utang) |
| | sale_return | A return of a past sale |
| | sale_return_item | Items returned and whether they go back to stock |

## 4. Must-have features (for the final project)
- Add, edit, search, and deactivate products
- Record stock received from suppliers
- Process a sale and print a receipt
- Record payments, including credit (utang) payments
- Manage suppliers and customers with their contacts
- Create roles and staff accounts with permissions

## 5. Nice-to-have features (only if there's time)
- Process returns and refunds
- Dashboard with today's sales, profit, and low-stock items
- Sign in with Google on the website, with sales data shown online (placeholder this week)
- An AI assistant to help the user to whatever they need within the system

## 6. Similar apps I looked at
- Loyverse POS: idea to borrow: the one idea i borrowed was their functions that was in their POS for example was the connect to a reciept printer
- Square POS: idea to borrow: the idea i plan to borrow on the next update is an AI assistant
