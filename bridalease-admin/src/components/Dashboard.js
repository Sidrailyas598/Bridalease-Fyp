// src/pages/AdminDashboard.jsx
import React, { useState, useEffect } from "react";
import { supabase } from "../supabaseClient";
import { useNavigate } from "react-router-dom";
import { 
  Users, 
  Shirt,
  BarChart3, 
  LogOut, 
  Home,
  Search,
  Eye,
  Edit,
  Trash2,
  CheckCircle,
  XCircle,
  MoreVertical,
  TrendingUp,
  TrendingDown,
  UserCheck,
  UserX,
  Package,
  DollarSign,
  Clock,
  Shield,
  Bell,
  Settings,
  ChevronDown,
  ChevronRight,
  Image as ImageIcon,
  ChevronLeft,
  CreditCard,
  AlertCircle,
  RefreshCw,
  Download,
  Calendar,
  Phone,
  Mail,
  MapPin,
  Truck,
  CheckSquare,
  XSquare,
  Info,
  Store,
  Bike,
  UserPlus,
  UserMinus,
  Map,
  ShoppingBag,
  Tag,
  Grid,
  List,
  Filter,
  EyeOff,
  Check,
  X,
  AlertTriangle,
  CalendarDays,
  RotateCcw,
  Copy,
  Mail as MailIcon,
  MessageCircle,
  DollarSign as DollarIcon,
  TrendingUp as TrendingIcon,
  BarChart,
  PieChart,
  Activity,
  Award,
  Star,
  MessageSquare,
  ThumbsUp,
  ThumbsDown,
  Crown,
  Save,
  RotateCw,
  Camera,
  Upload,
  X as CloseIcon,
  Check as CheckIcon,
  AlertCircle as AlertIcon,
  FileImage,
  ZoomIn,
  ZoomOut
} from "lucide-react";

