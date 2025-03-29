import React from 'react';
import './global.css';

const SafeSpotMarker = ({ 
  safeSpots, 
  onAddSafeSpot, 
  onRemoveSafeSpot, 
  onClearSafeSpots 
}) => {
  return (
    <div className="safe-spot-controls" style={{
      backgroundColor: 'white',
      padding: '0.75rem',
      borderRadius: '4px',
      boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
      flex: 1
    }}>
      <h3 style={{ 
        margin: '0 0 0.5rem 0',
        fontSize: '0.95rem',
        color: '#2c3e50'
      }}>
        Safe Spots Manager
      </h3>
      
      <div style={{ 
        marginBottom: '0.75rem',
        fontSize: '0.85rem',
        color: '#34495e'
      }}>
        <p style={{ margin: '0 0 0.25rem 0' }}>
          <strong>Total Marked:</strong> {safeSpots.length}
        </p>
        <p style={{ margin: 0 }}>
          Click map to add, click markers to remove
        </p>
      </div>

      <div style={{ display: 'flex', gap: '0.5rem' }}>
        <button
          onClick={() => onAddSafeSpot({ lat: 20, lng: 0 })}
          style={{
            padding: '0.35rem 0.7rem',
            fontSize: '0.8rem',
            backgroundColor: '#27ae60',
            color: 'white',
            border: 'none',
            borderRadius: '3px',
            cursor: 'pointer',
            flex: 1
          }}
        >
          Add Sample Spot
        </button>
        
        <button
          onClick={onClearSafeSpots}
          style={{
            padding: '0.35rem 0.7rem',
            fontSize: '0.8rem',
            backgroundColor: '#e74c3c',
            color: 'white',
            border: 'none',
            borderRadius: '3px',
            cursor: 'pointer',
            flex: 1
          }}
        >
          Clear All
        </button>
      </div>

      {safeSpots.length > 0 && (
        <div style={{ 
          marginTop: '0.75rem',
          maxHeight: '120px',
          overflowY: 'auto',
          borderTop: '1px solid #ecf0f1',
          paddingTop: '0.5rem'
        }}>
          <h4 style={{ 
            fontSize: '0.85rem',
            margin: '0 0 0.5rem 0',
            color: '#7f8c8d'
          }}>
            Saved Spots:
          </h4>
          <ul style={{
            listStyle: 'none',
            padding: 0,
            margin: 0,
            fontSize: '0.8rem'
          }}>
            {safeSpots.map(spot => (
              <li 
                key={spot.id}
                style={{
                  padding: '0.25rem 0',
                  borderBottom: '1px solid #ecf0f1',
                  display: 'flex',
                  justifyContent: 'space-between'
                }}
              >
                <span>{spot.name}</span>
                <button
                  onClick={() => onRemoveSafeSpot(spot.id)}
                  style={{
                    background: 'none',
                    border: 'none',
                    color: '#e74c3c',
                    cursor: 'pointer',
                    fontSize: '0.75rem'
                  }}
                >
                  Remove
                </button>
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
};

export default SafeSpotMarker;