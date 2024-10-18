data2 = results |> 
  st_transform(crs = 3857) |> 
  filter(.pred_1 >= 0.05) 

box <- region |> st_bbox()
set_defaults(map_service = "osm", map_type = "streets")
# Mapa base
m1 = ggplot() + 
  basemap_gglayer(box) +
  scale_fill_identity() + 
  coord_sf()

region2 <- region |> st_transform(3857)
# Mapa final
m1 + 
  new_scale_fill() + 
  geom_sf(data = region2, fill = NA, linewidth=0.5) + 
  labs(x = "", y = "") + 
  scale_x_continuous(expand = c(0, 0)) + 
  scale_y_continuous(expand = c(0, 0)) + 
  geom_sf(data = data2,aes(fill = .pred_1), col = NA,alpha = 0.7) +
  scale_fill_viridis_c('prob',option ="inferno" ,direction = -1) +
  # scale_fill_gradientn(colours = cpt("cmocean_haline",rev = 1)) +
  ggspatial::annotation_north_arrow(location = "tl",height = unit(1, "cm") ,width = unit(1, "cm")) +
  ggspatial::annotation_scale(location = "br") + 
  theme(
    axis.text = element_text(family = "Roboto Slab",size = 12),
    legend.text = element_text(family = "Roboto Slab",size = 12),
    legend.title = element_text(family = "Roboto Slab",size = 12))


ggsave(
  filename = 'tesing.png',
  plot = last_plot(),
  width = 10,
  height = 8,
  dpi = 300,
  bg = "white")

