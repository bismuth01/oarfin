import { useEffect, useState } from "react";
import axios from "axios";
import { MapContainer, TileLayer, Marker, Popup, Circle, Rectangle, LayersControl, useMapEvents } from "react-leaflet";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import DisasterFilter from "./DisasterFilter";
import SafeSpotMarker from "./SafeSpotMarker";
import './global.css';

// ... (keep your constants and getIcon function the same)

// Create a component to handle map clicks
function SpotMarker({ onSpotMarked }) {
  useMapEvents({
    click(e) {
      onSpotMarked(e.latlng);
    }
  });
  return null;
}

const DisasterMap = () => {
  // ... (keep your existing state and effects the same)

  const [safeSpots, setSafeSpots] = useState([]);

  const handleSpotMarked = (position, clearAll = false) => {
    if (clearAll) {
      setSafeSpots([]);
    } else if (position) {
      setSafeSpots(prev => [
        ...prev,
        {
          id: Date.now(),
          position,
          name: `Safe Spot ${prev.length + 1}`
        }
      ]);
    }
  };

  // ... (keep your loading and filter logic the same)

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100vh' }}>
      {/* Top control panel */}
      <div style={{
        display: 'flex',
        gap: '10px',
        padding: '10px',
        backgroundColor: '#f5f5f5',
        borderBottom: '1px solid #ddd'
      }}>
        <DisasterFilter 
          filters={filters}
          setFilters={setFilters}
          disasterCounts={disasterCounts}
        />
        <SafeSpotMarker onSpotMarked={handleSpotMarked} />
      </div>

      {/* Map area */}
      <div style={{ flex: 1 }}>
        <MapContainer 
          center={[20, 0]} 
          zoom={2} 
          style={{ height: '100%', width: '100%' }}
          className="rounded-md"
        >
          {/* Add the spot marker handler */}
          <SpotMarker onSpotMarked={handleSpotMarked} />

          {/* Base layers */}
          <LayersControl position="topright">
            <LayersControl.BaseLayer checked name="Satellite">
              <TileLayer
                url="https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}"
                attribution='Tiles &copy; Esri &mdash; Source: Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community'
              />
            </LayersControl.BaseLayer>
            <LayersControl.BaseLayer name="Street Map">
              <TileLayer
                url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
              />
            </LayersControl.BaseLayer>
          </LayersControl>

          {/* Render safe spots */}
          {safeSpots.map(spot => (
            <Marker
              key={spot.id}
              position={spot.position}
              icon={new L.Icon({
                iconUrl: 'https://cdn-icons-png.flaticon.com/512/2776/2776067.png',
                iconSize: [25, 41],
                iconAnchor: [12, 41]
              })}
            >
              <Popup>
                <strong>{spot.name}</strong><br />
                Lat: {spot.position.lat.toFixed(4)}<br />
                Lng: {spot.position.lng.toFixed(4)}
              </Popup>
            </Marker>
          ))}

          {/* Render disaster markers (keep your existing code) */}
          {filteredDisasters.map((event, index) => {
            // ... (keep your existing disaster marker code)
          })}
        </MapContainer>
      </div>
    </div>
  );
};

export default DisasterMap;