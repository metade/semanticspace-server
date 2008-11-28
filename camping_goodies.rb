require 'action_view'

PATH = File.dirname(__FILE__)

module Camping::Controllers  
  class Static < R '/static/(.+)'         
    MIME_TYPES = {'.css' => 'text/css', '.js' => 'text/javascript', 
                  '.jpg' => 'image/jpeg'}
    PATH = File.expand_path(File.dirname(__FILE__))
    
    def get(path)
      @headers['Content-Type'] = MIME_TYPES[path[/\.\w+$/, 0]] || "text/plain"
      unless path.include? ".." # prevent directory traversal attacks
        @headers['X-Sendfile'] = "#{PATH}/public/#{path}"
      else
        @status = "403"
        "403 - Invalid path"
      end
    end
  end
end

module CampingGoodies
  include ActionView::Helpers
  
  def render(m, layout=true)
    content = ERB.new(IO.read("#{PATH}/views/#{m}.html.erb")).result(binding)
    content = ERB.new(IO.read("#{PATH}/views/layout.html.erb")).result(binding) if layout
    return content
  end  
  
  def not_found(type, brand)
    r(404, render(:not_found))
  end
  
  def accept(format=nil)
    if (format and format =~ /js(on)?/)
      'application/json'
    elsif (format and format =~ /ya?ml/)
      'application/x-yaml'
    elsif (format and format=~ /svg/)
      'image/svg+xml'
    else
      env.ACCEPT.nil? ? (env.HTTP_ACCEPT.nil? ? 'text/html' : env.HTTP_ACCEPT) : env.ACCEPT
    end
  end
  
  def respond_to(format, object)
    case accept(format)
      when 'application/x-yaml' then
        @headers['Content-Type'] = 'application/x-yaml'
        object.to_yaml
      when 'application/json' then
        @headers['Content-Type'] = 'application/json'
        object.to_json
    end
  end
end