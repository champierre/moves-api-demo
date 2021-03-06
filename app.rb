require 'sinatra'
require 'oauth2'
require 'json'
require 'date'
require 'mail'

Mail.defaults do
  delivery_method :smtp, {
    :address => 'smtp.sendgrid.net',
    :port => '587',
    :domain => 'heroku.com',
    :user_name => ENV['SENDGRID_USERNAME'],
    :password => ENV['SENDGRID_PASSWORD'],
    :authentication => :plain,
    :enable_starttls_auto => true
  }
end

if ENV['RACK_ENV'] != 'production'
  require 'dotenv'
  Dotenv.load
end

# access tokens will be stored in the session
enable :sessions
set    :session_secret, 'super secret'

helpers do
  def format_date(date_str)
    Date.parse(date_str).strftime("%-m/%-d(%a)")
  end
end

def client
  OAuth2::Client.new(
    ENV['MOVES_CLIENT_ID'],
    ENV['MOVES_CLIENT_SECRET'],
    :site => 'https://api.moves-app.com',
    :authorize_url => 'moves://app/authorize',
    :token_url => 'https://api.moves-app.com/oauth/v1/access_token')
end

get "/" do
  if !session[:access_token].nil?
    erb :index
  else
    @moves_authorize_uri = client.auth_code.authorize_url(:redirect_uri => redirect_uri, :scope => 'activity location')
    erb :signin
  end
end

get '/moves/logout' do
  session[:access_token]  = nil
  redirect '/'
end

get '/auth/moves/callback' do
  new_token = client.auth_code.get_token(params[:code], :redirect_uri => redirect_uri)
  session[:access_token]  = new_token.token
  redirect '/'
end

def redirect_uri
  uri = URI.parse(request.url)
  uri.path = '/auth/moves/callback'
  uri.query = nil
  uri.to_s
end

def access_token
  OAuth2::AccessToken.new(client, session[:access_token], :refresh_token => session[:refresh_token])
end

get '/moves/profile' do
  @json = access_token.get("/api/1.1/user/profile").parsed
  erb :profile, :layout => !request.xhr?
end

get '/moves/recent' do
  @json = access_token.get("/api/1.1/user/summary/daily?pastDays=7").parsed
  @steps = @json.map { |day|
    unless day["summary"].nil?
      (day["summary"].find { |a| a["group"] == "walking"})["steps"]
    else
      0
    end
  }
  erb :recent, :layout => !request.xhr?
end

get '/moves/workdays' do
  start_date = Date::new((Date.today << 1).year, (Date.today << 1).month, 1)
  end_date = (start_date >> 1) - 1
  from = start_date.strftime("%Y%m%d")
  to = end_date.strftime("%Y%m%d")
  json = access_token.get("/api/1.1/user/places/daily?from=#{from}&to=#{to}").parsed

  @workdays = []
  @days_data = []
  json.each do |day|
    day_data = {}
    date = format_date(day["date"])
    day_data[:date] = date
    unless day["segments"].nil?
      segments = day["segments"].find_all { |s| s["type"] == 'place' }
      day_data[:segments] = []
      segments.each do |segment|
        if (place = segment["place"]["name"]) == (ENV['WORKING_PLACE_NAME'] || 'Office')
          day_data[:segments] << "<strong>#{place}</strong>"
          @workdays << date unless @workdays.include?(date)
        else
          day_data[:segments] << place
        end
      end
    end
    @days_data << day_data
  end

  erb :workdays, :layout => !request.xhr?
end

post '/emails' do
  Mail.new(
    to: ENV['EMAIL_TO'],
    from: ENV['EMAIL_TO'],
    subject: "Workdays: #{@params[:workdays_count]} days",
    body: @params[:workdays]
  ).deliver!
  erb :sent
end
