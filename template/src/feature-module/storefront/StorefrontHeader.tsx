import React, { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useSelector, useDispatch } from "react-redux";
import { logoPng, logoWhitePng } from "../../utils/imagepath";
import { logout } from "../../core/redux/authSlice";
import { all_routes } from "../../routes/all_routes";
import { storefrontCategories } from "../../core/json/storefrontData";

const routes = all_routes;

const StorefrontHeader: React.FC = () => {
  const [searchQuery, setSearchQuery] = useState("");
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const navigate = useNavigate();
  const dispatch = useDispatch();
  const user = useSelector((state: any) => state.auth?.user);
  const token = useSelector((state: any) => state.auth?.token);
  const cartItems = useSelector((state: any) => state.cart?.items || []);
  const cartCount = cartItems.reduce((sum: number, item: any) => sum + item.quantity, 0);
  const wishlistItems = useSelector((state: any) => state.wishlist?.items || []);
  const wishlistCount = wishlistItems.length;

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    if (searchQuery.trim()) {
      navigate(`/store/products?search=${encodeURIComponent(searchQuery.trim())}`);
    }
  };

  const handleLogout = () => {
    dispatch(logout());
    navigate("/signin");
  };

  return (
    <header className="storefront-header">
      {/* Top Bar */}
      <div className="storefront-topbar">
        <div className="container">
          <div className="row align-items-center">
            <div className="col-md-6">
              <span className="topbar-text">
                <i className="ti ti-truck me-1"></i>
                Free shipping on orders over $50
              </span>
            </div>
            <div className="col-md-6 text-end">
              <span className="topbar-text me-3">
                <i className="ti ti-phone me-1"></i>
                +1 (555) 123-4567
              </span>
              <span className="topbar-text">
                <i className="ti ti-mail me-1"></i>
                support@dreamspos.com
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* Main Header */}
      <div className="storefront-main-header">
        <div className="container">
          <div className="row align-items-center">
            {/* Logo */}
            <div className="col-lg-2 col-6">
              <Link to="/store" className="storefront-logo">
                <img src={logoPng} alt="DreamsPOS" className="logo-normal" />
                <img src={logoWhitePng} alt="DreamsPOS" className="logo-white" />
              </Link>
            </div>

            {/* Search Bar */}
            <div className="col-lg-6 d-none d-lg-block">
              <form className="storefront-search" onSubmit={handleSearch}>
                <div className="input-group">
                  <input
                    type="text"
                    className="form-control"
                    placeholder="Search products, brands and categories..."
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                  />
                  <button className="btn btn-primary" type="submit">
                    <i className="ti ti-search"></i>
                  </button>
                </div>
              </form>
            </div>

            {/* Header Actions */}
            <div className="col-lg-4 col-6">
              <div className="storefront-header-actions">
                <Link to="/store/wishlist" className="header-action-item position-relative" title="Wishlist">
                  <i className="ti ti-heart"></i>
                  {wishlistCount > 0 && (
                    <span className="storefront-cart-badge">{wishlistCount}</span>
                  )}
                  <span className="d-none d-md-inline ms-1">Wishlist</span>
                </Link>
                <Link to="/store/cart" className="header-action-item position-relative" title="Cart">
                  <i className="ti ti-shopping-cart"></i>
                  {cartCount > 0 && (
                    <span className="storefront-cart-badge">{cartCount}</span>
                  )}
                  <span className="d-none d-md-inline ms-1">Cart</span>
                </Link>
                {token ? (
                  <>
                    <div className="dropdown header-action-item">
                      <a
                        href="#"
                        className="dropdown-toggle"
                        data-bs-toggle="dropdown"
                        aria-expanded="false"
                        onClick={(e) => e.preventDefault()}
                      >
                        <i className="ti ti-user-circle"></i>
                        <span className="d-none d-md-inline ms-1">
                          {user?.displayName || "Account"}
                        </span>
                      </a>
                      <ul className="dropdown-menu dropdown-menu-end">
                        <li>
                          <Link className="dropdown-item" to={routes.profile}>
                            <i className="ti ti-user me-2"></i>My Profile
                          </Link>
                        </li>
                        <li>
                          <Link className="dropdown-item" to="/store/orders">
                            <i className="ti ti-package me-2"></i>My Orders
                          </Link>
                        </li>
                        <li>
                          <Link className="dropdown-item" to="/store/wishlist">
                            <i className="ti ti-heart me-2"></i>Wishlist
                          </Link>
                        </li>
                        <li>
                          <Link className="dropdown-item" to={routes.dashboard}>
                            <i className="ti ti-layout-dashboard me-2"></i>Admin Panel
                          </Link>
                        </li>
                        <li><hr className="dropdown-divider" /></li>
                        <li>
                          <a className="dropdown-item" href="#" onClick={(e) => { e.preventDefault(); handleLogout(); }}>
                            <i className="ti ti-logout me-2"></i>Logout
                          </a>
                        </li>
                      </ul>
                    </div>
                  </>
                ) : (
                  <Link to="/signin" className="btn btn-primary btn-sm">
                    <i className="ti ti-login me-1"></i>Sign In
                  </Link>
                )}
                <button
                  className="btn btn-link d-lg-none storefront-mobile-toggle"
                  onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
                >
                  <i className={mobileMenuOpen ? "ti ti-x" : "ti ti-menu-2"}></i>
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Navigation */}
      <nav className={`storefront-nav ${mobileMenuOpen ? "mobile-open" : ""}`}>
        <div className="container">
          <ul className="storefront-nav-list">
            <li className="nav-item">
              <Link to="/store" className="nav-link">
                <i className="ti ti-home me-1"></i>Home
              </Link>
            </li>
            <li className="nav-item dropdown">
              <a
                href="#"
                className="nav-link dropdown-toggle"
                data-bs-toggle="dropdown"
                onClick={(e) => e.preventDefault()}
              >
                <i className="ti ti-category me-1"></i>Categories
              </a>
              <ul className="dropdown-menu storefront-mega-menu">
                {storefrontCategories.map((cat) => (
                  <li key={cat.id}>
                    <Link
                      className="dropdown-item"
                      to={`/store/products?category=${encodeURIComponent(cat.name)}`}
                      onClick={() => setMobileMenuOpen(false)}
                    >
                      <i className={`${cat.icon} me-2`}></i>
                      {cat.name}
                      <span className="badge bg-light text-dark ms-auto">{cat.productCount}</span>
                    </Link>
                  </li>
                ))}
              </ul>
            </li>
            <li className="nav-item">
              <Link to="/store/products" className="nav-link">
                <i className="ti ti-package me-1"></i>All Products
              </Link>
            </li>
            <li className="nav-item">
              <Link to="/store/products?badge=sale" className="nav-link storefront-sale-link">
                <i className="ti ti-tag me-1"></i>Sale
              </Link>
            </li>
            <li className="nav-item">
              <Link to="/store/products?badge=new" className="nav-link">
                <i className="ti ti-sparkles me-1"></i>New Arrivals
              </Link>
            </li>
          </ul>

          {/* Mobile Search */}
          <div className="d-lg-none storefront-mobile-search">
            <form onSubmit={handleSearch}>
              <div className="input-group">
                <input
                  type="text"
                  className="form-control"
                  placeholder="Search products..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                />
                <button className="btn btn-primary" type="submit">
                  <i className="ti ti-search"></i>
                </button>
              </div>
            </form>
          </div>
        </div>
      </nav>
    </header>
  );
};

export default StorefrontHeader;
