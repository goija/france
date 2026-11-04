# ==============================================================================
# R-SCRIPT: 120° / 60° Hexagonaal Rooster & Symmetriepatronen (p3 & p6)
# ==============================================================================

# --- DEEL 1: Rotatiematrices voor 120° en 60° ---------------------------------

#' Maakt een 2D-rotatiematrix voor een gegeven hoek in graden
rot_matrix <- function(angle_deg) {
  rad <- angle_deg * pi / 180
  matrix(c(cos(rad), sin(rad), -sin(rad), cos(rad)), nrow = 2, ncol = 2)
}

# --- DEEL 2: Genereren van het Hexagonale Raster (60° / 120°) -----------------

#' Genereert de knooppunten van een 60°/120° hexagonaal rooster
generate_hex_grid <- function(nx = 5, ny = 5) {
  # Roostervectoren (a1 langs X-as, a2 onder 60°)
  a1 <- c(1, 0)
  a2 <- c(cos(pi/3), sin(pi/3)) # (0.5, sqrt(3)/2)
  
  grid_points <- expand.grid(i = 0:(nx - 1), j = 0:(ny - 1))
  
  coords <- t(apply(grid_points, 1, function(row) {
    row["i"] * a1 + row["j"] * a2
  }))
  
  colnames(coords) <- c("x", "y")
  return(as.data.frame(coords))
}

# --- DEEL 3: p3 Symmetriegroep Generator (120° Rotaties, 3-tallig) -------------

#' Genereert een p3-patroon op een hexagonaal rooster (120° rotaties)
generate_p3_pattern <- function(motif, nx = 3, ny = 3) {
  motif <- as.matrix(motif)
  
  # 3 rotatievarianten: 0°, 120°, 240°
  R0   <- rot_matrix(0)
  R120 <- rot_matrix(120)
  R240 <- rot_matrix(240)
  
  rot0   <- motif %*% t(R0)
  rot120 <- motif %*% t(R120)
  rot240 <- motif %*% t(R240)
  
  unit_cell <- rbind(rot0, rot120, rot240)
  
  # Transleerde cel over het hexagonale rooster
  a1 <- c(1, 0)
  a2 <- c(0.5, sqrt(3)/2)
  
  all_pts <- data.frame()
  for (i in 0:(nx - 1)) {
    for (j in 0:(ny - 1)) {
      offset <- i * a1 + j * a2
      translated <- sweep(unit_cell, 2, offset, "+")
      all_pts <- rbind(all_pts, data.frame(x = translated[,1], y = translated[,2]))
    }
  }
  return(all_pts)
}

# --- DEEL 4: p6 Symmetriegroep Generator (60° Rotaties, 6-tallig) --------------

#' Genereert een p6-patroon op een hexagonaal rooster (60° rotaties)
generate_p6_pattern <- function(motif, nx = 3, ny = 3) {
  motif <- as.matrix(motif)
  
  # 6 rotatievarianten: 0°, 60°, 120°, 180°, 240°, 300°
  rotations <- lapply(seq(0, 300, by = 60), function(angle) {
    motif %*% t(rot_matrix(angle))
  })
  
  unit_cell <- do.call(rbind, rotations)
  
  a1 <- c(1, 0)
  a2 <- c(0.5, sqrt(3)/2)
  
  all_pts <- data.frame()
  for (i in 0:(nx - 1)) {
    for (j in 0:(ny - 1)) {
      offset <- i * a1 + j * a2
      translated <- sweep(unit_cell, 2, offset, "+")
      all_pts <- rbind(all_pts, data.frame(x = translated[,1], y = translated[,2]))
    }
  }
  return(all_pts)
}

# --- DEEL 5: DEMONSTRATIE & VISUALISATIE --------------------------------------

# 1. Genereer het hexagonale netwerk
hex_grid <- generate_hex_grid(nx = 6, ny = 6)

# Plot 1: Het 60°/120° Hexagonale Knoop-Rooster
plot(hex_grid$x, hex_grid$y, col = "darkblue", pch = 19, asp = 1,
     main = "120° / 60° Hexagonaal Bravais-Rooster",
     xlab = "X", ylab = "Y")
grid()

# 2. Definieer een asymmetrisch basismotief
motif_demo <- matrix(c(0.1, 0.1,  0.25, 0.15,  0.2, 0.35), ncol = 2, byrow = TRUE)

# 3. Genereer p3 (120°) en p6 (60°) patronen
p3_pts <- generate_p3_pattern(motif = motif_demo, nx = 3, ny = 3)
p6_pts <- generate_p6_pattern(motif = motif_demo, nx = 3, ny = 3)

# Plot 2: p3 Patroon (120° Rotaties)
dev.new()
plot(p3_pts$x, p3_pts$y, col = "darkgreen", pch = 16, cex = 0.8, asp = 1,
     main = "Behangpatroongroep p3 (3-tallige 120° Rotaties)",
     xlab = "X", ylab = "Y")

# Plot 3: p6 Patroon (60° Rotaties)
dev.new()
plot(p6_pts$x, p6_pts$y, col = "firebrick", pch = 16, cex = 0.8, asp = 1,
     main = "Behangpatroongroep p6 (6-tallige 60° Rotaties)",
     xlab = "X", ylab = "Y")
