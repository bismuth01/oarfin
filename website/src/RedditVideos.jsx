import { useEffect, useState } from 'react';
import axios from 'axios';
import './RedditVideos.css';

const RedditVideos = () => {
  const [posts, setPosts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchRedditPosts = async () => {
      try {
        setLoading(true);
        const response = await axios.get(
          `${import.meta.env.VITE_WebData_URL}/reddit_news`
        );
        
        // Filter to only include video posts (type === 'video')
        const videoPosts = response.data.filter(post => post.type === 'video');
        setPosts(videoPosts);
      } catch (err) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };

    fetchRedditPosts();
  }, []);

  if (loading) return <div className="loading">Loading videos...</div>;
  if (error) return <div className="error">Error: {error}</div>;

  return (
    <div className="videos-section">
      <h2>Reddit Videos</h2>
      <div className="videos-grid">
        {posts.map((post, index) => (
          <div key={index} className="video-card">
            <h3>{post.title}</h3>
            <div className="video-container">
              {/* Embedded Reddit video player */}
              <iframe
                src={`${post.post_link}/embed`}
                className="reddit-embed"
                sandbox="allow-scripts allow-same-origin allow-popups"
                style={{ border: 'none' }}
                width="100%"
                height="400"
              ></iframe>
            </div>
            <a
              href={post.post_link}
              target="_blank"
              rel="noopener noreferrer"
              className="view-post"
            >
              View on Reddit
            </a>
          </div>
        ))}
      </div>
    </div>
  );
};

export default RedditVideos;