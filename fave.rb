require 'sinatra'
require 'redis'

r = Redis.new
#r.flushdb

$suggestedLinks = {"http://www.bankofamerica.com" => "Bank_Of_America", "http://www.fullerton.edu" => "Cal_State_Fulllerton", 
"http://www.youtube.com" => "YouTube", "http://www.facebook.com" => "Facebook", "http://www.amazon.com" => "Amazon",
"http://www.gmail.com" => "Gmail", "http://www.twitter.com" => "Twitter", "http://www.ruby-doc.org/core-1.9.3/" => "Ruby_API",
"http://redis.io/commands" => "Redis_API", "http://www.github.com" => "Github"}

$newBg = "default"
$sitesHash = {}
$toBeDeletedLinksHash = {}

#The homepage displays all the favorite URLs
get '/' do
   $sitesHash = r.hgetall 'favoriteURLs'
   erb :index
end

#after the registration form is submitted, information will be sent here
post '/register_process' do
  @reg_email = params[:email]
  @reg_pass = params[:password]
  #enter this information into the database
  redirect '/login'
end

#registration form is here
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

#login form
get '/login' do
  erb :login
end

#after the login form is submitted, information will be passed here
post '/login_process' do
  @login_email = params[:email]
  @login_pass = params[:password]
  #check credentials
      #if error, redirect to '/login_error'
      #if not, continue
  #load user's settings
  redirect '/'
end

#if there is a login error, redirect to this page
get '/login_error' do
   erb :login_error
end

#addURL and removeURL are form actions performed on the /customize page.
post '/addURL' do
   @hiddenURL = params[:hiddenURL]
   @url = params[:myURL]
   @siteName = params[:siteName]
   @image = params[:image]

   #Change "Bank of America" to "Bank_Of_America"
   @siteName.gsub!(" ","_")

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

#User changes the background color
post '/background' do
   $newBg = params[:background]
   $newBg.gsub!("#","")
   redirect '/'
end
