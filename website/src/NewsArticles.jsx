import { useEffect, useState } from 'react';
import axios from 'axios';
import './NewsArticles.css';

const NewsArticles = () => {
  const [articles, setArticles] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [retryCount, setRetryCount] = useState(0);

  const mockArticles = [
    {
      title: "Sample BBC News",
      content: "This is a sample news article about recent disaster events.",
      url: "https://bbc.com/news",
      source: "BBC"
    },
    {
      title: "Sample NDTV Update",
      content: "Mock data showing how disaster response teams are mobilizing.",
      url: "https://ndtv.com",
      source: "NDTV"
    }
  ];

  const fetchArticles = async () => {
    try {
      setLoading(true);
      setError(null);

      if (import.meta.env.MODE === 'development' && !import.meta.env.VITE_WebData_URL) {
        console.warn('Using mock data - API URL not configured');
        setArticles(mockArticles);
        return;
      }

      const apiUrl = import.meta.env.VITE_WebData_URL;
      if (!apiUrl) throw new Error('API base URL not configured');

      const [bbcResponse, ndtvResponse] = await Promise.all([
        axios.get(`${apiUrl}/bbc_news`, { timeout: 8000 }),
        axios.get(`${apiUrl}/ndtv_news`, { timeout: 8000 })
      ]);

      const validateArticle = (article) => ({
        title: article.title || 'Untitled Article',
        content: article.content || 'No content available',
        url: article.url || '#',
        source: article.source
      });

      setArticles([
        ...(bbcResponse.data?.map(a => validateArticle({ ...a, source: 'BBC' })) || []),
        ...(ndtvResponse.data?.map(a => validateArticle({ ...a, source: 'NDTV' })) || [])
      ]);

    } catch (err) {
      const errorMessage = err.response?.data?.message || 
                         err.message || 
                         'Failed to load news articles';
      
      console.error('Fetch error:', {
        error: err,
        message: errorMessage,
        retryCount
      });

      if (retryCount < 2) {
        setRetryCount(c => c + 1);
      } else {
        setError(errorMessage);
        if (mockArticles.length > 0) {
          setArticles(mockArticles);
          setError('Using demo data - API unavailable');
        }
      }
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    const controller = new AbortController();
    fetchArticles();

    return () => controller.abort();
  }, [retryCount]);

  if (loading) return (
    <div className="news-loading">
      <div className="news-spinner"></div>
      <p>Loading latest news...</p>
    </div>
  );

  if (error && articles.length === 0) return (
    <div className="news-error">
      <p>{error}</p>
      <button 
        onClick={() => setRetryCount(0)}
        className="retry-button"
      >
        Retry
      </button>
    </div>
  );

  return (
    <div className="news-container">
      <h2 className="news-header">Disaster News Updates</h2>
      
      {error && (
        <div className="news-warning">
          <p>{error}</p>
        </div>
      )}

      <div className="news-grid">
        {articles.map((article, index) => (
          <article key={`${article.source}-${index}`} className="news-card">
            <div className="news-source-tag">{article.source}</div>
            <h3 className="news-title">{article.title}</h3>
            <p className="news-content">
              {article.content.length > 200 
                ? `${article.content.substring(0, 200)}...` 
                : article.content}
            </p>
            <a
              href={article.url}
              target="_blank"
              rel="noopener noreferrer"
              className="news-link"
            >
              Read Full Story
              <span className="external-icon">↗</span>
            </a>
          </article>
        ))}
      </div>
    </div>
  );
};

export default NewsArticles;