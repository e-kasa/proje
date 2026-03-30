import React from "react";
import { Link } from "react-router-dom";
import { logoPng } from "../../utils/imagepath";

const StorefrontFooter: React.FC = () => {
  return (
    <footer className="storefront-footer">
      <div className="storefront-footer-main">
        <div className="container">
          <div className="row">
            {/* Brand */}
            <div className="col-lg-4 col-md-6 mb-4 mb-lg-0">
              <div className="footer-brand">
                <img src={logoPng} alt="DreamsPOS" className="footer-logo mb-3" />
                <p className="footer-desc">
                  Your one-stop online shop for the best products at great prices.
                  Quality guaranteed with fast shipping worldwide.
                </p>
                <div className="footer-social">
                  <a href="#" className="social-link" onClick={(e) => e.preventDefault()}>
                    <i className="ti ti-brand-facebook"></i>
                  </a>
                  <a href="#" className="social-link" onClick={(e) => e.preventDefault()}>
                    <i className="ti ti-brand-twitter"></i>
                  </a>
                  <a href="#" className="social-link" onClick={(e) => e.preventDefault()}>
                    <i className="ti ti-brand-instagram"></i>
                  </a>
                  <a href="#" className="social-link" onClick={(e) => e.preventDefault()}>
                    <i className="ti ti-brand-youtube"></i>
                  </a>
                </div>
              </div>
            </div>

            {/* Quick Links */}
            <div className="col-lg-2 col-md-6 col-6 mb-4 mb-lg-0">
              <h5 className="footer-title">Quick Links</h5>
              <ul className="footer-links">
                <li><Link to="/store">Home</Link></li>
                <li><Link to="/store/products">All Products</Link></li>
                <li><Link to="/store/products?badge=sale">Sale</Link></li>
                <li><Link to="/store/products?badge=new">New Arrivals</Link></li>
              </ul>
            </div>

            {/* Customer Service */}
            <div className="col-lg-2 col-md-6 col-6 mb-4 mb-lg-0">
              <h5 className="footer-title">Customer Service</h5>
              <ul className="footer-links">
                <li><Link to="/store/orders">Track Order</Link></li>
                <li><Link to="/store/cart">Shopping Cart</Link></li>
                <li><Link to="/store/wishlist">Wishlist</Link></li>
                <li><Link to="/faq">FAQ</Link></li>
              </ul>
            </div>

            {/* Contact Info */}
            <div className="col-lg-4 col-md-6">
              <h5 className="footer-title">Contact Us</h5>
              <ul className="footer-contact">
                <li>
                  <i className="ti ti-map-pin me-2"></i>
                  123 Commerce Street, New York, NY 10001
                </li>
                <li>
                  <i className="ti ti-phone me-2"></i>
                  +1 (555) 123-4567
                </li>
                <li>
                  <i className="ti ti-mail me-2"></i>
                  support@dreamspos.com
                </li>
                <li>
                  <i className="ti ti-clock me-2"></i>
                  Mon - Fri: 9:00 AM - 6:00 PM
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>

      {/* Bottom Bar */}
      <div className="storefront-footer-bottom">
        <div className="container">
          <div className="row align-items-center">
            <div className="col-md-6">
              <p className="mb-0">
                &copy; {new Date().getFullYear()} DreamsPOS. All rights reserved.
              </p>
            </div>
            <div className="col-md-6 text-md-end">
              <div className="payment-methods">
                <i className="ti ti-brand-visa" title="Visa"></i>
                <i className="ti ti-brand-mastercard" title="Mastercard"></i>
                <i className="ti ti-brand-paypal" title="PayPal"></i>
                <i className="ti ti-credit-card" title="Credit Card"></i>
              </div>
            </div>
          </div>
        </div>
      </div>
    </footer>
  );
};

export default StorefrontFooter;
