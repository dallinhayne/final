# Set up for the application and database. DO NOT CHANGE. #############################
require "sequel"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB = Sequel.connect(connection_string)                                                #
#######################################################################################

# Database schema - this should reflect your domain model
DB.create_table! :locations do
  primary_key :id
  String :title
  String :description, text: true
  String :average_rating
  String :address
end
DB.create_table! :reviews do
  primary_key :id
  foreign_key :location_id
  foreign_key :user_id
  Boolean :going
  String :comments, text: true
end
DB.create_table! :users do
  primary_key :id
  String :name
  String :email
  String :password
end

# Insert initial (seed) data
locations_table = DB.from(:locations)

locations_table.insert(title: "Las Vegas Center for Autism", 
                    description: "Our flagship location specializes in care for autistic children and teenagers.",
                    average_rating: "4.5/5.0 stars",
                    address: "3950 S Las Vegas Blvd, Las Vegas, NV 89119")

locations_table.insert(title: "San Diego Center for Behavioral Therapy", 
                    description: "Our SD location is our largest, with capacity for 100 students.",
                    average_rating: "4.8/5.0 stars",
                    address: "100 Park Blvd, San Diego, CA 92101")
                   
locations_table.insert(title: "Children's Center of Chicago", 
                    description: "Our Midwest location has 20 highly trained BCBA's, focused on improving behavioral planning.",
                    average_rating: "4.6/5.0 stars",
                    address: "2211 Campus Dr, Evanston, IL 60208")

puts "Success!"