require 'zillabyte'
require 'nokogiri'
require 'open-uri'
require 'csv'
require 'httpclient'

# Intantiate an app
app = Zillabyte.app "yc_stack"


# Source
stream = app.source do   
  name "yc_list_scraper"
  
  begin_cycle do
    html = Nokogiri::HTML(open("http://yclist.com/").read)
    @yc_companies = html.xpath("//tr[@class='operating']//a/@href").map{|a| a.value}
  end
  
  next_tuple do
    emit(:url => @yc_companies.shift) unless @yc_companies.empty?
  end
end


# Crawl the websites...
stream = stream.call_component("domain_crawl")


# Examine each page on the websites... 
stream = stream.each do
  prepare do
    @snippets = CSV.parse(File.open('tools.csv').read())
  end 

  execute do |tuple|
    @snippets.each do |vendor, snippet|
      if tuple[:html].include?(snippet)
        emit :url => tuple[:url], :tool => vendor
      end
    end
  end
end



# Sink it 
stream.sink do
  name "yc_stack_tools"
  column "url", :string
  column "tool", :string
end