import React from "react";
import { Link } from "react-router-dom";
import { useDispatch } from "react-redux";
import {
  storefrontProducts,
  storefrontCategories,
} from "../../core/json/storefrontData";
import { addToCart } from "../../store/cartSlice";
import { addToWishlist } from "../../store/wishlistSlice";
import { useAlert } from "../../components/AlertContext";

const StorefrontHome: React.FC = () => {
  const dispatch = useDispatch();
  const { showAlert } = useAlert();
  const featuredProducts = storefrontProducts.filter((p) => p.badge === "hot" || p.rating >= 4.5);
  const saleProducts = storefrontProducts.filter((p) => p.badge === "sale");
  const newProducts = storefrontProducts.filter((p) => p.badge === "new");

  const renderStars = (rating: number) => {
    const stars = [];
    const fullStars = Math.floor(rating);
    const hasHalf = rating % 1 >= 0.5;
    for (let i = 0; i < fullStars; i++) {
      stars.push(<i key={`full-${i}`} className="ti ti-star-filled text-warning"></i>);
    }
    if (hasHalf) {
      stars.push(<i key="half" className="ti ti-star-half-filled text-warning"></i>);
    }
    for (let i = stars.length; i < 5; i++) {
      stars.push(<i key={`empty-${i}`} className="ti ti-star text-muted"></i>);
    }
    return stars;
  };

  const renderProductCard = (product: typeof storefrontProducts[0]) => (
    <div key={product.id} className="col-xl-3 col-lg-4 col-md-6 col-sm-6 mb-4">
      <div className="storefront-product-card">
        {product.badge && (
          <span className={`product-badge badge-${product.badge}`}>
            {product.badge === "sale" ? "Sale" : product.badge === "new" ? "New" : "Hot"}
          </span>
        )}
        {!product.inStock && (
          <span className="product-badge badge-out">Out of Stock</span>
        )}
        <div className="product-image-wrap">
          <Link to={`/store/product/${product.id}`}>
            <img src={product.image} alt={product.name} className="product-image" />
          </Link>
          <div className="product-overlay">
            <Link to={`/store/product/${product.id}`} className="overlay-btn" title="Quick View">
              <i className="ti ti-eye"></i>
            </Link>
            <button
              className="overlay-btn"
              title="Add to Wishlist"
              onClick={(e) => {
                e.preventDefault();
                dispatch(
                  addToWishlist({
                    id: product.id,
                    name: product.name,
                    image: product.image,
                    price: product.price,
                    oldPrice: product.oldPrice,
                    category: product.category,
                    brand: product.brand,
                    inStock: product.inStock,
                  })
                );
                showAlert({
                  type: "success",
                  message: `${product.name} added to wishlist!`,
                  autoClose: 2000,
                });
              }}
            >
              <i className="ti ti-heart"></i>
            </button>
          </div>
        </div>
        <div className="product-info">
          <span className="product-category">{product.category}</span>
          <Link to={`/store/product/${product.id}`} className="product-name">
            {product.name}
          </Link>
          <div className="product-rating">
            {renderStars(product.rating)}
            <span className="rating-count">({product.reviewCount})</span>
          </div>
          <div className="product-price-row">
            <span className="product-price">${product.price.toFixed(2)}</span>
            {product.oldPrice && (
              <span className="product-old-price">${product.oldPrice.toFixed(2)}</span>
            )}
          </div>
          <button
            className={`btn btn-primary btn-sm w-100 mt-2`}
            disabled={!product.inStock}
            onClick={() => {
              dispatch(
                addToCart({
                  id: product.id,
                  name: product.name,
                  image: product.image,
                  price: product.price,
                  quantity: 1,
                  category: product.category,
                  brand: product.brand,
                })
              );
              showAlert({
                type: "success",
                message: `${product.name} added to cart!`,
                autoClose: 2000,
              });
            }}
          >
            <i className="ti ti-shopping-cart me-1"></i>
            {product.inStock ? "Add to Cart" : "Out of Stock"}
          </button>
        </div>
      </div>
    </div>
  );

  return (
    <div className="storefront-home">
      {/* Hero Section */}
      <section className="storefront-hero">
        <div className="container">
          <div className="row align-items-center">
            <div className="col-lg-6">
              <div className="hero-content">
                <span className="hero-badge">Welcome to DreamsPOS Store</span>
                <h1 className="hero-title">
                  Discover Amazing Products at <span className="text-primary">Great Prices</span>
                </h1>
                <p className="hero-subtitle">
                  Shop from our curated collection of premium products across
                  electronics, fashion, home decor, and more. Enjoy free shipping
                  on orders over $50.
                </p>
                <div className="hero-actions">
                  <Link to="/store/products" className="btn btn-primary btn-lg me-3">
                    <i className="ti ti-shopping-bag me-2"></i>Shop Now
                  </Link>
                  <Link to="/store/products?badge=sale" className="btn btn-outline-primary btn-lg">
                    <i className="ti ti-tag me-2"></i>View Deals
                  </Link>
                </div>
                <div className="hero-stats">
                  <div className="stat-item">
                    <strong>10K+</strong>
                    <span>Products</span>
                  </div>
                  <div className="stat-item">
                    <strong>50K+</strong>
                    <span>Customers</span>
                  </div>
                  <div className="stat-item">
                    <strong>99%</strong>
                    <span>Satisfaction</span>
                  </div>
                </div>
              </div>
            </div>
            <div className="col-lg-6 d-none d-lg-block">
              <div className="hero-image-grid">
                <div className="hero-grid-item hero-grid-large">
                  <img src={storefrontProducts[7]?.image} alt="Featured" />
                  <div className="hero-grid-label">Trending</div>
                </div>
                <div className="hero-grid-item">
                  <img src={storefrontProducts[0]?.image} alt="Featured" />
                </div>
                <div className="hero-grid-item">
                  <img src={storefrontProducts[1]?.image} alt="Featured" />
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Categories Section */}
      <section className="storefront-section">
        <div className="container">
          <div className="section-header">
            <h2 className="section-title">Shop by Category</h2>
            <Link to="/store/products" className="section-link">
              View All <i className="ti ti-arrow-right"></i>
            </Link>
          </div>
          <div className="row">
            {storefrontCategories.map((cat) => (
              <div key={cat.id} className="col-lg-2 col-md-4 col-6 mb-3">
                <Link
                  to={`/store/products?category=${encodeURIComponent(cat.name)}`}
                  className="storefront-category-card"
                >
                  <div className="category-icon">
                    <i className={cat.icon}></i>
                  </div>
                  <h6 className="category-name">{cat.name}</h6>
                  <span className="category-count">{cat.productCount} Products</span>
                </Link>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Featured Products */}
      <section className="storefront-section bg-light">
        <div className="container">
          <div className="section-header">
            <h2 className="section-title">Featured Products</h2>
            <Link to="/store/products" className="section-link">
              View All <i className="ti ti-arrow-right"></i>
            </Link>
          </div>
          <div className="row">
            {featuredProducts.slice(0, 4).map(renderProductCard)}
          </div>
        </div>
      </section>

      {/* Promo Banner */}
      <section className="storefront-promo">
        <div className="container">
          <div className="row">
            <div className="col-md-6 mb-3 mb-md-0">
              <div className="promo-card promo-primary">
                <div className="promo-content">
                  <span className="promo-label">Special Offer</span>
                  <h3>Up to 30% Off</h3>
                  <p>On all electronics this week</p>
                  <Link to="/store/products?category=Electronics" className="btn btn-light btn-sm">
                    Shop Electronics
                  </Link>
                </div>
                <div className="promo-icon">
                  <i className="ti ti-headphones"></i>
                </div>
              </div>
            </div>
            <div className="col-md-6">
              <div className="promo-card promo-dark">
                <div className="promo-content">
                  <span className="promo-label">New Collection</span>
                  <h3>Premium Bags</h3>
                  <p>Explore our latest arrivals</p>
                  <Link to="/store/products?category=Bags" className="btn btn-primary btn-sm">
                    Shop Bags
                  </Link>
                </div>
                <div className="promo-icon">
                  <i className="ti ti-briefcase"></i>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Sale Products */}
      {saleProducts.length > 0 && (
        <section className="storefront-section">
          <div className="container">
            <div className="section-header">
              <h2 className="section-title">
                <i className="ti ti-tag text-danger me-2"></i>On Sale
              </h2>
              <Link to="/store/products?badge=sale" className="section-link">
                View All <i className="ti ti-arrow-right"></i>
              </Link>
            </div>
            <div className="row">
              {saleProducts.slice(0, 4).map(renderProductCard)}
            </div>
          </div>
        </section>
      )}

      {/* New Arrivals */}
      {newProducts.length > 0 && (
        <section className="storefront-section bg-light">
          <div className="container">
            <div className="section-header">
              <h2 className="section-title">
                <i className="ti ti-sparkles text-warning me-2"></i>New Arrivals
              </h2>
              <Link to="/store/products?badge=new" className="section-link">
                View All <i className="ti ti-arrow-right"></i>
              </Link>
            </div>
            <div className="row">
              {newProducts.slice(0, 4).map(renderProductCard)}
            </div>
          </div>
        </section>
      )}

      {/* Features Strip */}
      <section className="storefront-features">
        <div className="container">
          <div className="row">
            <div className="col-lg-3 col-md-6 mb-3 mb-lg-0">
              <div className="feature-item">
                <i className="ti ti-truck feature-icon"></i>
                <div>
                  <h6>Free Shipping</h6>
                  <span>On orders over $50</span>
                </div>
              </div>
            </div>
            <div className="col-lg-3 col-md-6 mb-3 mb-lg-0">
              <div className="feature-item">
                <i className="ti ti-refresh feature-icon"></i>
                <div>
                  <h6>Easy Returns</h6>
                  <span>30-day return policy</span>
                </div>
              </div>
            </div>
            <div className="col-lg-3 col-md-6 mb-3 mb-lg-0">
              <div className="feature-item">
                <i className="ti ti-shield-check feature-icon"></i>
                <div>
                  <h6>Secure Payment</h6>
                  <span>100% secure checkout</span>
                </div>
              </div>
            </div>
            <div className="col-lg-3 col-md-6">
              <div className="feature-item">
                <i className="ti ti-headset feature-icon"></i>
                <div>
                  <h6>24/7 Support</h6>
                  <span>Dedicated support</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
};

export default StorefrontHome;
