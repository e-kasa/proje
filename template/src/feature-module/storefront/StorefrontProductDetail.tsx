import React, { useState } from "react";
import { Link, useParams } from "react-router-dom";
import { useDispatch } from "react-redux";
import { storefrontProducts } from "../../core/json/storefrontData";
import { addToCart } from "../../store/cartSlice";
import { addToWishlist } from "../../store/wishlistSlice";
import { useAlert } from "../../components/AlertContext";

const StorefrontProductDetail: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const product = storefrontProducts.find((p) => p.id === id);
  const [quantity, setQuantity] = useState(1);
  const [activeTab, setActiveTab] = useState("description");
  const dispatch = useDispatch();
  const { showAlert } = useAlert();

  if (!product) {
    return (
      <div className="container py-5 text-center">
        <i className="ti ti-package-off" style={{ fontSize: 64, color: "#ccc" }}></i>
        <h3 className="mt-3">Product Not Found</h3>
        <p>The product you are looking for does not exist.</p>
        <Link to="/store/products" className="btn btn-primary">
          Back to Products
        </Link>
      </div>
    );
  }

  const relatedProducts = storefrontProducts
    .filter((p) => p.category === product.category && p.id !== product.id)
    .slice(0, 4);

  const renderStars = (rating: number) => {
    const stars = [];
    const fullStars = Math.floor(rating);
    const hasHalf = rating % 1 >= 0.5;
    for (let i = 0; i < fullStars; i++) {
      stars.push(<i key={`f-${i}`} className="ti ti-star-filled text-warning"></i>);
    }
    if (hasHalf) {
      stars.push(<i key="h" className="ti ti-star-half-filled text-warning"></i>);
    }
    for (let i = stars.length; i < 5; i++) {
      stars.push(<i key={`e-${i}`} className="ti ti-star text-muted"></i>);
    }
    return stars;
  };

  return (
    <div className="storefront-product-detail">
      <div className="container py-4">
        {/* Breadcrumb */}
        <nav aria-label="breadcrumb" className="mb-4">
          <ol className="breadcrumb">
            <li className="breadcrumb-item">
              <Link to="/store">Home</Link>
            </li>
            <li className="breadcrumb-item">
              <Link to={`/store/products?category=${encodeURIComponent(product.category)}`}>
                {product.category}
              </Link>
            </li>
            <li className="breadcrumb-item active">{product.name}</li>
          </ol>
        </nav>

        {/* Product Section */}
        <div className="row mb-5">
          {/* Product Image */}
          <div className="col-lg-5 mb-4 mb-lg-0">
            <div className="product-detail-image">
              {product.badge && (
                <span className={`product-badge badge-${product.badge}`}>
                  {product.badge === "sale" ? "Sale" : product.badge === "new" ? "New" : "Hot"}
                </span>
              )}
              <img src={product.image} alt={product.name} className="img-fluid rounded" />
            </div>
          </div>

          {/* Product Info */}
          <div className="col-lg-7">
            <div className="product-detail-info">
              <span className="product-detail-brand">{product.brand}</span>
              <h2 className="product-detail-name">{product.name}</h2>

              <div className="product-detail-rating mb-3">
                {renderStars(product.rating)}
                <span className="ms-2 text-muted">
                  {product.rating} ({product.reviewCount} reviews)
                </span>
              </div>

              <div className="product-detail-price mb-3">
                <span className="detail-price">${product.price.toFixed(2)}</span>
                {product.oldPrice && (
                  <>
                    <span className="detail-old-price">${product.oldPrice.toFixed(2)}</span>
                    <span className="detail-discount">
                      Save {Math.round(((product.oldPrice - product.price) / product.oldPrice) * 100)}%
                    </span>
                  </>
                )}
              </div>

              <p className="product-detail-desc">{product.description}</p>

              {/* Stock Status */}
              <div className="mb-3">
                {product.inStock ? (
                  <span className="badge bg-success-light text-success px-3 py-2">
                    <i className="ti ti-check me-1"></i>In Stock
                  </span>
                ) : (
                  <span className="badge bg-danger-light text-danger px-3 py-2">
                    <i className="ti ti-x me-1"></i>Out of Stock
                  </span>
                )}
              </div>

              {/* Quantity & Add to Cart */}
              <div className="product-detail-actions mb-4">
                <div className="quantity-selector">
                  <button
                    className="btn btn-outline-secondary"
                    onClick={() => setQuantity(Math.max(1, quantity - 1))}
                    disabled={!product.inStock}
                  >
                    <i className="ti ti-minus"></i>
                  </button>
                  <input
                    type="number"
                    className="form-control text-center"
                    value={quantity}
                    onChange={(e) =>
                      setQuantity(Math.max(1, Math.min(99, Number(e.target.value))))
                    }
                    min={1}
                    max={99}
                    disabled={!product.inStock}
                  />
                  <button
                    className="btn btn-outline-secondary"
                    onClick={() => setQuantity(Math.min(99, quantity + 1))}
                    disabled={!product.inStock}
                  >
                    <i className="ti ti-plus"></i>
                  </button>
                </div>
                <button
                  className="btn btn-primary btn-lg"
                  disabled={!product.inStock}
                  onClick={() => {
                    dispatch(
                      addToCart({
                        id: product.id,
                        name: product.name,
                        image: product.image,
                        price: product.price,
                        quantity,
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
                  <i className="ti ti-shopping-cart me-2"></i>
                  Add to Cart
                </button>
                <button
                  className="btn btn-outline-danger btn-lg"
                  title="Add to Wishlist"
                  onClick={() => {
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

              {/* Product Meta */}
              <div className="product-meta">
                <div className="meta-item">
                  <span className="meta-label">Category:</span>
                  <Link to={`/store/products?category=${encodeURIComponent(product.category)}`}>
                    {product.category}
                  </Link>
                </div>
                <div className="meta-item">
                  <span className="meta-label">Brand:</span>
                  <span>{product.brand}</span>
                </div>
              </div>

              {/* Guarantees */}
              <div className="product-guarantees">
                <div className="guarantee-item">
                  <i className="ti ti-truck"></i>
                  <span>Free Shipping</span>
                </div>
                <div className="guarantee-item">
                  <i className="ti ti-refresh"></i>
                  <span>30-Day Returns</span>
                </div>
                <div className="guarantee-item">
                  <i className="ti ti-shield-check"></i>
                  <span>Secure Checkout</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Tabs */}
        <div className="product-detail-tabs mb-5">
          <ul className="nav nav-tabs">
            <li className="nav-item">
              <button
                className={`nav-link ${activeTab === "description" ? "active" : ""}`}
                onClick={() => setActiveTab("description")}
              >
                Description
              </button>
            </li>
            <li className="nav-item">
              <button
                className={`nav-link ${activeTab === "features" ? "active" : ""}`}
                onClick={() => setActiveTab("features")}
              >
                Features
              </button>
            </li>
            <li className="nav-item">
              <button
                className={`nav-link ${activeTab === "reviews" ? "active" : ""}`}
                onClick={() => setActiveTab("reviews")}
              >
                Reviews ({product.reviewCount})
              </button>
            </li>
          </ul>
          <div className="tab-content p-4 border border-top-0 rounded-bottom">
            {activeTab === "description" && (
              <div>
                <p>{product.description}</p>
                <p>
                  This product is brought to you by {product.brand}, a trusted name in {product.category.toLowerCase()}.
                  We ensure the highest quality standards and customer satisfaction.
                </p>
              </div>
            )}
            {activeTab === "features" && (
              <div>
                {product.features && product.features.length > 0 ? (
                  <ul className="feature-list">
                    {product.features.map((f, i) => (
                      <li key={i}>
                        <i className="ti ti-check text-success me-2"></i>
                        {f}
                      </li>
                    ))}
                  </ul>
                ) : (
                  <p>No features listed for this product.</p>
                )}
              </div>
            )}
            {activeTab === "reviews" && (
              <div className="text-center py-4">
                <i className="ti ti-message-dots" style={{ fontSize: 48, color: "#ccc" }}></i>
                <p className="mt-2 text-muted">
                  {product.reviewCount} reviews available. Review system coming soon.
                </p>
              </div>
            )}
          </div>
        </div>

        {/* Related Products */}
        {relatedProducts.length > 0 && (
          <div className="related-products">
            <h4 className="mb-4">Related Products</h4>
            <div className="row">
              {relatedProducts.map((rp) => (
                <div key={rp.id} className="col-xl-3 col-lg-4 col-md-6 mb-4">
                  <div className="storefront-product-card">
                    {rp.badge && (
                      <span className={`product-badge badge-${rp.badge}`}>
                        {rp.badge === "sale" ? "Sale" : rp.badge === "new" ? "New" : "Hot"}
                      </span>
                    )}
                    <Link to={`/store/product/${rp.id}`} className="product-image-wrap">
                      <img src={rp.image} alt={rp.name} className="product-image" />
                    </Link>
                    <div className="product-info">
                      <span className="product-category">{rp.category}</span>
                      <Link to={`/store/product/${rp.id}`} className="product-name">
                        {rp.name}
                      </Link>
                      <div className="product-rating">
                        {renderStars(rp.rating)}
                        <span className="rating-count">({rp.reviewCount})</span>
                      </div>
                      <div className="product-price-row">
                        <span className="product-price">${rp.price.toFixed(2)}</span>
                        {rp.oldPrice && (
                          <span className="product-old-price">${rp.oldPrice.toFixed(2)}</span>
                        )}
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default StorefrontProductDetail;
