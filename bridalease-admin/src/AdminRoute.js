import { Navigate } from "react-router-dom";
import { supabase } from "./supabaseClient";

export default function AdminRoute({ children }) {
  const user = supabase.auth.getUser();

  if (!user) return <Navigate to="/" />;

  return children;
}

