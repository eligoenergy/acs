class String
  def titleize
    upcased_words = ['CNU', 'II', 'IT', 'US', 'JV', 'AEA', 'UK', 'CA', 'AU', 'PI', 'PPS', 'SVP', 'CIO', 'CFO', 'CEO', 'CTO', 'VP', 'QA', 'QQ', 'DD', 'HR', 'DB', 'GBI', 'GB', 'IA', 'CS']
    result = ActiveSupport::Inflector.titleize(self).gsub(/\s{2,}/, ' ').gsub(/(.{1,}\..{2,}\b|.*\d{2}$)/) { |w| w.downcase }.strip.gsub(/(^\W|\s$)/, '').gsub(/(^'|'$)/,'')
    upcased_words.each do |word|
      result.gsub!(/\b#{word}\b/i,word)
    end
    result
  end
  
  def downcase_underscore
    self.downcase.gsub(/ /,'_')
  end
end