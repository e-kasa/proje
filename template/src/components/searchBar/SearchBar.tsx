// src/features/pos/components/SearchBar/SearchBar.tsx
import { useState } from 'react';

interface SearchBarProps {
    onSearch: (query: string) => void;
}

export const SearchBar = ({ onSearch }: SearchBarProps) => {
    const [query, setQuery] = useState('');

    const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const value = e.target.value;
        setQuery(value);
        onSearch(value);
    };

    return (
        <div className="input-icon-start pos-search position-relative">
      <span className="input-icon-addon">
        <i className="ti ti-search" />
      </span>
            <input
                type="text"
                className="form-control"
                placeholder="Ürün Ara..."
                value={query}
                onChange={handleChange}
            />
        </div>
    );
};