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
      backgroundColor: '#f0f0f0',
      padding: '0.5rem',
      borderRadius: '4px',
      boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
      marginBottom: '0.5rem',
      width: '200px'
    }}>
      <h3 style={{ 
        margin: '0 0 0.5rem 0',
        fontSize: '0.9rem',
        color: '#333'
      }}>
        Filter Disasters
      </h3>
      <div style={{ 
        display: 'grid',
        gridTemplateColumns: 'repeat(2, 1fr)',
        gap: '0.3rem',
        marginBottom: '0.5rem'
      }}>
        {Object.entries(filters).map(([type, isActive]) => (
          <label key={type} style={{ 
            display: 'flex',
            alignItems: 'center',
            gap: '0.3rem',
            fontSize: '0.8rem'
          }}>
            <input
              type="checkbox"
              checked={isActive}
              onChange={() => handleFilterChange(type)}
              style={{ margin: '0' }}
            />
            <span>
              {disasterNames[type]} 
              <span style={{ 
                color: '#666',
                marginLeft: '0.2rem',
                fontSize: '0.7rem'
              }}>
                ({disasterCounts[type] || 0})
              </span>
            </span>
          </label>
        ))}
      </div>
      <div style={{ 
        display: 'flex',
        gap: '0.3rem',
        justifyContent: 'space-between'
      }}>
        <button 
          onClick={() => toggleAllFilters(true)}
          style={{ 
            padding: '0.2rem 0.3rem',
            fontSize: '0.7rem',
            borderRadius: '3px',
            border: '1px solid #ccc',
            background: '#fff'
          }}
        >
          Select All
        </button>
        <button 
          onClick={() => toggleAllFilters(false)}
          style={{ 
            padding: '0.2rem 0.3rem',
            fontSize: '0.7rem',
            borderRadius: '3px',
            border: '1px solid #ccc',
            background: '#fff'
          }}
        >
          Deselect All
        </button>
      </div>
    </div>
  );
};

export default DisasterFilter;