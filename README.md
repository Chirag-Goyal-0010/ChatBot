# AI Chatbot with Website Scraping

A Rails application that scrapes websites, processes content using AI embeddings, and provides intelligent answers to user questions based on the scraped content.

## Features

- **Website Scraping**: Automatically scrapes websites using both static (Nokogiri) and dynamic (Puppeteer) methods
- **AI-Powered Q&A**: Uses OpenAI embeddings and GPT-3.5-turbo for semantic search and answer generation
- **Background Processing**: Uses Rails background jobs for scraping and embedding generation
- **Vector Search**: Implements semantic search using PostgreSQL with pgvector extension
- **Modern UI**: Built with Tailwind CSS and Hotwire for a responsive, modern interface

## Prerequisites

- Ruby 3.2+
- PostgreSQL 12+ with pgvector extension
- Node.js (for Puppeteer)
- OpenAI API key

## Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd chatbot
   ```

2. **Install Ruby dependencies**
   ```bash
   bundle install
   ```

3. **Set up environment variables**
   ```bash
   cp config/env.example .env
   ```
   
   Edit `.env` and add your configuration:
   ```env
   DATABASE_NAME=chatbot_development
   DATABASE_USERNAME=postgres
   DATABASE_PASSWORD=your_password_here
   DATABASE_HOST=localhost
   DATABASE_PORT=5432
   
   OPENAI_API_KEY=your_openai_api_key_here
   ```

4. **Set up the database**
   ```bash
   # Create and migrate the database
   bin/rails db:create
   bin/rails db:migrate
   
   # Enable pgvector extension (if not already enabled)
   bin/rails db:enable_pgvector
   ```

5. **Start the application**
   ```bash
   # Start the Rails server
   bin/dev
   ```

## Usage

1. **Submit a website URL**: Go to the homepage and enter a website URL to scrape
2. **Wait for processing**: The scraping happens in the background
3. **Ask questions**: Once scraping is complete, you can ask questions about the content
4. **Get AI answers**: The system will provide intelligent answers based on the scraped content

## Development

### Running Tests
```bash
bin/rails test
```

### Background Jobs
The application uses Solid Queue for background job processing. Jobs are automatically processed when running `bin/dev`.

### Database Schema
The application uses PostgreSQL with the pgvector extension for vector storage. Make sure the extension is enabled in your database.

## Architecture

- **Models**: `Website` and `WebsiteChunk` for data storage
- **Services**: 
  - `EmbeddingService` for OpenAI embeddings
  - `SemanticSearchService` for vector search
  - `AnswerGenerationService` for AI answer generation
  - `QuestionValidator` for input validation
- **Jobs**: Background jobs for scraping and embedding generation
- **Controllers**: RESTful controllers with Turbo Stream support

## Security

- Environment variables for sensitive configuration
- Input validation and sanitization
- URL validation using the `url_validation` gem
- Spam detection in question validation

## Deployment

The application is configured for deployment using Kamal. See `config/deploy.yml` for deployment configuration.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

This project is licensed under the MIT License.
