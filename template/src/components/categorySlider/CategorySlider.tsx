// src/features/pos/components/CategorySlider/CategorySlider.tsx

import Slider from 'react-slick';
import 'slick-carousel/slick/slick.css';
import 'slick-carousel/slick/slick-theme.css';
import {useCategories} from "../../feature-module/pos/hooks/useCategories.ts";

interface CategorySliderProps {
    selectedCategory?: number;
    onSelectCategory: (categoryId?: number) => void;
}

export const CategorySlider = ({
                                   selectedCategory,
                                   onSelectCategory,
                               }: CategorySliderProps) => {
    const { categories, loading } = useCategories();

    const settings = {
        dots: false,
        autoplay: false,
        slidesToShow: 8,
        arrows: true,
        infinite: false,
        speed: 500,
        responsive: [
            { breakpoint: 1400, settings: { slidesToShow: 7 } },
            { breakpoint: 1200, settings: { slidesToShow: 6 } },
            { breakpoint: 992, settings: { slidesToShow: 5 } },
            { breakpoint: 768, settings: { slidesToShow: 4 } },
            { breakpoint: 576, settings: { slidesToShow: 3 } },
        ],
    };

    if (loading) {
        return (
            <div className="text-center py-3">
                <div className="spinner-border spinner-border-sm text-primary" role="status">
                    <span className="visually-hidden">Yükleniyor...</span>
                </div>
            </div>
        );
    }

    return (
        <div className="category-slider-wrapper">
            <Slider {...settings} className="category-slider">
                {/* Tümü */}
                <div className="px-2">
                    <div
                        onClick={() => onSelectCategory(undefined)}
                        className={`category-item text-center ${!selectedCategory ? 'active' : ''}`}
                        role="button"
                        tabIndex={0}
                    >
                        <div className="category-icon-wrapper mb-2">
                            <div className="category-icon">
                                <i className="ti ti-category-2 fs-3" />
                            </div>
                        </div>
                        <p className="category-name mb-0">Tümü</p>
                    </div>
                </div>

                {/* Kategoriler */}
                {categories.map((category) => (
                    <div key={category.id} className="px-2">
                        <div
                            onClick={() => onSelectCategory(category.id)}
                            className={`category-item text-center ${
                                selectedCategory === category.id ? 'active' : ''
                            }`}
                            role="button"
                            tabIndex={0}
                        >
                            <div className="category-icon-wrapper mb-2">
                                <img
                                    src={category.imageUrl}
                                    alt={category.name}
                                    className="category-icon"
                                />
                            </div>
                            <p className="category-name mb-0">{category.name}</p>
                            <span className="category-count">{category.itemCount}</span>
                        </div>
                    </div>
                ))}
            </Slider>

            <style>{`
        .category-slider-wrapper {
          background: #f8f9fa;
          border-radius: 12px;
          padding: 15px 10px;
        }

        .category-slider .slick-slide {
          padding: 0 5px;
        }

        .category-slider .slick-arrow {
          width: 32px;
          height: 32px;
          background: white;
          border-radius: 50%;
          box-shadow: 0 2px 8px rgba(0,0,0,0.1);
          z-index: 10;
        }

        .category-slider .slick-arrow:before {
          color: #6c757d;
          font-size: 18px;
        }

        .category-slider .slick-prev {
          left: -15px;
        }

        .category-slider .slick-next {
          right: -15px;
        }

        .category-item {
          padding: 12px 8px;
          border-radius: 10px;
          cursor: pointer;
          transition: all 0.3s ease;
          background: white;
          border: 2px solid transparent;
        }

        .category-item:hover {
          transform: translateY(-2px);
          box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        }

        .category-item.active {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          border-color: #667eea;
          color: white;
        }

        .category-item.active .category-name,
        .category-item.active .category-count {
          color: white !important;
        }

        .category-icon-wrapper {
          display: flex;
          align-items: center;
          justify-content: center;
          height: 50px;
        }

        .category-icon {
          width: 45px;
          height: 45px;
          border-radius: 10px;
          object-fit: cover;
          background: white;
          display: flex;
          align-items: center;
          justify-content: center;
          box-shadow: 0 2px 6px rgba(0,0,0,0.08);
        }

        .category-item.active .category-icon {
          background: rgba(255,255,255,0.2);
          backdrop-filter: blur(10px);
        }

        .category-name {
          font-size: 12px;
          font-weight: 600;
          color: #495057;
          margin-bottom: 2px;
          white-space: nowrap;
          overflow: hidden;
          text-overflow: ellipsis;
        }

        .category-count {
          font-size: 10px;
          color: #6c757d;
          font-weight: 500;
        }

        /* Responsive */
        @media (max-width: 768px) {
          .category-slider-wrapper {
            padding: 10px 5px;
          }

          .category-item {
            padding: 8px 4px;
          }

          .category-icon {
            width: 40px;
            height: 40px;
          }

          .category-name {
            font-size: 11px;
          }

          .category-count {
            font-size: 9px;
          }
        }
      `}</style>
        </div>
    );
};