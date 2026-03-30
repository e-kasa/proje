import {
  stockImg01,
  stockImg02,
  stockImg03,
  stockImg04,
  stockImg05,
  stockImg06,
  expireProduct01,
  expireProduct02,
  expireProduct03,
  expireProduct04,
} from "../../utils/imagepath";

export interface StorefrontProduct {
  id: string;
  image: string;
  name: string;
  category: string;
  brand: string;
  price: number;
  oldPrice?: number;
  rating: number;
  reviewCount: number;
  description: string;
  inStock: boolean;
  badge?: "new" | "sale" | "hot";
  features?: string[];
}

export interface StorefrontCategory {
  id: string;
  name: string;
  icon: string;
  productCount: number;
  image: string;
}

export const storefrontCategories: StorefrontCategory[] = [
  {
    id: "1",
    name: "Computers",
    icon: "ti ti-device-laptop",
    productCount: 24,
    image: stockImg01,
  },
  {
    id: "2",
    name: "Electronics",
    icon: "ti ti-headphones",
    productCount: 38,
    image: stockImg03,
  },
  {
    id: "3",
    name: "Shoes",
    icon: "ti ti-shoe",
    productCount: 15,
    image: stockImg02,
  },
  {
    id: "4",
    name: "Furniture",
    icon: "ti ti-armchair",
    productCount: 21,
    image: stockImg05,
  },
  {
    id: "5",
    name: "Bags",
    icon: "ti ti-briefcase",
    productCount: 12,
    image: expireProduct01,
  },
  {
    id: "6",
    name: "Phones",
    icon: "ti ti-device-mobile",
    productCount: 30,
    image: expireProduct02,
  },
];

export const storefrontProducts: StorefrontProduct[] = [
  {
    id: "1",
    image: stockImg01,
    name: "Lenovo IdeaPad 3",
    category: "Computers",
    brand: "Lenovo",
    price: 599.99,
    oldPrice: 749.99,
    rating: 4.5,
    reviewCount: 128,
    description:
      "Powerful and portable laptop with AMD Ryzen processor, 8GB RAM, and 256GB SSD. Perfect for everyday computing needs.",
    inStock: true,
    badge: "sale",
    features: [
      "AMD Ryzen 5 Processor",
      "8GB DDR4 RAM",
      "256GB SSD",
      '15.6" FHD Display',
    ],
  },
  {
    id: "2",
    image: stockImg06,
    name: "Beats Pro",
    category: "Electronics",
    brand: "Beats",
    price: 159.99,
    rating: 4.7,
    reviewCount: 256,
    description:
      "Premium wireless headphones with active noise cancellation, crystal-clear sound, and all-day battery life.",
    inStock: true,
    badge: "hot",
    features: [
      "Active Noise Cancellation",
      "40hr Battery Life",
      "Bluetooth 5.0",
      "Premium Sound",
    ],
  },
  {
    id: "3",
    image: stockImg02,
    name: "Nike Jordan",
    category: "Shoes",
    brand: "Nike",
    price: 109.99,
    oldPrice: 139.99,
    rating: 4.8,
    reviewCount: 342,
    description:
      "Iconic basketball shoes with Air cushioning, premium leather upper, and classic Jordan design.",
    inStock: true,
    badge: "sale",
    features: [
      "Air Cushioning",
      "Premium Leather",
      "Rubber Outsole",
      "Iconic Design",
    ],
  },
  {
    id: "4",
    image: stockImg03,
    name: "Apple Series 5 Watch",
    category: "Electronics",
    brand: "Apple",
    price: 119.99,
    rating: 4.6,
    reviewCount: 189,
    description:
      "Always-on Retina display smartwatch with fitness tracking, heart rate monitoring, and seamless Apple ecosystem integration.",
    inStock: true,
    badge: "new",
    features: [
      "Always-On Display",
      "Heart Rate Monitor",
      "GPS + Cellular",
      "Water Resistant",
    ],
  },
  {
    id: "5",
    image: stockImg04,
    name: "Amazon Echo Dot",
    category: "Electronics",
    brand: "Amazon",
    price: 79.99,
    oldPrice: 99.99,
    rating: 4.3,
    reviewCount: 512,
    description:
      "Smart speaker with Alexa, rich sound quality, and smart home hub capabilities in a compact design.",
    inStock: true,
    badge: "sale",
    features: [
      "Alexa Voice Control",
      "Rich Sound",
      "Smart Home Hub",
      "Compact Design",
    ],
  },
  {
    id: "6",
    image: stockImg05,
    name: "Sanford Chair Sofa",
    category: "Furniture",
    brand: "Modern Wave",
    price: 319.99,
    rating: 4.4,
    reviewCount: 87,
    description:
      "Elegant and comfortable chair sofa with premium upholstery, ergonomic design, and modern aesthetic.",
    inStock: true,
    features: [
      "Premium Upholstery",
      "Ergonomic Design",
      "Solid Wood Frame",
      "Easy Assembly",
    ],
  },
  {
    id: "7",
    image: expireProduct01,
    name: "Red Premium Satchel",
    category: "Bags",
    brand: "Dior",
    price: 59.99,
    rating: 4.2,
    reviewCount: 64,
    description:
      "Luxurious red satchel bag crafted from premium materials with spacious compartments and adjustable strap.",
    inStock: true,
    badge: "new",
    features: [
      "Premium Material",
      "Spacious Interior",
      "Adjustable Strap",
      "Multiple Pockets",
    ],
  },
  {
    id: "8",
    image: expireProduct02,
    name: "iPhone 14 Pro",
    category: "Phones",
    brand: "Apple",
    price: 539.99,
    oldPrice: 599.99,
    rating: 4.9,
    reviewCount: 723,
    description:
      "Pro-level smartphone with Dynamic Island, 48MP camera system, A16 Bionic chip, and all-day battery life.",
    inStock: true,
    badge: "hot",
    features: [
      "48MP Camera System",
      "A16 Bionic Chip",
      "Dynamic Island",
      "All-Day Battery",
    ],
  },
  {
    id: "9",
    image: expireProduct03,
    name: "Gaming Chair",
    category: "Furniture",
    brand: "Arlime",
    price: 199.99,
    oldPrice: 249.99,
    rating: 4.1,
    reviewCount: 156,
    description:
      "Ergonomic gaming chair with lumbar support, adjustable armrests, reclining function, and breathable mesh.",
    inStock: true,
    badge: "sale",
    features: [
      "Lumbar Support",
      "Adjustable Armrests",
      "Reclining Function",
      "Breathable Mesh",
    ],
  },
  {
    id: "10",
    image: expireProduct04,
    name: "Borealis Backpack",
    category: "Bags",
    brand: "The North Face",
    price: 44.99,
    rating: 4.5,
    reviewCount: 231,
    description:
      "Durable and versatile backpack with padded laptop sleeve, multiple compartments, and comfortable straps.",
    inStock: false,
    features: [
      "Padded Laptop Sleeve",
      "Multiple Compartments",
      "Water Resistant",
      "Comfortable Straps",
    ],
  },
];
