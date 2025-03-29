import React from 'react';
import './global.css';

const DisasterFilter = ({ filters, setFilters, disasterCounts }) => {
  const disasterNames = {
    EQ: 'Earthquake',
    FL: 'Flood',
    TC: 'Cyclone',
    VO: 'Volcano',
    DR: 'Drought',
    WF: 'Wildfire'
  };

  const handleFilterChange = (type) => {
    setFilters(prev => ({
      ...prev,
      [type]: !prev[type]
    }));
  };

  const toggleAllFilters = (value) => {
    const newFilters = {};
    Object.keys(filters).forEach(type => {
      newFilters[type] = value;
    });
    setFilters(newFilters);
  };

  return (
    <div className="disaster-filter" style={{
      backgroundColor: 'white',
      padding: '1rem',
      borderRadius: '8px',
      boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
      marginBottom: '1rem'
    }}>
      <h3 style={{ marginTop: 0, marginBottom: '1rem' }}>Filter Disasters</h3>
      <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
        {Object.entries(filters).map(([type, isActive]) => (
          <label key={type} style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <input
              type="checkbox"
              checked={isActive}
              onChange={() => handleFilterChange(type)}
            />
            <span>
              {disasterNames[type]} 
              <span style={{ color: '#666', marginLeft: '0.3rem' }}>
                ({disasterCounts[type] || 0})
              </span>
            </span>
          </label>
        ))}
      </div>
      <div style={{ display: 'flex', gap: '0.5rem', marginTop: '1rem' }}>
        <button 
          onClick={() => toggleAllFilters(true)}
          style={{ padding: '0.3rem 0.5rem', fontSize: '0.8rem' }}
        >
          Select All
        </button>
        <button 
          onClick={() => toggleAllFilters(false)}
          style={{ padding: '0.3rem 0.5rem', fontSize: '0.8rem' }}
        >
          Deselect All
        </button>
      </div>
    </div>
  );
};

export default DisasterFilter;