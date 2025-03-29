import React, { useState } from 'react';
import './global.css';

const SafeSpotMarker = ({ 
  safeSpots, 
  disasterMarkers,
  onAddSafeSpot, 
  onRemoveSafeSpot, 
  onClearSafeSpots,
  onSendToBackend,
  onClickPosition
}) => {
  const [formData, setFormData] = useState({
    lat: '',
    lng: '',
    name: ''
  });

  const [disasterType, setDisasterType] = useState('EQ');

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (formData.lat && formData.lng) {
      onAddSafeSpot({
        lat: parseFloat(formData.lat),
        lng: parseFloat(formData.lng),
        name: formData.name || `Safe Spot ${safeSpots.length + 1}`
      });
      setFormData({ lat: '', lng: '', name: '' });
    }
  };

  const handleSendToBackend = () => {
    const data = {
      safeSpots: safeSpots.map(spot => ({
        latitude: spot.position.lat,
        longitude: spot.position.lng,
        name: spot.name
      })),
      disasters: disasterMarkers.map(marker => ({
        latitude: marker.geometry.coordinates[1],
        longitude: marker.geometry.coordinates[0],
        type: marker.properties.eventtype,
        description: marker.properties.htmldescription || marker.properties.title || "Unknown"
      }))
    };
    onSendToBackend(data);
  };

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
      
      {onClickPosition && (
        <div style={{ 
          marginBottom: '0.75rem',
          padding: '0.5rem',
          backgroundColor: '#f8f9fa',
          borderRadius: '4px',
          border: '1px solid #e9ecef'
        }}>
          <p style={{ margin: '0 0 0.25rem 0', fontSize: '0.85rem' }}>
            <strong>Clicked Position:</strong> 
            <br />Lat: {onClickPosition.lat.toFixed(6)}
            <br />Lng: {onClickPosition.lng.toFixed(6)}
          </p>
          <button
            onClick={() => {
              setFormData({
                lat: onClickPosition.lat.toFixed(6),
                lng: onClickPosition.lng.toFixed(6),
                name: `Safe Spot ${safeSpots.length + 1}`
              });
            }}
            style={{
              padding: '0.25rem 0.5rem',
              fontSize: '0.75rem',
              backgroundColor: '#3498db',
              color: 'white',
              border: 'none',
              borderRadius: '3px',
              cursor: 'pointer',
              marginTop: '0.25rem'
            }}
          >
            Use This Position
          </button>
        </div>
      )}

      <form onSubmit={handleSubmit} style={{ marginBottom: '0.75rem' }}>
        <div style={{ marginBottom: '0.5rem' }}>
          <label style={{ 
            display: 'block', 
            fontSize: '0.8rem', 
            marginBottom: '0.25rem',
            color: '#495057'
          }}>
            Latitude:
          </label>
          <input
            type="number"
            name="lat"
            value={formData.lat}
            onChange={handleInputChange}
            step="any"
            required
            style={{
              width: '100%',
              padding: '0.35rem',
              fontSize: '0.8rem',
              border: '1px solid #ced4da',
              borderRadius: '3px'
            }}
          />
        </div>
        
        <div style={{ marginBottom: '0.5rem' }}>
          <label style={{ 
            display: 'block', 
            fontSize: '0.8rem', 
            marginBottom: '0.25rem',
            color: '#495057'
          }}>
            Longitude:
          </label>
          <input
            type="number"
            name="lng"
            value={formData.lng}
            onChange={handleInputChange}
            step="any"
            required
            style={{
              width: '100%',
              padding: '0.35rem',
              fontSize: '0.8rem',
              border: '1px solid #ced4da',
              borderRadius: '3px'
            }}
          />
        </div>
        
        <div style={{ marginBottom: '0.5rem' }}>
          <label style={{ 
            display: 'block', 
            fontSize: '0.8rem', 
            marginBottom: '0.25rem',
            color: '#495057'
          }}>
            Name (optional):
          </label>
          <input
            type="text"
            name="name"
            value={formData.name}
            onChange={handleInputChange}
            style={{
              width: '100%',
              padding: '0.35rem',
              fontSize: '0.8rem',
              border: '1px solid #ced4da',
              borderRadius: '3px'
            }}
          />
        </div>
        
        <button
          type="submit"
          style={{
            width: '100%',
            padding: '0.35rem 0.7rem',
            fontSize: '0.8rem',
            backgroundColor: '#27ae60',
            color: 'white',
            border: 'none',
            borderRadius: '3px',
            cursor: 'pointer',
            marginBottom: '0.5rem'
          }}
        >
          Add Safe Spot
        </button>
      </form>

      <div style={{ display: 'flex', gap: '0.5rem', marginBottom: '0.75rem' }}>
        <button
          onClick={() => setFormData({
            lat: '20',
            lng: '0',
            name: `Sample Spot ${safeSpots.length + 1}`
          })}
          style={{
            padding: '0.35rem 0.7rem',
            fontSize: '0.8rem',
            backgroundColor: '#3498db',
            color: 'white',
            border: 'none',
            borderRadius: '3px',
            cursor: 'pointer',
            flex: 1
          }}
        >
          Sample Coords
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

      <button
        onClick={handleSendToBackend}
        style={{
          width: '100%',
          padding: '0.35rem 0.7rem',
          fontSize: '0.8rem',
          backgroundColor: '#9b59b6',
          color: 'white',
          border: 'none',
          borderRadius: '3px',
          cursor: 'pointer',
          marginBottom: '0.75rem'
        }}
      >
        Send Data to Backend
      </button>

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
            Saved Spots ({safeSpots.length}):
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
                <span>{spot.name} ({spot.position.lat.toFixed(4)}, {spot.position.lng.toFixed(4)})</span>
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