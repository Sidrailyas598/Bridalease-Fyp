// src/components/AdminLogin.jsx
import React, { useState } from "react";
import { supabase } from "../supabaseClient";
import { useNavigate } from "react-router-dom";
import { Shield, Lock, Mail, AlertCircle, Eye, EyeOff, Crown } from "lucide-react";

export default function AdminLogin() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const navigate = useNavigate();

  const loginAdmin = async (e) => {
    e.preventDefault();
    setError("");
    setLoading(true);

    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password
    });

    if (error) {
      setError(error.message);
      setLoading(false);
      return;
    }

    if (data.user.email !== "admin@bridalease.com") {
      setError("Access denied! You are not an administrator.");
      await supabase.auth.signOut();
      setLoading(false);
      return;
    }

    navigate("/dashboard");
  };

  return (
    <div className="min-h-screen flex items-center justify-center p-4 relative overflow-hidden bg-gradient-to-br from-purple-900 via-purple-800 to-purple-900">
      
      {/* Abstract Background Pattern - Dark Purple Theme */}
      <div className="absolute inset-0 opacity-20">
        <div className="absolute top-0 left-0 w-96 h-96 bg-yellow-500 rounded-full mix-blend-multiply filter blur-3xl animate-pulse"></div>
        <div className="absolute bottom-0 right-0 w-96 h-96 bg-purple-600 rounded-full mix-blend-multiply filter blur-3xl animate-pulse animation-delay-2000"></div>
        <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-96 h-96 bg-yellow-600 rounded-full mix-blend-multiply filter blur-3xl animate-pulse animation-delay-4000"></div>
      </div>
      
      {/* Login Card */}
      <div className="relative z-10 w-full max-w-md">
        <div className="bg-gray-900/95 backdrop-blur-sm rounded-2xl shadow-2xl border border-purple-700 overflow-hidden">
          {/* Header with Gradient - Dark Purple to Gold */}
          <div className="bg-gradient-to-r from-purple-900 to-purple-800 p-8 text-center relative overflow-hidden border-b border-yellow-500/30">
            {/* Decorative elements */}
            <div className="absolute top-0 left-0 w-24 h-24 bg-yellow-500/10 rounded-full -translate-x-1/2 -translate-y-1/2"></div>
            <div className="absolute bottom-0 right-0 w-32 h-32 bg-yellow-500/10 rounded-full translate-x-1/3 translate-y-1/3"></div>
            
            <div className="relative z-10">
              <div className="flex items-center justify-center mb-6">
                <div className="bg-gradient-to-br from-yellow-400 to-yellow-500 p-4 rounded-2xl shadow-lg mr-4">
                  <Shield className="w-10 h-10 text-purple-900" />
                </div>
                <div className="text-left">
                  <h1 className="text-3xl font-bold text-white tracking-tight">BridalEase</h1>
                  <p className="text-yellow-400 text-sm mt-1">Wedding Solutions Platform</p>
                </div>
              </div>
              <div className="inline-block bg-yellow-500/20 backdrop-blur-sm px-4 py-2 rounded-full border border-yellow-500/30">
                <h2 className="text-lg font-semibold text-yellow-400 flex items-center">
                  <Crown className="w-5 h-5 mr-2" />
                  Admin Portal
                </h2>
              </div>
            </div>
          </div>

          {/* Login Form */}
          <div className="p-8">
            <form onSubmit={loginAdmin} className="space-y-6">
              {/* Email Input */}
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">
                  Administrator Email
                </label>
                <div className="relative">
                  <div className="absolute left-4 top-1/2 transform -translate-y-1/2 text-yellow-500">
                    <Mail className="w-5 h-5" />
                  </div>
                  <input 
                    type="email" 
                    placeholder="admin@bridalease.com"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required 
                    className="w-full pl-12 pr-4 py-3.5 bg-gray-800 border border-purple-700 text-white placeholder-gray-500 rounded-xl focus:ring-2 focus:ring-yellow-500 focus:border-transparent transition-all duration-200"
                    disabled={loading}
                  />
                </div>
              </div>
              
              {/* Password Input */}
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">
                  Password
                </label>
                <div className="relative">
                  <div className="absolute left-4 top-1/2 transform -translate-y-1/2 text-yellow-500">
                    <Lock className="w-5 h-5" />
                  </div>
                  <input 
                    type={showPassword ? "text" : "password"}
                    placeholder="Enter your password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required 
                    className="w-full pl-12 pr-12 py-3.5 bg-gray-800 border border-purple-700 text-white placeholder-gray-500 rounded-xl focus:ring-2 focus:ring-yellow-500 focus:border-transparent transition-all duration-200"
                    disabled={loading}
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-4 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-yellow-500 transition-colors"
                  >
                    {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                  </button>
                </div>
              </div>

              {/* Error Message */}
              {error && (
                <div className="animate-fadeIn">
                  <div className="bg-red-900/50 border border-red-800 rounded-xl p-4">
                    <div className="flex items-start">
                      <AlertCircle className="w-5 h-5 text-red-400 mt-0.5 mr-3 flex-shrink-0" />
                      <div>
                        <p className="text-sm font-semibold text-red-300">Authentication Error</p>
                        <p className="text-sm text-red-400 mt-1">{error}</p>
                      </div>
                    </div>
                  </div>
                </div>
              )}

              {/* Submit Button - Gold Theme */}
              <button 
                type="submit" 
                disabled={loading}
                className="w-full py-4 px-4 bg-gradient-to-r from-yellow-500 to-yellow-600 text-purple-900 font-semibold rounded-xl hover:from-yellow-600 hover:to-yellow-700 transition-all duration-300 transform hover:-translate-y-1 hover:shadow-xl active:translate-y-0 disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none group"
              >
                {loading ? (
                  <div className="flex items-center justify-center">
                    <div className="w-6 h-6 border-3 border-purple-900 border-t-transparent rounded-full animate-spin mr-3"></div>
                    <span className="text-purple-900">Verifying Credentials...</span>
                  </div>
                ) : (
                  <div className="flex items-center justify-center">
                    <span className="text-purple-900 font-bold">Sign In to Dashboard</span>
                    <svg className="w-5 h-5 ml-2 transform group-hover:translate-x-1 transition-transform text-purple-900" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7l5 5m0 0l-5 5m5-5H6" />
                    </svg>
                  </div>
                )}
              </button>
            </form>

            {/* Security Note */}
            <div className="mt-8 pt-6 border-t border-purple-800">
              <div className="flex items-center justify-center space-x-3">
                <div className="flex items-center">
                  <div className="w-2 h-2 bg-yellow-500 rounded-full mr-2 animate-pulse"></div>
                  <span className="text-xs text-gray-400 font-medium">SSL Secured</span>
                </div>
                <div className="h-4 w-px bg-purple-700"></div>
                <div className="flex items-center">
                  <Shield className="w-4 h-4 text-yellow-500 mr-2" />
                  <span className="text-xs text-gray-400 font-medium">Admin Access Only</span>
                </div>
              </div>
            </div>
          </div>

          {/* Footer */}
          <div className="bg-gray-900/80 px-8 py-4 border-t border-purple-800">
            <div className="flex items-center justify-between">
              <div className="text-left">
                <p className="text-xs text-gray-400 font-medium">System Status</p>
                <div className="flex items-center mt-1">
                  <div className="w-2 h-2 bg-yellow-500 rounded-full mr-2"></div>
                  <span className="text-xs text-yellow-500">All Systems Operational</span>
                </div>
              </div>
              <div className="text-right">
                <p className="text-xs text-gray-500">v2.1.0</p>
                <p className="text-xs text-gray-600 mt-1">BridalEase © 2024</p>
              </div>
            </div>
          </div>
        </div>

        {/* Additional Security Info */}
        <div className="mt-6 bg-gray-900/90 rounded-xl p-5 border border-purple-800 shadow-lg">
          <div className="flex items-start">
            <div className="bg-gradient-to-br from-yellow-500 to-yellow-600 p-3 rounded-xl mr-4">
              <Shield className="w-6 h-6 text-purple-900" />
            </div>
            <div>
              <h3 className="text-sm font-semibold text-yellow-400">Enhanced Security Protocol</h3>
              <p className="text-xs text-gray-400 mt-2">
                This portal is protected with end-to-end encryption. Only authorized administrators with proper credentials can access the dashboard.
              </p>
              <div className="flex items-center mt-3 space-x-4">
                <span className="text-xs px-3 py-1 bg-yellow-500/20 text-yellow-400 rounded-full font-medium border border-yellow-500/30">256-bit SSL</span>
                <span className="text-xs px-3 py-1 bg-purple-800 text-purple-300 rounded-full font-medium border border-purple-700">2FA Ready</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}