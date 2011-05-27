class App
  CONFIG = YAML.load(File.open(File.join(Rails.root.to_s,'config/app.yml')))[Rails.env]
  class << self
    CONFIG.each_pair do |key, val|
      define_method "#{key}" do
        val
      end
    end
    
    def method_missing(method, *args)
      warn "App recieved message '#{method}' but it is not defined"
      warn caller.join("\n")
      nil
    end
  end
end
