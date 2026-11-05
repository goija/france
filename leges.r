# ==============================================================================
# R-SCRIPT: Rekenmodule Mijnbouwretributies & Vergunningsleges (Gecorrigeerd)
# ==============================================================================

bereken_mijnbouw_retributie <- function(dagen_boorgat = 0, 
                                         hoge_druk = FALSE, 
                                         installatie_type = "geen", 
                                         leges_categorie = "NONE") {
  
  # 1. Dagelijkse retributie boorgatactiviteiten (Bijlage 15, B.2g / B.2h)
  tarief_per_dag <- if (hoge_druk) 264 else 132  # €132/dag (<=689,5 bar) vs €264/dag (>689,5 bar)
  retributie_boorgat <- dagen_boorgat * tarief_per_dag
  
  # 2. Jaarlijkse toezichtsvergoeding exploitant (Bijlage 15, B.1 & B.2a-d)
  basis_toezicht <- if (installatie_type != "geen") 5000 else 0
  toeslag_installatie <- switch(installatie_type,
    "klein_land"  = 618,    # Klein land
    "klein_zee"   = 3089,   # Klein zee
    "groot_land"  = 6178,   # Groot land
    "groot_zee"   = 6178,   # Groot zee
    0
  )
  totaal_toezicht <- basis_toezicht + toeslag_installatie
  
  # 3. Legeskosten per besluitcategorie (Bijlage 15, D Tabel 1)
  tarieven_tabel <- c(
    "A" = 38200, "B" = 19200, "C" = 17960, "D" = 15280,
    "E" = 13970, "F" = 12450, "G" = 10030, "H" = 8020,
    "I" = 7280,  "J" = 5200,  "K" = 4300,  "L" = 3600,
    "M" = 19200, "N" = 1020,  "O" = 0,     "NONE" = 0
  )
  leges_kosten <- unname(tarieven_tabel[leges_categorie])
  
  # Totaaloverzicht
  totaal_bedrag <- retributie_boorgat + totaal_toezicht + leges_kosten
  
  # Hulpfunctie voor geldformattering (NL-conventie)
  format_eur <- function(x) {
    paste0("€ ", format(round(x, 2), nsmall = 2, big.mark = ".", decimal.mark = ","))
  }
  
  return(data.frame(
    Boorgat_Dagen        = dagen_boorgat,
    Werkdruk_Tier        = if (hoge_druk) "> 689,5 bar (€264/d)" else "≤ 689,5 bar (€132/d)",
    Retributie_Boorgat   = format_eur(retributie_boorgat),
    Jaarlijks_Toezicht   = format_eur(totaal_toezicht),
    Leges_Categorie      = leges_categorie,
    Leges_Kosten         = format_eur(leges_kosten),
    Totaal_Verschuldigd  = format_eur(totaal_bedrag)
  ))
}

# --- PROEFBEREKENING ----------------------------------------------------------
resultaat <- bereken_mijnbouw_retributie(
  dagen_boorgat    = 14, 
  hoge_druk        = TRUE, 
  installatie_type = "groot_zee", 
  leges_categorie  = "A"
)

print(resultaat)
