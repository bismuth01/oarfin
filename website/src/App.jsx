// src/App.jsx
import DisasterNewsBanner from './DisasterNewsBanner';
import DisasterMap from './DisasterMap';
import './global.css'

function App() {
  return (
    <div className="min-h-screen bg-gray-100">
      {/* Add the news banner at the top */}
      <DisasterNewsBanner />
      
      <div className="container mx-auto p-4">
        <h1 className="text-3xl font-bold mb-6">Global Disaster Alerts</h1>
        
        {/* Your existing map component */}
        <DisasterMap />
        
        {/* Other components... */}
      </div>
    </div>
  );
}

export default App;