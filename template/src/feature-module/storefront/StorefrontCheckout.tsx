import React, { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useSelector, useDispatch } from "react-redux";
import type { RootState } from "../../core/redux/store";
import { clearCart } from "../../store/cartSlice";
import { useAlert } from "../../components/AlertContext";

const StorefrontCheckout: React.FC = () => {
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const { showAlert } = useAlert();
  const cartItems = useSelector((state: RootState) => state.cart.items);
  const token = useSelector((state: RootState) => state.auth?.token);

  const [formData, setFormData] = useState({
    firstName: "",
    lastName: "",
    email: "",
    phone: "",
    address: "",
    city: "",
    state: "",
    zipCode: "",
    country: "US",
    paymentMethod: "card",
  });

  const subtotal = cartItems.reduce(
    (sum, item) => sum + item.price * item.quantity,
    0
  );
  const shipping = subtotal > 50 ? 0 : 9.99;
  const tax = subtotal * 0.08;
  const total = subtotal + shipping + tax;

  const handleChange = (
    e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>
  ) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    if (!token) {
      showAlert({
        type: "warning",
        message: "Please sign in to complete your order.",
        autoClose: 3000,
      });
      navigate("/signin");
      return;
    }

    if (cartItems.length === 0) {
      showAlert({
        type: "warning",
        message: "Your cart is empty.",
        autoClose: 3000,
      });
      return;
    }

    // Simulate order placement
    showAlert({
      type: "success",
      message: "Order placed successfully! Thank you for your purchase.",
      autoClose: 4000,
    });
    dispatch(clearCart());
    navigate("/store");
  };

  if (cartItems.length === 0) {
    return (
      <div className="container py-5 text-center">
        <i
          className="ti ti-shopping-cart-off"
          style={{ fontSize: 80, color: "#ccc" }}
        ></i>
        <h3 className="mt-3">No Items to Checkout</h3>
        <p className="text-muted">Add some products to your cart first.</p>
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
          <li className="breadcrumb-item">
            <Link to="/store/cart">Cart</Link>
          </li>
          <li className="breadcrumb-item active">Checkout</li>
        </ol>
      </nav>

      <h3 className="mb-4">Checkout</h3>

      <form onSubmit={handleSubmit}>
        <div className="row">
          {/* Billing Form */}
          <div className="col-lg-7 mb-4">
            {!token && (
              <div className="alert alert-warning mb-4">
                <i className="ti ti-alert-circle me-2"></i>
                <Link to="/signin" className="alert-link">
                  Sign in
                </Link>{" "}
                to complete your purchase or continue as guest.
              </div>
            )}

            <div className="card border">
              <div className="card-header bg-light">
                <h5 className="mb-0">
                  <i className="ti ti-map-pin me-2"></i>Shipping Information
                </h5>
              </div>
              <div className="card-body">
                <div className="row">
                  <div className="col-md-6 mb-3">
                    <label className="form-label">First Name *</label>
                    <input
                      type="text"
                      name="firstName"
                      className="form-control"
                      value={formData.firstName}
                      onChange={handleChange}
                      required
                    />
                  </div>
                  <div className="col-md-6 mb-3">
                    <label className="form-label">Last Name *</label>
                    <input
                      type="text"
                      name="lastName"
                      className="form-control"
                      value={formData.lastName}
                      onChange={handleChange}
                      required
                    />
                  </div>
                  <div className="col-md-6 mb-3">
                    <label className="form-label">Email *</label>
                    <input
                      type="email"
                      name="email"
                      className="form-control"
                      value={formData.email}
                      onChange={handleChange}
                      required
                    />
                  </div>
                  <div className="col-md-6 mb-3">
                    <label className="form-label">Phone</label>
                    <input
                      type="tel"
                      name="phone"
                      className="form-control"
                      value={formData.phone}
                      onChange={handleChange}
                    />
                  </div>
                  <div className="col-12 mb-3">
                    <label className="form-label">Address *</label>
                    <input
                      type="text"
                      name="address"
                      className="form-control"
                      value={formData.address}
                      onChange={handleChange}
                      required
                    />
                  </div>
                  <div className="col-md-4 mb-3">
                    <label className="form-label">City *</label>
                    <input
                      type="text"
                      name="city"
                      className="form-control"
                      value={formData.city}
                      onChange={handleChange}
                      required
                    />
                  </div>
                  <div className="col-md-4 mb-3">
                    <label className="form-label">State</label>
                    <input
                      type="text"
                      name="state"
                      className="form-control"
                      value={formData.state}
                      onChange={handleChange}
                    />
                  </div>
                  <div className="col-md-4 mb-3">
                    <label className="form-label">ZIP Code *</label>
                    <input
                      type="text"
                      name="zipCode"
                      className="form-control"
                      value={formData.zipCode}
                      onChange={handleChange}
                      required
                    />
                  </div>
                </div>
              </div>
            </div>

            {/* Payment Method */}
            <div className="card border mt-3">
              <div className="card-header bg-light">
                <h5 className="mb-0">
                  <i className="ti ti-credit-card me-2"></i>Payment Method
                </h5>
              </div>
              <div className="card-body">
                <div className="form-check mb-2">
                  <input
                    className="form-check-input"
                    type="radio"
                    name="paymentMethod"
                    id="card"
                    value="card"
                    checked={formData.paymentMethod === "card"}
                    onChange={handleChange}
                  />
                  <label className="form-check-label" htmlFor="card">
                    <i className="ti ti-credit-card me-1"></i>Credit / Debit
                    Card
                  </label>
                </div>
                <div className="form-check mb-2">
                  <input
                    className="form-check-input"
                    type="radio"
                    name="paymentMethod"
                    id="paypal"
                    value="paypal"
                    checked={formData.paymentMethod === "paypal"}
                    onChange={handleChange}
                  />
                  <label className="form-check-label" htmlFor="paypal">
                    <i className="ti ti-brand-paypal me-1"></i>PayPal
                  </label>
                </div>
                <div className="form-check">
                  <input
                    className="form-check-input"
                    type="radio"
                    name="paymentMethod"
                    id="cash"
                    value="cash"
                    checked={formData.paymentMethod === "cash"}
                    onChange={handleChange}
                  />
                  <label className="form-check-label" htmlFor="cash">
                    <i className="ti ti-cash me-1"></i>Cash on Delivery
                  </label>
                </div>
              </div>
            </div>
          </div>

          {/* Order Summary */}
          <div className="col-lg-5">
            <div className="card border position-sticky" style={{ top: 90 }}>
              <div className="card-header bg-light">
                <h5 className="mb-0">Order Summary</h5>
              </div>
              <div className="card-body">
                {cartItems.map((item) => (
                  <div
                    key={item.id}
                    className="d-flex align-items-center mb-3 pb-3 border-bottom"
                  >
                    <img
                      src={item.image}
                      alt={item.name}
                      style={{
                        width: 48,
                        height: 48,
                        objectFit: "contain",
                        borderRadius: 6,
                        background: "#f8f9fa",
                        padding: 4,
                        marginRight: 12,
                      }}
                    />
                    <div className="flex-grow-1">
                      <div className="fw-semibold small">{item.name}</div>
                      <div className="text-muted small">
                        Qty: {item.quantity}
                      </div>
                    </div>
                    <div className="fw-semibold">
                      ${(item.price * item.quantity).toFixed(2)}
                    </div>
                  </div>
                ))}

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
                <div className="d-flex justify-content-between mb-4">
                  <strong className="fs-5">Total</strong>
                  <strong className="fs-5 text-primary">
                    ${total.toFixed(2)}
                  </strong>
                </div>

                <button type="submit" className="btn btn-primary w-100 btn-lg">
                  <i className="ti ti-check me-2"></i>Place Order
                </button>

                <div className="text-center mt-3">
                  <small className="text-muted">
                    <i className="ti ti-shield-check me-1"></i>
                    Your payment information is secure
                  </small>
                </div>
              </div>
            </div>
          </div>
        </div>
      </form>
    </div>
  );
};

export default StorefrontCheckout;
