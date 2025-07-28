require Rails.root.join('lib', 'services', 'nokogiri_scraper')
require Rails.root.join('lib', 'services', 'puppeteer_scraper')

class WebsitesController < ApplicationController
  def new
    @website = Website.new
  end

  def create
    @website = Website.new(website_params)
    @website.url = @website.url.strip if @website.url.present?
    if @website.save
      flash[:notice] = 'Website URL submitted successfully! Scraping in progress...'
      # Start scraping synchronously
      chunks = NokogiriScraper.scrape(@website.url)
      if chunks.nil? || chunks.empty?
        chunks = PuppeteerScraper.scrape(@website.url)
        flash[:alert] = 'Static scraping failed, used dynamic scraping.' if chunks
      end
      if chunks && !chunks.empty?
        chunks.each_with_index do |chunk, idx|
          WebsiteChunk.create!(website: @website, content: chunk[:content], section: chunk[:section], position: idx)
        end
        flash[:notice] = 'Scraping completed and content saved.'
      else
        flash[:alert] = 'Scraping failed for this website.'
        Rails.logger.error("Scraping failed for website ID: #{@website.id}, URL: #{@website.url}")
      end
      redirect_to websites_path
    else
      flash.now[:alert] = 'Invalid URL. Please try again.'
      render :new
    end
  end

  def index
    @websites = Website.all
    if params[:question].present? && params[:chunks].present?
      @chunks = WebsiteChunk.where(id: params[:chunks].split(','))
    end
  end

  # POST /websites/ask
  def ask
    question = params[:question]
    @chunks = EmbeddingService.find_similar_chunks(question, limit: 5)
    if @chunks.nil?
      flash.now[:alert] = "I don't have information to answer that question."
    end
    redirect_to websites_path(question: question, chunks: @chunks&.pluck(:id))
  end

  # GET/POST /websites/answer - AI-powered answer endpoint
  def answer
    if request.get?
      # GET request - show the form
      @answer = {
        question: "",
        answer: "",
        chunks: [],
        success: false
      }
      render :answer
      return
    end
    
    # POST request - process the question
    question = params[:question]
    
    if question.blank?
      flash[:alert] = "Please provide a question."
      redirect_to answer_website_path and return
    end
    
    begin
      # Use semantic search to find relevant chunks
      require Rails.root.join('lib', 'services', 'semantic_search_service')
      search_service = SemanticSearchService.new
      search_result = search_service.search(question, limit: 5)
      
      if search_result[:success] && search_result[:chunks].any?
        # Format chunks for OpenAI prompt
        chunks_text = format_chunks_for_prompt(search_result[:chunks])
        
        # Get AI answer using OpenAI completion
        ai_answer = generate_ai_answer(question, chunks_text)
        
        @answer = {
          question: question,
          answer: ai_answer,
          chunks: search_result[:chunks],
          success: true
        }
      else
        @answer = {
          question: question,
          answer: "I don't have enough information to answer that question.",
          chunks: [],
          success: false
        }
      end
    rescue => e
      Rails.logger.error("Answer generation failed: #{e.message}")
      @answer = {
        question: question,
        answer: "Sorry, I encountered an error while processing your question.",
        chunks: [],
        success: false
      }
    end
    
    respond_to do |format|
      format.html { render :answer }
      format.json { render json: @answer }
    end
  end

  private

  def website_params
    params.require(:website).permit(:url, :status)
  end

  # Format chunks for OpenAI prompt
  def format_chunks_for_prompt(chunks)
    chunks.map.with_index(1) do |chunk, index|
      "Source #{index}:\n#{chunk.content}\n"
    end.join("\n")
  end

  # Generate AI answer using OpenAI completion API
  def generate_ai_answer(question, chunks_text)
    require 'openai'
    
    client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
    
    prompt = <<~PROMPT
      You are a helpful AI assistant. Based on the following information, please answer the user's question.

      Information:
      #{chunks_text}

      Question: #{question}

      Please provide a clear, helpful answer based on the information above. If the information doesn't contain enough details to answer the question, say so.
    PROMPT

    response = client.chat(parameters: {
      model: "gpt-3.5-turbo",
      messages: [
        { role: "system", content: "You are a helpful AI assistant that answers questions based on provided information." },
        { role: "user", content: prompt }
      ],
      max_tokens: 500,
      temperature: 0.7
    })

    response.dig("choices", 0, "message", "content") || "Sorry, I couldn't generate an answer."
  rescue => e
    Rails.logger.error("OpenAI completion failed: #{e.message}")
    "Sorry, I encountered an error while generating the answer."
  end
end
