// src/components/DisasterNewsBanner.jsx
import { useEffect, useState } from "react";
import axios from "axios";
import "./global.css";
const DisasterNewsBanner = () => {
  const [disasterNews, setDisasterNews] = useState([]);
  const [currentNewsIndex, setCurrentNewsIndex] = useState(0);

  useEffect(() => {
    const fetchDisasterNews = async () => {
      try {
        const response = await axios.get(
          import.meta.env.VITE_API_Banner
        );
        
        const newsItems = response.data.map((event) => ({
          id: event.eventid,
          title: event.title,
          date: event.eventdate,
          subtitle: event.subtitle,
          link: `https://www.gdacs.org/report.aspx?eventtype=${event.eventtype}&eventid=${event.eventid}`,
          type: event.eventtype,
          mangnitude: event.subtitle,
          alertLevel: event.alertlevel,
          time: event.datestring,
        }));
        
        setDisasterNews(newsItems);
      } catch (error) {
        console.error("Error fetching disaster news:", error);
      }
    };

    fetchDisasterNews();
  }, []);

  useEffect(() => {
    if (disasterNews.length > 0) {
      const interval = setInterval(() => {
        setCurrentNewsIndex((prevIndex) =>
          prevIndex === disasterNews.length - 1 ? 0 : prevIndex + 1
        );
      }, 5000);

      return () => clearInterval(interval);
    }
  }, [disasterNews]);

  const getAlertColor = (alertLevel) => {
    switch (alertLevel) {
      case "Red": return "text-red-500";
      case "Orange": return "text-orange-500";
      case "Green": return "text-green-500";
      default: return "text-gray-500";
    }
  };
  
  const getEventType = (type) => {
    switch (type) {
        case "EQ": return "Earthquake in ";
        case "FL": return "Flood in ";
        case "TC": return "Tropical Cyclone ";
        case "VO": return "Volcanic Erruption in ";
        case "WF": return "Wild Fire in ";
        case "DR": return "Drought in ";
        default: return "Unidentifeid Event in ";
      }
  };

  const getTitle = (title, type) => {
    if ( type === "DR") {
      // For tropical cyclones and droughts, get the part before hyphen
      return title.split('-')[0];
    }
    else if (type === "EQ" || type === "WF" || type === "FL" || type === "VO" ||type === "TC" ) {
      // For other types, return the title as-is
      return title;
    }
    else {
      // For unknown types, return empty string
      return "";
    }
  };

  if (disasterNews.length === 0) {
    return <div className="w-full bg-blue-900 text-white p-2">Loading disaster alerts...</div>;
  }

  return (
    <div className="w-full bg-blue-900 text-white p-2 overflow-hidden">
      <div className="flex items-center">
        <div className="font-bold mr-4 whitespace-nowrap">LATEST DISASTER ALERTS:</div>
        
        <div className="flex-1 overflow-hidden">
          <div className="whitespace-nowrap">
            {disasterNews.map((news, index) => (
              <div 
                key={news.id} 
                className={`inline-block mr-8 transition-opacity duration-500 ${index === currentNewsIndex ? 'opacity-100' : 'opacity-0 absolute'}`}
              >
                <a 
                  href={news.link} 
                  target="_blank" 
                  rel="noopener noreferrer"
                  className={`font-bold ${getAlertColor(news.alertLevel)}`}
                >
                  {getEventType(news.type)}{getTitle(news.title,news.type)} {news.subtitle} - {new Date(news.date).toLocaleDateString()} ({new Date(news.date).toLocaleTimeString()})
                </a>
              </div>
            ))}
          </div>
        </div>
        
       
      </div>
    </div>
  );
};

export default DisasterNewsBanner;