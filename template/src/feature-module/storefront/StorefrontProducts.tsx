import React, { useState, useMemo } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { useDispatch } from "react-redux";
import {
  storefrontProducts,
  storefrontCategories,
  StorefrontProduct,
} from "../../core/json/storefrontData";
import { addToCart } from "../../store/cartSlice";
import { addToWishlist } from "../../store/wishlistSlice";
import { useAlert } from "../../components/AlertContext";

const StorefrontProducts: React.FC = () => {
  const dispatch = useDispatch();
  const { showAlert } = useAlert();
  const [searchParams] = useSearchParams();
  const categoryFilter = searchParams.get("category") || "";
  const badgeFilter = searchParams.get("badge") || "";
  const searchFilter = searchParams.get("search") || "";

  const [sortBy, setSortBy] = useState("featured");
  const [priceRange, setPriceRange] = useState<[number, number]>([0, 1000]);
  const [selectedCategories, setSelectedCategories] = useState<string[]>(
    categoryFilter ? [categoryFilter] : []
  );
  const [inStockOnly, setInStockOnly] = useState(false);
  const [viewMode, setViewMode] = useState<"grid" | "list">("grid");

  const toggleCategory = (cat: string) => {
    setSelectedCategories((prev) =>
      prev.includes(cat) ? prev.filter((c) => c !== cat) : [...prev, cat]
    );
  };

  const filteredProducts = useMemo(() => {
    let result = [...storefrontProducts];

    // Search filter
    if (searchFilter) {
      const q = searchFilter.toLowerCase();
      result = result.filter(
        (p) =>
          p.name.toLowerCase().includes(q) ||
          p.brand.toLowerCase().includes(q) ||
          p.category.toLowerCase().includes(q)
      );
    }

    // Category filter
    if (selectedCategories.length > 0) {
      result = result.filter((p) => selectedCategories.includes(p.category));
    }

    // Badge filter
    if (badgeFilter) {
      result = result.filter((p) => p.badge === badgeFilter);
    }

    // Price filter
    result = result.filter(
      (p) => p.price >= priceRange[0] && p.price <= priceRange[1]
    );

    // In stock filter
    if (inStockOnly) {
      result = result.filter((p) => p.inStock);
    }

    // Sort
    switch (sortBy) {
      case "price-low":
        result.sort((a, b) => a.price - b.price);
        break;
      case "price-high":
        result.sort((a, b) => b.price - a.price);
        break;
      case "rating":
        result.sort((a, b) => b.rating - a.rating);
        break;
      case "name":
        result.sort((a, b) => a.name.localeCompare(b.name));
        break;
      default:
        break;
    }

    return result;
  }, [searchFilter, selectedCategories, badgeFilter, priceRange, inStockOnly, sortBy]);

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

  const renderProductCard = (product: StorefrontProduct) => (
    <div
      key={product.id}
      className={viewMode === "grid" ? "col-xl-4 col-lg-4 col-md-6 mb-4" : "col-12 mb-3"}
    >
      <div className={`storefront-product-card ${viewMode === "list" ? "list-view" : ""}`}>
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
          {viewMode === "list" && (
            <p className="product-desc">{product.description}</p>
          )}
          <div className="product-rating">
            {renderStars(product.rating)}
            <span className="rating-count">({product.reviewCount})</span>
          </div>
          <div className="product-price-row">
            <span className="product-price">${product.price.toFixed(2)}</span>
            {product.oldPrice && (
              <span className="product-old-price">${product.oldPrice.toFixed(2)}</span>
            )}
            {product.oldPrice && (
              <span className="product-discount">
                -{Math.round(((product.oldPrice - product.price) / product.oldPrice) * 100)}%
              </span>
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

  const pageTitle = badgeFilter
    ? badgeFilter === "sale"
      ? "Sale Items"
      : "New Arrivals"
    : searchFilter
    ? `Search: "${searchFilter}"`
    : categoryFilter
    ? categoryFilter
    : "All Products";

  return (
    <div className="storefront-products-page">
      <div className="container py-4">
        {/* Breadcrumb */}
        <nav aria-label="breadcrumb" className="mb-3">
          <ol className="breadcrumb">
            <li className="breadcrumb-item">
              <Link to="/store">Home</Link>
            </li>
            <li className="breadcrumb-item active">{pageTitle}</li>
          </ol>
        </nav>

        <div className="row">
          {/* Sidebar Filters */}
          <div className="col-lg-3 mb-4">
            <div className="storefront-filter-sidebar">
              <div className="filter-section">
                <h6 className="filter-title">Categories</h6>
                {storefrontCategories.map((cat) => (
                  <label key={cat.id} className="filter-checkbox">
                    <input
                      type="checkbox"
                      checked={selectedCategories.includes(cat.name)}
                      onChange={() => toggleCategory(cat.name)}
                    />
                    <span className="checkmark"></span>
                    {cat.name}
                    <span className="filter-count">({cat.productCount})</span>
                  </label>
                ))}
              </div>

              <div className="filter-section">
                <h6 className="filter-title">Price Range</h6>
                <div className="price-inputs">
                  <div className="input-group input-group-sm mb-2">
                    <span className="input-group-text">$</span>
                    <input
                      type="number"
                      className="form-control"
                      value={priceRange[0]}
                      onChange={(e) =>
                        setPriceRange([Number(e.target.value), priceRange[1]])
                      }
                      min={0}
                    />
                    <span className="input-group-text">-</span>
                    <span className="input-group-text">$</span>
                    <input
                      type="number"
                      className="form-control"
                      value={priceRange[1]}
                      onChange={(e) =>
                        setPriceRange([priceRange[0], Number(e.target.value)])
                      }
                      min={0}
                    />
                  </div>
                </div>
              </div>

              <div className="filter-section">
                <h6 className="filter-title">Availability</h6>
                <label className="filter-checkbox">
                  <input
                    type="checkbox"
                    checked={inStockOnly}
                    onChange={(e) => setInStockOnly(e.target.checked)}
                  />
                  <span className="checkmark"></span>
                  In Stock Only
                </label>
              </div>

              <button
                className="btn btn-outline-secondary btn-sm w-100 mt-3"
                onClick={() => {
                  setSelectedCategories([]);
                  setPriceRange([0, 1000]);
                  setInStockOnly(false);
                  setSortBy("featured");
                }}
              >
                <i className="ti ti-x me-1"></i>Clear All Filters
              </button>
            </div>
          </div>

          {/* Product Grid */}
          <div className="col-lg-9">
            {/* Toolbar */}
            <div className="storefront-toolbar">
              <div className="toolbar-left">
                <span className="result-count">
                  {filteredProducts.length} product{filteredProducts.length !== 1 ? "s" : ""} found
                </span>
              </div>
              <div className="toolbar-right">
                <select
                  className="form-select form-select-sm"
                  value={sortBy}
                  onChange={(e) => setSortBy(e.target.value)}
                >
                  <option value="featured">Featured</option>
                  <option value="price-low">Price: Low to High</option>
                  <option value="price-high">Price: High to Low</option>
                  <option value="rating">Highest Rated</option>
                  <option value="name">Name: A to Z</option>
                </select>
                <div className="view-toggle">
                  <button
                    className={`btn btn-sm ${viewMode === "grid" ? "btn-primary" : "btn-outline-secondary"}`}
                    onClick={() => setViewMode("grid")}
                  >
                    <i className="ti ti-grid-dots"></i>
                  </button>
                  <button
                    className={`btn btn-sm ${viewMode === "list" ? "btn-primary" : "btn-outline-secondary"}`}
                    onClick={() => setViewMode("list")}
                  >
                    <i className="ti ti-list"></i>
                  </button>
                </div>
              </div>
            </div>

            {/* Products */}
            {filteredProducts.length > 0 ? (
              <div className="row">{filteredProducts.map(renderProductCard)}</div>
            ) : (
              <div className="storefront-empty">
                <i className="ti ti-package-off"></i>
                <h5>No products found</h5>
                <p>Try adjusting your filters or search terms</p>
                <Link to="/store/products" className="btn btn-primary btn-sm">
                  Clear Filters
                </Link>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default StorefrontProducts;
