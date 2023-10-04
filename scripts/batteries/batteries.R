batteries_POM <- read_excel(
  "./intermediate_data/Batteries.xlsx",
  sheet = "Onthemarket") %>%
  pivot_longer(-c("Year", "Source"),
               names_to = "Type",
               values_to = "value") %>%
  clean_names() %>%
  write_csv("./cleaned_data/batteries_POM.csv")
