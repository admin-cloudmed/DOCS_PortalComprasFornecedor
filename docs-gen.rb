require 'rubygems'
require 'crack'

obj = Crack::XML.parse(File.read(File.expand_path('posxml.xsd')))

commands = []

# Adds on commands array the name and description of each command
obj["xs:schema"]["xs:group"]["xs:choice"]["xs:element"].each do |element|
  command = Hash.new
  command["name"] = element["name"]
  command["description"] = element["xs:annotation"]["xs:documentation"]
  
  if element["xs:annotation"]["xs:example"]
    command["example"] = element["xs:annotation"]["xs:example"]
  end

  commands << command
end

# Adds on commands array the parameters of each command
obj["xs:schema"]["xs:complexType"].each do |element|
  next if element["name"] == "pagina" || element["name"] == "funcao"
  next if element["xs:attribute"].nil?

  params = []

  if element["xs:attribute"].is_a?(Array)
    element["xs:attribute"].each do |p|
      param = Hash.new
      param["name"] = p["name"]
      param["type"] = p["type"]
      param["description"] = p["xs:annotation"]["xs:documentation"]

      params << param
    end
  else
    param = Hash.new
    param["name"] = element["xs:attribute"]["name"]
    param["type"] = element["xs:attribute"]["type"]
    param["description"] = element["xs:attribute"]["xs:annotation"]["xs:documentation"]

    params << param
  end

  commands.select { |cmd| cmd["name"] == element["name"] }[0].merge!("parameters" => params)
end

# Write to ERB file
begin
  file = File.open("templates/commands.erb", "w")

  file.write("<ul id=\"commands\">\n")
  commands.each do |command|
    file.write("<li><a href=\"##{command["name"].gsub(".", "_")}\">#{command["name"]}</a></li>\n")
  end
  file.write("</ul>\n")
  file.write("<br style=\"clear:both;\">\n")
        
  commands.each do |command|
    file.write("<h2 id=\"#{command["name"].gsub(".", "_")}\">#{command["name"]}</h2>\n")
    file.write("<a href=\"#top\" class=\"backtotop\">Voltar ao topo</a>\n")
    file.write("<p>#{command["description"]}</p>\n")
    
    if command["parameters"]
      file.write("<p><strong>Parametros</strong></p>\n")
      file.write("<ul>\n")
      command["parameters"].each do |param|
        file.write("<li>#{param["name"]}: #{param["description"]}</li>\n")
      end
      file.write("</ul>\n")
    end
    
    if command["example"]
      file.write("<p><strong>Exemplo</strong></p>\n")
      file.write("<pre class=\"brush: xml;\">#{command["example"].gsub("<", "&lt;").gsub(">", "&gt;")}</pre>\n")
    end
  end
rescue IOError => e
  puts "Could not write to file (#{e.message})"
ensure
  file.close unless file == nil
end