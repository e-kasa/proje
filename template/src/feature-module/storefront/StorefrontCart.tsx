import React from "react";
import { Link } from "react-router-dom";
import { useSelector, useDispatch } from "react-redux";
import type { RootState } from "../../core/redux/store";
import { removeFromCart, updateQuantity, clearCart } from "../../store/cartSlice";

const StorefrontCart: React.FC = () => {
  const dispatch = useDispatch();
  const cartItems = useSelector((state: RootState) => state.cart.items);

  const subtotal = cartItems.reduce(
    (sum, item) => sum + item.price * item.quantity,
    0
  );
  const shipping = subtotal > 50 ? 0 : 9.99;
  const tax = subtotal * 0.08;
  const total = subtotal + shipping + tax;

  if (cartItems.length === 0) {
    return (
      <div className="container py-5 text-center">
        <i
          className="ti ti-shopping-cart-off"
          style={{ fontSize: 80, color: "#ccc" }}
        ></i>
        <h3 className="mt-3">Your Cart is Empty</h3>
        <p className="text-muted">
          Looks like you haven't added any items to your cart yet.
        </p>
        <Link to="/store/products" className="btn btn-primary mt-2">
          <i className="ti ti-shopping-bag me-2"></i>Continue Shopping
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
          <li className="breadcrumb-item active">Shopping Cart</li>
        </ol>
      </nav>

      <h3 className="mb-4">Shopping Cart ({cartItems.length} items)</h3>

      <div className="row">
        {/* Cart Items */}
        <div className="col-lg-8 mb-4">
          <div className="card border">
            <div className="card-body p-0">
              <div className="table-responsive">
                <table className="table mb-0">
                  <thead className="bg-light">
                    <tr>
                      <th style={{ width: "45%" }}>Product</th>
                      <th style={{ width: "15%" }}>Price</th>
                      <th style={{ width: "20%" }}>Quantity</th>
                      <th style={{ width: "15%" }}>Total</th>
                      <th style={{ width: "5%" }}></th>
                    </tr>
                  </thead>
                  <tbody>
                    {cartItems.map((item) => (
                      <tr key={item.id}>
                        <td>
                          <div className="d-flex align-items-center">
                            <img
                              src={item.image}
                              alt={item.name}
                              style={{
                                width: 64,
                                height: 64,
                                objectFit: "contain",
                                marginRight: 12,
                                borderRadius: 8,
                                background: "#f8f9fa",
                                padding: 4,
                              }}
                            />
                            <div>
                              <Link
                                to={`/store/product/${item.id}`}
                                className="fw-semibold text-dark text-decoration-none"
                              >
                                {item.name}
                              </Link>
                              <div className="text-muted small">
                                {item.category} &middot; {item.brand}
                              </div>
                            </div>
                          </div>
                        </td>
                        <td className="align-middle">
                          ${item.price.toFixed(2)}
                        </td>
                        <td className="align-middle">
                          <div className="d-flex align-items-center">
                            <button
                              className="btn btn-outline-secondary btn-sm"
                              onClick={() =>
                                dispatch(
                                  updateQuantity({
                                    id: item.id,
                                    quantity: item.quantity - 1,
                                  })
                                )
                              }
                              disabled={item.quantity <= 1}
                            >
                              <i className="ti ti-minus"></i>
                            </button>
                            <input
                              type="number"
                              className="form-control form-control-sm text-center mx-1"
                              style={{ width: 50 }}
                              value={item.quantity}
                              min={1}
                              max={99}
                              onChange={(e) =>
                                dispatch(
                                  updateQuantity({
                                    id: item.id,
                                    quantity: Number(e.target.value),
                                  })
                                )
                              }
                            />
                            <button
                              className="btn btn-outline-secondary btn-sm"
                              onClick={() =>
                                dispatch(
                                  updateQuantity({
                                    id: item.id,
                                    quantity: item.quantity + 1,
                                  })
                                )
                              }
                              disabled={item.quantity >= 99}
                            >
                              <i className="ti ti-plus"></i>
                            </button>
                          </div>
                        </td>
                        <td className="align-middle fw-semibold">
                          ${(item.price * item.quantity).toFixed(2)}
                        </td>
                        <td className="align-middle">
                          <button
                            className="btn btn-sm btn-outline-danger"
                            onClick={() =>
                              dispatch(removeFromCart(item.id))
                            }
                            title="Remove"
                          >
                            <i className="ti ti-trash"></i>
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <div className="d-flex justify-content-between mt-3">
            <Link to="/store/products" className="btn btn-outline-primary">
              <i className="ti ti-arrow-left me-1"></i>Continue Shopping
            </Link>
            <button
              className="btn btn-outline-danger"
              onClick={() => dispatch(clearCart())}
            >
              <i className="ti ti-trash me-1"></i>Clear Cart
            </button>
          </div>
        </div>

        {/* Order Summary */}
        <div className="col-lg-4">
          <div className="card border">
            <div className="card-header bg-light">
              <h5 className="mb-0">Order Summary</h5>
            </div>
            <div className="card-body">
              <div className="d-flex justify-content-between mb-2">
                <span>Subtotal</span>
                <span>${subtotal.toFixed(2)}</span>
              </div>
              <div className="d-flex justify-content-between mb-2">
                <span>Shipping</span>
                <span>
                  {shipping === 0 ? (
                    <span className="text-success">Free</span>
                  ) : (
                    `$${shipping.toFixed(2)}`
                  )}
                </span>
              </div>
              <div className="d-flex justify-content-between mb-3">
                <span>Tax (8%)</span>
                <span>${tax.toFixed(2)}</span>
              </div>
              <hr />
              <div className="d-flex justify-content-between mb-3">
                <strong className="fs-5">Total</strong>
                <strong className="fs-5 text-primary">
                  ${total.toFixed(2)}
                </strong>
              </div>

              {shipping > 0 && (
                <div className="alert alert-info py-2 small mb-3">
                  <i className="ti ti-truck me-1"></i>
                  Add ${(50 - subtotal).toFixed(2)} more for free shipping!
                </div>
              )}

              <Link
                to="/store/checkout"
                className="btn btn-primary w-100 btn-lg"
              >
                <i className="ti ti-lock me-2"></i>Proceed to Checkout
              </Link>

              <div className="text-center mt-3">
                <small className="text-muted">
                  <i className="ti ti-shield-check me-1"></i>
                  Secure checkout &middot; SSL encrypted
                </small>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default StorefrontCart;
