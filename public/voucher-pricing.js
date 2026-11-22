(function (root) {
  function available(voucher) {
    return Boolean(voucher && !voucher.used_at);
  }

  function quote(subtotal, eligible) {
    const amount = Number(subtotal);
    const safeSubtotal = Number.isFinite(amount) ? Math.max(0, amount) : 0;
    const discount = eligible ? Math.round(safeSubtotal * 0.05) : 0;
    return {
      subtotal: safeSubtotal,
      discount,
      total: safeSubtotal - discount,
    };
  }

  root.CQVoucherPricing = Object.freeze({ available, quote });
})(globalThis);