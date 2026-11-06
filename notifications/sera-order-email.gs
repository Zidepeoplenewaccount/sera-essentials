/**
 * SERA ESSENTIALS — new order email notifications
 *
 * Deploy as a Google Apps Script web app, execute as the script owner,
 * and set the script property:
 *   SERA_WEBHOOK_SECRET = a long random secret
 *
 * Configure a Supabase Database Webhook for INSERT on public.orders:
 *   POST https://script.google.com/macros/s/YOUR_DEPLOYMENT_ID/exec?key=YOUR_SECRET
 *
 * Keep the secret out of this file, GitHub, and the storefront.
 */

const SERA_NOTIFICATION_EMAIL = 'enibeedboss@gmail.com';

function doPost(e) {
  try {
    const expectedSecret = PropertiesService.getScriptProperties()
      .getProperty('SERA_WEBHOOK_SECRET');
    const suppliedSecret = e && e.parameter ? e.parameter.key : '';

    if (!expectedSecret || !suppliedSecret || suppliedSecret !== expectedSecret) {
      return jsonResponse({ ok: false, error: 'Unauthorized' });
    }

    const payload = JSON.parse(e.postData.contents || '{}');
    if (payload.type !== 'INSERT' || payload.table !== 'orders' || payload.schema !== 'public') {
      return jsonResponse({ ok: true, ignored: true });
    }

    const order = payload.record || {};
    if (!order.order_number || !order.id) {
      throw new Error('Webhook payload is missing the order reference.');
    }

    const items = Array.isArray(order.items) ? order.items : [];
    const itemLines = items.map(function(item) {
      const quantity = Number(item.quantity || 0);
      const unitPrice = Number(item.unit_price || 0);
      const originalPrice = Number(item.original_unit_price || unitPrice);
      const discount = Math.max(0, originalPrice - unitPrice);
      const variants = [item.colour, item.size].filter(Boolean).join(' / ');
      return {
        text: quantity + ' × ' + (item.name || 'Product') +
          (variants ? ' (' + variants + ')' : '') +
          ' — ' + naira(unitPrice) + ' each' +
          (discount > 0 ? ' [discount: ' + naira(discount) + ' per item]' : ''),
        html: '<li><strong>' + escapeHtml(quantity + ' × ' + (item.name || 'Product')) +
          '</strong>' + (variants ? ' (' + escapeHtml(variants) + ')' : '') +
          ' — ' + naira(unitPrice) + ' each' +
          (discount > 0 ? '<br><span style="color:#16803c">Discount: ' + naira(discount) + ' per item</span>' : '') +
          '</li>'
      };
    });

    const customer = order.customer_name || 'Not provided';
    const phone = order.phone || 'Not provided';
    const email = order.email || 'Not provided';
    const address = order.delivery_address || 'Not provided';
    const subtotal = Number(order.subtotal || 0);
    const delivery = Number(order.delivery_fee || 0);
    const total = Number(order.total || 0);
    const subject = 'New SERA order: ' + order.order_number;

    const plainBody = [
      'A new order has been placed on SERA ESSENTIALS.',
      '',
      'Order: ' + order.order_number,
      'Payment status: ' + (order.status || 'pending_verification'),
      'Customer: ' + customer,
      'Phone: ' + phone,
      'Email: ' + email,
      'Delivery address: ' + address,
      '',
      'ITEMS',
      itemLines.map(function(line) { return line.text; }).join('\n') || 'No item details received',
      '',
      'Subtotal: ' + naira(subtotal),
      'Delivery: ' + naira(delivery),
      'Total: ' + naira(total),
      '',
      'Payment is not verified automatically. Check the SERA admin dashboard and confirm the funds in the bank account before updating the order.'
    ].join('\n');

    const htmlBody =
      '<div style="font-family:Arial,sans-serif;color:#241b2b;line-height:1.6;max-width:620px">' +
      '<h2 style="color:#6d28d9">New SERA order received</h2>' +
      '<p>A customer has submitted an order on SERA ESSENTIALS.</p>' +
      '<p><strong>Order:</strong> ' + escapeHtml(order.order_number) + '<br>' +
      '<strong>Payment status:</strong> ' + escapeHtml(order.status || 'pending_verification') + '</p>' +
      '<h3>Customer details</h3><p><strong>Name:</strong> ' + escapeHtml(customer) +
      '<br><strong>WhatsApp:</strong> ' + escapeHtml(phone) +
      '<br><strong>Email:</strong> ' + escapeHtml(email) +
      '<br><strong>Delivery address:</strong> ' + escapeHtml(address) + '</p>' +
      '<h3>Order items</h3><ul>' + itemLines.map(function(line) { return line.html; }).join('') + '</ul>' +
      '<p><strong>Subtotal:</strong> ' + naira(subtotal) +
      '<br><strong>Delivery:</strong> ' + naira(delivery) +
      '<br><strong>Total:</strong> <span style="font-size:18px;color:#6d28d9;font-weight:bold">' + naira(total) + '</span></p>' +
      '<p style="background:#fff4e5;padding:12px;border-radius:8px"><strong>Important:</strong> This order is awaiting payment verification. Check the bank account and receipt in the SERA admin dashboard before confirming payment.</p>' +
      '</div>';

    GmailApp.sendEmail(SERA_NOTIFICATION_EMAIL, subject, plainBody, {
      htmlBody: htmlBody,
      name: 'SERA ESSENTIALS Orders'
    });

    return jsonResponse({ ok: true, order_number: order.order_number });
  } catch (error) {
    console.error(error);
    return jsonResponse({ ok: false, error: String(error.message || error) });
  }
}

function naira(amount) {
  return '₦' + Number(amount || 0).toLocaleString('en-NG', { maximumFractionDigits: 2 });
}

function escapeHtml(value) {
  return String(value == null ? '' : value).replace(/[&<>"']/g, function(character) {
    return ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[character];
  });
}

function jsonResponse(value) {
  return ContentService.createTextOutput(JSON.stringify(value))
    .setMimeType(ContentService.MimeType.JSON);
}
