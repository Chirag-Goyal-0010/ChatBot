class QuestionValidator
  def self.validate(question)
    if question.blank?
      return { valid: false, error: "Please enter a question." }
    end
    
    if question.strip.length < 3
      return { valid: false, error: "Question must be at least 3 characters long." }
    end
    
    if question.strip.length > 500
      return { valid: false, error: "Question is too long. Please keep it under 500 characters." }
    end
    
    # Check for common spam patterns
    spam_patterns = [
      /\b(spam|viagra|casino|poker|loan)\b/i,
      /\b(free|money|cash|earn|rich)\b.*\b(now|fast|quick|easy)\b/i,
      /\d{10,}/, # Too many consecutive numbers
      /[A-Z]{10,}/, # Too many consecutive uppercase letters
      /\b(click|buy|order|purchase)\b.*\b(here|now|today)\b/i
    ]
    
    spam_patterns.each do |pattern|
      if question.match?(pattern)
        return { valid: false, error: "Question contains inappropriate content." }
      end
    end
    
    { valid: true, error: nil }
  end
end 