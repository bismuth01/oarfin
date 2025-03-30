import { useEffect, useState } from 'react';
import axios from 'axios';
import './NewsArticles.css';

const NewsArticles = () => {
  const [articles, setArticles] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchArticles = async () => {
      try {
        setLoading(true);
        const [bbcResponse, ndtvResponse] = await Promise.all([
          axios.get(`${import.meta.env.VITE_WebData_URL}:5123/bbc_news`),
          axios.get(`${import.meta.env.VITE_WebData_URL}:5123/ndtv_news`)
        ]);
        
        // Combine and format articles from both sources
        const combinedArticles = [
          ...bbcResponse.data.map(article => ({ ...article, source: 'BBC' })),
          ...ndtvResponse.data.map(article => ({ ...article, source: 'NDTV' }))
        ];
        
        setArticles(combinedArticles);
      } catch (err) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };

    fetchArticles();
  }, []);

  if (loading) return <div className="loading">Loading articles...</div>;
  if (error) return <div className="error">Error: {error}</div>;

  return (
    <div className="news-section">
      <h2>Latest Disaster News</h2>
      <div className="articles-grid">
        {articles.map((article, index) => (
          <div key={index} className="article-card">
            <h3>{article.title}</h3>
            <p className="source">{article.source}</p>
            <p>{article.content}</p>
            <a 
              href={article.url} 
              target="_blank" 
              rel="noopener noreferrer" 
              className="read-more"
            >
              Read full article
            </a>
          </div>
        ))}
      </div>
    </div>
  );
};

export default NewsArticles;