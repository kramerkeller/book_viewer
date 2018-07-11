require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"

not_found do
  redirect "/"
end

before do
  @chapter_names = File.readlines("data/toc.txt")

  # chapters consist of name, number, paragraphs
  @chapters = @chapter_names.map.with_index do |chapter_name, index|
    chapter_num = index + 1
    chapter_text = File.read("data/chp#{chapter_num}.txt")
    chapter_paragraphs = chapter_text.split("\n\n")

    {name: chapter_name, num: chapter_num, paragraphs: chapter_paragraphs}
  end
end

helpers do
  def in_paragraph(text)
    text.split("\n\n").map.with_index do | paragraph, index |
      "<p id=paragraph#{index + 1}>#{paragraph}</p>"
    end.join
  end

  def in_strong(text, target)
    strong_text = "<strong>" + target + "</strong>"
    text.gsub(target, strong_text)
  end
end

def results(query)
  results = []
  return results if !query || query.empty?

  @chapters.each_with_index do |chapter, index|
    hits = []
    chapter_num = index + 1

    chapter[:paragraphs].each_with_index do |paragraph, i|
      id = i + 1
      hits << { paragraph_match: paragraph, paragraph_id: id } if paragraph.match(query)
    end

    results << {chapter_name: chapter[:name], chapter_num: chapter_num, hits: hits} unless hits.empty?
  end

  results
end

get "/" do
  @title = "The Adventures of Sherlock Holmes"
  erb :home
end

get "/search" do
  @results = results(params[:query])
  erb :search
end

get "/chapters/:number" do
  number = params[:number].to_i
  chapter_name = @chapter_names[number - 1]

  @title = "Chapter #{number}: #{chapter_name}"
  @chapter = File.read("data/chp#{number}.txt")

  erb :chapter
end
