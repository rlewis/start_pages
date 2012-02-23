require 'sinatra'
require 'redis'
require 'rubygems' # may be needed by heroku

r = Redis.new

before do
   @suggestedLinks = {"http://www.bankofamerica.com" => ["Bank Of America", "icon-boa.png"], "http://www.fullerton.edu" => ["Cal State Fulllerton", "icon-csuf.png"], "http://www.youtube.com" => ["YouTube", "icon-youtube.png"], "http://www.facebook.com" => ["Facebook", "icon-facebook.png"],  "http://www.ruby-doc.org/core-1.9.3/" => ["Ruby API", "icon-ruby.png"], "http://redis.io/commands" => ["Redis API", "icon-redis.png"], "http://www.amazon.com" => ["Amazon", "icon-amazon.png"], "http://www.github.com" => ["GitHub", "icon-github.png"], "http://www.gmail.com" => ["Gmail", "icon-gmail.png"], "http://www.twitter.com" => ["Twitter", "icon-twitter.png"]}
   @toBeDeletedLinksHash = {}
   @favoriteURLs0 = session[:email]
end

@sitesHash = {}
@toBeDeletedLinksHash = {}
@favoriteURLs0

configure do
   enable :sessions
   $newBg = "default"
   $newBgImg = "default"
   $customImages = Hash.new
end

get '/register' do
   @emptyFields = true
   @duplicate = true
   erb :register
end

post '/register' do
   r.select 0
   if((params[:email] == "") || (params[:password] == ""))
      @emptyFields = true
   elsif(r.hexists 'userInfo', params[:email])
      @duplicate = true
   else
      r.hset 'userInfo', params[:email], params[:password]
   end
   erb :register
end


#The homepage displays all the favorite URLs
get '/' do  
   if(session[:email] == nil)
      r.select 1
      @sitesHash = r.hgetall 'favoriteURLs1'
   else 
      r.select 0
      @user_prefs = r.hgetall "user_prefs"
      $newBg = @user_prefs["setting_bg_color"]
      $newBgImg = @user_prefs["setting_bg"]
      @sitesHash = r.hgetall @favoriteURLs0
   end
   erb :index
end

#"edit" from Truc's code is called "customize" in this code
get '/edit' do
     erb :customize
end

get '/customize' do  
   if(session[:email] == nil)
      r.select 1
      @sitesHash = r.hgetall 'favoriteURLs1'
      @toBeDeletedLinksHash = r.hgetall 'favoriteURLs1'
   else 
      r.select 0
      @sitesHash = r.hgetall @favoriteURLs0
      @toBeDeletedLinksHash = r.hgetall @favoriteURLs0
   end
   erb :customize
end

get '/login' do
   @prompt = true
    erb :login
end


#login page
post '/login' do
  r.select 0

  @invalidInfo = false
   if (!(r.hexists 'userInfo', params[:email]) && !(r.hexists 'userInfo', params[:password]))
     @invalidInfo = true
   end

  if ((r.hexists 'userInfo', params[:email]) && !((r.hget 'userInfo', params[:email]).eql? params[:password]) )
     @invalidInfo = true
  else
     session[:email] = params[:email]
  end
  erb :login
end

#addURL and removeURL are form actions performed on the /customize page.
post '/addURL' do
   @hiddenURL = params[:hiddenURL]
   @url = params[:myURL]
   @siteName = params[:siteName]

if params[:file]!=nil
   #here we upload the image
      @fileName = params[:file][:filename]
      File.open('public/images/' + @fileName, "w") do |f|
      f.write(params[:file][:tempfile].read)
end

   #add the image to the "customImages" hash, which we use to display the custom images
   #on index.erb   
	$customImages = {@url => @fileName}
   end

   if(session[:email] == nil)
      r.select 1
      if((@hiddenURL != nil) && (@url == nil))
   	 r.hsetnx 'favoriteURLs1',@hiddenURL, @siteName 
      else
        r.hsetnx 'favoriteURLs1', @url, @siteName
      end
   else
      r.select 0
      if((@hiddenURL != nil) && (@url == nil))
   	 r.hsetnx @favoriteURLs0,@hiddenURL, @siteName 
      else
        r.hsetnx @favoriteURLs0, @url, @siteName
      end
   end
   redirect '/customize'
end

post '/removeURL' do
     if(session[:email] == nil)
      r.select 1
      @hiddenURL = params[:hiddenURL]
      @siteName = params[:siteName]
      @suggestedLinks[@hiddenURL] = @siteName
      r.hdel 'favoriteURLs1', @hiddenURL
      $customImages.delete(@hiddenURL)
      redirect '/'
   else
      r.select 0
      @hiddenURL = params[:hiddenURL]
      @siteName = params[:siteName]
      @suggestedLinks[@hiddenURL] = @siteName
      r.hdel @favoriteURLs0, @hiddenURL
      $customImages.delete(@hiddenURL)
      redirect '/'
   end  
end

get '/logout' do
   r.select 1
   r.flushdb 
   session.clear  
   redirect '/'
end
   

#this section is no longer needed since the favorite URLs will be displayed on the front page.
get '/mySites' do
   @sitesHash = r.hgetall 'favoriteURLs'
   erb :index
end

#User changes the background color
post '/update' do
   $newBg = params[:background]
   if ($newBg == "default")
     $newBg = "95a2a6"
   end
   
   $newBgImg = params[:bgimage]
   
   r.select 0
   r.hmset "user_prefs", "user", session[:email], "setting_bg", $newBgImg, "setting_bg_color", $newBg
   
   redirect '/'
end
