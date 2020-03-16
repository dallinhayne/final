# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"                                                                     #
require "sinatra/reloader" if development?                                            #
require "sequel"                                                                      #
require "logger"                                                                      #
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
account_sid = "AC027d88dda5af03e1732f895465dc6273"
auth_token = "262928649d372bca4224d57ba449a6d9"

# set up a client to talk to the Twilio REST API


# send the SMS from your trial Twilio number to your verified non-Twilio number

locations_table = DB.from(:locations)
reviews_table = DB.from(:reviews)
users_table = DB.from(:users)

before do
    @current_user = users_table.where(id: session["user_id"]).to_a[0]
end

get '/send_text' do
    account_sid= ENV["TWILIO_ACCOUNT_SID"]
    # auth_token =""

end 

# homepage and list of events (aka "index")
get "/" do
    puts "params: #{params}"

    pp loactions_table.all.to_a
    @locations = locations_table.all.to_a
    view "locations"
end

# event details (aka "show")
get "/locations/:id" do
    puts "params: #{params}"

    @users_table = users_table
    @location = locations_table.where(id: params[:id]).to_a[0]
    pp @location
    @reviews = reviews_table.where(location_id: @location[:id]).to_a
    @going_count = reviews_table.where(location_id: @location[:id], going: true).count
    view "location"
end

# display the rsvp form (aka "new")
get "/locations/:id/reviews/new" do
    puts "params: #{params}"

    @location = locations_table.where(id: params[:id]).to_a[0]
    view "new_review"
end

# receive the submitted rsvp form (aka "create")
post "/locations/:id/reviews/create" do
    puts "params: #{params}"

    # first find the event that rsvp'ing for
    @location = locations_table.where(id: params[:id]).to_a[0]
    # next we want to insert a row in the rsvps table with the rsvp form data
    reviews_table.insert(
        location_id: @location[:id],
        user_id: session["user_id"],
        comments: params["comments"],
        going: params["going"]
    )
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

# display the signup form (aka "new")
get "/users/new" do
    view "new_user"
end

# receive the submitted signup form (aka "create")
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

# display the login form (aka "new")
get "/logins/new" do
    view "new_login"
end

# receive the submitted login form (aka "create")
post "/logins/create" do
    puts "params: #{params}"

    # step 1: user with the params["email"] ?
    @user = users_table.where(email: params["email"]).to_a[0]
    if @user
        # step 2: if @user, does the encrypted password match?
        if BCrypt::Password.new(@user[:password]) == params["password"]
            # set encrypted cookie for logged in user
            session["user_id"] = @user[:id]
            view "create_login"
        else
            view "create_login_failed"
        end
    else
        view "create_login_failed"
    end
end

# logout user
get "/logout" do
    # remove encrypted cookie for logged out user
    session["user_id"] = nil
    redirect "/logins/new"
end