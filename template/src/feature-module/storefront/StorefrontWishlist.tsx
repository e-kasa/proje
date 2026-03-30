import React from "react";
import { Link } from "react-router-dom";
import { useSelector, useDispatch } from "react-redux";
import type { RootState } from "../../core/redux/store";
import { removeFromWishlist } from "../../store/wishlistSlice";
import { addToCart } from "../../store/cartSlice";
import { useAlert } from "../../components/AlertContext";

const StorefrontWishlist: React.FC = () => {
  const dispatch = useDispatch();
  const { showAlert } = useAlert();
  const wishlistItems = useSelector((state: RootState) => state.wishlist.items);

  const handleMoveToCart = (item: typeof wishlistItems[0]) => {
    dispatch(
      addToCart({
        id: item.id,
        name: item.name,
        image: item.image,
        price: item.price,
        quantity: 1,
        category: item.category,
        brand: item.brand,
      })
    );
    dispatch(removeFromWishlist(item.id));
    showAlert({
      type: "success",
      message: `${item.name} moved to cart!`,
      autoClose: 2000,
    });
  };

  if (wishlistItems.length === 0) {
    return (
      <div className="container py-5 text-center">
        <i
          className="ti ti-heart-off"
          style={{ fontSize: 80, color: "#ccc" }}
        ></i>
        <h3 className="mt-3">Your Wishlist is Empty</h3>
        <p className="text-muted">
          Browse our products and add your favorites to the wishlist.
        </p>
        <Link to="/store/products" className="btn btn-primary mt-2">
          <i className="ti ti-shopping-bag me-2"></i>Browse Products
        </Link>
      </div>
    );
  }

  return (
    <div className="container py-4">
      <nav aria-label="breadcrumb" className="mb-3">
        <ol className="breadcrumb">
          <li className="breadcrumb-item">
            <Link to="/store">Home</Link>
          </li>
          <li className="breadcrumb-item active">Wishlist</li>
        </ol>
      </nav>

      <div className="d-flex justify-content-between align-items-center mb-4">
        <h3 className="mb-0">
          My Wishlist ({wishlistItems.length} item
          {wishlistItems.length !== 1 ? "s" : ""})
        </h3>
      </div>

      <div className="row">
        {wishlistItems.map((item) => (
          <div key={item.id} className="col-xl-3 col-lg-4 col-md-6 mb-4">
            <div className="storefront-product-card">
              <Link
                to={`/store/product/${item.id}`}
                className="product-image-wrap"
              >
                <img
                  src={item.image}
                  alt={item.name}
                  className="product-image"
                />
              </Link>
              <div className="product-info">
                <span className="product-category">{item.category}</span>
                <Link
                  to={`/store/product/${item.id}`}
                  className="product-name"
                >
                  {item.name}
                </Link>
                <div className="product-price-row">
                  <span className="product-price">
                    ${item.price.toFixed(2)}
                  </span>
                  {item.oldPrice && (
                    <span className="product-old-price">
                      ${item.oldPrice.toFixed(2)}
                    </span>
                  )}
                </div>
                <div className="d-flex gap-2 mt-2">
                  <button
                    className="btn btn-primary btn-sm flex-grow-1"
                    disabled={!item.inStock}
                    onClick={() => handleMoveToCart(item)}
                  >
                    <i className="ti ti-shopping-cart me-1"></i>
                    {item.inStock ? "Add to Cart" : "Out of Stock"}
                  </button>
                  <button
                    className="btn btn-outline-danger btn-sm"
                    onClick={() => {
                      dispatch(removeFromWishlist(item.id));
                      showAlert({
                        type: "info",
                        message: `${item.name} removed from wishlist.`,
                        autoClose: 2000,
                      });
                    }}
                    title="Remove from Wishlist"
                  >
                    <i className="ti ti-trash"></i>
                  </button>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default StorefrontWishlist;
