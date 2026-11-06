# SERA ESSENTIALS

A lightweight, mobile-first storefront for SERA ESSENTIALS, an extension of Sera Beauty Essentials.

## Brand palette
- Deep berry pink: `#9D174D`
- Dark berry: `#701238`
- Soft blush: `#F8E8EF`
- Warm ivory: `#FFFDFB`
- Charcoal: `#292329`

## Files
- `index.html`: storefront and cart interface.
- `products.json`: editable product catalogue.

## Add a product
Edit `products.json` and add an object like:

```json
{
  "id": "sera-002",
  "name": "Product name",
  "category": "Home",
  "description": "Short product description.",
  "price": 12500,
  "image": "https://example.com/your-product-image.jpg",
  "active": true
}
```

Use a unique ID, a numeric price in naira, and an image URL you have permission to use. Set `active` to `false` to hide a product. Do not publish supplier cost or private sourcing links in this file.

## Publish with GitHub Pages
In the repository, open **Settings → Pages**. Under **Build and deployment**, choose **Deploy from a branch**, select **main** and **/(root)**, then save. GitHub Pages will publish the site at:

`https://zidepeoplenewaccount.github.io/sera-essentials/`

The first publication can take a few minutes.

## Important launch note
The current checkout is a visual starter only. It does not collect or store orders or process payments yet. Before accepting customer orders, connect a private order form/spreadsheet workflow and configure Sera's official WhatsApp contact. Never put payment secrets or private supplier credentials in this public repository.
