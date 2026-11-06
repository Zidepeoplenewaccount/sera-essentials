// Public Supabase project settings. The anon/publishable key is designed for browser use.
// Security comes from the Row Level Security policies in supabase-setup.sql.
// Replace these two values after creating your free Supabase project.
export const SUPABASE_URL = "https://gfxgdcmvzrmynfzmkoyl.supabase.co";
export const SUPABASE_ANON_KEY = "sb_publishable_bGMwzaZr7LRHErpGLGwxqg_d6oP4KwU";

// Add SERA's verified bank transfer details before accepting orders.
// Never put passwords, service-role keys or secret API keys in this file.
export const PAYMENT_DETAILS = {
  bankName: "Moniepoint MFB",
  accountName: "SERA ESSENTIALS",
  accountNumber: "6500896540"
};
