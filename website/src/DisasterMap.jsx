import { useEffect, useState } from "react";
import axios from "axios";
import { 
  MapContainer, 
  TileLayer, 
  Marker, 
  Popup, 
  Circle, 
  Rectangle, 
  LayersControl,
  useMapEvents 
} from "react-leaflet";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import DisasterFilter from "./DisasterFilter";
import SafeSpotMarker from "./SafeSpotMarker";
import './global.css';

// Base API URL
const API_BASE_URL = import.meta.env.VITE_API_Marker; 
// Disaster types
const DISASTER_TYPES = ["EQ", "FL", "TC", "VO", "DR", "WF"];

// Safe spot icon
const safeSpotIcon = new L.Icon({
  iconUrl: 'https://cdn-icons-png.flaticon.com/512/2776/2776067.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowSize: [41, 41]
});

// Define different icons for each disaster type
const getIcon = (eventType) => {
  const iconMap = {
    EQ: "https://cdn-icons-png.flaticon.com/512/1840/1840485.png", // Earthquake
    FL: "https://cdn-icons-png.flaticon.com/512/1840/1840525.png", // Flood
    TC: "https://cdn-icons-png.flaticon.com/512/1840/1840491.png", // Cyclone
    VO: "https://cdn-icons-png.flaticon.com/512/1840/1840506.png", // Volcano
    DR: "https://cdn-icons-png.flaticon.com/512/1840/1840489.png", // Drought
    WF: "https://cdn-icons-png.flaticon.com/512/1840/1840524.png", // Wildfire
  };
  return iconMap[eventType] || "https://cdn-icons-png.flaticon.com/512/184/184525.png"; // Default icon
};

// Component to handle map clicks for safe spots
function SpotMarker({ onMapClick }) {
  useMapEvents({
    click(e) {
      onMapClick(e.latlng);
    }
  });
  return null;
}

const DisasterMap = () => {
  const [disasters, setDisasters] = useState([]);
  const [filters, setFilters] = useState({
    EQ: true, FL: true, TC: true, VO: true, DR: true, WF: true
  });
  const [loading, setLoading] = useState(true);
  const [safeSpots, setSafeSpots] = useState([]);
  const [clickPosition, setClickPosition] = useState(null);

  // Add a new safe spot
  const handleAddSafeSpot = (position) => {
    setSafeSpots(prev => [
      ...prev,
      {
        id: Date.now(),
        position: {
          lat: position.lat,
          lng: position.lng
        },
        name: position.name || `Safe Spot ${prev.length + 1}`
      }
    ]);
  };

  // Remove a safe spot
  const handleRemoveSafeSpot = (id) => {
    setSafeSpots(prev => prev.filter(spot => spot.id !== id));
  };

  // Clear all safe spots
  const handleClearSafeSpots = () => {
    setSafeSpots([]);
  };

  // Handle map click
  const handleMapClick = (latlng) => {
    setClickPosition(latlng);
  };

  // Send data to backend
  const handleSendToBackend = async (data) => {
    try {
      console.log("Sending data to backend:", data);
      // Replace with your actual API endpoint
      // const response = await axios.post('YOUR_BACKEND_ENDPOINT', data);
      alert(`Data prepared for backend:\n${JSON.stringify(data, null, 2)}`);
    } catch (error) {
      console.error("Error sending data to backend:", error);
      alert("Error sending data to backend");
    }
  };

  // Calculate disaster counts by type
  const disasterCounts = disasters.reduce((counts, disaster) => {
    const type = disaster.properties?.eventtype;
    if (type) {
      counts[type] = (counts[type] || 0) + 1;
    }
    return counts;
  }, {});

  // Filter disasters based on active filters
  const filteredDisasters = disasters.filter(disaster => {
    const type = disaster.properties?.eventtype;
    return type && filters[type];
  });

  useEffect(() => {
    const fetchDisasters = async () => {
      try {
        setLoading(true);
        let allDisasters = [];

        for (const type of DISASTER_TYPES) {
          try {
            const response = await axios.get(`${API_BASE_URL}${type}`);
            const events = response.data?.features?.filter(event => {
              const coords = event.geometry?.coordinates;
              return Array.isArray(coords) && coords.length >= 2 && 
                     typeof coords[0] === "number" && 
                     typeof coords[1] === "number";
            }) || [];
            allDisasters = [...allDisasters, ...events];
          } catch (error) {
            console.error(`Error fetching ${type} data:`, error);
          }
        }

        setDisasters(allDisasters);
      } catch (error) {
        console.error('Error fetching disasters:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchDisasters();
  }, [API_BASE_URL]);

  if (loading) return <div>Loading disaster data...</div>;

  return (
    <div style={{ display: 'flex', height: '100vh' }}>
      {/* Left panel - Map */}
      <div style={{ flex: 3 }}>
        <MapContainer 
          center={[20, 0]} 
          zoom={2} 
          style={{ height: '100%', width: '100%' }}
          className="rounded-md"
        >
          <SpotMarker onMapClick={handleMapClick} />
          
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
              position={[spot.position.lat, spot.position.lng]}
              icon={safeSpotIcon}
              eventHandlers={{
                click: () => handleRemoveSafeSpot(spot.id)
              }}
            >
              <Popup>
                <strong>{spot.name}</strong><br />
                Latitude: {spot.position.lat.toFixed(4)}<br />
                Longitude: {spot.position.lng.toFixed(4)}
              </Popup>
            </Marker>
          ))}

          {/* Render disaster markers */}
          {filteredDisasters.map((event, index) => {
            const coords = event.geometry?.coordinates;
            const bbox = event.bbox || [];
            const eventType = event.properties?.eventtype || "Unknown";
            const description = event.properties?.htmldescription || 
                              event.properties?.title || 
                              event.properties?.description || 
                              "Unknown Event";
            const alertLevel = event.properties?.alertlevel || "N/A";

            const event_icon = L.icon({
              iconUrl: event.properties?.icon || getIcon(eventType),
              iconSize: [22, 22],
              iconAnchor: [11, 22],
            });

            const markerPosition = [coords[1], coords[0]];

            let affectedArea = null;
            if (bbox.length === 4) {
              const [minLon, minLat, maxLon, maxLat] = bbox;
              if (minLon !== maxLon || minLat !== maxLat) {
                affectedArea = <Rectangle bounds={[[minLat, minLon], [maxLat, maxLon]]} pathOptions={{ color: "red", weight: 2 }} />;
              } else {
                affectedArea = <Circle center={markerPosition} radius={50000} pathOptions={{ color: "red", weight: 2 }} />;
              }
            }

            return (
              <div key={index}>
                <Marker position={markerPosition} icon={event_icon}>
                  <Popup>
                    <strong>{description}</strong>
                    <p>Type: {eventType}</p>
                    <p>Alert Level: {alertLevel}</p>
                  </Popup>
                </Marker>
                {affectedArea}
              </div>
            );
          })}
        </MapContainer>
      </div>

      {/* Right panel - Controls */}
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', padding: '10px', backgroundColor: '#f5f5f5' }}>
        <DisasterFilter 
          filters={filters}
          setFilters={setFilters}
          disasterCounts={disasterCounts}
        />
        
        <SafeSpotMarker 
          safeSpots={safeSpots}
          disasterMarkers={filteredDisasters}
          onAddSafeSpot={handleAddSafeSpot}
          onRemoveSafeSpot={handleRemoveSafeSpot}
          onClearSafeSpots={handleClearSafeSpots}
          onSendToBackend={handleSendToBackend}
          onClickPosition={clickPosition}
        />
      </div>
    </div>
  );
};

export default DisasterMap;