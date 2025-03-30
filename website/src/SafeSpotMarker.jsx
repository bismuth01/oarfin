import React, { useState } from 'react';
import './global.css';

const SafeSpotMarker = ({ 
  safeSpots, 
  onAddSafeSpot, 
  onRemoveSafeSpot, 
  onClearSafeSpots,
  onSendToBackend,
  onClickPosition
}) => {
  const [formData, setFormData] = useState({
    lat: '',
    lng: '',
    name: '',
    eventid: ''
  });
  const [errors, setErrors] = useState({});

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
    // Clear error when typing
    if (errors[name]) {
      setErrors(prev => ({ ...prev, [name]: '' }));
    }
  };


  const handleSubmit = (e) => {
    e.preventDefault();
    if (formData.lat && formData.lng) {
      onAddSafeSpot({
        lat: parseFloat(formData.lat),
        lng: parseFloat(formData.lng),
        name: formData.name || `Safe Spot ${safeSpots.length + 1}`,
        eventid: formData.eventid || `safespot-${Date.now()}` // Ensure we always have an ID
      });
      setFormData({ lat: '', lng: '', name: '', eventid: '' });
    }
  };

  const handleSendToBackend = () => {
    const data = {
      safeSpots: safeSpots.map(spot => ({
        latitude: spot.position.lat,
        longitude: spot.position.lng,
        name: spot.name,
        eventId: spot.eventid
      }))
    };
    onSendToBackend(data);
  };

  return (
    <div className="safe-spot-controls" style={{
      backgroundColor: 'white',
      padding: '0.5rem',
      borderRadius: '4px',
      boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
      flex: 1,
      fontSize: '0.8rem'
    }}>
      <h3 style={{ 
        margin: '0 0 0.5rem 0',
        fontSize: '0.9rem',
        color: '#2c3e50'
      }}>
        Safe Spots Manager
      </h3>
      
      {onClickPosition && (
        <div style={{ 
          marginBottom: '0.5rem',
          padding: '0.4rem',
          backgroundColor: '#f8f9fa',
          borderRadius: '3px',
          border: '1px solid #e9ecef',
          fontSize: '0.75rem'
        }}>
          <p style={{ margin: '0 0 0.2rem 0' }}>
            <strong>Clicked Position:</strong> 
            <br />Lat: {onClickPosition.lat.toFixed(6)}
            <br />Lng: {onClickPosition.lng.toFixed(6)}
          </p>
          <button
            onClick={() => {
              setFormData(prev => ({
                ...prev,
                lat: onClickPosition.lat.toFixed(6),
                lng: onClickPosition.lng.toFixed(6)
              }));
            }}
            style={{
              padding: '0.2rem 0.4rem',
              fontSize: '0.7rem',
              backgroundColor: '#3498db',
              color: 'white',
              border: 'none',
              borderRadius: '2px',
              cursor: 'pointer',
              marginTop: '0.2rem'
            }}
          >
            Use This Position
          </button>
        </div>
      )}

      <form onSubmit={handleSubmit} style={{ marginBottom: '0.5rem' }}>
        <div style={{ marginBottom: '0.4rem' }}>
          <label style={{ 
            display: 'block', 
            marginBottom: '0.2rem',
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
              padding: '0.3rem',
              border: `1px solid ${errors.lat ? '#e74c3c' : '#ced4da'}`,
              borderRadius: '2px',
              fontSize: '0.75rem'
            }}
          />
          {errors.lat && <span style={{ color: '#e74c3c', fontSize: '0.7rem' }}>{errors.lat}</span>}
        </div>
        
        <div style={{ marginBottom: '0.4rem' }}>
          <label style={{ 
            display: 'block', 
            marginBottom: '0.2rem',
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
              padding: '0.3rem',
              border: `1px solid ${errors.lng ? '#e74c3c' : '#ced4da'}`,
              borderRadius: '2px',
              fontSize: '0.75rem'
            }}
          />
          {errors.lng && <span style={{ color: '#e74c3c', fontSize: '0.7rem' }}>{errors.lng}</span>}
        </div>
        
        <div style={{ marginBottom: '0.4rem' }}>
          <label style={{ 
            display: 'block', 
            marginBottom: '0.2rem',
            color: '#495057'
          }}>
            Event ID (required):
          </label>
          <input
            type="text"
            name="eventid"
            value={formData.eventid}
            onChange={handleInputChange}
            required
            style={{
              width: '100%',
              padding: '0.3rem',
              border: `1px solid ${errors.eventId ? '#e74c3c' : '#ced4da'}`,
              borderRadius: '2px',
              fontSize: '0.75rem'
            }}
            placeholder="Add event id of disaster whoes safe spot is marked"
            />
        </div>
        
        <div style={{ marginBottom: '0.4rem' }}>
          <label style={{ 
            display: 'block', 
            marginBottom: '0.2rem',
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
              padding: '0.3rem',
              border: '1px solid #ced4da',
              borderRadius: '2px',
              fontSize: '0.75rem'
            }}
          />
        </div>
        
        <button
          type="submit"
          style={{
            width: '100%',
            padding: '0.3rem',
            fontSize: '0.75rem',
            backgroundColor: '#27ae60',
            color: 'white',
            border: 'none',
            borderRadius: '2px',
            cursor: 'pointer',
            marginBottom: '0.4rem'
          }}
        >
          Add Safe Spot
        </button>
      </form>

      <div style={{ display: 'flex', gap: '0.3rem', marginBottom: '0.5rem' }}>
        <button
          onClick={() => setFormData({
            lat: '20',
            lng: '0',
            name: `Sample Spot ${safeSpots.length + 1}`,
            eventId: `sample-${Date.now().toString().slice(-4)}`
          })}
          style={{
            padding: '0.3rem',
            fontSize: '0.75rem',
            backgroundColor: '#3498db',
            color: 'white',
            border: 'none',
            borderRadius: '2px',
            cursor: 'pointer',
            flex: 1
          }}
        >
          Sample
        </button>
        
        <button
          onClick={onClearSafeSpots}
          style={{
            padding: '0.3rem',
            fontSize: '0.75rem',
            backgroundColor: '#e74c3c',
            color: 'white',
            border: 'none',
            borderRadius: '2px',
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
          padding: '0.3rem',
          fontSize: '0.75rem',
          backgroundColor: '#9b59b6',
          color: 'white',
          border: 'none',
          borderRadius: '2px',
          cursor: 'pointer',
          marginBottom: '0.5rem'
        }}
      >
        Send to Backend
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
            <div>
              <div>{spot.name}</div>
              <div style={{ fontSize: '0.7rem', color: '#666' }}>
                {spot.position.lat.toFixed(4)}, {spot.position.lng.toFixed(4)}
                <br />
                ID: {spot.eventid}  {/* Display the eventid here */}
              </div>
            </div>
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