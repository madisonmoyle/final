# Set up for the application and database. DO NOT CHANGE. #############################
require "sequel"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB = Sequel.connect(connection_string)                                                #
#######################################################################################

# Database schema - this should reflect your domain model
DB.create_table! :restaurants do
  primary_key :id
  String :name
  String :address
  String :city
  String :state
  String :country
  String :url, text: true
  String :google_stars
end

DB.create_table! :users do
   primary_key :id
   String :name
   String :email
   String :password
 end

DB.create_table! :attend do
  primary_key :id
  foreign_key :restaurant_id
  foreign_key :user_id
  Boolean :attend
  Integer :rating
  String :comments, text: true
end

# Insert initial (seed) data

restaurants_table = DB.from(:restaurants)

restaurants_table.insert(name: "Lula Cafe", 
                    address: "2537 North Kedzie Avenue",
                    city: "Chicago",
                    state: "IL",
                    country: "USA",
                    url: "http://lulacafe.com/", 
                    google_stars: "4.7"
                    )

restaurants_table.insert(name: "Pacific Standard Time", 
                    address: "141 West Erie Street",
                    city: "Chicago",
                    state: "IL",
                    country: "USA",
                    url: "https://www.pstchicago.com/", 
                    google_stars: "4.6"
                    )

restaurants_table.insert(name: "Galit", 
                    address: "2429 North Lincoln Avenue",
                    city: "Chicago",
                    state: "IL",
                    country: "USA",
                    url: "https://www.galitrestaurant.com/", 
                    google_stars: "4.6"
                    )

 restaurants_table.insert(name: "Pequod's Pizza", 
                    address: "2207 North Clybourn Avenue",
                    city: "Chicago",
                    state: "IL",
                    country: "USA",
                    url: "https://pequodspizza.com/chicago/", 
                    google_stars: "4.4"
                    )

puts "database created"
