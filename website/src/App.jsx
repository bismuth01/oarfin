// src/App.jsx
import DisasterNewsBanner from './DisasterNewsBanner';
import DisasterMap from './DisasterMap';
import './global.css'

function App() {
  return (
    <div className="min-h-screen bg-gray-100">
      {/* Add the news banner at the top */}
      <DisasterNewsBanner />
      <div className="container height 100vh width 100vh mx-auto p-4">
        {/* Your existing map component */}
        <DisasterMap />
        {/* Other components... */}
      </div>
    </div>
  );
}

export default App;