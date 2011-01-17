require 'sinatra'
require 'haml'
require 'data_mapper'
require 'dm-postgres-adapter'

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/words.db")

#DATABASE

class Word
  include DataMapper::Resource
  property :id,           Serial
  property :name,        String
  property :starts_with,  String
  property :point_value,  Integer
end

DataMapper.finalize

#METHODS

$point_values = {"a" => 1, "b" => 3, "c" => 3, "d" => 2, "e" => 1, "f" => 4, "g" => 2, "h" => 4, "i" => 1, "j" => 8, "k" => 5, "l" => 1, "m" => 3, "n" => 1, "o" => 1, "p" => 3, "q" => 10, "r" => 1, "s" => 1, "t" => 1, "u" => 1, "v" => 4, "w" => 4, "x" => 8, "y" => 4, "z" => 10}

def point_value(word)
  total = 0
  word.each_char do |char|
    val = $point_values[char]
    if val == nil
      puts "Problem with '" + char + "'"
    else
    total = total + $point_values[char]
    end
  end
return total

end

#======================ROUTES==========================

#CSS

get '/' do
 redirect '/validate'
end

# index of all words
get '/words' do
  @title = "Word List"
  @words = Word.all
  haml :index
end

# list words by letter
get '/words/list/:id' do
  @title = params[:id].upcase + " Word List"
  @words = Word.all(:starts_with => params[:id])
  haml :list
end


# add new word
get '/words/new' do
  @title = "Add New Word"
  haml :new
end

# create new word   
post '/words' do
  name = params[:name]
  points = point_value(name)
  @word = Word.create(:name => name, :starts_with => name[0], :point_value => points)
  if @word.save
    status 201
    redirect '/words/list/a'
  else
    status 400
    haml :new
  end
end

get '/words/:id' do
  @word = Word.get(params[:id])
  haml :show
end
# delete word confirmation
get '/words/delete/:id' do
  @word = Word.get(params[:id])
  haml :delete
end

# delete word
delete '/words/:id' do
  Word.get(params[:id]).destroy
  redirect '/words/list/a'  
end

# validate word
get '/validate' do
  @title = "Validate that Word"
  @count = Word.count
  haml :validate
end

#post validate
post '/validate' do 
  @is_word = params[:is_word].downcase
  if Word.first(:name => @is_word)
    @word = Word.first(:name => @is_word)
    "YES " + @is_word + " is a valid word " + "worth " + @word.point_value.to_s + " points"
  else
    "NO " + @is_word + " is not valid"
  end
end

# import words
get '/import' do
  @title = "Import Words"
  haml :import
end

# post import
post '/import' do
  unless params[:file] &&
         (tmpfile = params[:file][:tempfile]) &&
         (name = params[:file][:filename])
    @error = "No file selected"
    return haml(:import)
  end
  STDERR.puts "Uploading file, original name #{name.inspect}"
  f = File.open(tmpfile,"r")
  w = Hash.new
  f.each_line do |line|
    line = line.strip.chomp.downcase
    w[line] = 1
  end  
  
  w.each do |k,v|
    points = point_value(k)
    Word.create({ :name => k, :starts_with => k[0], :point_value => points })
  end    
    # here you would write it to its final location
    STDERR.puts "Upload complete"
    redirect '/words'
end

# Catch all that doesn't seem to work
get '/*' do
  "We couldn't find '#{params[:splat]}"
  haml :layout
end
    

DataMapper.auto_upgrade!
