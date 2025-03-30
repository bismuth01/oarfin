import { useState } from 'react';
import DisasterNewsBanner from './DisasterNewsBanner';
import DisasterMap from './DisasterMap';
import NewsArticles from './NewsArticles';
import RedditVideos from './RedditVideos';
import './global.css';

function App() {
  const [activeView, setActiveView] = useState('map'); // 'map', 'news', or 'videos'

  return (
    <div className="min-h-screen bg-gray-100">
      {/* News banner at the top */}
      <DisasterNewsBanner />
      
      {/* Navigation tabs */}
      <div className="container mx-auto px-4 py-2">
        <div className="flex space-x-4 mb-4 border-b border-gray-200">
          <button
            className={`py-2 px-4 font-medium ${activeView === 'map' ? 'text-blue-600 border-b-2 border-blue-600' : 'text-gray-500 hover:text-gray-700'}`}
            onClick={() => setActiveView('map')}
          >
            Disaster Map
          </button>
          <button
            className={`py-2 px-4 font-medium ${activeView === 'news' ? 'text-blue-600 border-b-2 border-blue-600' : 'text-gray-500 hover:text-gray-700'}`}
            onClick={() => setActiveView('news')}
          >
            News Articles
          </button>
          <button
            className={`py-2 px-4 font-medium ${activeView === 'videos' ? 'text-blue-600 border-b-2 border-blue-600' : 'text-gray-500 hover:text-gray-700'}`}
            onClick={() => setActiveView('videos')}
          >
            Reddit Videos
          </button>
        </div>
      </div>

      {/* Main content area */}
      <div className="container mx-auto p-4">
        {activeView === 'map' && <DisasterMap />}
        {activeView === 'news' && <NewsArticles />}
        {activeView === 'videos' && <RedditVideos />}
      </div>
    </div>
  );
}

export default App;