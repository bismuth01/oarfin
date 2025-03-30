# Oarfin APIs

Oarfin uses 2 APIs : -
- Webscraper API
- LLM API

The LLM API checks wheather an article is related to a natural disaster.
The Webscraper API can scrape for the latest articles from news sites and use the LLM API to confirm that they are related to natural disasters, and it can also scrape subreddits to get posts.

## Webscraper API

The Webscraper API current has 3 available endpoints
### `/bbc_news`
Gives the list of latest articles scraped from !(BBC)[https://www.bbc.com/future-earth] related to natural disasters.

Type: `GET`

Input: `{}`

Output: Json list of items `{ url, title, content}`. `url` is URL to the article, `title` is the title of the article and `content` is the article content of the article

### `/ndtv_news`
Gives the list of latest articles scraped from !(NDTV)[https://www.ndtv.com/world] related to natural disasters.

Type: `GET`

Input: `{}`

Output: Json list of items `{ url, title, content}`. `url` is URL to the article, `title` is the title of the article and `content` is the article content of the article

### `/reddit_news`
Gives the list of latest posts scrapped from !(r/DisasterUpdate)[https://www.reddit.com/r/DisasterUpdate].

Type: `GET`

Input: `{}`

Output: Json list of items `{ title, type, post_link}`. `title` is post title, `type` tells the media attached with the post, can be `image` or `video` and `post_link` is link to the post

## LLM API

The LLM API has only 1 endpoint
### `/is_disaster_news`
Takes article title and content and outputs `YES` for related to natural disaster or `NO` for not related to natural disaster.

Type: `POST`

Input Body: `{title, content}`

Output: `{ answer }`. `answer` can be strings `YES` or `NO`
