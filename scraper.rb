# This is a template for a Ruby scraper on Morph (https://morph.io)
# including some code snippets below that you should find helpful

require 'scraperwiki'
require 'mechanize'

def save_media_release(page)
  container = page.search('div#content-main')

  title = container.search(:h1)[1].text

  pub_datetime = DateTime.parse(container.children[8].text, '%A, %d %B %Y %l:%M:%S %p')

  # Strip the release header and meta elements leaving just the body
  container.children[0...9].remove

  media_release = {
    title: title,
    pub_datetime: pub_datetime.to_s,
    body: container.inner_html,
    url: page.uri.to_s,
    scraped_datetime: DateTime.now.to_s
  }

  puts "Saving: #{title}, #{pub_datetime.strftime('%Y-%m-%d')}"
  ScraperWiki.save_sqlite([:url], media_release)
end

agent = Mechanize.new

index = agent.get('http://www.police.nsw.gov.au/news/media_release_archives')

index.search('#content_div_111604 a').each do |link|
  if !ScraperWiki.select("url from data where url='#{link.attr(:href)}'").empty?
    puts "Skipping already saved media release #{link.text} #{link.attr(:href)}"
  else
    media_release_page = agent.get(link.attr(:href))
    save_media_release(media_release_page)
  end
end

