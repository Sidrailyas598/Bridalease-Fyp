import { createClient } from "@supabase/supabase-js";

export const supabase = createClient(
  "https://booeleldfprujllrxoik.supabase.co",
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJvb2VsZWxkZnBydWpsbHJ4b2lrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzOTY1NTcsImV4cCI6MjA3OTk3MjU1N30.E4RQ9GZaqJs7pE5VxkgfUkIC_F3xREKzJ2k96a_3e0U"
);