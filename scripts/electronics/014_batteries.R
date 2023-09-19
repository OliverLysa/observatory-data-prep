
### Batteries accepted for treatment (tonnes, UK)

```{r}
VehicBattall <- read_excel("data.xlsx", sheet = "BattTre") %>% 
  gather(Battery_Type, Value, - Year, - Accepted_by, -Source) %>% filter(Source=="Automotive") %>% filter(Battery_Type=="Total") %>% mutate_if(is.numeric, round, digits=0)

VehicBattgraph <- ggplot(VehicBattall, aes(Year, Value, fill=Accepted_by)) + 
  geom_bar(position = "stack", stat = "identity", width = 0.7) +
  scale_x_continuous(breaks = seq(2010,2020)) +
  theme(axis.title.x = element_blank()) +
  theme(axis.title.y = element_blank())

ggplotly(VehicBattgraph, tooltip = c("Value")) %>% 
  layout(legend = list(orientation = 'h')) %>% 
  layout(legend = list(x = 0, y = - 0.1))

```
