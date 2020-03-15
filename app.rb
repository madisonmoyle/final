# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"                                                                     #
require "sinatra/reloader" if development?                                            #
require "sequel"                                                                      #
require "logger"                                                                      #
require "twilio-ruby"                                                                 #
require "bcrypt"
require "geocoder"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
DB.loggers << Logger.new($stdout) unless DB.loggers.size > 0                          #
def view(template); erb template.to_sym; end                                          #
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'           #
before { puts; puts "--------------- NEW REQUEST ---------------"; puts }             #
after { puts; }    

# put your API credentials here (found on your Twilio dashboard)
# account_sid = ENV["TWILIO_ACCOUNT_SID"]
# auth_token = ENV["TWILIO_AUTH_TOKEN"]

# # set up a client to talk to the Twilio REST API
# client = Twilio::REST::Client.new(account_sid, auth_token)

# # send the SMS from your trial Twilio number to your verified non-Twilio number
# client.messages.create(
#  from: "+13477897597", 
#  to: "+12604093910",
#  body: "Hey KIEI 451!"
# )                                                                   #
#######################################################################################

restaurants_table = DB.from(:restaurants)
attend_table = DB.from(:attend)
users_table = DB.from(:users)

before do
    @current_user = users_table.where(id: session["user_id"]).to_a[0]
end

get "/" do
    puts "params: #{params}"

    pp restaurants_table.all.to_a
    @restaurants = restaurants_table.all.to_a
    view "restaurants"
end

get "/restaurants/:id" do
    puts "params: #{params}"

    @restaurant = restaurants_table.where(id: params[:id]).to_a[0]
    pp @restaurant
    @users_table = users_table 
    @attend = attend_table.where(restaurant_id: @restaurant[:id]).to_a
    @going_count = attend_table.where(restaurant_id: @restaurant[:id], attend: true).count
    @review_avg = attend_table.where(restaurant_id: @restaurant[:id], attend: true).avg(:rating)
   

    results = Geocoder.search("#{@restaurant[:address]},#{@restaurant[:city]} #{@restaurant[:state]}")
    lat_long_results = results.first.coordinates
    @lat_long = "#{lat_long_results[0]}, #{lat_long_results[1]}" # => [lat, long]
    puts @lat_long
    puts "lat long above"
    #@lat_long = "#{@lat},#{@long}"
    #"#{lat_long[0]} #{lat_long[1]}"

    view "restaurant"
end

get "/restaurants/:id/attend/new" do
    puts "params: #{params}"

    @restaurant = restaurants_table.where(id: params[:id]).to_a[0]
    @current_user = users_table.where(id: session["user_id"]).to_a[0]
    
    if @current_user
    view "new_attend"
    else 
    view "please_login"
    end
end

get "/restaurants/:id/attend/create" do
    puts "params: #{params}"

    @users_table = users_table 
    @restaurant = restaurants_table.where(id: params[:id]).to_a[0]
    
    attend_table.insert(
    restaurant_id: @restaurant[:id],
    user_id: session["user_id"],
    rating: params["rating"],
    comments: params["comments"],
    attend: params["attend"]
    )

    view "create_attend"
end

get "/attend/:id/edit" do
    puts "params: #{params}"

    @attend = attend_table.where(id: params["id"]).to_a[0]
    @restaurant = restaurants_table.where(id: @attend[:restaurant_id]).to_a[0]
    
    view "edit_attend"
end

post "/attend/:id/update" do
    puts "params: #{params}"
  
    @attend = attend_table.where(id: params["id"]).to_a[0] #remember, this route is stateless, so we only know the id of the rsvp
    @restaurant = restaurants_table.where(id: @attend[:restaurant_id]).to_a[0]
    if @current_user && @current_user[:id]==@attend[:user_id]
    attend_table.where(id: params["id"]).update(
        rating: params["rating"],
        comments: params["comments"],
        attend: params["attend"])
    end

    view "update_attend"
end

get "/attend/:id/destroy" do
    puts "params: #{params}"

    
    @attend = attend_table.where(id: params["id"]).to_a[0]
    @restaurant = restaurants_table.where(id: @attend[:restaurant_id]).to_a[0]
    attend_table.where(id: params["id"]).delete

    view "destroy_attend"
end

get "/users/new" do
    view "new_user"
end

post "/users/create" do
    puts "params: #{params}"

existing_user = users_table.where(email: params["email"]).to_a[0]
if existing_user
    view "error"
else
    @users = users_table.where(id: params[:id]).to_a[0]
    
    users_table.insert(
    name: params["name"],
    email: params["email"],
    password: BCrypt::Password.create(params["password"])
    )

    view "create_user"
end
end

get "/logins/new" do

    view "new_login"
end

post "/logins/create" do
    puts "params: #{params}"

    @user = users_table.where(email: params["email"]).to_a[0]
    if @user && BCrypt::Password.new(@user[:password])==params["password"]

        #know user is logged in, but encrypt it so it's not a cookie
        #session and cookie arrays are automatically stored here through sinatra 
        session["user_id"] = @user[:id]
        view "create_login"
    else 
        view "create_login_failed"
    end
end

get "/logout" do

    @current_user = users_table.where(id: session["user_id"]).to_a[0]
    session["user_id"] = nil

    view "logout"
end

puts "success"