module Bookmaker
  module Base
    DEFAULT_LAYOUT = 'boom'
    DEFAULT_THEME = 'eiffel'
    DEFAULT_SYNTAX = 'plain_text'
    GEM_ROOT = File.expand_path(File.dirname(__FILE__) + "/../../")
    
    def self.html_path
      BOOKMAKER_ROOT + "/output/#{app_name}.html"
    end
    
    def self.pdf_path
      BOOKMAKER_ROOT + "/output/#{app_name}.pdf"
    end
    
    def self.template_path
      BOOKMAKER_ROOT + "/templates/layout.html"
    end
    
    def self.config_path
      BOOKMAKER_ROOT + "/config.yml"
    end
    
    def self.text_dir
      BOOKMAKER_ROOT + "/text"
    end
    
    def self.config
      @config ||= YAML::load_file(config_path)
    end
    
    def self.parse_layout(contents)
      template = File.new(template_path).read
      cfg = config.merge(:contents => contents)
      env = OpenStruct.new(cfg)

      ERB.new(template).result env.instance_eval{binding}
    end
    
    def self.generate_pdf
      IO.popen('prince --silent -i html %s -o %s' % [html_path, pdf_path])
    end
    
    def self.generate_html
      # get chosen theme
      theme = config['theme']
      
      # all parsed markdown file holder
      contents = ""
      
      # first, get all chapters; then, get all parsed markdown
      # files from this chapter and group them into a <div class="chapter"> tag
      Dir.entries(text_dir).sort.each do |dirname|
        next if %w(. ..).include?(dirname) || File.file?(text_dir + "/#{dirname}")
        
        # gets all parsed markdown files to wrap in a 
        # chapter element
        chapter = ""
        
        Dir["#{text_dir}/#{dirname}/*.markdown"].sort.each do |markdown_file|
          file_contents = Discount.new(File.new(markdown_file).read).to_html

          # if Ultraviolet is installed, apply syntax highlight
          if Object.const_defined?('Uv')
            file_contents.gsub! /<pre><code>(.*?)<\/code><\/pre>/m do |match|
              full_code = $1
              full_code.gsub! /&lt;/, '<'
              full_code.gsub! /&gt;/, '>'
              full_code.gsub! /&amp;/, '&'
              matches, syntax, code = *full_code.match(/<div lang="(.*?)">(.*?)<\/div>/sim)

              code ||= full_code
              syntax = Bookmaker::Base.default_syntax unless Bookmaker::Base.syntax?(syntax)
              theme = Bookmaker::Base.default_theme unless Bookmaker::Base.theme?(theme)

              Uv.parse(code, "xhtml", syntax, false, theme)
            end
          end

          chapter << (file_contents + "\n\n")
        end
        
        contents << '<div class="chapter">%s</div>' % chapter
      end

      # save html file
      File.open(html_path, 'w+') do |f|
        f << Bookmaker::Base.parse_layout(contents)
      end
    end
    
    def self.app_name
      ENV['BOOKMAKER_NAME'] || 'bookmaker'
    end
    
    def self.theme?(theme_name)
      themes.include?(theme_name)
    end
    
    def self.syntax?(syntax_name)
      syntaxes.include?(syntax_name)
    end
    
    def self.default_theme
      DEFAULT_THEME
    end
    
    def self.default_syntax
      DEFAULT_SYNTAX
    end
    
    def self.default_layout
      DEFAULT_LAYOUT
    end
    
    def self.syntaxes
      Uv.syntaxes
    end
    
    def self.layouts
      @layouts ||= begin
        filter = File.join(GEM_ROOT, "app_generators/bookmaker/templates/layouts/*.css")
        Dir[filter].collect{|path| File.basename(path).gsub(/\.css$/, '') }.sort
      end
    end
    
    def self.themes
      @themes ||= begin
        filter = File.join(GEM_ROOT, "app_generators/bookmaker/templates/css/*.css")
        Dir[filter].collect{|path| File.basename(path).gsub(/\.css$/, '') }.sort
      end
    end
  end
end