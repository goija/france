# ==============================================================================
# R-SCRIPT: Hexagonaal Rooster met Spiegelassen (p3m1, p31m, p6m)
# ==============================================================================

# --- Rotatie- en Spiegelmatrices ----------------------------------------------
rot_matrix <- function(deg) {
  rad <- deg * pi / 180
  matrix(c(cos(rad), sin(rad), -sin(rad), cos(rad)), 2, 2)
}

# Spiegelmatrix over de Y-as (X -> -X)
mirror_y <- matrix(c(-1, 0, 0, 1), 2, 2)

# --- Generator voor p3m1 (3-tallig + spiegeling door rotatiecentra) ------------
generate_p3m1_pattern <- function(motif, nx = 3, ny = 3) {
  motif <- as.matrix(motif)
  
  # De 3 rotaties (0°, 120°, 240°) + hun gespiegelde varianten
  rotations <- lapply(c(0, 120, 240), function(a) motif %*% t(rot_matrix(a)))
  mirrored  <- lapply(rotations, function(m) m %*% t(mirror_y))
  
  unit_cell <- do.call(rbind, c(rotations, mirrored))
  
  return(tile_hex_grid(unit_cell, nx, ny))
}

# --- Generator voor p31m (3-tallig + spiegeling 30° gedraaid) ------------------
generate_p31m_pattern <- function(motif, nx = 3, ny = 3) {
  motif <- as.matrix(motif)
  
  # Spiegeling onder 30° rotatie
  mirror_30 <- rot_matrix(30) %*% mirror_y %*% t(rot_matrix(30))
  
  rotations <- lapply(c(0, 120, 240), function(a) motif %*% t(rot_matrix(a)))
  mirrored  <- lapply(rotations, function(m) m %*% t(mirror_30))
  
  unit_cell <- do.call(rbind, c(rotations, mirrored))
  
  return(tile_hex_grid(unit_cell, nx, ny))
}

# --- Generator voor p6m (6-tallig + 6 spiegelassen: Grafeen Symmetrie) ---------
generate_p6m_pattern <- function(motif, nx = 3, ny = 3) {
  motif <- as.matrix(motif)
  
  # 6 rotaties (0°, 60°, 120°, 180°, 240°, 300°) + 6 gespiegelde varianten
  rotations <- lapply(seq(0, 300, by = 60), function(a) motif %*% t(rot_matrix(a)))
  mirrored  <- lapply(rotations, function(m) m %*% t(mirror_y))
  
  unit_cell <- do.call(rbind, c(rotations, mirrored))
  
  return(tile_hex_grid(unit_cell, nx, ny))
}

# --- Hulpfunctie voor het betegelen van het 60°/120° rooster -------------------
tile_hex_grid <- function(unit_cell, nx, ny) {
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

# --- DEMONSTRATIE & VISUALISATIE ----------------------------------------------

# Basismotief (driehoekje in de eenheidscel)
motif <- matrix(c(0.1, 0.05,  0.2, 0.1,  0.15, 0.25), ncol = 2, byrow = TRUE)

# Genereer p3m1, p31m en p6m patronen
p3m1_pts <- generate_p3m1_pattern(motif, nx = 3, ny = 3)
p31m_pts <- generate_p31m_pattern(motif, nx = 3, ny = 3)
p6m_pts  <- generate_p6m_pattern(motif, nx = 3, ny = 3)

# Visualisatie p6m (Maximale Hexagonale Symmetrie)
plot(p6m_pts$x, p6m_pts$y, col = "purple", pch = 16, cex = 0.7, asp = 1,
     main = "Behangpatroongroep p6m (6-tallige Rotatie + 6 Spiegelassen)",
     xlab = "X", ylab = "Y")
grid()
