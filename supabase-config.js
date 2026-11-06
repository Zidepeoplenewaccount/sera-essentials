// Public Supabase project settings. The anon/publishable key is designed for browser use.
// Security comes from the Row Level Security policies in supabase-setup.sql.
// Replace these two values after creating your free Supabase project.
export const SUPABASE_URL = "YOUR_SUPABASE_PROJECT_URL";
export const SUPABASE_ANON_KEY = "YOUR_SUPABASE_ANON_OR_PUBLISHABLE_KEY";

// Add SERA's verified bank transfer details before accepting orders.
// Never put passwords, service-role keys or secret API keys in this file.
export const PAYMENT_DETAILS = {
  bankName: "ADD BANK NAME",
  accountName: "ADD ACCOUNT NAME",
  accountNumber: "ADD ACCOUNT NUMBER"
};