export default function AdminDashboard() {
  const [user, setUser] = useState(null);
  const [activeTab, setActiveTab] = useState("overview");
  const [loading, setLoading] = useState(true);
  const [users, setUsers] = useState([]);
  const [dresses, setDresses] = useState([]);
  const [orders, setOrders] = useState([]);
  const [riders, setRiders] = useState([]);
  const [deliveries, setDeliveries] = useState([]);
  const [vendors, setVendors] = useState([]);
  const [vendorEarnings, setVendorEarnings] = useState([]);
  const [reviews, setReviews] = useState([]);
  const [notifications, setNotifications] = useState([]);
  const [returnRequests, setReturnRequests] = useState([]);
  const [loadingData, setLoadingData] = useState(false);
  const [searchTerm, setSearchTerm] = useState("");
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);
  const [imageIndices, setImageIndices] = useState({});
  
  // Debug States
  const [debugInfo, setDebugInfo] = useState({
    ordersCount: 0,
    lastFetch: null,
    error: null
  });
  
  // Modal States
  const [showPaymentModal, setShowPaymentModal] = useState(false);
  const [showOrderModal, setShowOrderModal] = useState(false);
  const [showUserModal, setShowUserModal] = useState(false);
  const [showRiderModal, setShowRiderModal] = useState(false);
  const [showDressEditModal, setShowDressEditModal] = useState(false);
  const [showAddRiderModal, setShowAddRiderModal] = useState(false);
  const [showRiderCredentialsModal, setShowRiderCredentialsModal] = useState(false);
  const [showVendorEarningsModal, setShowVendorEarningsModal] = useState(false);
  const [showReviewsModal, setShowReviewsModal] = useState(false);
  const [showAddDressModal, setShowAddDressModal] = useState(false);
  const [showReturnDeliveryModal, setShowReturnDeliveryModal] = useState(false);
  const [showInspectionModal, setShowInspectionModal] = useState(false);
  const [showInspectionDetailsModal, setShowInspectionDetailsModal] = useState(false);
  
  // Selected Items
  const [selectedOrder, setSelectedOrder] = useState(null);
  const [selectedUser, setSelectedUser] = useState(null);
  const [selectedRider, setSelectedRider] = useState(null);
  const [selectedDress, setSelectedDress] = useState(null);
  const [selectedVendor, setSelectedVendor] = useState(null);
  const [selectedReturnDelivery, setSelectedReturnDelivery] = useState(null);
  const [selectedReturnRequest, setSelectedReturnRequest] = useState(null);
  const [newRiderCredentials, setNewRiderCredentials] = useState(null);
  const [inspectionPhotos, setInspectionPhotos] = useState([]);
  const [currentPhotoIndex, setCurrentPhotoIndex] = useState(0);
  
  // New Rider Form State
  const [newRider, setNewRider] = useState({
    name: '',
    email: '',
    phone: '',
    vehicleType: 'Motorcycle',
    vehicleNumber: '',
    serviceArea: '',
    city: '',
    password: '',
    confirmPassword: ''
  });

  // Dress Edit Form State
  const [dressEditForm, setDressEditForm] = useState({
    name: '',
    description: '',
    price: '',
    rental_price: '',
    status: 'available',
    is_approved: false,
    available_after: ''
  });

  // Processing States
  const [processingPayment, setProcessingPayment] = useState(false);
  const [updatingDress, setUpdatingDress] = useState(false);
  const [creatingRider, setCreatingRider] = useState(false);
  const [updatingDeliveryStatus, setUpdatingDeliveryStatus] = useState(false);
  
  const [dateRange, setDateRange] = useState("week");
  const [stats, setStats] = useState({
    totalUsers: 0,
    totalBrides: 0,
    totalVendors: 0,
    totalRiders: 0,
    totalDresses: 0,
    approvedDresses: 0,
    pendingDresses: 0,
    availableDresses: 0,
    rentedDresses: 0,
    soldDresses: 0,
    activeUsers: 0,
    blockedUsers: 0,
    totalOrders: 0,
    pendingOrders: 0,
    completedOrders: 0,
    purchaseOrders: 0,
    rentalOrders: 0,
    pendingPayments: 0,
    totalRevenue: 0,
    adminCommission: 0,
    vendorPayouts: 0,
    riderEarnings: 0,
    revenueGrowth: 0,
    userGrowth: 0,
    orderGrowth: 0,
    activeDeliveries: 0,
    completedDeliveries: 0,
    returnDeliveries: 0,
    activeRiders: 0,
    inactiveRiders: 0,
    totalReviews: 0,
    averageRating: 0,
    pendingInspections: 0,
    completedInspections: 0,
    rejectedInspections: 0
  });
  
  const navigate = useNavigate();

  // ==================== HELPER FUNCTIONS ====================
  const formatDate = (dateString) => {
    if (!dateString) return 'N/A';
    try {
      return new Date(dateString).toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      });
    } catch (e) {
      return 'Invalid date';
    }
  };

  const formatCurrency = (amount) => {
    if (amount === null || amount === undefined) return 'Rs 0';
    return `Rs ${Number(amount).toLocaleString()}`;
  };

  const getStatusColor = (status) => {
    const colors = {
      'pending': 'bg-yellow-100 text-yellow-800 border border-yellow-200',
      'awaiting_verification': 'bg-orange-100 text-orange-800 border border-orange-200 animate-pulse',
      'approved': 'bg-green-100 text-green-800 border border-green-200',
      'completed': 'bg-green-100 text-green-800 border border-green-200',
      'rejected': 'bg-red-100 text-red-800 border border-red-200',
      'confirmed': 'bg-blue-100 text-blue-800 border border-blue-200',
      'assigned': 'bg-purple-100 text-purple-800 border border-purple-200',
      'picked': 'bg-indigo-100 text-indigo-800 border border-indigo-200',
      'delivered': 'bg-green-100 text-green-800 border border-green-200',
      'return_assigned': 'bg-orange-100 text-orange-800 border border-orange-200',
      'return_picked': 'bg-amber-100 text-amber-800 border border-amber-200',
      'return_delivered': 'bg-green-100 text-green-800 border border-green-200',
      'cancelled': 'bg-gray-100 text-gray-800 border border-gray-200',
      'available': 'bg-green-100 text-green-800 border border-green-200',
      'rented': 'bg-orange-100 text-orange-800 border border-orange-200',
      'sold': 'bg-red-100 text-red-800 border border-red-200',
      'paid': 'bg-green-100 text-green-800 border border-green-200',
      'pending_inspection': 'bg-purple-100 text-purple-800 border border-purple-200',
      'inspection_completed': 'bg-green-100 text-green-800 border border-green-200'
    };
    return colors[status] || 'bg-gray-100 text-gray-800 border border-gray-200';
  };

  const getDressStatusBadge = (dress) => {
    if (dress.status === 'sold') {
      return { text: 'SOLD OUT', color: 'bg-red-100 text-red-800' };
    }
    if (dress.status === 'booked') {
      return { text: 'BOOKED', color: 'bg-orange-100 text-orange-800' };
    }
    if (dress.status === 'pending') {
      return { text: 'PENDING', color: 'bg-yellow-100 text-yellow-800' };
    }
    if (dress.status === 'rejected') {
      return { text: 'REJECTED', color: 'bg-red-100 text-red-800' };
    }
    if (dress.status === 'archived') {
      return { text: 'ARCHIVED', color: 'bg-gray-100 text-gray-800' };
    }
    if (dress.status === 'draft') {
      return { text: 'DRAFT', color: 'bg-gray-100 text-gray-800' };
    }
    return { text: 'AVAILABLE', color: 'bg-green-100 text-green-800' };
  };

  const getDressImages = (dress) => {
    if (dress?.images && Array.isArray(dress.images)) {
      return dress.images;
    }
    return [];
  };

  const navigateImage = (dressId, direction) => {
    const dress = dresses.find(d => d.id === dressId);
    const images = getDressImages(dress);
    if (images.length <= 1) return;
    
    setImageIndices(prev => {
      const currentIndex = prev[dressId] || 0;
      let newIndex;
      
      if (direction === 'next') {
        newIndex = (currentIndex + 1) % images.length;
      } else {
        newIndex = (currentIndex - 1 + images.length) % images.length;
      }
      
      return { ...prev, [dressId]: newIndex };
    });
  };

  const handleDressEditChange = (e) => {
    const { name, value, type, checked } = e.target;
    setDressEditForm(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value
    }));
  };

  useEffect(() => {
    checkUser();
  }, []);

  useEffect(() => {
    if (user) {
      fetchAllData();
    }
  }, [user]);

  useEffect(() => {
    calculateStats();
  }, [users, dresses, orders, riders, deliveries, vendorEarnings, reviews, returnRequests]);

  const checkUser = async () => {
    try {
      const { data: { user }, error } = await supabase.auth.getUser();
      
      if (error || !user || user.email !== "admin@bridalease.com") {
        navigate("/admin");
        return;
      }
      
      setUser(user);
      setLoading(false);
    } catch (error) {
      console.error("Check user error:", error);
      setLoading(false);
    }
  };

  const fetchAllData = async () => {
    setLoadingData(true);
    setDebugInfo(prev => ({ ...prev, error: null }));
    
    try {
      console.log('Fetching all data...');
      
      await fetchUsers();
      await fetchDresses();
      await fetchOrders();
      await fetchRiders();
      await fetchDeliveries();
      await fetchVendors();
      await fetchVendorEarnings();
      await fetchReviews();
      await fetchNotifications();
      await fetchReturnRequests();
      
      console.log('All data fetched successfully');
    } catch (error) {
      console.error("Error fetching data:", error);
      setDebugInfo(prev => ({ ...prev, error: error.message }));
    }
    setLoadingData(false);
  };

  const fetchUsers = async () => {
    try {
      const { data, error } = await supabase
        .from('users')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      setUsers(data || []);
    } catch (error) {
      console.error('Error fetching users:', error);
    }
  };

  const fetchDresses = async () => {
    try {
      const { data, error } = await supabase
        .from('dresses')
        .select(`
          *,
          vendor:vendor_id (
            id,
            email,
            full_name,
            business_name,
            phone,
            business_address
          )
        `)
        .order('created_at', { ascending: false });

      if (error) throw error;
      
      const initialIndices = {};
      data?.forEach((dress) => {
        initialIndices[dress.id] = 0;
      });
      
      setImageIndices(initialIndices);
      setDresses(data || []);
    } catch (error) {
      console.error('Error fetching dresses:', error);
    }
  };

  const fetchOrders = async () => {
    try {
      console.log('Fetching orders...');
      
      const { data: ordersData, error: ordersError } = await supabase
        .from('orders')
        .select('*')
        .order('created_at', { ascending: false });

      if (ordersError) throw ordersError;
      
      console.log('Orders fetched:', ordersData?.length || 0);
      
      const { data: itemsData, error: itemsError } = await supabase
        .from('order_items')
        .select('*')
        .order('created_at', { ascending: false });

      if (itemsError) throw itemsError;
      
      const ordersWithItems = ordersData?.map(order => ({
        ...order,
        order_items: itemsData?.filter(item => item.order_id === order.id) || []
      })) || [];
      
      setOrders(ordersWithItems);
      setDebugInfo(prev => ({ 
        ...prev, 
        ordersCount: ordersWithItems.length, 
        lastFetch: new Date().toLocaleTimeString() 
      }));
      
    } catch (error) {
      console.error('Error fetching orders:', error);
      setDebugInfo(prev => ({ ...prev, error: error.message }));
    }
  };

  const fetchRiders = async () => {
    try {
      const { data, error } = await supabase
        .from('riders')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      setRiders(data || []);
    } catch (error) {
      console.error('Error fetching riders:', error);
    }
  };

  const fetchDeliveries = async () => {
    try {
      const { data: deliveriesData, error: deliveriesError } = await supabase
        .from('deliveries')
        .select('*')
        .order('created_at', { ascending: false });

      if (deliveriesError) throw deliveriesError;
      
      const orderIds = [...new Set(deliveriesData?.map(d => d.order_id).filter(Boolean))];
      const riderIds = [...new Set(deliveriesData?.map(d => d.rider_id).filter(Boolean))];
      
      let ordersMap = {};
      let ridersMap = {};
      
      if (orderIds.length > 0) {
        const { data: ordersData } = await supabase
          .from('orders')
          .select('id, customer_name, delivery_address, contact_number, total_amount, order_type, rental_end_date, payment_method, payment_status, status')
          .in('id', orderIds);
        
        ordersMap = (ordersData || []).reduce((acc, order) => {
          acc[order.id] = order;
          return acc;
        }, {});
      }
      
      if (riderIds.length > 0) {
        const { data: ridersData } = await supabase
          .from('riders')
          .select('id, name, phone, vehicle_number')
          .in('id', riderIds);
        
        ridersMap = (ridersData || []).reduce((acc, rider) => {
          acc[rider.id] = rider;
          return acc;
        }, {});
      }
      
      const deliveriesWithRelations = deliveriesData?.map(delivery => ({
        ...delivery,
        orders: ordersMap[delivery.order_id] || null,
        riders: ridersMap[delivery.rider_id] || null
      })) || [];
      
      setDeliveries(deliveriesWithRelations);
    } catch (error) {
      console.error('Error fetching deliveries:', error);
    }
  };

  const fetchVendors = async () => {
    try {
      const { data, error } = await supabase
        .from('users')
        .select('*')
        .eq('role', 'vendor')
        .order('created_at', { ascending: false });

      if (error) throw error;
      setVendors(data || []);
    } catch (error) {
      console.error('Error fetching vendors:', error);
    }
  };

  const fetchVendorEarnings = async () => {
    try {
      const { data, error } = await supabase
        .from('vendor_earnings')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      
      const vendorIds = [...new Set(data?.map(e => e.vendor_id).filter(Boolean))];
      
      if (vendorIds.length > 0) {
        const { data: vendorsData } = await supabase
          .from('users')
          .select('id, full_name, business_name, email')
          .in('id', vendorIds);
        
        const vendorsMap = (vendorsData || []).reduce((acc, vendor) => {
          acc[vendor.id] = vendor;
          return acc;
        }, {});
        
        const earningsWithVendors = data?.map(earning => ({
          ...earning,
          users: vendorsMap[earning.vendor_id] || null
        })) || [];
        
        setVendorEarnings(earningsWithVendors);
      } else {
        setVendorEarnings(data || []);
      }
    } catch (error) {
      console.error('Error fetching vendor earnings:', error);
    }
  };

  const fetchReviews = async () => {
    try {
      const { data, error } = await supabase
        .from('reviews')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      
      const brideIds = [...new Set(data?.map(r => r.user_id).filter(Boolean))];
      const vendorIds = [...new Set(data?.map(r => r.vendor_id).filter(Boolean))];
      
      let bridesMap = {};
      let vendorsMap = {};
      
      if (brideIds.length > 0) {
        const { data: bridesData } = await supabase
          .from('users')
          .select('id, full_name, email')
          .in('id', brideIds);
        
        bridesMap = (bridesData || []).reduce((acc, bride) => {
          acc[bride.id] = bride;
          return acc;
        }, {});
      }
      
      if (vendorIds.length > 0) {
        const { data: vendorsData } = await supabase
          .from('users')
          .select('id, business_name, full_name')
          .in('id', vendorIds);
        
        vendorsMap = (vendorsData || []).reduce((acc, vendor) => {
          acc[vendor.id] = vendor;
          return acc;
        }, {});
      }
      
      const reviewsWithRelations = data?.map(review => ({
        ...review,
        users: bridesMap[review.user_id] || null,
        vendors: vendorsMap[review.vendor_id] || null
      })) || [];
      
      setReviews(reviewsWithRelations);
    } catch (error) {
      console.error('Error fetching reviews:', error);
    }
  };

  const fetchNotifications = async () => {
    try {
      const { data, error } = await supabase
        .from('notifications')
        .select('*')
        .eq('user_type', 'admin')
        .order('created_at', { ascending: false })
        .limit(50);

      if (error) throw error;
      setNotifications(data || []);
    } catch (error) {
      console.error('Error fetching notifications:', error);
    }
  };

  const fetchReturnRequests = async () => {
    try {
      const { data, error } = await supabase
        .from('return_requests')
        .select('*, orders!inner(*)')
        .order('requested_at', { ascending: false });

      if (error) throw error;
      setReturnRequests(data || []);
      console.log('Return requests fetched:', data?.length || 0);
    } catch (error) {
      console.error('Error fetching return requests:', error);
    }
  };

  const calculateStats = () => {
    const totalUsers = users.length;
    const totalBrides = users.filter(u => u.role === 'bride').length;
    const totalVendors = users.filter(u => u.role === 'vendor').length;
    const activeUsers = users.filter(u => !u.is_blocked).length;
    const blockedUsers = users.filter(u => u.is_blocked).length;
    
    const totalDresses = dresses.length;
    const approvedDresses = dresses.filter(d => d.is_approved).length;
    const pendingDresses = dresses.filter(d => !d.is_approved).length;
    const availableDresses = dresses.filter(d => d.status === 'available' && d.is_approved).length;
    const rentedDresses = dresses.filter(d => d.status === 'booked').length;
    const soldDresses = dresses.filter(d => d.status === 'sold').length;
    
    const totalOrders = orders.length;
    const pendingOrders = orders.filter(o => o.status === 'pending').length;
    const completedOrders = orders.filter(o => o.status === 'delivered').length;
    
    const purchaseOrders = orders.filter(o => o.order_type === 'purchase').length;
    const rentalOrders = orders.filter(o => o.order_type === 'rent' || o.order_type === 'rental').length;
    
    const pendingPayments = orders.filter(o => 
      o.payment_method !== 'cod' && 
      (o.payment_status === 'awaiting_verification' || o.payment_status === 'pending')
    ).length;
    
    const totalRevenue = orders.reduce((sum, o) => sum + (Number(o.total_amount) || 0), 0);
    
    const totalRiders = riders.length;
    const activeRiders = riders.filter(r => r.is_active).length;
    const inactiveRiders = riders.filter(r => !r.is_active).length;
    
    const activeDeliveries = deliveries.filter(d => d.status === 'assigned' || d.status === 'picked').length;
    const completedDeliveries = deliveries.filter(d => d.status === 'delivered').length;
    const returnDeliveries = deliveries.filter(d => 
      d.status === 'return_assigned' || d.status === 'return_picked' || d.status === 'return_delivered'
    ).length;
    
    const totalReviews = reviews.length;
    const averageRating = totalReviews > 0 
      ? reviews.reduce((sum, r) => sum + (r.rating || 0), 0) / totalReviews 
      : 0;

    const adminCommission = vendorEarnings.reduce((sum, e) => sum + (e.admin_commission || 0), 0);
    const vendorPayouts = vendorEarnings.reduce((sum, e) => sum + (e.vendor_payout || 0), 0);
    
    const riderEarnings = completedDeliveries * 500;

    // Return request stats
    const pendingInspections = returnRequests.filter(r => r.return_status === 'pending_inspection').length;
    const completedInspections = returnRequests.filter(r => r.return_status === 'completed').length;
    const rejectedInspections = returnRequests.filter(r => r.return_status === 'rejected').length;

    setStats({
      totalUsers,
      totalBrides,
      totalVendors,
      totalRiders,
      activeRiders,
      inactiveRiders,
      totalDresses,
      approvedDresses,
      pendingDresses,
      availableDresses,
      rentedDresses,
      soldDresses,
      activeUsers,
      blockedUsers,
      totalOrders,
      pendingOrders,
      completedOrders,
      purchaseOrders,
      rentalOrders,
      pendingPayments,
      totalRevenue,
      adminCommission,
      vendorPayouts,
      riderEarnings,
      revenueGrowth: 12.5,
      userGrowth: 8.3,
      orderGrowth: 15.7,
      activeDeliveries,
      completedDeliveries,
      returnDeliveries,
      totalReviews,
      averageRating,
      pendingInspections,
      completedInspections,
      rejectedInspections
    });
  };

  // ==================== USER MANAGEMENT FUNCTIONS ====================
  const toggleUserBlock = async (userId, currentStatus) => {
    try {
      const { error } = await supabase
        .from('users')
        .update({ is_blocked: !currentStatus })
        .eq('id', userId);

      if (error) throw error;
      
      setUsers(users.map(user => 
        user.id === userId 
          ? { ...user, is_blocked: !currentStatus } 
          : user
      ));
      
      alert(`User ${!currentStatus ? 'blocked' : 'unblocked'} successfully!`);
    } catch (error) {
      console.error('Error updating user:', error);
      alert('Error updating user');
    }
  };

  const deleteUser = async (userId) => {
    if (!window.confirm('Are you sure you want to delete this user? This action cannot be undone.')) return;
    
    try {
      const { error } = await supabase
        .from('users')
        .delete()
        .eq('id', userId);

      if (error) throw error;
      setUsers(users.filter(user => user.id !== userId));
      alert('User deleted successfully!');
    } catch (error) {
      console.error('Error deleting user:', error);
      alert('Error deleting user');
    }
  };

  const verifyUser = async (userId) => {
    try {
      const { error } = await supabase
        .from('users')
        .update({ is_verified: true })
        .eq('id', userId);

      if (error) throw error;
      
      setUsers(users.map(user => 
        user.id === userId 
          ? { ...user, is_verified: true } 
          : user
      ));
      
      alert('User verified successfully!');
    } catch (error) {
      console.error('Error verifying user:', error);
      alert('Error verifying user');
    }
  };

  // ==================== VENDOR EARNINGS FUNCTIONS ====================
  const markVendorEarningAsPaid = async (earningId) => {
    try {
      const { error } = await supabase
        .from('vendor_earnings')
        .update({ 
          status: 'paid',
          paid_at: new Date().toISOString()
        })
        .eq('id', earningId);

      if (error) throw error;
      
      setVendorEarnings(vendorEarnings.map(e => 
        e.id === earningId 
          ? { ...e, status: 'paid', paid_at: new Date().toISOString() } 
          : e
      ));
      
      alert('Marked as paid successfully!');
    } catch (error) {
      console.error('Error updating earning:', error);
      alert('Error updating earning');
    }
  };

  // ==================== RIDER MANAGEMENT FUNCTIONS ====================
  const handleAddRider = async () => {
    if (!newRider.name || !newRider.email || !newRider.phone || !newRider.password) {
      alert('Please fill all required fields');
      return;
    }
    
    if (newRider.password !== newRider.confirmPassword) {
      alert('Passwords do not match');
      return;
    }
    
    setCreatingRider(true);
    
    try {
      const { data: authData, error: authError } = await supabase.auth.signUp({
        email: newRider.email,
        password: newRider.password,
      });

      if (authError) {
        if (authError.message.includes('rate limit')) {
          alert('Email rate limit exceeded. Please wait an hour or use a different email.');
          setCreatingRider(false);
          return;
        }
        throw authError;
      }

      const { data: riderData, error: riderError } = await supabase
        .from('riders')
        .insert([{
          id: authData.user.id,
          name: newRider.name,
          email: newRider.email,
          phone: newRider.phone,
          vehicle_type: newRider.vehicleType,
          vehicle_number: newRider.vehicleNumber,
          service_area: newRider.serviceArea,
          city: newRider.city,
          is_active: true,
          created_at: new Date().toISOString()
        }])
        .select();

      if (riderError) throw riderError;

      setNewRiderCredentials({
        name: newRider.name,
        email: newRider.email,
        password: newRider.password,
        phone: newRider.phone,
        vehicle: `${newRider.vehicleType} - ${newRider.vehicleNumber}`,
        serviceArea: newRider.serviceArea,
        city: newRider.city
      });

      setNewRider({
        name: '',
        email: '',
        phone: '',
        vehicleType: 'Motorcycle',
        vehicleNumber: '',
        serviceArea: '',
        city: '',
        password: '',
        confirmPassword: ''
      });

      setShowAddRiderModal(false);
      setShowRiderCredentialsModal(true);
      fetchRiders();
      
    } catch (error) {
      console.error('Error creating rider:', error);
      alert('Error creating rider: ' + error.message);
    } finally {
      setCreatingRider(false);
    }
  };

  const copyToClipboard = (text) => {
    navigator.clipboard.writeText(text);
    alert('Copied to clipboard!');
  };

  const sendCredentialsViaEmail = () => {
    if (newRiderCredentials) {
      window.location.href = `mailto:${newRiderCredentials.email}?subject=Your Rider Account Credentials&body=Hello ${newRiderCredentials.name},%0D%0A%0D%0AYour rider account has been created. Here are your login credentials:%0D%0A%0D%0AWebsite: ${window.location.origin}/rider-login%0D%0AEmail: ${newRiderCredentials.email}%0D%0APassword: ${newRiderCredentials.password}%0D%0A%0D%0APlease login and complete your profile.%0D%0A%0D%0ARegards,%0D%0ABridalEase Admin Team`;
    }
  };

  // ==================== ORDER STATUS UPDATE FUNCTION (SYNC) ====================
  const updateOrderStatus = async (orderId, newStatus) => {
    try {
      // Update order status
      const { error } = await supabase
        .from('orders')
        .update({ status: newStatus })
        .eq('id', orderId);
      
      if (error) throw error;
      
      // If delivered, also update delivery if exists
      if (newStatus === 'delivered') {
        const { data: delivery } = await supabase
          .from('deliveries')
          .select('id')
          .eq('order_id', orderId)
          .eq('status', 'picked')
          .maybeSingle();
        
        if (delivery) {
          await supabase
            .from('deliveries')
            .update({ status: 'delivered', delivered_at: new Date().toISOString() })
            .eq('id', delivery.id);
        }
        
        // Add rider earnings
        const { data: deliveryData } = await supabase
          .from('deliveries')
          .select('id, rider_id')
          .eq('order_id', orderId)
          .eq('status', 'delivered')
          .maybeSingle();
          
        if (deliveryData?.rider_id) {
          await supabase
            .from('rider_earnings')
            .insert({
              delivery_id: deliveryData.id,
              rider_id: deliveryData.rider_id,
              order_id: orderId,
              base_amount: 500,
              total_amount: 500,
              status: 'pending',
              created_at: new Date().toISOString()
            });
        }
      }
      
      // Refresh data
      await fetchOrders();
      await fetchDeliveries();
      
      alert(`✅ Order status updated to ${newStatus}!`);
      
    } catch (error) {
      console.error('Error updating order:', error);
      alert('Error updating order status: ' + error.message);
    }
  };

  // ==================== DELIVERY FUNCTIONS WITH SYNC ====================
  const assignDelivery = async (orderId, riderId, isReturn = false) => {
    try {
      const { data: existing } = await supabase
        .from('deliveries')
        .select('id')
        .eq('order_id', orderId)
        .eq('status', isReturn ? 'return_assigned' : 'assigned')
        .maybeSingle();

      if (existing) {
        alert('This delivery already has an active assignment');
        return;
      }

      const status = isReturn ? 'return_assigned' : 'assigned';
      
      const { data: deliveryData, error: deliveryError } = await supabase
        .from('deliveries')
        .insert([{
          order_id: orderId,
          rider_id: riderId,
          status: status,
          assigned_at: new Date().toISOString(),
          created_at: new Date().toISOString()
        }])
        .select();

      if (deliveryError) throw deliveryError;

      // Update order status
      await supabase
        .from('orders')
        .update({ status: isReturn ? 'return_assigned' : 'assigned' })
        .eq('id', orderId);

      const rider = riders.find(r => r.id === riderId);
      
      if (rider) {
        await supabase.from('notifications').insert({
          user_id: riderId,
          user_type: 'rider',
          type: isReturn ? 'return_delivery' : 'new_delivery',
          title: isReturn ? 'Return Delivery Assigned' : 'New Delivery Assigned',
          message: isReturn 
            ? `You have been assigned to pick up a return from customer for order #${orderId.substring(0, 8)}`
            : `You have been assigned a new delivery for order #${orderId.substring(0, 8)}`,
          data: { order_id: orderId, delivery_id: deliveryData[0].id, is_return: isReturn },
          created_at: new Date().toISOString()
        });
      }

      setDeliveries([...deliveries, ...deliveryData]);
      await fetchOrders(); // Refresh orders to show updated status
      
      alert(`✅ ${isReturn ? 'Return' : 'Delivery'} assigned to ${rider?.name || 'rider'} successfully!`);
      setShowOrderModal(false);
      setShowReturnDeliveryModal(false);
      
    } catch (error) {
      console.error('Error assigning delivery:', error);
      alert('Error assigning delivery: ' + error.message);
    }
  };

  const updateDeliveryStatus = async (deliveryId, newStatus) => {
    setUpdatingDeliveryStatus(true);
    
    try {
      const updates = { status: newStatus };
      
      if (newStatus === 'picked' || newStatus === 'return_picked') {
        updates.picked_at = new Date().toISOString();
      } else if (newStatus === 'delivered' || newStatus === 'return_delivered') {
        updates.delivered_at = new Date().toISOString();
      }
      
      const { error } = await supabase
        .from('deliveries')
        .update(updates)
        .eq('id', deliveryId);

      if (error) throw error;
      
      // Get the delivery to find order_id
      const delivery = deliveries.find(d => d.id === deliveryId);
      if (!delivery) return;
      
      const isReturn = newStatus.startsWith('return_');
      
      // SYNC: UPDATE ORDER STATUS BASED ON DELIVERY STATUS
      if (newStatus === 'assigned') {
        await supabase
          .from('orders')
          .update({ status: 'assigned' })
          .eq('id', delivery.order_id);
      }
      else if (newStatus === 'picked') {
        await supabase
          .from('orders')
          .update({ status: 'picked' })
          .eq('id', delivery.order_id);
      }
      else if (newStatus === 'delivered') {
        const order = orders.find(o => o.id === delivery.order_id);
        
        await supabase
          .from('orders')
          .update({ 
            status: 'delivered',
            delivered_at: new Date().toISOString()
          })
          .eq('id', delivery.order_id);
        
        // For rental orders, set rental dates
        if (order?.order_type === 'rent') {
          const rentalDays = order.rental_days || 3;
          const today = new Date();
          const endDate = new Date();
          endDate.setDate(endDate.getDate() + rentalDays);
          
          await supabase
            .from('orders')
            .update({
              rental_start_date: today.toISOString().split('T')[0],
              rental_end_date: endDate.toISOString().split('T')[0],
              return_status: 'pending'
            })
            .eq('id', delivery.order_id);
        }
        
        // Add rider earnings
        await supabase
          .from('rider_earnings')
          .insert({
            delivery_id: deliveryId,
            rider_id: delivery.rider_id,
            order_id: delivery.order_id,
            base_amount: 500,
            total_amount: 500,
            status: 'pending',
            created_at: new Date().toISOString()
          });
      }
      else if (newStatus === 'return_assigned') {
        await supabase
          .from('orders')
          .update({ return_status: 'assigned' })
          .eq('id', delivery.order_id);
      }
      else if (newStatus === 'return_picked') {
        await supabase
          .from('orders')
          .update({ return_status: 'picked' })
          .eq('id', delivery.order_id);
      }
      else if (newStatus === 'return_delivered') {
        await supabase
          .from('orders')
          .update({ 
            return_status: 'completed',
            returned_at: new Date().toISOString()
          })
          .eq('id', delivery.order_id);
        
        // Update dress status back to available
        const { data: orderItems } = await supabase
          .from('order_items')
          .select('dress_id')
          .eq('order_id', delivery.order_id)
          .maybeSingle();

        if (orderItems?.dress_id) {
          await supabase
            .from('dresses')
            .update({ status: 'available' })
            .eq('id', orderItems.dress_id);
        }
        
        // Add rider earnings for return delivery
        await supabase
          .from('rider_earnings')
          .insert({
            delivery_id: deliveryId,
            rider_id: delivery.rider_id,
            order_id: delivery.order_id,
            base_amount: 500,
            total_amount: 500,
            status: 'pending',
            created_at: new Date().toISOString()
          });
      }
      
      // Update local states
      setDeliveries(deliveries.map(d => 
        d.id === deliveryId ? { ...d, ...updates } : d
      ));
      
      // Refresh orders and return requests to show updated status
      await fetchOrders();
      await fetchReturnRequests();
      
      alert(`✅ Delivery status updated to ${newStatus}! Order status synced.`);
      
    } catch (error) {
      console.error('Error updating delivery:', error);
      alert('Error updating delivery status: ' + error.message);
    } finally {
      setUpdatingDeliveryStatus(false);
    }
  };

  const getRiderPerformance = (riderId) => {
    const riderDeliveries = deliveries.filter(d => d.rider_id === riderId);
    const total = riderDeliveries.length;
    const completed = riderDeliveries.filter(d => d.status === 'delivered' || d.status === 'return_delivered').length;
    const inProgress = riderDeliveries.filter(d => 
      d.status === 'assigned' || d.status === 'picked' || 
      d.status === 'return_assigned' || d.status === 'return_picked'
    ).length;
    
    const completionRate = total > 0 ? Math.round((completed / total) * 100) : 0;
    
    return { total, completed, inProgress, completionRate };
  };

  const viewRiderDetails = (rider) => {
    const performance = getRiderPerformance(rider.id);
    setSelectedRider({ ...rider, performance });
    setShowRiderModal(true);
  };

  const toggleRiderStatus = async (riderId, currentStatus) => {
    try {
      const { error } = await supabase
        .from('riders')
        .update({ is_active: !currentStatus })
        .eq('id', riderId);

      if (error) throw error;
      
      await supabase.from('notifications').insert({
        user_id: riderId,
        user_type: 'rider',
        type: 'account_status',
        title: 'Account Status Updated',
        message: `Your rider account has been ${!currentStatus ? 'activated' : 'deactivated'}.`,
        created_at: new Date().toISOString()
      });
      
      setRiders(riders.map(rider => 
        rider.id === riderId 
          ? { ...rider, is_active: !currentStatus } 
          : rider
      ));
      
      alert(`Rider ${!currentStatus ? 'activated' : 'deactivated'} successfully!`);
    } catch (error) {
      console.error('Error updating rider:', error);
      alert('Error updating rider status');
    }
  };

  const deleteRider = async (riderId) => {
    if (!window.confirm('Are you sure you want to delete this rider? This action cannot be undone.')) return;
    
    try {
      const { error } = await supabase
        .from('riders')
        .delete()
        .eq('id', riderId);

      if (error) throw error;
      
      setRiders(riders.filter(rider => rider.id !== riderId));
      alert('Rider deleted successfully!');
    } catch (error) {
      console.error('Error deleting rider:', error);
      alert('Error deleting rider');
    }
  };

  const getAvailableRiders = () => {
    return riders.filter(r => r.is_active);
  };

  const calculateRiderEarnings = (riderId) => {
    const completedDeliveries = deliveries.filter(d => 
      d.rider_id === riderId && (d.status === 'delivered' || d.status === 'return_delivered')
    );
    
    const baseRate = 500;
    const totalEarnings = completedDeliveries.length * baseRate;
    
    return {
      total: totalEarnings,
      count: completedDeliveries.length,
      rate: baseRate
    };
  };

  // ==================== INSPECTION FUNCTIONS ====================
  const viewInspectionDetails = (returnRequest) => {
    setSelectedReturnRequest(returnRequest);
    const photos = returnRequest.inspection_photos || [];
    setInspectionPhotos(photos);
    setCurrentPhotoIndex(0);
    setShowInspectionDetailsModal(true);
  };

  const nextPhoto = () => {
    if (inspectionPhotos.length > 0) {
      setCurrentPhotoIndex((prev) => (prev + 1) % inspectionPhotos.length);
    }
  };

  const prevPhoto = () => {
    if (inspectionPhotos.length > 0) {
      setCurrentPhotoIndex((prev) => (prev - 1 + inspectionPhotos.length) % inspectionPhotos.length);
    }
  };

  // ==================== DRESS MANAGEMENT FUNCTIONS ====================
  const openDressEditModal = (dress) => {
    setSelectedDress(dress);
    setDressEditForm({
      name: dress.name || '',
      description: dress.description || '',
      price: dress.price?.toString() || '',
      rental_price: dress.rental_price?.toString() || '',
      status: dress.status || 'available',
      is_approved: dress.is_approved || false,
      available_after: dress.available_after ? dress.available_after.split('T')[0] : ''
    });
    setShowDressEditModal(true);
  };

  const saveDressChanges = async () => {
    if (!selectedDress) return;
    
    setUpdatingDress(true);
    try {
      const validStatuses = ['draft', 'pending', 'available', 'booked', 'sold', 'archived', 'rejected'];
      
      let statusToSave = dressEditForm.status;
      if (!validStatuses.includes(statusToSave)) {
        statusToSave = 'available';
      }
      
      const updates = {
        name: dressEditForm.name || null,
        description: dressEditForm.description || null,
        price: dressEditForm.price ? parseFloat(dressEditForm.price) : null,
        rental_price: dressEditForm.rental_price ? parseFloat(dressEditForm.rental_price) : null,
        status: statusToSave,
        is_approved: dressEditForm.is_approved || false,
        updated_at: new Date().toISOString()
      };

      if (dressEditForm.available_after) {
        updates.available_after = dressEditForm.available_after;
      }

      console.log('Updating dress with:', updates);

      const { error } = await supabase
        .from('dresses')
        .update(updates)
        .eq('id', selectedDress.id);

      if (error) throw error;

      setDresses(dresses.map(dress => 
        dress.id === selectedDress.id 
          ? { ...dress, ...updates } 
          : dress
      ));

      alert('Dress updated successfully!');
      setShowDressEditModal(false);
    } catch (error) {
      console.error('Error updating dress:', error);
      alert('Error updating dress: ' + error.message);
    } finally {
      setUpdatingDress(false);
    }
  };

  const toggleDressApproval = async (dressId, currentStatus) => {
    try {
      const { error } = await supabase
        .from('dresses')
        .update({ is_approved: !currentStatus })
        .eq('id', dressId);

      if (error) throw error;
      
      setDresses(dresses.map(dress => 
        dress.id === dressId 
          ? { ...dress, is_approved: !currentStatus } 
          : dress
      ));
      
      const dress = dresses.find(d => d.id === dressId);
      if (dress) {
        await supabase.from('notifications').insert({
          user_id: dress.vendor_id,
          user_type: 'vendor',
          type: 'dress_approval',
          title: !currentStatus ? 'Dress Approved' : 'Dress Unapproved',
          message: !currentStatus 
            ? `Your dress "${dress.name}" has been approved` 
            : `Your dress "${dress.name}" has been unapproved`,
          data: { dress_id: dressId },
          created_at: new Date().toISOString()
        });
      }
      
      alert(`Dress ${!currentStatus ? 'approved' : 'unapproved'} successfully!`);
    } catch (error) {
      console.error('Error updating dress:', error);
      alert('Error updating dress');
    }
  };

  const deleteDress = async (dressId) => {
    if (!window.confirm('Are you sure you want to delete this dress? This action cannot be undone.')) return;
    
    try {
      const { error } = await supabase
        .from('dresses')
        .delete()
        .eq('id', dressId);

      if (error) throw error;
      setDresses(dresses.filter(dress => dress.id !== dressId));
      alert('Dress deleted successfully!');
    } catch (error) {
      console.error('Error deleting dress:', error);
      alert('Error deleting dress');
    }
  };

  // ==================== PAYMENT APPROVAL FUNCTIONS ====================
  const approvePayment = async (orderId) => {
    setProcessingPayment(true);
    try {
      const { data: order, error: orderError } = await supabase
        .from('orders')
        .select('*')
        .eq('id', orderId)
        .single();

      if (orderError) throw orderError;

      await supabase
        .from('orders')
        .update({ 
          payment_status: 'completed',
          status: 'confirmed'
        })
        .eq('id', orderId);

      await supabase.from('notifications').insert({
        user_id: order.user_id,
        user_type: 'bride',
        type: 'payment_approved',
        title: 'Payment Approved',
        message: 'Your payment has been approved! Your order is now confirmed.',
        data: { order_id: orderId },
        created_at: new Date().toISOString()
      });

      if (order.vendor_id) {
        await supabase.from('notifications').insert({
          user_id: order.vendor_id,
          user_type: 'vendor',
          type: 'new_order',
          title: 'New Order Received',
          message: 'You have a new order to process.',
          data: { order_id: orderId },
          created_at: new Date().toISOString()
        });
      }
      
      setOrders(orders.map(o => 
        o.id === orderId 
          ? { ...o, payment_status: 'completed', status: 'confirmed' } 
          : o
      ));
      
      setShowPaymentModal(false);
      alert('Payment approved successfully!');
      
    } catch (error) {
      console.error('Error approving payment:', error);
      alert('Error approving payment: ' + error.message);
    } finally {
      setProcessingPayment(false);
    }
  };

  const rejectPayment = async (orderId) => {
    const reason = prompt('Please enter reason for rejection:');
    if (!reason) return;
    
    setProcessingPayment(true);
    try {
      const { error } = await supabase
        .from('orders')
        .update({ 
          payment_status: 'rejected',
          payment_rejection_reason: reason
        })
        .eq('id', orderId);

      if (error) throw error;
      
      setOrders(orders.map(order => 
        order.id === orderId 
          ? { ...order, payment_status: 'rejected' } 
          : order
      ));
      
      setShowPaymentModal(false);
      alert('Payment rejected!');
    } catch (error) {
      console.error('Error rejecting payment:', error);
      alert('Error rejecting payment');
    } finally {
      setProcessingPayment(false);
    }
  };

  // ==================== RENDER MODALS ====================
  // (Keep all modal render functions from previous code - they remain the same)
  
  const renderInspectionDetailsModal = () => (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl max-w-4xl w-full max-h-[90vh] overflow-y-auto">
        <div className="p-6 border-b border-gray-200 sticky top-0 bg-white flex items-center justify-between">
          <h2 className="text-xl font-bold text-gray-800">Inspection Details</h2>
          <button onClick={() => setShowInspectionDetailsModal(false)} className="p-2 hover:bg-gray-100 rounded-lg">
            <X className="w-5 h-5 text-gray-500" />
          </button>
        </div>
        
        {selectedReturnRequest && (
          <div className="p-6">
            {/* Order Info */}
            <div className="bg-purple-50 p-4 rounded-lg mb-6">
              <div className="flex justify-between items-center">
                <div>
                  <p className="text-xs text-purple-600">Order ID</p>
                  <p className="font-mono text-sm font-bold">{selectedReturnRequest.order_id}</p>
                </div>
                <div className="text-right">
                  <p className="text-xs text-purple-600">Requested</p>
                  <p className="text-sm">{formatDate(selectedReturnRequest.requested_at)}</p>
                </div>
              </div>
            </div>

            {/* Inspection Photos Gallery */}
            {inspectionPhotos.length > 0 && (
              <div className="mb-6">
                <h3 className="font-semibold mb-3 flex items-center">
                  <Camera className="w-5 h-5 mr-2 text-purple-600" />
                  Inspection Photos
                </h3>
                <div className="bg-gray-100 rounded-lg p-4">
                  <div className="relative flex items-center justify-center">
                    <button
                      onClick={prevPhoto}
                      className="absolute left-2 bg-black/50 hover:bg-black/70 text-white p-2 rounded-full transition-all"
                    >
                      <ChevronLeft className="w-5 h-5" />
                    </button>
                    <img
                      src={inspectionPhotos[currentPhotoIndex]}
                      alt={`Inspection ${currentPhotoIndex + 1}`}
                      className="max-h-96 rounded-lg shadow-lg object-contain"
                    />
                    <button
                      onClick={nextPhoto}
                      className="absolute right-2 bg-black/50 hover:bg-black/70 text-white p-2 rounded-full transition-all"
                    >
                      <ChevronRight className="w-5 h-5" />
                    </button>
                  </div>
                  <div className="text-center mt-3">
                    <p className="text-sm text-gray-600">
                      {currentPhotoIndex + 1} of {inspectionPhotos.length}
                    </p>
                  </div>
                </div>
              </div>
            )}

            {/* Inspection Results */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
              <div className="bg-gray-50 p-4 rounded-lg">
                <p className="text-sm text-gray-500">Dress Condition</p>
                <p className="font-semibold text-lg">
                  {selectedReturnRequest.inspection_status === 'accepted' ? 'Good Condition' : 'Damaged'}
                </p>
              </div>
              {selectedReturnRequest.penalty_amount > 0 && (
                <div className="bg-red-50 p-4 rounded-lg">
                  <p className="text-sm text-gray-500">Penalty Amount</p>
                  <p className="font-semibold text-lg text-red-600">
                    {formatCurrency(selectedReturnRequest.penalty_amount)}
                  </p>
                </div>
              )}
            </div>

            {/* Damage Description */}
            {selectedReturnRequest.damage_description && (
              <div className="mb-6">
                <h3 className="font-semibold mb-2">Damage Description</h3>
                <div className="bg-gray-50 p-4 rounded-lg">
                  <p className="text-gray-700">{selectedReturnRequest.damage_description}</p>
                </div>
              </div>
            )}

            {/* Return Status */}
            <div className="flex justify-end">
              <span className={`px-4 py-2 rounded-full text-sm font-medium ${getStatusColor(selectedReturnRequest.return_status)}`}>
                {selectedReturnRequest.return_status?.toUpperCase()}
              </span>
            </div>
          </div>
        )}
      </div>
    </div>
  );

  const renderAddRiderModal = () => (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        <div className="p-6 border-b border-gray-200 sticky top-0 bg-white flex items-center justify-between">
          <h2 className="text-xl font-bold text-gray-800">Add New Rider</h2>
          <button onClick={() => setShowAddRiderModal(false)} className="p-2 hover:bg-gray-100 rounded-lg">
            <X className="w-5 h-5 text-gray-500" />
          </button>
        </div>
        
        <div className="p-6">
          <div className="bg-purple-50 p-4 rounded-lg mb-6 border-l-4 border-purple-600">
            <div className="flex items-start">
              <Info className="w-5 h-5 text-purple-600 mr-3 mt-0.5" />
              <div>
                <p className="text-sm font-medium text-purple-800">Rider Account Creation</p>
                <p className="text-sm text-purple-600 mt-1">
                  Rider will receive login credentials. Make sure to save the password to share with them.
                </p>
              </div>
            </div>
          </div>

          <div className="space-y-4">
            <div>
              <h3 className="font-medium text-gray-700 mb-3">Personal Information</h3>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Full Name *</label>
                  <input
                    type="text"
                    value={newRider.name}
                    onChange={(e) => setNewRider({...newRider, name: e.target.value})}
                    className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-purple-500"
                    placeholder="John Doe"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Phone Number *</label>
                  <input
                    type="text"
                    value={newRider.phone}
                    onChange={(e) => setNewRider({...newRider, phone: e.target.value})}
                    className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-purple-500"
                    placeholder="03001234567"
                  />
                </div>
              </div>
            </div>

            <div>
              <h3 className="font-medium text-gray-700 mb-3">Account Credentials</h3>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Email Address *</label>
                  <input
                    type="email"
                    value={newRider.email}
                    onChange={(e) => setNewRider({...newRider, email: e.target.value})}
                    className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-purple-500"
                    placeholder="rider@example.com"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Password *</label>
                  <input
                    type="text"
                    value={newRider.password}
                    onChange={(e) => setNewRider({...newRider, password: e.target.value})}
                    className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-purple-500"
                    placeholder="Minimum 6 characters"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Confirm Password *</label>
                  <input
                    type="text"
                    value={newRider.confirmPassword}
                    onChange={(e) => setNewRider({...newRider, confirmPassword: e.target.value})}
                    className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-purple-500"
                    placeholder="Re-enter password"
                  />
                </div>
              </div>
            </div>

            <div>
              <h3 className="font-medium text-gray-700 mb-3">Vehicle Information</h3>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Vehicle Type</label>
                  <select
                    value={newRider.vehicleType}
                    onChange={(e) => setNewRider({...newRider, vehicleType: e.target.value})}
                    className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-purple-500"
                  >
                    <option>Motorcycle</option>
                    <option>Scooter</option>
                    <option>Bicycle</option>
                    <option>Car</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Vehicle Number</label>
                  <input
                    type="text"
                    value={newRider.vehicleNumber}
                    onChange={(e) => setNewRider({...newRider, vehicleNumber: e.target.value})}
                    className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-purple-500"
                    placeholder="LEH-1234"
                  />
                </div>
              </div>
            </div>

            <div>
              <h3 className="font-medium text-gray-700 mb-3">Service Area</h3>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">City</label>
                  <input
                    type="text"
                    value={newRider.city}
                    onChange={(e) => setNewRider({...newRider, city: e.target.value})}
                    className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-purple-500"
                    placeholder="Lahore"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Service Area</label>
                  <input
                    type="text"
                    value={newRider.serviceArea}
                    onChange={(e) => setNewRider({...newRider, serviceArea: e.target.value})}
                    className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-purple-500"
                    placeholder="DHA, Gulberg, etc"
                  />
                </div>
              </div>
            </div>

            <div className="flex space-x-3 pt-6">
              <button
                onClick={() => setShowAddRiderModal(false)}
                className="flex-1 bg-gray-100 text-gray-700 py-3 rounded-lg hover:bg-gray-200"
              >
                Cancel
              </button>
              <button
                onClick={handleAddRider}
                disabled={creatingRider}
                className="flex-1 bg-purple-600 text-white py-3 rounded-lg hover:bg-purple-700 disabled:opacity-50 flex items-center justify-center"
              >
                {creatingRider ? (
                  <>
                    <RefreshCw className="w-4 h-4 animate-spin mr-2" />
                    Creating...
                  </>
                ) : (
                  <>
                    <UserPlus className="w-4 h-4 mr-2" />
                    Create Rider
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );

  const renderCredentialsModal = () => (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl max-w-md w-full">
        <div className="p-6 border-b border-gray-200">
          <div className="flex items-center justify-between">
            <h2 className="text-xl font-bold text-gray-800">Rider Created Successfully!</h2>
            <button onClick={() => setShowRiderCredentialsModal(false)} className="p-2 hover:bg-gray-100 rounded-lg">
              <X className="w-5 h-5 text-gray-500" />
            </button>
          </div>
        </div>
        
        <div className="p-6">
          <div className="bg-green-50 p-4 rounded-lg mb-6 border-l-4 border-green-600">
            <div className="flex items-center">
              <CheckCircle className="w-5 h-5 text-green-600 mr-3" />
              <p className="text-sm text-green-700">
                Rider account has been created. Share these credentials with the rider.
              </p>
            </div>
          </div>

          <div className="bg-gray-50 rounded-lg p-4 mb-6">
            <div className="space-y-3">
              <div className="flex justify-between items-center">
                <span className="text-sm text-gray-600">Name:</span>
                <span className="font-medium">{newRiderCredentials?.name}</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-gray-600">Email:</span>
                <div className="flex items-center">
                  <span className="font-medium mr-2">{newRiderCredentials?.email}</span>
                  <button onClick={() => copyToClipboard(newRiderCredentials?.email)} className="hover:text-purple-600">
                    <Copy className="w-4 h-4 text-gray-400 hover:text-purple-600" />
                  </button>
                </div>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-gray-600">Password:</span>
                <div className="flex items-center">
                  <span className="font-medium mr-2">{newRiderCredentials?.password}</span>
                  <button onClick={() => copyToClipboard(newRiderCredentials?.password)} className="hover:text-purple-600">
                    <Copy className="w-4 h-4 text-gray-400 hover:text-purple-600" />
                  </button>
                </div>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-gray-600">Phone:</span>
                <span className="font-medium">{newRiderCredentials?.phone}</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-gray-600">Vehicle:</span>
                <span className="font-medium">{newRiderCredentials?.vehicle}</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-gray-600">City:</span>
                <span className="font-medium">{newRiderCredentials?.city || 'Not specified'}</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-gray-600">Service Area:</span>
                <span className="font-medium">{newRiderCredentials?.serviceArea || 'Not specified'}</span>
              </div>
            </div>
          </div>

          <div className="flex space-x-3">
            <button
              onClick={sendCredentialsViaEmail}
              className="flex-1 bg-purple-600 text-white py-3 rounded-lg hover:bg-purple-700 flex items-center justify-center"
            >
              <MailIcon className="w-4 h-4 mr-2" />
              Email Credentials
            </button>
            <button
              onClick={() => {
                const message = `Hello ${newRiderCredentials?.name}, your rider account has been created.\n\nWebsite: ${window.location.origin}/rider-login\nEmail: ${newRiderCredentials?.email}\nPassword: ${newRiderCredentials?.password}\nCity: ${newRiderCredentials?.city}\nService Area: ${newRiderCredentials?.serviceArea}\n\nPlease login to start delivering.`;
                window.open(`https://wa.me/?text=${encodeURIComponent(message)}`);
              }}
              className="flex-1 bg-green-600 text-white py-3 rounded-lg hover:bg-green-700 flex items-center justify-center"
            >
              <MessageCircle className="w-4 h-4 mr-2" />
              WhatsApp
            </button>
          </div>
        </div>
      </div>
    </div>
  );

  const renderRiderDetailsModal = () => (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        <div className="p-6 border-b border-gray-200 sticky top-0 bg-white flex items-center justify-between">
          <h2 className="text-xl font-bold text-gray-800">Rider Performance Details</h2>
          <button onClick={() => setShowRiderModal(false)} className="p-2 hover:bg-gray-100 rounded-lg">
            <X className="w-5 h-5 text-gray-500" />
          </button>
        </div>
        
        {selectedRider && (
          <div className="p-6">
            <div className="flex items-center space-x-4 mb-6">
              <div className="w-16 h-16 bg-gradient-to-br from-purple-500 to-purple-700 rounded-full flex items-center justify-center">
                <Bike className="w-8 h-8 text-white" />
              </div>
              <div>
                <h3 className="text-lg font-bold">{selectedRider.name}</h3>
                <p className="text-gray-600">{selectedRider.email}</p>
                <div className="flex items-center mt-1">
                  <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium ${
                    selectedRider.is_active ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
                  }`}>
                    {selectedRider.is_active ? 'Active' : 'Inactive'}
                  </span>
                  <span className="text-xs text-gray-500 ml-2">ID: {selectedRider.id.substring(0, 8)}</span>
                </div>
              </div>
            </div>

            <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
              <div className="bg-purple-50 rounded-lg p-4 text-center">
                <p className="text-2xl font-bold text-purple-600">{selectedRider.performance?.total || 0}</p>
                <p className="text-xs text-gray-600">Total Deliveries</p>
              </div>
              <div className="bg-green-50 rounded-lg p-4 text-center">
                <p className="text-2xl font-bold text-green-600">{selectedRider.performance?.completed || 0}</p>
                <p className="text-xs text-gray-600">Completed</p>
              </div>
              <div className="bg-yellow-50 rounded-lg p-4 text-center">
                <p className="text-2xl font-bold text-yellow-600">{selectedRider.performance?.inProgress || 0}</p>
                <p className="text-xs text-gray-600">In Progress</p>
              </div>
              <div className="bg-orange-50 rounded-lg p-4 text-center">
                <p className="text-2xl font-bold text-orange-600">{selectedRider.performance?.completionRate || 0}%</p>
                <p className="text-xs text-gray-600">Completion Rate</p>
              </div>
            </div>

            <div className="bg-gray-50 rounded-lg p-4 mb-6">
              <h4 className="font-semibold mb-3">Contact & Vehicle Information</h4>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <p className="text-sm text-gray-500">Phone</p>
                  <p className="font-medium">{selectedRider.phone}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-500">Vehicle Type</p>
                  <p className="font-medium">{selectedRider.vehicle_type}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-500">Vehicle Number</p>
                  <p className="font-medium">{selectedRider.vehicle_number}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-500">City</p>
                  <p className="font-medium">{selectedRider.city || 'Not specified'}</p>
                </div>
                <div className="col-span-2">
                  <p className="text-sm text-gray-500">Service Area</p>
                  <p className="font-medium">{selectedRider.service_area || 'Not specified'}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-500">Joined Date</p>
                  <p className="font-medium">{formatDate(selectedRider.created_at)}</p>
                </div>
              </div>
            </div>

            {selectedRider.performance && (
              <div className="bg-green-50 rounded-lg p-4">
                <h4 className="font-semibold mb-3">Earnings Summary</h4>
                <div className="flex justify-between items-center">
                  <div>
                    <p className="text-sm text-gray-600">Total Deliveries: <span className="font-bold">{selectedRider.performance.completed}</span></p>
                    <p className="text-sm text-gray-600">Rate per Delivery: <span className="font-bold">Rs 500</span></p>
                  </div>
                  <div className="text-right">
                    <p className="text-xs text-gray-500">Total Earnings</p>
                    <p className="text-2xl font-bold text-green-600">
                      Rs {selectedRider.performance.completed * 500}
                    </p>
                  </div>
                </div>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );

  const renderDressEditModal = () => (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        <div className="p-6 border-b border-gray-200 sticky top-0 bg-white flex items-center justify-between">
          <h2 className="text-xl font-bold text-gray-800">Edit Dress</h2>
          <button onClick={() => setShowDressEditModal(false)} className="p-2 hover:bg-gray-100 rounded-lg">
            <X className="w-5 h-5 text-gray-500" />
          </button>
        </div>
        
        {selectedDress && (
          <div className="p-6">
            <div className="flex items-center space-x-4 mb-6">
              <div className="w-20 h-20 bg-gray-100 rounded-lg overflow-hidden">
                {getDressImages(selectedDress).length > 0 ? (
                  <img src={getDressImages(selectedDress)[0]} alt={selectedDress.name} className="w-full h-full object-cover" />
                ) : (
                  <ImageIcon className="w-8 h-8 text-gray-400 m-6" />
                )}
              </div>
              <div>
                <h3 className="text-lg font-bold">{selectedDress.name}</h3>
                <p className="text-sm text-gray-600">ID: {selectedDress.id.substring(0, 8)}</p>
              </div>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Dress Name</label>
                <input
                  type="text"
                  name="name"
                  value={dressEditForm.name}
                  onChange={handleDressEditChange}
                  className="w-full border rounded-lg px-3 py-2 focus:ring-2 focus:ring-purple-500"
                  placeholder="Dress name"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Description</label>
                <textarea
                  name="description"
                  value={dressEditForm.description}
                  onChange={handleDressEditChange}
                  rows="3"
                  className="w-full border rounded-lg px-3 py-2 focus:ring-2 focus:ring-purple-500"
                  placeholder="Dress description"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Price (Rs)</label>
                  <input
                    type="number"
                    name="price"
                    value={dressEditForm.price}
                    onChange={handleDressEditChange}
                    className="w-full border rounded-lg px-3 py-2 focus:ring-2 focus:ring-purple-500"
                    placeholder="0"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Rental Price (per day)</label>
                  <input
                    type="number"
                    name="rental_price"
                    value={dressEditForm.rental_price}
                    onChange={handleDressEditChange}
                    className="w-full border rounded-lg px-3 py-2 focus:ring-2 focus:ring-purple-500"
                    placeholder="0"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Status</label>
                  <select
                    name="status"
                    value={dressEditForm.status}
                    onChange={handleDressEditChange}
                    className="w-full border rounded-lg px-3 py-2 focus:ring-2 focus:ring-purple-500"
                  >
                    <option value="available">Available</option>
                    <option value="booked">Booked</option>
                    <option value="sold">Sold</option>
                    <option value="pending">Pending</option>
                    <option value="draft">Draft</option>
                    <option value="archived">Archived</option>
                    <option value="rejected">Rejected</option>
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Available After</label>
                  <input
                    type="date"
                    name="available_after"
                    value={dressEditForm.available_after}
                    onChange={handleDressEditChange}
                    className="w-full border rounded-lg px-3 py-2 focus:ring-2 focus:ring-purple-500"
                    disabled={dressEditForm.status !== 'booked'}
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Approval Status</label>
                <div className="flex items-center space-x-4">
                  <label className="flex items-center">
                    <input
                      type="radio"
                      name="is_approved"
                      value="true"
                      checked={dressEditForm.is_approved === true}
                      onChange={() => setDressEditForm(prev => ({ ...prev, is_approved: true }))}
                      className="mr-2"
                    />
                    Approved
                  </label>
                  <label className="flex items-center">
                    <input
                      type="radio"
                      name="is_approved"
                      value="false"
                      checked={dressEditForm.is_approved === false}
                      onChange={() => setDressEditForm(prev => ({ ...prev, is_approved: false }))}
                      className="mr-2"
                    />
                    Pending
                  </label>
                </div>
              </div>
            </div>

            <div className="flex space-x-3 mt-6">
              <button
                onClick={() => setShowDressEditModal(false)}
                className="flex-1 bg-gray-100 text-gray-700 py-2 rounded-lg hover:bg-gray-200 transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={saveDressChanges}
                disabled={updatingDress}
                className="flex-1 bg-purple-600 text-white py-2 rounded-lg hover:bg-purple-700 disabled:opacity-50 flex items-center justify-center transition-colors"
              >
                {updatingDress ? (
                  <>
                    <RefreshCw className="w-4 h-4 animate-spin mr-2" />
                    Saving...
                  </>
                ) : (
                  <>
                    <Save className="w-4 h-4 mr-2" />
                    Save Changes
                  </>
                )}
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );

  const renderOrderModal = () => (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl max-w-3xl w-full max-h-[90vh] overflow-y-auto">
        <div className="p-6 border-b border-gray-200 sticky top-0 bg-white flex items-center justify-between">
          <h2 className="text-xl font-bold text-gray-800">Order Details</h2>
          <button onClick={() => setShowOrderModal(false)} className="p-2 hover:bg-gray-100 rounded-lg">
            <X className="w-5 h-5 text-gray-500" />
          </button>
        </div>
        
        {selectedOrder && (
          <div className="p-6">
            {/* Order Header */}
            <div className="bg-purple-50 p-4 rounded-lg mb-6 flex justify-between items-center">
              <div>
                <p className="text-xs text-purple-600">Order ID</p>
                <p className="font-mono text-sm font-bold">{selectedOrder.id}</p>
              </div>
              <div className="text-right">
                <p className="text-xs text-purple-600">Date</p>
                <p className="text-sm">{formatDate(selectedOrder.created_at)}</p>
              </div>
            </div>

            {/* Customer Information */}
            <div className="mb-6">
              <h3 className="font-medium mb-3 flex items-center">
                <Users className="w-4 h-4 mr-2 text-purple-600" />
                Customer Information
              </h3>
              <div className="bg-gray-50 p-4 rounded-lg">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-xs text-gray-500">Name</p>
                    <p className="font-medium">{selectedOrder.customer_name}</p>
                  </div>
                  <div>
                    <p className="text-xs text-gray-500">Phone</p>
                    <p className="font-medium">{selectedOrder.contact_number}</p>
                  </div>
                  <div className="col-span-2">
                    <p className="text-xs text-gray-500">Delivery Address</p>
                    <p className="font-medium">{selectedOrder.delivery_address}</p>
                  </div>
                </div>
              </div>
            </div>

            {/* Order Items */}
            <div className="mb-6">
              <h3 className="font-medium mb-3 flex items-center">
                <Package className="w-4 h-4 mr-2 text-purple-600" />
                Order Items
              </h3>
              {selectedOrder.order_items?.map((item, idx) => (
                <div key={idx} className="bg-gray-50 p-4 rounded-lg mb-2">
                  <div className="flex justify-between items-start">
                    <div>
                      <p className="font-medium">{item.dress_name}</p>
                      <div className="flex items-center mt-1 space-x-3">
                        <span className="text-xs bg-gray-200 px-2 py-1 rounded-full">
                          Qty: {item.quantity || 1}
                        </span>
                        {item.is_rental && (
                          <span className="text-xs bg-orange-100 text-orange-700 px-2 py-1 rounded-full">
                            Rental • {item.rental_days} days
                          </span>
                        )}
                      </div>
                    </div>
                    <p className="font-medium text-purple-600">
                      Rs {Number(item.price).toLocaleString()}
                    </p>
                  </div>
                </div>
              ))}
            </div>

            {/* Payment Summary */}
            <div className="mb-6">
              <h3 className="font-medium mb-3 flex items-center">
                <DollarSign className="w-4 h-4 mr-2 text-purple-600" />
                Payment Summary
              </h3>
              <div className="bg-gray-50 p-4 rounded-lg">
                <div className="space-y-2">
                  <div className="flex justify-between">
                    <span className="text-gray-600">Subtotal</span>
                    <span className="font-medium">{formatCurrency(selectedOrder.subtotal)}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-600">Delivery Charges</span>
                    <span className="font-medium">{formatCurrency(selectedOrder.delivery_charges)}</span>
                  </div>
                  {selectedOrder.security_deposit > 0 && (
                    <div className="flex justify-between">
                      <span className="text-gray-600">Security Deposit</span>
                      <span className="font-medium text-orange-600">{formatCurrency(selectedOrder.security_deposit)}</span>
                    </div>
                  )}
                  <div className="border-t pt-2 mt-2">
                    <div className="flex justify-between font-bold">
                      <span>Total Amount</span>
                      <span className="text-purple-600 text-lg">{formatCurrency(selectedOrder.total_amount)}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Payment Status */}
            <div className="grid grid-cols-2 gap-4 mb-6">
              <div>
                <p className="text-xs text-gray-500 mb-1">Payment Method</p>
                <span className="capitalize px-3 py-1 bg-purple-100 text-purple-800 rounded-full text-xs font-medium">
                  {selectedOrder.payment_method}
                </span>
              </div>
              <div>
                <p className="text-xs text-gray-500 mb-1">Payment Status</p>
                <span className={`inline-flex px-3 py-1 rounded-full text-xs font-medium ${getStatusColor(selectedOrder.payment_status)}`}>
                  {selectedOrder.payment_method === 'cod' ? 'N/A' : selectedOrder.payment_status}
                </span>
              </div>
            </div>

            {/* Order Status Flow */}
            <div className="mt-4 p-4 bg-gray-50 rounded-lg">
              <h3 className="font-medium mb-2">Order Progress</h3>
              <div className="flex items-center justify-between text-xs">
                <div className="text-center">
                  <div className={`w-8 h-8 rounded-full mx-auto flex items-center justify-center ${
                    selectedOrder.payment_method === 'cod' || selectedOrder.payment_status === 'completed' ? 'bg-green-500' : 'bg-gray-300'
                  }`}>
                    <CheckCircle className="w-4 h-4 text-white" />
                  </div>
                  <p className="mt-1">Payment</p>
                </div>
                <div className="flex-1 h-0.5 bg-gray-300 mx-2"></div>
                <div className="text-center">
                  <div className={`w-8 h-8 rounded-full mx-auto flex items-center justify-center ${
                    selectedOrder.status === 'confirmed' ? 'bg-blue-500' : 'bg-gray-300'
                  }`}>
                    <Check className="w-4 h-4 text-white" />
                  </div>
                  <p className="mt-1">Confirmed</p>
                </div>
                <div className="flex-1 h-0.5 bg-gray-300 mx-2"></div>
                <div className="text-center">
                  <div className={`w-8 h-8 rounded-full mx-auto flex items-center justify-center ${
                    selectedOrder.status === 'assigned' ? 'bg-purple-500' : 'bg-gray-300'
                  }`}>
                    <Bike className="w-4 h-4 text-white" />
                  </div>
                  <p className="mt-1">Assigned</p>
                </div>
                <div className="flex-1 h-0.5 bg-gray-300 mx-2"></div>
                <div className="text-center">
                  <div className={`w-8 h-8 rounded-full mx-auto flex items-center justify-center ${
                    selectedOrder.status === 'picked' ? 'bg-indigo-500' : 'bg-gray-300'
                  }`}>
                    <Package className="w-4 h-4 text-white" />
                  </div>
                  <p className="mt-1">Picked</p>
                </div>
                <div className="flex-1 h-0.5 bg-gray-300 mx-2"></div>
                <div className="text-center">
                  <div className={`w-8 h-8 rounded-full mx-auto flex items-center justify-center ${
                    selectedOrder.status === 'delivered' ? 'bg-green-500' : 'bg-gray-300'
                  }`}>
                    <CheckCircle className="w-4 h-4 text-white" />
                  </div>
                  <p className="mt-1">Delivered</p>
                </div>
              </div>
            </div>

            {/* Assign Rider Section */}
            {(selectedOrder.status === 'confirmed' || (selectedOrder.payment_method === 'cod' && selectedOrder.status === 'pending')) && (
              <div className="mt-6 p-4 bg-purple-50 rounded-lg">
                <h3 className="font-medium mb-3 flex items-center">
                  <Bike className="w-5 h-5 mr-2 text-purple-600" />
                  Assign Delivery Rider
                </h3>
                
                {selectedOrder.payment_method === 'cod' && selectedOrder.status === 'pending' && (
                  <div className="mb-3 p-2 bg-yellow-100 text-yellow-800 text-sm rounded-lg">
                    COD order - Ready for delivery
                  </div>
                )}
                
                <select
                  onChange={(e) => {
                    if (e.target.value) {
                      if (window.confirm('Assign this order to the selected rider?')) {
                        assignDelivery(selectedOrder.id, e.target.value, false);
                      }
                    }
                  }}
                  className="w-full border rounded-lg px-3 py-2 mb-3 focus:ring-2 focus:ring-purple-500"
                  defaultValue=""
                >
                  <option value="" disabled>Select a rider</option>
                  {getAvailableRiders().map(rider => {
                    const activeDeliveries = deliveries.filter(d => 
                      d.rider_id === rider.id && d.status !== 'delivered' && d.status !== 'return_delivered'
                    ).length;
                    
                    return (
                      <option key={rider.id} value={rider.id}>
                        {rider.name} - {rider.vehicle_number} ({activeDeliveries} active) - {rider.city || 'City not set'}
                      </option>
                    );
                  })}
                </select>
                
                <p className="text-xs text-gray-600">
                  {getAvailableRiders().length} riders available
                </p>
              </div>
            )}

            {/* Return Delivery Section for Rental Orders */}
            {selectedOrder.order_type === 'rent' && selectedOrder.status === 'delivered' && (
              <div className="mt-6 p-4 bg-orange-50 rounded-lg">
                <h3 className="font-medium mb-3 flex items-center">
                  <RotateCcw className="w-5 h-5 mr-2 text-orange-600" />
                  Schedule Return Pickup
                </h3>
                
                <p className="text-sm text-orange-700 mb-3">
                  Return by: {formatDate(selectedOrder.rental_end_date)}
                </p>
                
                <select
                  onChange={(e) => {
                    if (e.target.value) {
                      if (window.confirm('Assign return pickup to selected rider?')) {
                        assignDelivery(selectedOrder.id, e.target.value, true);
                      }
                    }
                  }}
                  className="w-full border rounded-lg px-3 py-2 mb-3 focus:ring-2 focus:ring-orange-500"
                  defaultValue=""
                >
                  <option value="" disabled>Select a rider for return</option>
                  {getAvailableRiders().map(rider => (
                    <option key={rider.id} value={rider.id}>
                      {rider.name} - {rider.vehicle_number}
                    </option>
                  ))}
                </select>
              </div>
            )}

            {/* Quick Status Update Buttons */}
            {selectedOrder.status !== 'delivered' && selectedOrder.status !== 'cancelled' && (
              <div className="mt-6 p-4 bg-blue-50 rounded-lg">
                <h3 className="font-medium mb-3 flex items-center">
                  <RefreshCw className="w-4 h-4 mr-2 text-blue-600" />
                  Quick Status Update
                </h3>
                <div className="flex flex-wrap gap-2">
                  {selectedOrder.status === 'confirmed' && (
                    <button
                      onClick={() => {
                        if (window.confirm('Mark this order as Assigned?')) {
                          updateOrderStatus(selectedOrder.id, 'assigned');
                          setShowOrderModal(false);
                        }
                      }}
                      className="bg-purple-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-purple-700"
                    >
                      Mark as Assigned
                    </button>
                  )}
                  {selectedOrder.status === 'assigned' && (
                    <button
                      onClick={() => {
                        if (window.confirm('Mark this order as Picked?')) {
                          updateOrderStatus(selectedOrder.id, 'picked');
                          setShowOrderModal(false);
                        }
                      }}
                      className="bg-indigo-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-indigo-700"
                    >
                      Mark as Picked
                    </button>
                  )}
                  {selectedOrder.status === 'picked' && (
                    <button
                      onClick={() => {
                        if (window.confirm('Mark this order as Delivered?')) {
                          updateOrderStatus(selectedOrder.id, 'delivered');
                          setShowOrderModal(false);
                        }
                      }}
                      className="bg-green-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-green-700"
                    >
                      Mark as Delivered
                    </button>
                  )}
                </div>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );

  const renderReturnDeliveryModal = () => (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        <div className="p-6 border-b border-gray-200 sticky top-0 bg-white flex items-center justify-between">
          <h2 className="text-xl font-bold text-gray-800">Schedule Return Pickup</h2>
          <button onClick={() => setShowReturnDeliveryModal(false)} className="p-2 hover:bg-gray-100 rounded-lg">
            <X className="w-5 h-5 text-gray-500" />
          </button>
        </div>
        
        {selectedReturnDelivery && (
          <div className="p-6">
            <div className="bg-orange-50 p-4 rounded-lg mb-6">
              <p className="font-medium">Order #{selectedReturnDelivery.order_id?.substring(0, 8)}</p>
              <p className="text-sm text-gray-600 mt-1">Customer: {selectedReturnDelivery.orders?.customer_name}</p>
              <p className="text-sm text-orange-600 mt-2">Return by: {formatDate(selectedReturnDelivery.orders?.rental_end_date)}</p>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Select Rider for Return</label>
                <select
                  onChange={(e) => {
                    if (e.target.value) {
                      if (window.confirm('Assign return pickup to selected rider?')) {
                        assignDelivery(selectedReturnDelivery.order_id, e.target.value, true);
                      }
                    }
                  }}
                  className="w-full border rounded-lg px-3 py-2 focus:ring-2 focus:ring-orange-500"
                  defaultValue=""
                >
                  <option value="" disabled>Select a rider</option>
                  {getAvailableRiders().map(rider => (
                    <option key={rider.id} value={rider.id}>
                      {rider.name} - {rider.vehicle_number} - {rider.city || ''}
                    </option>
                  ))}
                </select>
              </div>

              <div className="bg-blue-50 p-3 rounded-lg">
                <p className="text-sm text-blue-700">
                  <Info className="w-4 h-4 inline mr-1" />
                  Rider will pick up the dress from customer and return to vendor
                </p>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );

  const renderVendorEarningsModal = () => (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl max-w-4xl w-full max-h-[90vh] overflow-y-auto">
        <div className="p-6 border-b border-gray-200 sticky top-0 bg-white flex items-center justify-between">
          <h2 className="text-xl font-bold text-gray-800">Vendor Earnings</h2>
          <button onClick={() => setShowVendorEarningsModal(false)} className="p-2 hover:bg-gray-100 rounded-lg">
            <X className="w-5 h-5 text-gray-500" />
          </button>
        </div>
        
        <div className="p-6">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-purple-50">
                <tr>
                  <th className="py-3 px-6 text-left text-xs font-semibold uppercase">Vendor</th>
                  <th className="py-3 px-6 text-left text-xs font-semibold uppercase">Order ID</th>
                  <th className="py-3 px-6 text-left text-xs font-semibold uppercase">Total</th>
                  <th className="py-3 px-6 text-left text-xs font-semibold uppercase">Commission (20%)</th>
                  <th className="py-3 px-6 text-left text-xs font-semibold uppercase">Vendor Payout</th>
                  <th className="py-3 px-6 text-left text-xs font-semibold uppercase">Status</th>
                  <th className="py-3 px-6 text-left text-xs font-semibold uppercase">Actions</th>
                </tr>
              </thead>
              <tbody>
                {vendorEarnings.map(earning => (
                  <tr key={earning.id} className="hover:bg-purple-50/50">
                    <td className="py-4 px-6">
                      <p className="font-medium">{earning.users?.business_name || earning.users?.full_name}</p>
                      <p className="text-xs text-gray-500">{earning.users?.email}</p>
                    </td>
                    <td className="py-4 px-6 font-mono text-sm">{earning.order_id.substring(0, 8)}...</td>
                    <td className="py-4 px-6">{formatCurrency(earning.total_amount)}</td>
                    <td className="py-4 px-6 text-orange-600">{formatCurrency(earning.admin_commission)}</td>
                    <td className="py-4 px-6 text-green-600 font-medium">{formatCurrency(earning.vendor_payout)}</td>
                    <td className="py-4 px-6">
                      <span className={`px-3 py-1 rounded-full text-xs font-medium ${
                        earning.status === 'paid' ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800'
                      }`}>
                        {earning.status}
                      </span>
                    </td>
                    <td className="py-4 px-6">
                      {earning.status === 'pending' && (
                        <button
                          onClick={() => markVendorEarningAsPaid(earning.id)}
                          className="bg-green-600 text-white px-3 py-1 rounded-lg text-sm hover:bg-green-700"
                        >
                          Mark Paid
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );

  const renderReviewsModal = () => (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl max-w-4xl w-full max-h-[90vh] overflow-y-auto">
        <div className="p-6 border-b border-gray-200 sticky top-0 bg-white flex items-center justify-between">
          <h2 className="text-xl font-bold text-gray-800">Customer Reviews</h2>
          <button onClick={() => setShowReviewsModal(false)} className="p-2 hover:bg-gray-100 rounded-lg">
            <X className="w-5 h-5 text-gray-500" />
          </button>
        </div>
        
        <div className="p-6">
          <div className="mb-6 flex items-center space-x-4">
            <div className="bg-purple-50 p-4 rounded-lg">
              <p className="text-sm text-gray-600">Average Rating</p>
              <p className="text-3xl font-bold text-purple-600">{stats.averageRating.toFixed(1)} ⭐</p>
            </div>
            <div className="bg-blue-50 p-4 rounded-lg">
              <p className="text-sm text-gray-600">Total Reviews</p>
              <p className="text-3xl font-bold text-blue-600">{stats.totalReviews}</p>
            </div>
          </div>

          <div className="space-y-4">
            {reviews.map(review => (
              <div key={review.id} className="border rounded-lg p-4 hover:shadow-md transition-shadow">
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center space-x-2">
                    <span className="font-medium">{review.users?.full_name}</span>
                    <span className="text-sm text-gray-500">•</span>
                    <span className="text-sm text-gray-500">{formatDate(review.created_at)}</span>
                  </div>
                  <div className="flex items-center">
                    {[...Array(5)].map((_, i) => (
                      <Star
                        key={i}
                        className={`w-4 h-4 ${i < review.rating ? 'text-yellow-400 fill-current' : 'text-gray-300'}`}
                      />
                    ))}
                  </div>
                </div>
                <p className="text-gray-700">{review.comment || review.review}</p>
                <p className="text-sm text-gray-500 mt-2">Vendor: {review.vendors?.business_name}</p>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );

  const renderRidersTable = () => (
    <div className="bg-white rounded-xl shadow-lg overflow-hidden">
      <div className="p-6 border-b flex justify-between items-center">
        <div>
          <h2 className="text-lg font-semibold">Rider Management</h2>
          <p className="text-sm text-gray-600 mt-1">
            {stats.activeRiders} active • {stats.inactiveRiders} inactive
          </p>
        </div>
        <button 
          onClick={() => setShowAddRiderModal(true)} 
          className="flex items-center space-x-2 bg-purple-600 text-white px-4 py-2 rounded-lg hover:bg-purple-700 transition-colors shadow-md"
        >
          <UserPlus className="w-4 h-4" />
          <span>Create New Rider</span>
        </button>
      </div>
      
      <div className="overflow-x-auto">
        <table className="w-full">
          <thead className="bg-purple-50">
            <tr>
              <th className="py-3 px-6 text-left text-xs font-semibold text-gray-600 uppercase">Rider</th>
              <th className="py-3 px-6 text-left text-xs font-semibold text-gray-600 uppercase">Contact</th>
              <th className="py-3 px-6 text-left text-xs font-semibold text-gray-600 uppercase">Vehicle</th>
              <th className="py-3 px-6 text-left text-xs font-semibold text-gray-600 uppercase">Service Area</th>
              <th className="py-3 px-6 text-left text-xs font-semibold text-gray-600 uppercase">Status</th>
              <th className="py-3 px-6 text-left text-xs font-semibold text-gray-600 uppercase">Performance</th>
              <th className="py-3 px-6 text-left text-xs font-semibold text-gray-600 uppercase">Earnings</th>
              <th className="py-3 px-6 text-left text-xs font-semibold text-gray-600 uppercase">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {riders.map(rider => {
              const performance = getRiderPerformance(rider.id);
              const earnings = calculateRiderEarnings(rider.id);
              
              return (
                <tr key={rider.id} className="hover:bg-purple-50/50 transition-colors">
                  <td className="py-4 px-6">
                    <div className="flex items-center space-x-3">
                      <div className="w-10 h-10 bg-gradient-to-br from-purple-500 to-purple-700 rounded-full flex items-center justify-center text-white font-semibold">
                        {rider.name?.charAt(0).toUpperCase()}
                      </div>
                      <div>
                        <p className="font-medium">{rider.name}</p>
                        <p className="text-xs text-gray-500">{rider.email}</p>
                      </div>
                    </div>
                   </td>
                  <td className="py-4 px-6">
                    <p className="text-sm">{rider.phone}</p>
                   </td>
                  <td className="py-4 px-6">
                    <p className="text-sm">{rider.vehicle_type}</p>
                    <p className="text-xs text-gray-500">{rider.vehicle_number}</p>
                   </td>
                  <td className="py-4 px-6">
                    <p className="text-sm font-medium">{rider.city || '-'}</p>
                    <p className="text-xs text-gray-500">{rider.service_area || '-'}</p>
                   </td>
                  <td className="py-4 px-6">
                    <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${
                      rider.is_active ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
                    }`}>
                      {rider.is_active ? 'Active' : 'Inactive'}
                    </span>
                   </td>
                  <td className="py-4 px-6">
                    <div className="space-y-1">
                      <div className="flex items-center text-xs">
                        <span className="text-gray-600 w-16">Deliveries:</span>
                        <span className="font-medium">{performance.completed}/{performance.total}</span>
                      </div>
                      <div className="flex items-center text-xs">
                        <span className="text-gray-600 w-16">Rate:</span>
                        <span className="font-medium">{performance.completionRate}%</span>
                      </div>
                    </div>
                   </td>
                  <td className="py-4 px-6">
                    <p className="font-medium text-green-600">Rs {earnings.total}</p>
                    <p className="text-xs text-gray-500">{earnings.count} deliveries</p>
                   </td>
                  <td className="py-4 px-6">
                    <div className="flex space-x-2">
                      <button 
                        onClick={() => viewRiderDetails(rider)}
                        className="p-2 text-purple-600 hover:bg-purple-50 rounded-lg"
                        title="View Details"
                      >
                        <Eye className="w-4 h-4" />
                      </button>
                      <button 
                        onClick={() => toggleRiderStatus(rider.id, rider.is_active)}
                        className={`p-2 ${
                          rider.is_active 
                            ? 'text-yellow-600 hover:bg-yellow-50' 
                            : 'text-green-600 hover:bg-green-50'
                        } rounded-lg`}
                        title={rider.is_active ? 'Deactivate' : 'Activate'}
                      >
                        {rider.is_active ? <UserMinus className="w-4 h-4" /> : <UserCheck className="w-4 h-4" />}
                      </button>
                      <button 
                        onClick={() => deleteRider(rider.id)} 
                        className="p-2 text-red-600 hover:bg-red-50 rounded-lg"
                        title="Delete"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                   </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );

  // ==================== MAIN RENDER ====================
  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-purple-50 via-white to-purple-50 flex items-center justify-center">
        <div className="text-center">
          <div className="relative">
            <div className="w-16 h-16 border-4 border-purple-200 border-t-purple-600 rounded-full animate-spin"></div>
            <div className="absolute inset-0 flex items-center justify-center">
              <Shield className="w-8 h-8 text-purple-600" />
            </div>
          </div>
          <p className="mt-4 text-gray-600 font-medium">Loading Admin Dashboard...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-50 via-white to-purple-50">
      {/* Debug Panel */}
      <div className="fixed top-20 right-4 z-50 bg-white shadow-xl rounded-lg p-3 max-w-xs border-l-4 border-purple-600 text-xs">
        <p className="font-bold text-purple-800">Debug Info</p>
        <p>Orders: <span className="font-mono">{debugInfo.ordersCount}</span></p>
        <p>Last Fetch: <span className="font-mono">{debugInfo.lastFetch || 'Never'}</span></p>
        {debugInfo.error && <p className="text-red-600">Error: {debugInfo.error}</p>}
        <button 
          onClick={fetchAllData} 
          className="mt-2 w-full bg-purple-600 text-white py-1 rounded-lg text-xs hover:bg-purple-700"
        >
          Refresh Data
        </button>
      </div>

      {/* Modals */}
      {showInspectionDetailsModal && renderInspectionDetailsModal()}
      {showAddRiderModal && renderAddRiderModal()}
      {showRiderCredentialsModal && renderCredentialsModal()}
      {showRiderModal && renderRiderDetailsModal()}
      {showDressEditModal && renderDressEditModal()}
      {showOrderModal && renderOrderModal()}
      {showReturnDeliveryModal && renderReturnDeliveryModal()}
      {showVendorEarningsModal && renderVendorEarningsModal()}
      {showReviewsModal && renderReviewsModal()}
      
      {/* Payment Approval Modal */}
      {showPaymentModal && selectedOrder && selectedOrder.payment_method !== 'cod' && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <div className="p-6 border-b border-purple-200 bg-purple-50">
              <div className="flex items-center justify-between">
                <h2 className="text-xl font-bold text-purple-800">Payment Verification</h2>
                <button onClick={() => setShowPaymentModal(false)} className="p-2 hover:bg-purple-100 rounded-lg">
                  <XCircle className="w-5 h-5 text-purple-600" />
                </button>
              </div>
            </div>
            
            <div className="p-6">
              <div className="bg-purple-50 p-4 rounded-lg mb-6">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-xs text-gray-500">Order ID</p>
                    <p className="font-mono text-sm text-purple-600">{selectedOrder.id}</p>
                  </div>
                  <div>
                    <p className="text-xs text-gray-500">Date</p>
                    <p className="text-sm">{formatDate(selectedOrder.created_at)}</p>
                  </div>
                  <div>
                    <p className="text-xs text-gray-500">Customer</p>
                    <p className="text-sm font-medium">{selectedOrder.customer_name}</p>
                  </div>
                  <div>
                    <p className="text-xs text-gray-500">Amount</p>
                    <p className="text-sm font-bold text-purple-600">{formatCurrency(selectedOrder.total_amount)}</p>
                  </div>
                </div>
              </div>

              {selectedOrder.payment_proof_url && (
                <div className="mb-6">
                  <h3 className="font-medium mb-3 text-purple-800">Payment Receipt</h3>
                  <img src={selectedOrder.payment_proof_url} alt="Receipt" className="w-full rounded-lg border border-purple-200" />
                </div>
              )}

              <div className="flex space-x-3">
                <button 
                  onClick={() => approvePayment(selectedOrder.id)} 
                  disabled={processingPayment}
                  className="flex-1 bg-green-600 text-white py-3 rounded-lg hover:bg-green-700 disabled:opacity-50 transition-colors"
                >
                  {processingPayment ? 'Processing...' : 'Approve Payment'}
                </button>
                <button 
                  onClick={() => rejectPayment(selectedOrder.id)} 
                  disabled={processingPayment}
                  className="flex-1 bg-red-600 text-white py-3 rounded-lg hover:bg-red-700 disabled:opacity-50 transition-colors"
                >
                  Reject
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* User Details Modal */}
      {showUserModal && selectedUser && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl max-w-lg w-full">
            <div className="p-6 border-b border-gray-200">
              <div className="flex items-center justify-between">
                <h2 className="text-xl font-bold text-gray-800">User Details</h2>
                <button onClick={() => setShowUserModal(false)} className="p-2 hover:bg-gray-100 rounded-lg">
                  <XCircle className="w-5 h-5 text-gray-500" />
                </button>
              </div>
            </div>
            
            <div className="p-6">
              <div className="flex items-center space-x-4 mb-6">
                <div className="w-16 h-16 bg-gradient-to-br from-purple-500 to-purple-700 rounded-full flex items-center justify-center text-white text-2xl font-bold">
                  {selectedUser.full_name?.charAt(0).toUpperCase() || 'U'}
                </div>
                <div>
                  <h3 className="text-lg font-bold">{selectedUser.full_name || 'No Name'}</h3>
                  <p className="text-gray-600">{selectedUser.email}</p>
                  <span className="inline-block mt-1 text-xs text-gray-500">ID: {selectedUser.id}</span>
                </div>
              </div>

              <div className="space-y-4">
                <div className="flex items-center space-x-3">
                  <Phone className="w-5 h-5 text-gray-400" />
                  <span>{selectedUser.phone || 'Not provided'}</span>
                </div>
                
                {selectedUser.role === 'vendor' && (
                  <>
                    <div className="flex items-center space-x-3">
                      <Store className="w-5 h-5 text-gray-400" />
                      <span>{selectedUser.business_name || 'Not provided'}</span>
                    </div>
                    <div className="flex items-center space-x-3">
                      <MapPin className="w-5 h-5 text-gray-400" />
                      <span>{selectedUser.business_address || 'Not provided'}</span>
                    </div>
                  </>
                )}

                <div className="flex items-center space-x-3">
                  <Calendar className="w-5 h-5 text-gray-400" />
                  <span>Joined {formatDate(selectedUser.created_at)}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Main Layout */}
      <nav className="bg-gradient-to-r from-purple-800 to-purple-900 shadow-lg fixed top-0 right-0 left-0 z-40">
        <div className="px-6 py-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-4">
              <button onClick={() => setSidebarCollapsed(!sidebarCollapsed)} className="p-2 rounded-lg hover:bg-purple-700 text-white">
                <div className="w-5 h-5">
                  <div className={`h-0.5 bg-yellow-400 mb-1 transition-all ${sidebarCollapsed ? 'w-3' : 'w-4'}`}></div>
                  <div className={`h-0.5 bg-yellow-400 mb-1 transition-all ${sidebarCollapsed ? 'w-4' : 'w-5'}`}></div>
                  <div className={`h-0.5 bg-yellow-400 transition-all ${sidebarCollapsed ? 'w-3' : 'w-4'}`}></div>
                </div>
              </button>
              
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-yellow-400 w-5 h-5" />
                <input 
                  type="text" 
                  placeholder="Search orders, users, dresses..." 
                  className="pl-10 pr-4 py-2 bg-purple-700 text-white placeholder-yellow-300 border border-purple-600 rounded-lg w-80 focus:ring-2 focus:ring-yellow-400 focus:border-transparent" 
                  value={searchTerm} 
                  onChange={(e) => setSearchTerm(e.target.value)} 
                />
              </div>
            </div>

            <div className="flex items-center space-x-4">
              <button className="relative p-2 rounded-full hover:bg-purple-700">
                <Bell className="w-5 h-5 text-yellow-400" />
                {notifications.filter(n => !n.is_read).length > 0 && (
                  <span className="absolute -top-1 -right-1 bg-yellow-400 text-purple-900 text-xs w-5 h-5 rounded-full flex items-center justify-center animate-pulse">
                    {notifications.filter(n => !n.is_read).length}
                  </span>
                )}
              </button>
              
              <div className="flex items-center space-x-3">
                <div className="w-8 h-8 bg-gradient-to-br from-yellow-400 to-yellow-500 rounded-full flex items-center justify-center text-purple-900 font-semibold">
                  A
                </div>
                <div>
                  <p className="text-sm font-medium text-white">Admin</p>
                  <p className="text-xs text-yellow-300">{user?.email}</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </nav>

      <div className="flex pt-16">
        {/* Sidebar */}
        <aside className={`bg-gradient-to-b from-purple-800 to-purple-900 transition-all duration-300 ${sidebarCollapsed ? 'w-20' : 'w-64'} fixed left-0 top-16 bottom-0 overflow-y-auto shadow-xl z-30`}>
          <div className="p-6">
            <nav className="space-y-1">
              <button onClick={() => setActiveTab("overview")} 
                className={`w-full flex items-center ${sidebarCollapsed ? 'justify-center' : ''} space-x-3 px-4 py-3 rounded-lg transition-all ${
                  activeTab === "overview" ? 'bg-yellow-400 text-purple-900' : 'text-yellow-200 hover:bg-purple-700'
                }`}>
                <Home className="w-5 h-5" />
                {!sidebarCollapsed && <span>Overview</span>}
              </button>

              <button onClick={() => setActiveTab("users")}
                className={`w-full flex items-center ${sidebarCollapsed ? 'justify-center' : ''} space-x-3 px-4 py-3 rounded-lg transition-all ${
                  activeTab === "users" ? 'bg-yellow-400 text-purple-900' : 'text-yellow-200 hover:bg-purple-700'
                }`}>
                <Users className="w-5 h-5" />
                {!sidebarCollapsed && (
                  <div className="flex items-center justify-between flex-1">
                    <span>Users</span>
                    <span className="bg-purple-700 text-yellow-200 text-xs px-2 py-1 rounded-full">
                      {stats.totalUsers}
                    </span>
                  </div>
                )}
              </button>

              <button onClick={() => setActiveTab("dresses")}
                className={`w-full flex items-center ${sidebarCollapsed ? 'justify-center' : ''} space-x-3 px-4 py-3 rounded-lg transition-all ${
                  activeTab === "dresses" ? 'bg-yellow-400 text-purple-900' : 'text-yellow-200 hover:bg-purple-700'
                }`}>
                <Shirt className="w-5 h-5" />
                {!sidebarCollapsed && (
                  <div className="flex items-center justify-between flex-1">
                    <span>Dresses</span>
                    <span className="bg-purple-700 text-yellow-200 text-xs px-2 py-1 rounded-full">
                      {stats.totalDresses}
                    </span>
                  </div>
                )}
              </button>

              <button onClick={() => setActiveTab("orders")}
                className={`w-full flex items-center ${sidebarCollapsed ? 'justify-center' : ''} space-x-3 px-4 py-3 rounded-lg transition-all ${
                  activeTab === "orders" ? 'bg-yellow-400 text-purple-900' : 'text-yellow-200 hover:bg-purple-700'
                }`}>
                <Package className="w-5 h-5" />
                {!sidebarCollapsed && (
                  <div className="flex items-center justify-between flex-1">
                    <span>Orders</span>
                    <span className="bg-purple-700 text-yellow-200 text-xs px-2 py-1 rounded-full">
                      {stats.totalOrders}
                    </span>
                  </div>
                )}
              </button>

              <button onClick={() => setActiveTab("payments")}
                className={`w-full flex items-center ${sidebarCollapsed ? 'justify-center' : ''} space-x-3 px-4 py-3 rounded-lg transition-all ${
                  activeTab === "payments" ? 'bg-yellow-400 text-purple-900' : 'text-yellow-200 hover:bg-purple-700'
                }`}>
                <CreditCard className="w-5 h-5" />
                {!sidebarCollapsed && (
                  <div className="flex items-center justify-between flex-1">
                    <span>Payments</span>
                    {stats.pendingPayments > 0 && (
                      <span className="bg-yellow-400 text-purple-900 text-xs px-2 py-1 rounded-full animate-pulse">
                        {stats.pendingPayments}
                      </span>
                    )}
                  </div>
                )}
              </button>

              <button onClick={() => setActiveTab("riders")}
                className={`w-full flex items-center ${sidebarCollapsed ? 'justify-center' : ''} space-x-3 px-4 py-3 rounded-lg transition-all ${
                  activeTab === "riders" ? 'bg-yellow-400 text-purple-900' : 'text-yellow-200 hover:bg-purple-700'
                }`}>
                <Bike className="w-5 h-5" />
                {!sidebarCollapsed && (
                  <div className="flex items-center justify-between flex-1">
                    <span>Riders</span>
                    <span className="bg-purple-700 text-yellow-200 text-xs px-2 py-1 rounded-full">
                      {stats.totalRiders}
                    </span>
                  </div>
                )}
              </button>

              <button onClick={() => setActiveTab("deliveries")}
                className={`w-full flex items-center ${sidebarCollapsed ? 'justify-center' : ''} space-x-3 px-4 py-3 rounded-lg transition-all ${
                  activeTab === "deliveries" ? 'bg-yellow-400 text-purple-900' : 'text-yellow-200 hover:bg-purple-700'
                }`}>
                <Truck className="w-5 h-5" />
                {!sidebarCollapsed && (
                  <div className="flex items-center justify-between flex-1">
                    <span>Deliveries</span>
                    <span className="bg-purple-700 text-yellow-200 text-xs px-2 py-1 rounded-full">
                      {stats.activeDeliveries}
                    </span>
                  </div>
                )}
              </button>

              <button onClick={() => setActiveTab("vendors")}
                className={`w-full flex items-center ${sidebarCollapsed ? 'justify-center' : ''} space-x-3 px-4 py-3 rounded-lg transition-all ${
                  activeTab === "vendors" ? 'bg-yellow-400 text-purple-900' : 'text-yellow-200 hover:bg-purple-700'
                }`}>
                <Store className="w-5 h-5" />
                {!sidebarCollapsed && (
                  <div className="flex items-center justify-between flex-1">
                    <span>Vendors</span>
                    <span className="bg-purple-700 text-yellow-200 text-xs px-2 py-1 rounded-full">
                      {stats.totalVendors}
                    </span>
                  </div>
                )}
              </button>

              <button onClick={() => setActiveTab("earnings")}
                className={`w-full flex items-center ${sidebarCollapsed ? 'justify-center' : ''} space-x-3 px-4 py-3 rounded-lg transition-all ${
                  activeTab === "earnings" ? 'bg-yellow-400 text-purple-900' : 'text-yellow-200 hover:bg-purple-700'
                }`}>
                <DollarIcon className="w-5 h-5" />
                {!sidebarCollapsed && <span>Earnings</span>}
              </button>

              <button onClick={() => setActiveTab("reviews")}
                className={`w-full flex items-center ${sidebarCollapsed ? 'justify-center' : ''} space-x-3 px-4 py-3 rounded-lg transition-all ${
                  activeTab === "reviews" ? 'bg-yellow-400 text-purple-900' : 'text-yellow-200 hover:bg-purple-700'
                }`}>
                <Star className="w-5 h-5" />
                {!sidebarCollapsed && <span>Reviews</span>}
              </button>

              <button onClick={() => setActiveTab("analytics")}
                className={`w-full flex items-center ${sidebarCollapsed ? 'justify-center' : ''} space-x-3 px-4 py-3 rounded-lg transition-all ${
                  activeTab === "analytics" ? 'bg-yellow-400 text-purple-900' : 'text-yellow-200 hover:bg-purple-700'
                }`}>
                <BarChart3 className="w-5 h-5" />
                {!sidebarCollapsed && <span>Analytics</span>}
              </button>

              <button onClick={() => setActiveTab("inspections")}
                className={`w-full flex items-center ${sidebarCollapsed ? 'justify-center' : ''} space-x-3 px-4 py-3 rounded-lg transition-all ${
                  activeTab === "inspections" ? 'bg-yellow-400 text-purple-900' : 'text-yellow-200 hover:bg-purple-700'
                }`}>
                <Camera className="w-5 h-5" />
                {!sidebarCollapsed && (
                  <div className="flex items-center justify-between flex-1">
                    <span>Inspections</span>
                    <span className="bg-purple-700 text-yellow-200 text-xs px-2 py-1 rounded-full">
                      {stats.pendingInspections}
                    </span>
                  </div>
                )}
              </button>
            </nav>

            <div className="mt-8 pt-8 border-t border-purple-700">
              <button onClick={async () => { await supabase.auth.signOut(); navigate("/admin"); }}
                className="w-full flex items-center space-x-3 px-4 py-3 text-yellow-200 hover:bg-purple-700 rounded-lg transition-all">
                <LogOut className="w-5 h-5" />
                {!sidebarCollapsed && <span>Logout</span>}
              </button>
            </div>
          </div>
        </aside>

        {/* Main Content */}
        <main className={`flex-1 transition-all duration-300 p-6 ${sidebarCollapsed ? 'ml-20' : 'ml-64'}`}>
          {/* Stats Summary */}
          <div className="mb-6 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
            <div className="bg-white rounded-xl shadow-lg p-4 border-l-4 border-purple-600">
              <p className="text-sm text-gray-600">Total Orders</p>
              <p className="text-2xl font-bold text-purple-600">{stats.totalOrders}</p>
              <div className="flex mt-2 space-x-2">
                <span className="text-xs bg-yellow-100 text-yellow-800 px-2 py-1 rounded-full">Pending: {stats.pendingOrders}</span>
                <span className="text-xs bg-green-100 text-green-800 px-2 py-1 rounded-full">Completed: {stats.completedOrders}</span>
              </div>
            </div>
            
            <div className="bg-white rounded-xl shadow-lg p-4 border-l-4 border-yellow-500">
              <p className="text-sm text-gray-600">Total Revenue</p>
              <p className="text-2xl font-bold text-green-600">{formatCurrency(stats.totalRevenue)}</p>
              <div className="flex mt-2">
                <span className="text-xs bg-orange-100 text-orange-800 px-2 py-1 rounded-full">Pending: {stats.pendingPayments}</span>
              </div>
            </div>
            
            <div className="bg-white rounded-xl shadow-lg p-4 border-l-4 border-purple-600">
              <p className="text-sm text-gray-600">Active Deliveries</p>
              <p className="text-2xl font-bold text-purple-600">{stats.activeDeliveries}</p>
              <p className="text-xs text-gray-500 mt-2">Returns: {stats.returnDeliveries}</p>
            </div>
            
            <div className="bg-white rounded-xl shadow-lg p-4 border-l-4 border-yellow-500">
              <p className="text-sm text-gray-600">Average Rating</p>
              <p className="text-2xl font-bold text-yellow-600">{stats.averageRating.toFixed(1)} ⭐</p>
              <p className="text-xs text-gray-500 mt-2">{stats.totalReviews} reviews</p>
            </div>

            <div className="bg-white rounded-xl shadow-lg p-4 border-l-4 border-purple-600">
              <p className="text-sm text-gray-600">Pending Inspections</p>
              <p className="text-2xl font-bold text-purple-600">{stats.pendingInspections}</p>
              <p className="text-xs text-gray-500 mt-2">Completed: {stats.completedInspections} | Rejected: {stats.rejectedInspections}</p>
            </div>
          </div>

          {loadingData ? (
            <div className="flex justify-center py-20">
              <RefreshCw className="w-8 h-8 text-purple-600 animate-spin" />
            </div>
          ) : (
            <>
              {/* Overview Tab */}
              {activeTab === "overview" && (
                <div className="space-y-6">
                  <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                    <div className="bg-gradient-to-br from-purple-600 to-purple-700 rounded-xl shadow-lg p-6 text-white">
                      <Crown className="w-8 h-8 mb-3 text-yellow-400" />
                      <p className="text-3xl font-bold">{stats.totalOrders}</p>
                      <p className="text-sm opacity-90">Total Orders</p>
                      <p className="text-xs mt-2 text-yellow-300">Pending: {stats.pendingOrders}</p>
                    </div>
                    
                    <div className="bg-gradient-to-br from-purple-600 to-purple-700 rounded-xl shadow-lg p-6 text-white">
                      <Users className="w-8 h-8 mb-3 text-yellow-400" />
                      <p className="text-3xl font-bold">{stats.totalUsers}</p>
                      <p className="text-sm opacity-90">Total Users</p>
                      <p className="text-xs mt-2 text-yellow-300">Vendors: {stats.totalVendors}</p>
                    </div>
                    
                    <div className="bg-gradient-to-br from-purple-600 to-purple-700 rounded-xl shadow-lg p-6 text-white">
                      <DollarSign className="w-8 h-8 mb-3 text-yellow-400" />
                      <p className="text-3xl font-bold">{formatCurrency(stats.totalRevenue)}</p>
                      <p className="text-sm opacity-90">Total Revenue</p>
                      <p className="text-xs mt-2 text-yellow-300">Pending: {stats.pendingPayments}</p>
                    </div>
                  </div>

                  {/* Recent Orders */}
                  <div className="bg-white rounded-xl shadow-lg p-6">
                    <h3 className="text-lg font-semibold mb-4 text-purple-800">Recent Orders</h3>
                    <div className="overflow-x-auto">
                      <table className="w-full">
                        <thead className="bg-purple-50">
                          <tr>
                            <th className="py-3 px-4 text-left text-xs font-semibold text-purple-800 uppercase">Order ID</th>
                            <th className="py-3 px-4 text-left text-xs font-semibold text-purple-800 uppercase">Customer</th>
                            <th className="py-3 px-4 text-left text-xs font-semibold text-purple-800 uppercase">Amount</th>
                            <th className="py-3 px-4 text-left text-xs font-semibold text-purple-800 uppercase">Payment</th>
                            <th className="py-3 px-4 text-left text-xs font-semibold text-purple-800 uppercase">Status</th>
                          </tr>
                        </thead>
                        <tbody>
                          {orders.slice(0, 5).map(order => (
                            <tr key={order.id} className="border-b hover:bg-purple-50/50">
                              <td className="py-3 px-4 font-mono text-sm text-purple-600">{order.id.substring(0, 8)}...</td>
                              <td className="py-3 px-4 font-medium">{order.customer_name}</td>
                              <td className="py-3 px-4 font-medium text-green-600">{formatCurrency(order.total_amount)}</td>
                              <td className="py-3 px-4">
                                {order.payment_method === 'cod' ? (
                                  <span className="px-2 py-1 rounded-full text-xs bg-green-100 text-green-800">COD</span>
                                ) : (
                                  <span className={`px-2 py-1 rounded-full text-xs ${getStatusColor(order.payment_status)}`}>
                                    {order.payment_status}
                                  </span>
                                )}
                              </td>
                              <td className="py-3 px-4">
                                <span className={`px-2 py-1 rounded-full text-xs ${getStatusColor(order.status)}`}>
                                  {order.status}
                                </span>
                              </td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  </div>
                </div>
              )}

              {/* Orders Tab */}
              {activeTab === "orders" && (
                <div className="bg-white rounded-xl shadow-lg overflow-hidden">
                  <div className="p-6 border-b border-purple-200 bg-purple-50">
                    <h2 className="text-lg font-semibold text-purple-800">All Orders ({stats.totalOrders})</h2>
                  </div>
                  <div className="overflow-x-auto">
                    <table className="w-full">
                      <thead className="bg-purple-100">
                        <tr>
                          <th className="py-3 px-6 text-left text-xs font-semibold text-purple-800 uppercase">Order ID</th>
                          <th className="py-3 px-6 text-left text-xs font-semibold text-purple-800 uppercase">Customer</th>
                          <th className="py-3 px-6 text-left text-xs font-semibold text-purple-800 uppercase">Type</th>
                          <th className="py-3 px-6 text-left text-xs font-semibold text-purple-800 uppercase">Amount</th>
                          <th className="py-3 px-6 text-left text-xs font-semibold text-purple-800 uppercase">Payment</th>
                          <th className="py-3 px-6 text-left text-xs font-semibold text-purple-800 uppercase">Status</th>
                          <th className="py-3 px-6 text-left text-xs font-semibold text-purple-800 uppercase">Sync</th>
                          <th className="py-3 px-6 text-left text-xs font-semibold text-purple-800 uppercase">Date</th>
                          <th className="py-3 px-6 text-left text-xs font-semibold text-purple-800 uppercase">Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {orders.map(order => {
                          const delivery = deliveries.find(d => d.order_id === order.id);
                          const isSynced = delivery?.status === order.status || 
                            (order.status === 'confirmed' && !delivery) ||
                            (order.status === 'delivered' && delivery?.status === 'delivered');
                          
                          return (
                            <tr key={order.id} className="hover:bg-purple-50/50 border-b">
                              <td className="py-4 px-6 font-mono text-sm text-purple-600">{order.id.substring(0, 8)}...</td>
                              <td className="py-4 px-6">
                                <p className="font-medium">{order.customer_name}</p>
                                <p className="text-xs text-gray-500">{order.contact_number}</p>
                              </td>
                              <td className="py-4 px-6">
                                <span className={`px-3 py-1 rounded-full text-xs font-medium ${
                                  order.order_type === 'purchase' 
                                    ? 'bg-green-100 text-green-800' 
                                    : 'bg-orange-100 text-orange-800'
                                }`}>
                                  {order.order_type}
                                </span>
                              </td>
                              <td className="py-4 px-6 font-medium text-green-600">{formatCurrency(order.total_amount)}</td>
                              <td className="py-4 px-6">
                                {order.payment_method === 'cod' ? (
                                  <span className="px-3 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">COD</span>
                                ) : (
                                  <span className={`px-3 py-1 rounded-full text-xs font-medium ${getStatusColor(order.payment_status)}`}>
                                    {order.payment_status}
                                  </span>
                                )}
                              </td>
                              <td className="py-4 px-6">
                                <div className="flex flex-col space-y-1">
                                  <span className={`px-3 py-1 rounded-full text-xs font-medium ${getStatusColor(order.status)}`}>
                                    {order.status}
                                  </span>
                                  {/* Quick Status Update Buttons */}
                                  {order.status === 'confirmed' && (
                                    <button
                                      onClick={() => updateOrderStatus(order.id, 'assigned')}
                                      className="text-xs bg-purple-100 text-purple-700 px-2 py-0.5 rounded hover:bg-purple-200"
                                    >
                                      Assign
                                    </button>
                                  )}
                                  {order.status === 'assigned' && (
                                    <button
                                      onClick={() => updateOrderStatus(order.id, 'picked')}
                                      className="text-xs bg-blue-100 text-blue-700 px-2 py-0.5 rounded hover:bg-blue-200"
                                    >
                                      Mark Picked
                                    </button>
                                  )}
                                  {order.status === 'picked' && (
                                    <button
                                      onClick={() => updateOrderStatus(order.id, 'delivered')}
                                      className="text-xs bg-green-100 text-green-700 px-2 py-0.5 rounded hover:bg-green-200"
                                    >
                                      Mark Delivered
                                    </button>
                                  )}
                                </div>
                              </td>
                              <td className="py-4 px-6">
                                <div className="flex items-center space-x-1">
                                  {isSynced ? (
                                    <CheckCircle className="w-4 h-4 text-green-500" />
                                  ) : (
                                    <AlertCircle className="w-4 h-4 text-yellow-500" />
                                  )}
                                  <span className="text-xs text-gray-500">
                                    {isSynced ? 'Synced' : 'Pending Sync'}
                                  </span>
                                </div>
                              </td>
                              <td className="py-4 px-6 text-sm text-gray-600">{formatDate(order.created_at)}</td>
                              <td className="py-4 px-6">
                                <div className="flex space-x-2">
                                  <button 
                                    onClick={() => {
                                      setSelectedOrder(order);
                                      setShowOrderModal(true);
                                    }}
                                    className="p-2 text-purple-600 hover:bg-purple-100 rounded-lg"
                                    title="View Details"
                                  >
                                    <Eye className="w-4 h-4" />
                                  </button>
                                  {order.payment_method !== 'cod' && order.payment_status === 'awaiting_verification' && (
                                    <button 
                                      onClick={() => {
                                        setSelectedOrder(order);
                                        setShowPaymentModal(true);
                                      }}
                                      className="p-2 text-green-600 hover:bg-green-100 rounded-lg"
                                      title="Verify Payment"
                                    >
                                      <CreditCard className="w-4 h-4" />
                                    </button>
                                  )}
                                  {order.order_type === 'rent' && order.status === 'delivered' && (
                                    <button 
                                      onClick={() => {
                                        setSelectedReturnDelivery({ order_id: order.id, orders: order });
                                        setShowReturnDeliveryModal(true);
                                      }}
                                      className="p-2 text-orange-600 hover:bg-orange-100 rounded-lg"
                                      title="Schedule Return"
                                    >
                                      <RotateCcw className="w-4 h-4" />
                                    </button>
                                  )}
                                </div>
                              </td>
                            </tr>
                          );
                        })}
                      </tbody>
                    </table>
                  </div>
                </div>
              )}

              {/* Deliveries Tab */}
              {activeTab === "deliveries" && (
                <div className="bg-white rounded-xl shadow-lg overflow-hidden">
                  <div className="p-6 border-b">
                    <h2 className="text-lg font-semibold">Delivery Management</h2>
                  </div>
                  <div className="overflow-x-auto">
                    <table className="w-full">
                      <thead className="bg-blue-50">
                        <tr>
                          <th className="py-3 px-6 text-left text-xs font-semibold uppercase">Type</th>
                          <th className="py-3 px-6 text-left text-xs font-semibold uppercase">Order</th>
                          <th className="py-3 px-6 text-left text-xs font-semibold uppercase">Customer</th>
                          <th className="py-3 px-6 text-left text-xs font-semibold uppercase">Rider</th>
                          <th className="py-3 px-6 text-left text-xs font-semibold uppercase">Status</th>
                          <th className="py-3 px-6 text-left text-xs font-semibold uppercase">Order Sync</th>
                          <th className="py-3 px-6 text-left text-xs font-semibold uppercase">Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {deliveries.map(delivery => {
                          const isReturn = delivery.status?.startsWith('return_');
                          const orderStatus = delivery.orders?.status;
                          const isSynced = 
                            (delivery.status === 'assigned' && orderStatus === 'assigned') ||
                            (delivery.status === 'picked' && orderStatus === 'picked') ||
                            (delivery.status === 'delivered' && orderStatus === 'delivered') ||
                            (delivery.status === 'return_assigned' && orderStatus === 'return_assigned') ||
                            (delivery.status === 'return_picked' && orderStatus === 'return_picked') ||
                            (delivery.status === 'return_delivered' && orderStatus === 'completed');
                          
                          return (
                            <tr key={delivery.id} className="hover:bg-blue-50/50">
                              <td className="py-4 px-6">
                                {isReturn ? (
                                  <span className="bg-orange-100 text-orange-800 px-2 py-1 rounded-full text-xs font-medium">
                                    RETURN
                                  </span>
                                ) : (
                                  <span className="bg-blue-100 text-blue-800 px-2 py-1 rounded-full text-xs font-medium">
                                    DELIVERY
                                  </span>
                                )}
                              </td>
                              <td className="py-4 px-6 font-mono text-sm">{delivery.order_id?.substring(0, 8)}...</td>
                              <td className="py-4 px-6">{delivery.orders?.customer_name}</td>
                              <td className="py-4 px-6">{delivery.riders?.name || 'Unassigned'}</td>
                              <td className="py-4 px-6">
                                <div className="flex items-center space-x-2">
                                  <select 
                                    value={delivery.status} 
                                    onChange={(e) => updateDeliveryStatus(delivery.id, e.target.value)}
                                    className="border rounded-lg px-2 py-1 text-sm focus:ring-2 focus:ring-purple-500"
                                    disabled={updatingDeliveryStatus}
                                  >
                                    {isReturn ? (
                                      <>
                                        <option value="return_assigned">📦 Return Assigned</option>
                                        <option value="return_picked">🏍️ Return Picked</option>
                                        <option value="return_delivered">✅ Return Delivered</option>
                                      </>
                                    ) : (
                                      <>
                                        <option value="assigned">📦 Assigned</option>
                                        <option value="picked">🏍️ Picked</option>
                                        <option value="delivered">✅ Delivered</option>
                                      </>
                                    )}
                                  </select>
                                  {updatingDeliveryStatus && (
                                    <RefreshCw className="w-3 h-3 text-purple-600 animate-spin" />
                                  )}
                                </div>
                              </td>
                              <td className="py-4 px-6">
                                <div className="flex items-center space-x-1">
                                  {isSynced ? (
                                    <CheckCircle className="w-4 h-4 text-green-500" />
                                  ) : (
                                    <RefreshCw className="w-4 h-4 text-yellow-500 animate-pulse" />
                                  )}
                                  <span className="text-xs text-gray-500">
                                    {isSynced ? 'Synced' : 'Syncing...'}
                                  </span>
                                </div>
                              </td>
                              <td className="py-4 px-6">
                                <button 
                                  onClick={() => {
                                    if (delivery.orders) {
                                      setSelectedOrder(delivery.orders);
                                      setShowOrderModal(true);
                                    }
                                  }}
                                  className="text-purple-600 hover:text-purple-800 text-sm flex items-center"
                                >
                                  <Eye className="w-4 h-4 mr-1" /> View Order
                                </button>
                               </td>
                             </tr>
                          );
                        })}
                      </tbody>
                    </table>
                  </div>
                </div>
              )}

              {/* Rest of the tabs remain same as previous code */}
              {/* Payments Tab */}
              {activeTab === "payments" && (
                <div className="bg-white rounded-xl shadow-lg overflow-hidden">
                  <div className="p-6 border-b border-purple-200 bg-purple-50">
                    <h2 className="text-lg font-semibold text-purple-800">Pending Payments ({stats.pendingPayments})</h2>
                  </div>
                  <div className="overflow-x-auto">
                    <table className="w-full">
                      <thead className="bg-purple-100">
                        <tr>
                          <th className="py-3 px-6 text-left text-xs font-semibold text-purple-800 uppercase">Order ID</th>
                          <th className="py-3 px-6 text-left text-xs font-semibold text-purple-800 uppercase">Customer</th>
                          <th className="py-3 px-6 text-left text-xs font-semibold text-purple-800 uppercase">Amount</th>
                          <th className="py-3 px-6 text-left text-xs font-semibold text-purple-800 uppercase">Method</th>
                          <th className="py-3 px-6 text-left text-xs font-semibold text-purple-800 uppercase">Status</th>
                          <th className="py-3 px-6 text-left text-xs font-semibold text-purple-800 uppercase">Receipt</th>
                          <th className="py-3 px-6 text-left text-xs font-semibold text-purple-800 uppercase">Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {orders
                          .filter(o => o.payment_method !== 'cod' && (o.payment_status === 'awaiting_verification' || o.payment_status === 'pending'))
                          .map(order => (
                          <tr key={order.id} className="hover:bg-purple-50/50 border-b">
                            <td className="py-4 px-6 font-mono text-sm text-purple-600">{order.id.substring(0, 8)}...</td>
                            <td className="py-4 px-6">
                              <p className="font-medium">{order.customer_name}</p>
                              <p className="text-xs text-gray-500">{order.contact_number}</p>
                            </td>
                            <td className="py-4 px-6 font-medium text-green-600">{formatCurrency(order.total_amount)}</td>
                            <td className="py-4 px-6 capitalize text-gray-700">{order.payment_method}</td>
                            <td className="py-4 px-6">
                              <span className={`px-3 py-1 rounded-full text-xs font-medium ${getStatusColor(order.payment_status)}`}>
                                {order.payment_status}
                              </span>
                            </td>
                            <td className="py-4 px-6">
                              {order.payment_proof_url ? (
                                <a 
                                  href={order.payment_proof_url} 
                                  target="_blank" 
                                  rel="noopener noreferrer"
                                  className="text-purple-600 hover:text-purple-800 text-sm flex items-center"
                                >
                                  <Eye className="w-4 h-4 mr-1" /> View
                                </a>
                              ) : (
                                <span className="text-gray-400">No receipt</span>
                              )}
                            </td>
                            <td className="py-4 px-6">
                              <button 
                                onClick={() => {
                                  setSelectedOrder(order);
                                  setShowPaymentModal(true);
                                }}
                                className="px-4 py-2 bg-yellow-400 text-purple-900 rounded-lg hover:bg-yellow-500 text-sm font-medium"
                              >
                                Verify Payment
                              </button>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>
              )}

              {/* Riders Tab */}
              {activeTab === "riders" && renderRidersTable()}

              {/* Inspections Tab */}
              {activeTab === "inspections" && (
                <div className="bg-white rounded-xl shadow-lg overflow-hidden">
                  <div className="p-6 border-b border-purple-200 bg-purple-50">
                    <h2 className="text-lg font-semibold text-purple-800">Return Inspections</h2>
                    <p className="text-sm text-gray-600 mt-1">Pending: {stats.pendingInspections} | Completed: {stats.completedInspections} | Rejected: {stats.rejectedInspections}</p>
                  </div>
                  <div className="overflow-x-auto">
                    <table className="w-full">
                      <thead className="bg-purple-100">
                        <tr>
                          <th className="py-3 px-6 text-left text-xs font-semibold text-purple-800 uppercase">Order ID</th>
                          <th className="py-3 px-6 text-left text-xs font-semibold text-purple-800 uppercase">Customer</th>
                          <th className="py-3 px-6 text-left text-xs font-semibold text-purple-800 uppercase">Status</th>
                          <th className="py-3 px-6 text-left text-xs font-semibold text-purple-800 uppercase">Inspection Status</th>
                          <th className="py-3 px-6 text-left text-xs font-semibold text-purple-800 uppercase">Photos</th>
                          <th className="py-3 px-6 text-left text-xs font-semibold text-purple-800 uppercase">Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {returnRequests.map(request => {
                          const order = request.orders;
                          const photos = request.inspection_photos || [];
                          return (
                            <tr key={request.id} className="hover:bg-purple-50/50 border-b">
                              <td className="py-4 px-6 font-mono text-sm text-purple-600">{order?.id?.substring(0, 8)}...</td>
                              <td className="py-4 px-6">
                                <p className="font-medium">{order?.customer_name}</p>
                                <p className="text-xs text-gray-500">{order?.contact_number}</p>
                              </td>
                              <td className="py-4 px-6">
                                <span className={`px-3 py-1 rounded-full text-xs font-medium ${getStatusColor(request.return_status)}`}>
                                  {request.return_status?.toUpperCase()}
                                </span>
                              </td>
                              <td className="py-4 px-6">
                                <span className={`px-3 py-1 rounded-full text-xs font-medium ${request.inspection_status === 'accepted' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}`}>
                                  {request.inspection_status === 'accepted' ? 'ACCEPTED' : request.inspection_status === 'rejected' ? 'REJECTED' : 'PENDING'}
                                </span>
                              </td>
                              <td className="py-4 px-6">
                                {photos.length > 0 ? (
                                  <div className="flex items-center">
                                    <Camera className="w-4 h-4 text-purple-600 mr-1" />
                                    <span className="text-sm">{photos.length} photo(s)</span>
                                  </div>
                                ) : (
                                  <span className="text-gray-400">No photos</span>
                                )}
                              </td>
                              <td className="py-4 px-6">
                                <button 
                                  onClick={() => viewInspectionDetails(request)}
                                  className="p-2 text-purple-600 hover:bg-purple-100 rounded-lg"
                                  title="View Inspection Details"
                                >
                                  <Eye className="w-4 h-4" />
                                </button>
                              </td>
                            </tr>
                          );
                        })}
                      </tbody>
                    </table>
                  </div>
                </div>
              )}

              {/* Vendors Tab */}
              {activeTab === "vendors" && (
                <div className="bg-white rounded-xl shadow-lg overflow-hidden">
                  <div className="p-6 border-b">
                    <h2 className="text-lg font-semibold">Vendor Management</h2>
                  </div>
                  <div className="overflow-x-auto">
                    <table className="w-full">
                      <thead className="bg-purple-50">
                        <tr>
                          <th className="py-3 px-6 text-left text-xs font-semibold uppercase">Vendor</th>
                          <th className="py-3 px-6 text-left text-xs font-semibold uppercase">Business</th>
                          <th className="py-3 px-6 text-left text-xs font-semibold uppercase">Dresses</th>
                          <th className="py-3 px-6 text-left text-xs font-semibold uppercase">Orders</th>
                          <th className="py-3 px-6 text-left text-xs font-semibold uppercase">Earnings</th>
                          <th className="py-3 px-6 text-left text-xs font-semibold uppercase">Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {vendors.map(vendor => {
                          const vendorDresses = dresses.filter(d => d.vendor_id === vendor.id);
                          const vendorOrders = orders.filter(o => o.vendor_id === vendor.id);
                          const vendorEarningsTotal = vendorEarnings
                            .filter(e => e.vendor_id === vendor.id)
                            .reduce((sum, e) => sum + e.vendor_payout, 0);
                          
                          return (
                            <tr key={vendor.id} className="hover:bg-purple-50/50">
                              <td className="py-4 px-6">
                                <div className="flex items-center space-x-3">
                                  <div className="w-10 h-10 bg-purple-100 rounded-full flex items-center justify-center">
                                    <Store className="w-5 h-5 text-purple-600" />
                                  </div>
                                  <div>
                                    <p className="font-medium">{vendor.full_name}</p>
                                    <p className="text-xs text-gray-500">{vendor.email}</p>
                                  </div>
                                </div>
                              </td>
                              <td className="py-4 px-6">
                                <p className="font-medium">{vendor.business_name}</p>
                                <p className="text-xs text-gray-500">{vendor.phone}</p>
                              </td>
                              <td className="py-4 px-6">
                                <span className="bg-purple-100 text-purple-800 px-3 py-1 rounded-full text-xs">
                                  {vendorDresses.length} dresses
                                </span>
                                <div className="mt-1">
                                  <span className="text-xs text-green-600">{vendorDresses.filter(d => d.status === 'available').length} available</span>
                                  <span className="text-xs text-orange-600 ml-2">{vendorDresses.filter(d => d.status === 'booked').length} booked</span>
                                </div>
                              </td>
                              <td className="py-4 px-6">
                                <span className="bg-blue-100 text-blue-800 px-3 py-1 rounded-full text-xs">
                                  {vendorOrders.length} orders
                                </span>
                              </td>
                              <td className="py-4 px-6">
                                <p className="font-medium text-green-600">{formatCurrency(vendorEarningsTotal)}</p>
                              </td>
                              <td className="py-4 px-6">
                                <button 
                                  onClick={() => {
                                    setSelectedVendor(vendor);
                                  }}
                                  className="p-2 text-purple-600 hover:bg-purple-50 rounded-lg"
                                >
                                  <Eye className="w-4 h-4" />
                                </button>
                              </td>
                            </tr>
                          );
                        })}
                      </tbody>
                    </table>
                  </div>
                </div>
              )}

              {/* Dresses Tab */}
              {activeTab === "dresses" && (
                <div className="bg-white rounded-xl shadow-lg overflow-hidden">
                  <div className="p-6 border-b">
                    <h2 className="text-lg font-semibold">Dress Catalog</h2>
                  </div>
                  <div className="overflow-x-auto">
                    <table className="w-full">
                      <thead className="bg-purple-50">
                        <tr>
                          <th className="py-3 px-6 text-left text-xs font-semibold uppercase">Image</th>
                          <th className="py-3 px-6 text-left text-xs font-semibold uppercase">Name</th>
                          <th className="py-3 px-6 text-left text-xs font-semibold uppercase">Vendor</th>
                          <th className="py-3 px-6 text-left text-xs font-semibold uppercase">Price</th>
                          <th className="py-3 px-6 text-left text-xs font-semibold uppercase">Status</th>
                          <th className="py-3 px-6 text-left text-xs font-semibold uppercase">Approval</th>
                          <th className="py-3 px-6 text-left text-xs font-semibold uppercase">Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {dresses.map(dress => {
                          const statusBadge = getDressStatusBadge(dress);
                          return (
                            <tr key={dress.id} className="hover:bg-purple-50/50">
                              <td className="py-4 px-6">
                                <div className="w-16 h-16 bg-gray-100 rounded-lg overflow-hidden relative">
                                  {getDressImages(dress).length > 0 ? (
                                    <img src={getDressImages(dress)[imageIndices[dress.id] || 0]} alt={dress.name} className="w-full h-full object-cover" />
                                  ) : (
                                    <ImageIcon className="w-8 h-8 text-gray-400 m-4" />
                                  )}
                                  {getDressImages(dress).length > 1 && (
                                    <>
                                      <button
                                        onClick={(e) => { e.stopPropagation(); navigateImage(dress.id, 'prev'); }}
                                        className="absolute left-0 top-1/2 transform -translate-y-1/2 bg-black/50 text-white p-1 rounded-r"
                                      >
                                        <ChevronLeft className="w-3 h-3" />
                                      </button>
                                      <button
                                        onClick={(e) => { e.stopPropagation(); navigateImage(dress.id, 'next'); }}
                                        className="absolute right-0 top-1/2 transform -translate-y-1/2 bg-black/50 text-white p-1 rounded-l"
                                      >
                                        <ChevronRight className="w-3 h-3" />
                                      </button>
                                    </>
                                  )}
                                </div>
                              </td>
                              <td className="py-4 px-6">
                                <p className="font-medium">{dress.name}</p>
                                <p className="text-xs text-gray-500">ID: {dress.id.substring(0, 8)}</p>
                              </td>
                              <td className="py-4 px-6">
                                <p className="text-sm">{dress.vendor?.business_name || 'Unknown'}</p>
                                <p className="text-xs text-gray-500">{dress.vendor?.email}</p>
                              </td>
                              <td className="py-4 px-6">
                                <p className="font-medium">{formatCurrency(dress.price)}</p>
                                {dress.rental_price && (
                                  <p className="text-xs text-orange-600">Rent: {formatCurrency(dress.rental_price)}/day</p>
                                )}
                              </td>
                              <td className="py-4 px-6">
                                <span className={`inline-flex px-3 py-1 rounded-full text-xs font-medium ${statusBadge.color}`}>
                                  {statusBadge.text}
                                </span>
                                {dress.status === 'booked' && dress.available_after && (
                                  <p className="text-xs text-gray-500 mt-1">
                                    Available: {formatDate(dress.available_after).split(',')[0]}
                                  </p>
                                )}
                              </td>
                              <td className="py-4 px-6">
                                <span className={`px-3 py-1 rounded-full text-xs font-medium ${
                                  dress.is_approved ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800'
                                }`}>
                                  {dress.is_approved ? 'Approved' : 'Pending'}
                                </span>
                              </td>
                              <td className="py-4 px-6">
                                <div className="flex space-x-2">
                                  <button 
                                    onClick={() => openDressEditModal(dress)}
                                    className="p-2 text-purple-600 hover:bg-purple-50 rounded-lg"
                                    title="Edit Dress"
                                  >
                                    <Edit className="w-4 h-4" />
                                  </button>
                                  <button 
                                    onClick={() => toggleDressApproval(dress.id, dress.is_approved)}
                                    className={`p-2 ${
                                      dress.is_approved 
                                        ? 'text-yellow-600 hover:bg-yellow-50' 
                                        : 'text-green-600 hover:bg-green-50'
                                    } rounded-lg`}
                                    title={dress.is_approved ? 'Unapprove' : 'Approve'}
                                  >
                                    {dress.is_approved ? <XCircle className="w-4 h-4" /> : <CheckCircle className="w-4 h-4" />}
                                  </button>
                                  <button 
                                    onClick={() => deleteDress(dress.id)} 
                                    className="p-2 text-red-600 hover:bg-red-50 rounded-lg"
                                    title="Delete Dress"
                                  >
                                    <Trash2 className="w-4 h-4" />
                                  </button>
                                </div>
                              </td>
                            </tr>
                          );
                        })}
                      </tbody>
                    </table>
                  </div>
                </div>
              )}

              {/* Earnings Tab */}
              {activeTab === "earnings" && (
                <div className="space-y-6">
                  <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                    <div className="bg-white rounded-xl shadow-lg p-6">
                      <p className="text-sm text-gray-600">Admin Commission</p>
                      <p className="text-2xl font-bold text-purple-600">{formatCurrency(stats.adminCommission)}</p>
                    </div>
                    <div className="bg-white rounded-xl shadow-lg p-6">
                      <p className="text-sm text-gray-600">Vendor Payouts</p>
                      <p className="text-2xl font-bold text-green-600">{formatCurrency(stats.vendorPayouts)}</p>
                    </div>
                    <div className="bg-white rounded-xl shadow-lg p-6">
                      <p className="text-sm text-gray-600">Rider Earnings</p>
                      <p className="text-2xl font-bold text-blue-600">{formatCurrency(stats.riderEarnings)}</p>
                    </div>
                  </div>
                  
                  <button
                    onClick={() => setShowVendorEarningsModal(true)}
                    className="w-full bg-purple-600 text-white py-3 rounded-lg hover:bg-purple-700"
                  >
                    View Detailed Vendor Earnings
                  </button>
                </div>
              )}

              {/* Users Tab */}
              {activeTab === "users" && (
                <div className="bg-white rounded-xl shadow-lg overflow-hidden">
                  <div className="p-6 border-b">
                    <h2 className="text-lg font-semibold">User Management</h2>
                  </div>
                  <div className="overflow-x-auto">
                    <table className="w-full">
                      <thead className="bg-purple-50">
                        <tr>
                          <th className="py-3 px-6 text-left text-xs font-semibold uppercase">User</th>
                          <th className="py-3 px-6 text-left text-xs font-semibold uppercase">Role</th>
                          <th className="py-3 px-6 text-left text-xs font-semibold uppercase">Status</th>
                          <th className="py-3 px-6 text-left text-xs font-semibold uppercase">Verified</th>
                          <th className="py-3 px-6 text-left text-xs font-semibold uppercase">Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {users.map(user => (
                          <tr key={user.id} className="hover:bg-purple-50/50">
                            <td className="py-4 px-6">
                              <div className="flex items-center space-x-3">
                                <div className="w-10 h-10 bg-gradient-to-br from-purple-500 to-purple-700 rounded-full flex items-center justify-center text-white font-semibold">
                                  {user.full_name?.charAt(0).toUpperCase() || 'U'}
                                </div>
                                <div>
                                  <p className="font-medium">{user.full_name || 'No Name'}</p>
                                  <p className="text-sm text-gray-600">{user.email}</p>
                                </div>
                              </div>
                            </td>
                            <td className="py-4 px-6">
                              <span className={`px-3 py-1 rounded-full text-xs font-medium ${
                                user.role === 'bride' ? 'bg-pink-100 text-pink-800' : 'bg-purple-100 text-purple-800'
                              }`}>
                                {user.role}
                              </span>
                            </td>
                            <td className="py-4 px-6">
                              <span className={`px-3 py-1 rounded-full text-xs font-medium ${
                                user.is_blocked ? 'bg-red-100 text-red-800' : 'bg-green-100 text-green-800'
                              }`}>
                                {user.is_blocked ? 'Blocked' : 'Active'}
                              </span>
                            </td>
                            <td className="py-4 px-6">
                              {user.is_verified ? (
                                <CheckCircle className="w-5 h-5 text-green-500" />
                              ) : (
                                <XCircle className="w-5 h-5 text-gray-400" />
                              )}
                            </td>
                            <td className="py-4 px-6">
                              <div className="flex space-x-2">
                                <button onClick={() => { setSelectedUser(user); setShowUserModal(true); }}
                                  className="p-2 text-purple-600 hover:bg-purple-50 rounded-lg">
                                  <Eye className="w-4 h-4" />
                                </button>
                                {!user.is_verified && (
                                  <button onClick={() => verifyUser(user.id)} 
                                    className="p-2 text-green-600 hover:bg-green-50 rounded-lg">
                                    <CheckCircle className="w-4 h-4" />
                                  </button>
                                )}
                                <button onClick={() => toggleUserBlock(user.id, user.is_blocked)}
                                  className={`p-2 ${user.is_blocked ? 'text-green-600 hover:bg-green-50' : 'text-red-600 hover:bg-red-50'} rounded-lg`}>
                                  {user.is_blocked ? <UserCheck className="w-4 h-4" /> : <UserX className="w-4 h-4" />}
                                </button>
                                <button onClick={() => deleteUser(user.id)} 
                                  className="p-2 text-red-600 hover:bg-red-50 rounded-lg">
                                  <Trash2 className="w-4 h-4" />
                                </button>
                              </div>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>
              )}

              {/* Analytics Tab */}
              {activeTab === "analytics" && (
                <div className="space-y-6">
                  <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                    <div className="bg-white rounded-xl shadow-lg p-6">
                      <h3 className="font-semibold mb-4">User Distribution</h3>
                      <div className="space-y-4">
                        <div>
                          <div className="flex justify-between text-sm">
                            <span>Brides</span>
                            <span className="font-medium">{stats.totalBrides}</span>
                          </div>
                          <div className="h-2 bg-gray-200 rounded-full mt-1">
                            <div className="h-full bg-pink-500 rounded-full" style={{ width: `${(stats.totalBrides / stats.totalUsers) * 100 || 0}%` }}></div>
                          </div>
                        </div>
                        <div>
                          <div className="flex justify-between text-sm">
                            <span>Vendors</span>
                            <span className="font-medium">{stats.totalVendors}</span>
                          </div>
                          <div className="h-2 bg-gray-200 rounded-full mt-1">
                            <div className="h-full bg-purple-500 rounded-full" style={{ width: `${(stats.totalVendors / stats.totalUsers) * 100 || 0}%` }}></div>
                          </div>
                        </div>
                        <div>
                          <div className="flex justify-between text-sm">
                            <span>Riders</span>
                            <span className="font-medium">{stats.totalRiders}</span>
                          </div>
                          <div className="h-2 bg-gray-200 rounded-full mt-1">
                            <div className="h-full bg-green-500 rounded-full" style={{ width: `${(stats.totalRiders / 50) * 100 || 0}%` }}></div>
                          </div>
                        </div>
                      </div>
                    </div>

                    <div className="bg-white rounded-xl shadow-lg p-6">
                      <h3 className="font-semibold mb-4">Revenue Breakdown</h3>
                      <div className="space-y-3">
                        <div className="flex justify-between">
                          <span>Total Revenue</span>
                          <span className="font-bold text-green-600">{formatCurrency(stats.totalRevenue)}</span>
                        </div>
                        <div className="flex justify-between">
                          <span>Admin Commission (20%)</span>
                          <span className="font-bold text-purple-600">{formatCurrency(stats.adminCommission)}</span>
                        </div>
                        <div className="flex justify-between">
                          <span>Vendor Payouts (80%)</span>
                          <span className="font-bold text-green-600">{formatCurrency(stats.vendorPayouts)}</span>
                        </div>
                        <div className="flex justify-between">
                          <span>Rider Earnings</span>
                          <span className="font-bold text-blue-600">{formatCurrency(stats.riderEarnings)}</span>
                        </div>
                      </div>
                    </div>
                  </div>

                  <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                    <div className="bg-white rounded-xl shadow-lg p-6">
                      <h3 className="font-semibold mb-4">Order Statistics</h3>
                      <div className="space-y-3">
                        <div className="flex justify-between">
                          <span>Total Orders</span>
                          <span className="font-bold">{stats.totalOrders}</span>
                        </div>
                        <div className="flex justify-between">
                          <span>Purchase Orders</span>
                          <span className="font-bold text-green-600">{stats.purchaseOrders}</span>
                        </div>
                        <div className="flex justify-between">
                          <span>Rental Orders</span>
                          <span className="font-bold text-orange-600">{stats.rentalOrders}</span>
                        </div>
                        <div className="flex justify-between">
                          <span>Completed</span>
                          <span className="font-bold text-green-600">{stats.completedOrders}</span>
                        </div>
                        <div className="flex justify-between">
                          <span>Returned</span>
                          <span className="font-bold text-purple-600">{stats.returnDeliveries}</span>
                        </div>
                      </div>
                    </div>

                    <div className="bg-white rounded-xl shadow-lg p-6">
                      <h3 className="font-semibold mb-4">Dress Status</h3>
                      <div className="space-y-3">
                        <div className="flex justify-between">
                          <span>Available</span>
                          <span className="font-bold text-green-600">{stats.availableDresses}</span>
                        </div>
                        <div className="flex justify-between">
                          <span>Booked</span>
                          <span className="font-bold text-orange-600">{stats.rentedDresses}</span>
                        </div>
                        <div className="flex justify-between">
                          <span>Sold</span>
                          <span className="font-bold text-purple-600">{stats.soldDresses}</span>
                        </div>
                        <div className="flex justify-between">
                          <span>Pending Approval</span>
                          <span className="font-bold text-yellow-600">{stats.pendingDresses}</span>
                        </div>
                      </div>
                    </div>

                    <div className="bg-white rounded-xl shadow-lg p-6">
                      <h3 className="font-semibold mb-4">Reviews & Ratings</h3>
                      <div className="space-y-3">
                        <div className="flex justify-between">
                          <span>Total Reviews</span>
                          <span className="font-bold">{stats.totalReviews}</span>
                        </div>
                        <div className="flex justify-between">
                          <span>Average Rating</span>
                          <span className="font-bold text-yellow-600">{stats.averageRating.toFixed(1)} ⭐</span>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              )}

              {/* Reviews Tab */}
              {activeTab === "reviews" && (
                <div className="bg-white rounded-xl shadow-lg overflow-hidden">
                  <div className="p-6 border-b">
                    <h2 className="text-lg font-semibold">Customer Reviews</h2>
                  </div>
                  <div className="p-6">
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                      {reviews.map(review => (
                        <div key={review.id} className="border rounded-lg p-4">
                          <div className="flex items-center justify-between mb-2">
                            <span className="font-medium">{review.users?.full_name}</span>
                            <span className="text-sm text-gray-500">{formatDate(review.created_at)}</span>
                          </div>
                          <div className="flex items-center mb-2">
                            {[...Array(5)].map((_, i) => (
                              <Star
                                key={i}
                                className={`w-4 h-4 ${i < review.rating ? 'text-yellow-400 fill-current' : 'text-gray-300'}`}
                              />
                            ))}
                          </div>
                          <p className="text-gray-700">{review.comment || review.review}</p>
                          <p className="text-sm text-gray-500 mt-2">Vendor: {review.vendors?.business_name}</p>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              )}
            </>
          )}
        </main>
      </div>
    </div>
  );
}