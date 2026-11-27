# TOMMY WEARS — Luxury fashion storefront

A responsive luxury-minimalist fashion storefront for men and women. Built with React, Vite and Framer Motion; Supabase handles the catalogue, admin authentication and product-image storage; Netlify hosts the site. Checkout opens WhatsApp with the customer's selected items and delivery details. There is no automated payment gateway.

## 1. Project configuration

The connected Supabase project is already configured with the TOMMY WEARS foundation:

- `public.products` — catalogue, pricing, sizes, colours, stock and visibility
- `public.store_admins` — allow-list of users permitted to manage the store
- `public.order_requests` — optional order inquiry table (the current checkout sends the cart to WhatsApp)
- `product-images` — public image delivery bucket; uploads and changes are restricted to store admins
- Row Level Security and least-privilege table grants

For a fresh Supabase project, run `supabase/schema.sql` in the SQL Editor. Do not re-run it against another store's database without reviewing it first.

## 2. Run locally

1. Install Node.js 20 or later.
2. Copy `.env.example` to `.env`.
3. The supplied `.env` is already configured with the connected Supabase project and your WhatsApp number. Keep it for local development; do not commit `.env` to a public repository.
4. Run `npm install` and `npm run dev`.

The connected project values are:

- Project URL: `https://yfcidxhmysnpaitcezcj.supabase.co`
- Publishable key: the project publishable key is already supplied in the local `.env` file. It is designed for browser use; never expose a Supabase secret key or `service_role` key.

A publishable key is designed for browser use. Never place a Supabase secret key or `service_role` key in frontend code or Netlify environment variables.

## 3. Store administrator already authorised

The administrator account `samy.highland@gmail.com` has already been added to `public.store_admins` in the connected Supabase project. Sign in at `/admin` using the password you created for that Supabase Auth account. Do not share your password or any secret API key. Only this allow-listed account can manage products and upload product images.

## 4. Deploy to Netlify

1. Push this project folder to a Git repository.
2. Import the repository in Netlify.
3. Build command: `npm run build`; publish directory: `dist`.
4. Add these environment variables in Netlify site settings:
   - `VITE_SUPABASE_URL=https://yfcidxhmysnpaitcezcj.supabase.co`
   - `VITE_SUPABASE_ANON_KEY=YOUR_SB_PUBLISHABLE_KEY`
   - `VITE_WHATSAPP_NUMBER=2348037991565`
5. Redeploy after saving the environment variables.

The included `netlify.toml` enables SPA routing so `/admin` loads correctly after refresh.

## 5. Store administration

Open `https://YOUR-NETLIFY-SITE.netlify.app/admin` and sign in with the administrator account. The control room supports adding, editing, hiding and deleting products, uploading images, setting prices, categories, gender, sizes, colours, stock, featured and new-arrival flags.

## 6. WhatsApp checkout

Customers add items to their bag, enter their name, phone number and delivery address, then send the order summary to the store's WhatsApp number. Confirm availability, delivery fee and payment in chat. The app does not mark an order as paid or confirmed automatically.

## 7. Before launch

- Replace the editorial campaign photography and sample product photography with TOMMY WEARS-owned or properly licensed images.
- Confirm the WhatsApp checkout opens the correct business chat.
- Sign in to `/admin` with the already-authorised administrator account.
- Test a product upload, product edit, hidden listing, mobile layout and WhatsApp checkout before announcing the store.

### Netlify build dependency compatibility

This project pins `motion-dom` and `motion-utils` to the versions compatible with `framer-motion@12.4.7` using npm `overrides`. If Netlify has cached an older dependency tree, use **Deploys → Trigger deploy → Clear cache and deploy site** after pushing the updated `package.json`.
