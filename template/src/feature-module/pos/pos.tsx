// src/features/pos/pages/Pos.tsx
import { useState, useEffect } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { CategorySlider } from '../../components/categorySlider/CategorySlider';
import { ProductGrid } from '../../components/productGrid/ProductGrid';
import { OrderPanel } from '../../components/orderPanel/OrderPanel';
import PosModals from '../../core/modals/pos-modal/posModalstjsx';

const Pos = () => {
    const [selectedCategory, setSelectedCategory] = useState<number | undefined>();
    const [searchQuery, setSearchQuery] = useState('');
    const Location = useLocation();

    useEffect(() => {
        document.body.classList.add('pos-page');
        return () => {
            document.body.classList.remove('pos-page');
        };
    }, [Location.pathname]);

    return (
        <div className="main-wrapper">
            <div className="page-wrapper pos-pg-wrapper ms-0">
                <div className="content pos-design pos-two p-0">
                    <div className="row align-items-start pos-wrapper">

                        {/* SOL TARAF - ÜRÜNLER */}
                        <div className="col-md-12 col-lg-6 col-xl-8 ps-0">
                            <div className="pos-categories tabs_wrapper">

                                {/* Header */}
                                <div className="pos-products-bar d-flex align-items-center justify-content-between">
                                    <div className="d-flex align-items-center">
                                        <div className="pos-selection">
                                            <h5>Hoşgeldiniz, Admin</h5>
                                            <p>{new Date().toLocaleDateString('tr-TR', {
                                                day: 'numeric',
                                                month: 'long',
                                                year: 'numeric',
                                            })}</p>
                                        </div>
                                    </div>
                                    <div className="d-flex align-items-center">
                                        <Link to="#" className="btn btn-secondary me-2">
                                            <i className="ti ti-tag me-1" />
                                            Markalar
                                        </Link>
                                        <Link to="#" className="btn btn-primary">
                                            <i className="ti ti-star me-1" />
                                            Öne Çıkanlar
                                        </Link>
                                    </div>
                                </div>

                                {/* Kategori Slider */}
                                <div className="tabs_container">
                                    <CategorySlider
                                        selectedCategory={selectedCategory}
                                        onSelectCategory={setSelectedCategory}
                                    />
                                </div>

                                {/* ARAMA BARI - GÜZELLEŞTİRİLMİŞ */}
                                <div className="pos-search-bar">
                                    <div className="search-bar-wrapper">
                                        <div className="search-input-group">
                      <span className="search-icon">
                        <i className="ti ti-search" />
                      </span>
                                            <input
                                                type="search"
                                                className="form-control search-input"
                                                placeholder="Ürün ara (isim, barkod, SKU...)"
                                                value={searchQuery}
                                                onChange={(e) => setSearchQuery(e.target.value)}
                                            />
                                            {searchQuery && (
                                                <button
                                                    className="clear-search-btn"
                                                    onClick={() => setSearchQuery('')}
                                                >
                                                    <i className="ti ti-x" />
                                                </button>
                                            )}
                                        </div>
                                    </div>
                                </div>

                                {/* Ürün Grid */}
                                <div className="tabs_container">
                                    <div className="product-body">
                                        <ProductGrid
                                            categoryId={selectedCategory}
                                            searchQuery={searchQuery}
                                        />
                                    </div>
                                </div>

                            </div>
                        </div>

                        {/* SAĞ TARAF - SİPARİŞ PANELİ */}
                        <div className="col-md-12 col-lg-6 col-xl-4 ps-0">
                            <OrderPanel />
                        </div>

                    </div>
                </div>
            </div>
            <PosModals />

            {/* ARAMA BARI ÖZEL STİLLER */}
            <style>{`
        .pos-search-bar {
          padding: 15px 20px;
          background: #f8f9fa;
          border-radius: 0;
        }

        .search-bar-wrapper {
          max-width: 100%;
          margin: 0 auto;
        }

        .search-input-group {
          position: relative;
          display: flex;
          align-items: center;
          background: white;
          border-radius: 10px;
          box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
          overflow: hidden;
          transition: all 0.3s ease;
        }

        .search-input-group:focus-within {
          box-shadow: 0 4px 12px rgba(102, 126, 234, 0.25);
          border: 2px solid #667eea;
        }

        .search-icon {
          display: flex;
          align-items: center;
          justify-content: center;
          padding: 0 15px;
          color: #6c757d;
          font-size: 20px;
          pointer-events: none;
        }

        .search-input {
          flex: 1;
          border: none;
          outline: none;
          padding: 14px 15px 14px 0;
          font-size: 15px;
          color: #495057;
          background: transparent;
          box-shadow: none !important;
        }

        .search-input::placeholder {
          color: #adb5bd;
          font-weight: 400;
        }

        .clear-search-btn {
          display: flex;
          align-items: center;
          justify-content: center;
          width: 36px;
          height: 36px;
          margin-right: 8px;
          background: #f1f3f5;
          border: none;
          border-radius: 50%;
          color: #6c757d;
          cursor: pointer;
          transition: all 0.2s ease;
          font-size: 18px;
        }

        .clear-search-btn:hover {
          background: #e9ecef;
          color: #495057;
        }

        .clear-search-btn:active {
          transform: scale(0.95);
        }

        /* Responsive */
        @media (max-width: 768px) {
          .pos-search-bar {
            padding: 12px 15px;
          }

          .search-input {
            padding: 12px 12px 12px 0;
            font-size: 14px;
          }

          .search-icon {
            padding: 0 12px;
            font-size: 18px;
          }

          .clear-search-btn {
            width: 32px;
            height: 32px;
            font-size: 16px;
          }
        }

        /* Focus animasyonu */
        @keyframes searchPulse {
          0% {
            box-shadow: 0 4px 12px rgba(102, 126, 234, 0.25);
          }
          50% {
            box-shadow: 0 4px 16px rgba(102, 126, 234, 0.35);
          }
          100% {
            box-shadow: 0 4px 12px rgba(102, 126, 234, 0.25);
          }
        }

        .search-input:focus {
          animation: searchPulse 2s ease-in-out infinite;
        }
      `}</style>
        </div>
    );
};

export default Pos;