# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"                                                                     #
require "sinatra/reloader" if development?                                            #
require "sequel"                                                                      #
require "logger" 
require "geocoder"                                                                     #
require "twilio-ruby"                                                                 #
require "bcrypt"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
DB.loggers << Logger.new($stdout) unless DB.loggers.size > 0                          #
def view(template); erb template.to_sym; end                                          #
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'           #
before { puts; puts "--------------- NEW REQUEST ---------------"; puts }             #
after { puts; }                                                                       #
#######################################################################################

# put your API credentials here (found on your Twilio dashboard)
# account_sid = "AC027d88dda5af03e1732f895465dc6273"
# auth_token = "ab0276371eca7229074be29439beb392"

    
# client = Twilio::REST::Client.new(account_sid,auth_token)

locations_table = DB.from(:locations)
reviews_table = DB.from(:reviews)
users_table = DB.from(:users)

before do
    @current_user = users_table.where(id: session["user_id"]).to_a[0]
end



get "/" do
    puts "params: #{params}"

    pp locations_table.all.to_a
    @locations = locations_table.all.to_a
    view "locations"

end

get "/locations/:id" do
    puts "params: #{params}"

    @users_table = users_table
    @location = locations_table.where(id: params[:id]).to_a[0]
    pp @location
    @reviews = reviews_table.where(location_id: @location[:id]).to_a
    @going_count = reviews_table.where(location_id: @location[:id], going: true).count
    
    results = Geocoder.search(@location[:address])

    lat_long = results.first.coordinates # => [lat,long]
    @lat = lat_long[0]
    @long = lat_long[1]
    
    
    view "location"
end


get "/locations/:id/reviews/new" do
    puts "params: #{params}"

    @location = locations_table.where(id: params[:id]).to_a[0]
    view "new_review"
end


post "/locations/:id/reviews/create" do
    puts "params: #{params}"

   
    @location = locations_table.where(id: params[:id]).to_a[0]
 
    reviews_table.insert(
        location_id: @location[:id],
        user_id: session["user_id"],
        comments: params["comments"],
        going: params["going"]
    )
#       client.messages.create(
#  from: "+12064663374", 
#  to: "+18584723202",
#  body: "Thanks for leaving us a review!"
# )
    redirect "locations/#{@location[:id]}"
  
end

get "/reviews/:id/edit" do
    puts "params: #{params}"

    @review = reviews_table.where(id: params["id"]).to_a[0]
    @location = locations_table.where(id: @review[:location_id]).to_a[0]
    view "edit_review"
end

post "/reviews/:id/update" do
    puts "params: #{params}"
 @review = reviews_table.where(id: params["id"]).to_a[0]
 @locations = locations_table.where(id: @review[:location_id]).to_a[0]
 if @current_user && @current_user[:id] == @review[:id]
 reviews_table.where(id: params["id"]).update(
     going: params["going"],
     comments: params["comments"]
    
 )
 view "update_review"
 else
    view "error"  
end
end
get "/reviews/:id/destroy" do
    puts "params: #{params}"

    review = reviews_table.where(id: params["id"]).to_a[0]
    @location = locations_table.where(id: review[:location_id]).to_a[0]

    reviews_table.where(id: params["id"]).delete

    view "destroy_review"
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
    if @user
      
        if BCrypt::Password.new(@user[:password]) == params["password"]
           
            session["user_id"] = @user[:id]
            view "create_login"
        else
            view "create_login_failed"
        end
    else
        view "create_login_failed"
    end
end


get "/logout" do
 
    session["user_id"] = nil
    redirect "/logins/new"
end