
# Created by Luiz Morais
# Mar 31, 2020

library(geojsonio)
library(dplyr)
library(readr)
library(stringr)
library(here)
library(stringi)

rm(list = ls())

cg = topojson_read(here('data/raw_cg.json')) %>%
    mutate(NM_BAIRRO = stri_trans_general(NM_BAIRRO, id = 'Latin-ASCII'),
           NM_BAIRRO = case_when(
               NM_BAIRRO == 'CENTRO DE CAMPINA GRANDE' ~ 'CENTRO',
               NM_BAIRRO == 'JARDIM QUARENTA' ~ 'QUARENTA',
               NM_BAIRRO == '' ~ 'AREA RURAL',
               TRUE ~ as.character(NM_BAIRRO)
           )) %>%
    select(-id, -ID) %>%
    rename_at(vars(starts_with('NM_')), funs(str_remove(., 'NM_'))) %>%
    rename_all(funs(str_to_lower(.)))

idosos_cad = read_csv(here('data/raw_idosos_cad_bairros.csv')) %>%
    mutate(BAIRRO = stri_trans_general(BAIRRO, id = "Latin-ASCII")) %>%
    rename_all(funs(str_to_lower(.))) %>%
    rename_all(funs(str_replace(., ' ', '_')))

bairros_idosos = idosos_cad %>% pull(bairro) %>% unique()
bairros_cg = cg %>% pull(bairro) %>% unique()

# Neighborhoods in CAD but not in CG
print(setdiff(bairros_idosos, bairros_cg))

# Neighborhoods in CG but not in CAD
print(setdiff(bairros_cg, bairros_idosos))

prop_idosos_bairros = cg %>%
    select(bairro, populacao, densidade) %>%
    as_tibble() %>%
    group_by(bairro) %>%
    summarise(populacao_bairro = sum(as.integer(as.character(populacao)), na.rm = T),
              densidade_bairro = mean(as.integer(as.character(densidade)), na.rm = T)) %>%
    merge(idosos_cad) %>%
    group_by(bairro) %>%
    mutate(proporcao_idosos = qtd_idosos / populacao_bairro)

# Save CAD's neighborhoods without accents
write_csv(x = idosos_cad, path = here('data/idosos_cad_bairros.csv'))

# Save percentage of elderly
write_csv(x = prop_idosos_bairros, path = here('data/prop_idosos_bairros.csv'))

# Save CG's neighborhoods without accents
topojson_write(input = cg, file = here('data/cg_all.json'), object_name = 'setores')

# Save CG's urban area only
topojson_write(input = cg %>% filter(tipo == 'URBANO'), file = here('data/cg.json'), object_name = 'setores')
