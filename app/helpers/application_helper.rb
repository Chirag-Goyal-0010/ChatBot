module ApplicationHelper
  def markdown(text)
    return "" if text.blank?
    
    markdown = Redcarpet::Markdown.new(
      Redcarpet::Render::HTML.new(
        hard_wrap: true,
        link_attributes: { target: '_blank' }
      ),
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true
    )
    
    # Consider sanitizing to mitigate potential XSS from model/LLM output
    sanitized_html = markdown.render(text)
    sanitize(sanitized_html)
  end
end
