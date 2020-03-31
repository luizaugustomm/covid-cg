
# Created by Luiz Morais
# Mar 31, 2020

library(geojsonio)
library(dplyr)
library(readr)
library(here)
library(stringi)

cg = topojson_read(here('data/raw_cg.json')) %>%
    mutate(NM_BAIRRO = stri_trans_general(NM_BAIRRO, id = 'Latin-ASCII'),
           NM_BAIRRO = case_when(
               NM_BAIRRO == 'CENTRO DE CAMPINA GRANDE' ~ 'CENTRO',
               NM_BAIRRO == 'JARDIM QUARENTA' ~ 'QUARENTA',
               NM_BAIRRO == '' ~ 'AREA RURAL',
               TRUE ~ as.character(NM_BAIRRO)
           ))

idosos_cad = read_csv(here('data/raw_idosos_cad_bairros.csv')) %>%
    mutate(BAIRRO = stri_trans_general(BAIRRO, id = "Latin-ASCII"))

bairros_idosos = idosos_cad %>% pull(BAIRRO) %>% unique()
bairros_cg = cg %>% pull(NM_BAIRRO) %>% unique()

# Neighborhoods in CAD but not in CG
print(setdiff(bairros_idosos, bairros_cg))

# Neighborhoods in CG but not in CAD
print(setdiff(bairros_cg, bairros_idosos))

# Save CAD's neighborhoods without accents
write_csv(x = idosos_cad, path = here('data/idosos_cad_bairros.csv'))

# Save CG's neighborhoods without accents
topojson_write(input = cg, file = here('data/cg_all.json'))

# Save CG's urban area only
topojson_write(input = cg %>% filter(TIPO == 'URBANO'), file = here('data/cg.json'))