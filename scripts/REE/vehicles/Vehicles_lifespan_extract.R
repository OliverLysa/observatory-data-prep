require(readxl)
require(magrittr)
require(writexl)

Vehiclelife <- read_excel("./Vehicles/Lifespan.xlsx", sheet = 1)
Vehiclelife <- Vehiclelife[c(6:42486), c(1:124)] %>% row_to_names(row_number = 1) 
Vehiclelife <- Vehiclelife %>% gather(Year, Number, -Make, -`Generic model 1`, -`Model 1`)
Vehiclelife <- Vehiclelife %>% mutate(CurrentYear = 2020) 
Vehiclelife$Year <- as.numeric(as.character(Vehiclelife$Year))
Vehiclelife$Number <- as.numeric(as.character(Vehiclelife$Number))
Vehiclelife$CurrentYear <- as.numeric(as.character(Vehiclelife$CurrentYear))
Vehiclelife <- Vehiclelife %>% mutate(Age = CurrentYear - Year) %>% na.omit() 

Vehiclelifetotal <- Vehiclelife %>% group_by(Age) 
Vehiclelifetotal$Value <- as.numeric(as.character(Vehiclelifetotal$Value))

write_xlsx(Vehiclelifetotal, "Vehiclelifetotal.xlsx")  




