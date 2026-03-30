import React from "react";
import { Link } from "react-router-dom";
import { useSelector } from "react-redux";
import type { RootState } from "../../core/redux/store";

const sampleOrders = [
  {
    id: "ORD-001",
    date: "2025-12-01",
    status: "Delivered",
    statusColor: "success",
    items: 3,
    total: 259.97,
  },
  {
    id: "ORD-002",
    date: "2025-12-03",
    status: "Shipped",
    statusColor: "info",
    items: 1,
    total: 89.99,
  },
  {
    id: "ORD-003",
    date: "2025-12-05",
    status: "Processing",
    statusColor: "warning",
    items: 2,
    total: 149.98,
  },
];

const StorefrontOrders: React.FC = () => {
  const token = useSelector((state: RootState) => state.auth?.token);

  if (!token) {
    return (
      <div className="container py-5 text-center">
        <i
          className="ti ti-lock"
          style={{ fontSize: 80, color: "#ccc" }}
        ></i>
        <h3 className="mt-3">Please Sign In</h3>
        <p className="text-muted">
          You need to sign in to view your order history.
        </p>
        <Link to="/signin" className="btn btn-primary mt-2">
          <i className="ti ti-login me-2"></i>Sign In
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
          <li className="breadcrumb-item active">My Orders</li>
        </ol>
      </nav>

      <h3 className="mb-4">My Orders</h3>

      {sampleOrders.length === 0 ? (
        <div className="text-center py-5">
          <i
            className="ti ti-package-off"
            style={{ fontSize: 80, color: "#ccc" }}
          ></i>
          <h4 className="mt-3">No Orders Yet</h4>
          <p className="text-muted">
            You haven't placed any orders yet. Start shopping!
          </p>
          <Link to="/store/products" className="btn btn-primary mt-2">
            <i className="ti ti-shopping-bag me-2"></i>Browse Products
          </Link>
        </div>
      ) : (
        <div className="card border">
          <div className="table-responsive">
            <table className="table table-hover mb-0">
              <thead className="table-light">
                <tr>
                  <th>Order ID</th>
                  <th>Date</th>
                  <th>Items</th>
                  <th>Total</th>
                  <th>Status</th>
                  <th>Action</th>
                </tr>
              </thead>
              <tbody>
                {sampleOrders.map((order) => (
                  <tr key={order.id}>
                    <td>
                      <strong>{order.id}</strong>
                    </td>
                    <td>{new Date(order.date).toLocaleDateString()}</td>
                    <td>{order.items} item{order.items !== 1 ? "s" : ""}</td>
                    <td>
                      <strong>${order.total.toFixed(2)}</strong>
                    </td>
                    <td>
                      <span
                        className={`badge bg-${order.statusColor}-light text-${order.statusColor}`}
                      >
                        {order.status}
                      </span>
                    </td>
                    <td>
                      <button className="btn btn-sm btn-outline-primary">
                        <i className="ti ti-eye me-1"></i>View
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      <div className="text-center mt-4">
        <Link to="/store/products" className="btn btn-outline-primary">
          <i className="ti ti-shopping-bag me-2"></i>Continue Shopping
        </Link>
      </div>
    </div>
  );
};

export default StorefrontOrders;
