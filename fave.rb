require 'sinatra'
require 'redis'

r = Redis.new
#r.flushdb

$suggestedLinks = {"http://www.bankofamerica.com" => "Bank Of America", "http://www.fullerton.edu" => "Cal State Fulllerton", 
"http://www.youtube.com" => "YouTube", "http://www.facebook.com" => "Facebook", "http://csuf.kenytt.net" => "Web Programming CPSC 473, CSU Fullerton",
"http://www.frys.com" => "Frys Electronic", "http://www.nasa.com" => "NASA", "http://www.ruby-doc.org/core-1.9.3/" => "Ruby API",
"http://redis.io/commands" => "Redis API"}


$sitesHash = {}
$toBeDeletedLinksHash = {}

#The homepage displays all the favorite URLs
get '/' do
   $sitesHash = r.hgetall 'favoriteURLs'
   erb :index
end

#if there is a get or a post to /register, the register page will be rendered
post '/register' do
   erb :register
end

get '/register' do
   erb :register
end

#"edit" from Truc's code is called "customize" in this code
get '/edit' do
     erb :customize
end

get '/customize' do
    erb :customize
end

#login page
get '/login' do
  erb :login
end

#addURL and removeURL are form actions performed on the /customize page.
post '/addURL' do
   @hiddenURL = params[:hiddenURL]
   @url = params[:myURL]
   @siteName = params[:siteName]

   if((@hiddenURL != nil) && (@url == nil))
   	r.hsetnx 'favoriteURLs',@hiddenURL, @siteName 
	r.hsetnx 'toBeDeletedLinks', @hiddenURL, @siteName
	$suggestedLinks.delete(@hiddenURL)
   else
       r.hsetnx 'favoriteURLs', @url, @siteName
	r.hsetnx 'toBeDeletedLinks', @url, @siteName
   end

   $toBeDeletedLinksHash = r.hgetall 'toBeDeletedLinks'
   redirect '/edit'
end

post '/removeURL' do
   @hiddenURL = params[:hiddenURL]
   @siteName = params[:siteName]
   $suggestedLinks[@hiddenURL] = @siteName
   r.hdel 'favoriteURLs', @hiddenURL
   r.hdel 'toBeDeletedLinks', @hiddenURL
   $toBeDeletedLinksHash = r.hgetall 'toBeDeletedLinks'
   redirect '/edit'
end

#this section is no longer needed since the favorite URLs will be displayed on the front page.
get '/mySites' do
   $sitesHash = r.hgetall 'favoriteURLs'
   erb :index
end
