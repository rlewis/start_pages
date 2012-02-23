require 'sinatra'
require 'redis'
require 'rubygems' # may be needed by heroku


before do
   @suggestedLinks = {"http://www.bankofamerica.com" => ["Bank Of America", "icon-boa.png"], "http://www.fullerton.edu" => ["Cal State Fulllerton", "icon-csuf.png"], "http://www.youtube.com" => ["YouTube", "icon-youtube.png"], "http://www.facebook.com" => ["Facebook", "icon-facebook.png"],  "http://www.ruby-doc.org/core-1.9.3/" => ["Ruby API", "icon-ruby.png"], "http://redis.io/commands" => ["Redis API", "icon-redis.png"], "http://www.amazon.com" => ["Amazon", "icon-amazon.png"], "http://www.github.com" => ["GitHub", "icon-github.png"], "http://www.gmail.com" => ["Gmail", "icon-gmail.png"], "http://www.twitter.com" => ["Twitter", "icon-twitter.png"]}
   @toBeDeletedLinksHash = {}
   @favoriteURLs0 = session[:email]
end

@sitesHash = {}
@annon_sitesHash = {}
@toBeDeletedLinksHash = {}
@favoriteURLs0

configure do
   uri = URI.parse(ENV["REDISTOGO_URL"])
   REDIS = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)

   
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
   REDIS.select 0
   if((params[:email] == "") || (params[:password] == ""))
      @emptyFields = true
   elsif(REDIS.hexists 'userInfo', params[:email])
      @duplicate = true
   else
      REDIS.hset 'userInfo', params[:email], params[:password]
   end
   erb :register
end


#The homepage displays all the favorite URLs
get '/' do  
	puts $newBg
  puts $newBgImg
   if(session[:email] == nil)
      REDIS.select 0
      @sitesHash = REDIS.hgetall 'favoriteURLs1'
   else 
      REDIS.select 0
      @user_prefs = REDIS.hgetall "user_prefs"
      puts @user_prefs
      @sitesHash = REDIS.hgetall @favoriteURLs0
   end
   erb :index
end

#"edit" from Truc's code is called "customize" in this code
get '/edit' do
     erb :customize
end

get '/customize' do  
   if(session[:email] == nil)
      REDIS.select 0
      @sitesHash = REDIS.hgetall 'favoriteURLs1'
      @toBeDeletedLinksHash = REDIS.hgetall 'favoriteURLs1'
   else 
      REDIS.select 0
      @sitesHash = REDIS.hgetall @favoriteURLs0
      @toBeDeletedLinksHash = REDIS.hgetall @favoriteURLs0
   end
   erb :customize
end

get '/login' do
   @prompt = true
    erb :login
end


#login page
post '/login' do
  REDIS.select 0

  @invalidInfo = false
   if (!(REDIS.hexists 'userInfo', params[:email]) && !(REDIS.hexists 'userInfo', params[:password]))
     @invalidInfo = true
   end

  if ((REDIS.hexists 'userInfo', params[:email]) && !((REDIS.hget 'userInfo', params[:email]).eql? params[:password]) )
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

   if params[:file]=='nil'
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
      REDIS.select 0
      if((@hiddenURL != nil) && (@url == nil))
   	 REDIS.hsetnx 'favoriteURLs1',@hiddenURL, @siteName 
      else
        REDIS.hsetnx 'favoriteURLs1', @url, @siteName
      end
   else
      REDIS.select 0
      if((@hiddenURL != nil) && (@url == nil))
   	 REDIS.hsetnx @favoriteURLs0,@hiddenURL, @siteName 
      else
        REDIS.hsetnx @favoriteURLs0, @url, @siteName
      end
   end
   redirect '/customize'
end

post '/removeURL' do
     if(session[:email] == nil)
      REDIS.select 0
      @annon_hiddenURL = params[:hiddenURL]
      @annon_siteName = params[:siteName]
      @suggestedLinks[@annon_hiddenURL] = @annon_siteName
      REDIS.hdel 'favoriteURLs1', @annon_hiddenURL
      $customImages.delete(@annon_hiddenURL)
      redirect '/'
   else
      REDIS.select 0
      @hiddenURL = params[:hiddenURL]
      @siteName = params[:siteName]
      @suggestedLinks[@hiddenURL] = @siteName
      REDIS.hdel @favoriteURLs0, @hiddenURL
      $customImages.delete(@hiddenURL)
      redirect '/'
   end  
end

get '/logout' do
   REDIS.select 0
   REDIS.flushdb 
   session.clear  
   redirect '/'
end
   

#this section is no longer needed since the favorite URLs will be displayed on the front page.
get '/mySites' do
   @sitesHash = REDIS.hgetall 'favoriteURLs'
   erb :index
end

#User changes the background color
post '/update' do
   $newBg = params[:background]
   if ($newBg == "default")
     $newBg = "95a2a6"
   end
   
   $newBgImg = params[:bgimage]
   
   REDIS.select 0
   REDIS.hmset "user_prefs", "user", session[:email], "setting_bg", $newBgImg, "setting_bg_color", $newBg
   
   redirect '/'
end


