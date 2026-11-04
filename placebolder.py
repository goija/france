
# --------------------------------------------------------------- Procrustes

def similarity_procrustes(X, Y):
    """
    Least-squares similarity fit die X op Y legt:  Y ~ s * (X @ R) + t.

    Parameters
    ----------
    X, Y : (n, 2) arrays van correspondeerende 2D-punten.

    Returns
    -------
    dict met R, scale, translation, fitted, residuals, distances, rmse,
    sigma (singuliere waarden) en theta_deg (rotatiehoek).
    """
    X = np.asarray(X, dtype=float)
    Y = np.asarray(Y, dtype=float)
    if X.shape != Y.shape or X.ndim != 2 or X.shape[1] != 2:
        raise ValueError("X en Y moeten beide van vorm (n, 2) zijn.")

    mx, my = X.mean(axis=0), Y.mean(axis=0)
    A, B = X - mx, Y - my                       # centreren

    M = A.T @ B
    U, sv, Vt = np.linalg.svd(M)
    R = U @ Vt
    if np.linalg.det(R) < 0:                    # spiegeling vermijden
        U = U.copy()
        U[:, -1] *= -1
        R = U @ Vt

    denom = float((A ** 2).sum())
    s = float(sv.sum()) / denom if denom > 0 else 0.0
    t = my - s * (mx @ R)

    fitted = s * (X @ R) + t
    resid = Y - fitted
    dist = np.linalg.norm(resid, axis=1)
    rmse = float(np.sqrt(np.mean(dist ** 2)))

    return {
        "R": R,
        "scale": s,
        "translation": t,
        "fitted": fitted,
        "residuals": resid,
        "distances": dist,
        "rmse": rmse,
        "sigma": sv,
        "theta_deg": float(np.degrees(np.arctan2(R[1, 0], R[0, 0]))),
    }


def bootstrap_rmse(X, Y, n_boot=10000, seed=0):
    """Bootstrap 95%-CI voor de RMSE (puntparen met teruglegging)."""
    rng = np.random.default_rng(seed)
    n = len(X)
    out = np.empty(n_boot)
    for i in range(n_boot):
        idx = rng.integers(0, n, n)
        out[i] = similarity_procrustes(X[idx], Y[idx])["rmse"]
    lo, hi = np.percentile(out, [2.5, 97.5])
    return float(lo), float(hi), out


def permutation_test(X, Y, n_perm=20000, seed=0):
    """
    Test of de koppeling canvas<->hemel beter is dan een willekeurige koppeling.
    p = fractie van permutaties met een RMSE kleiner dan of gelijk aan de
    waargenomen RMSE. Kleine p => de correspondentie is betekenisvol.
    """
    rng = np.random.default_rng(seed)
    obs = similarity_procrustes(X, Y)["rmse"]
    n = len(X)
    null = np.empty(n_perm)
    for i in range(n_perm):
        perm = rng.permutation(n)
        null[i] = similarity_procrustes(X, Y[perm])["rmse"]
    p = float((np.sum(null <= obs) + 1) / (n_perm + 1))
    return obs, p, null


# ------------------------------------------------------------------------ IO

def load_csv(path):
    """Lees label,cx,cy,sx,sy regels. Regels met # of te weinig velden worden genegeerd."""
    labels, C, S = [], [], []
    with open(path, encoding="utf-8") as fh:
        fh.readline()                            # header overslaan
        for line in fh:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            parts = [p.strip() for p in line.split(",")]
            if len(parts) < 5:
                continue
            labels.append(parts[0])
            C.append([float(parts[1]), float(parts[2])])
            S.append([float(parts[3]), float(parts[4])])
    if len(labels) < 3:
        raise ValueError("Minimaal 3 geldige punten nodig.")
    return labels, np.array(C), np.array(S)


# ------------------------------------------- voorbeelddata (PLACEHOLDER!)

DEMO_LABELS = [f"Sn{i}" for i in range(1, 11)]

# Willekeurige, plausibele startwaarden -- GEEN echte metingen.
DEMO_CANVAS = np.array([
    [118, 342], [205, 300], [268, 262], [352, 236], [430, 210],
    [498, 250], [560, 292], [612, 330], [655, 372], [700, 410],
], dtype=float)

_DEMO_R = np.array([[0.970, -0.242], [0.242, 0.970]])
_DEMO_NOISE = np.array([
    [1.4, -0.8], [-0.9, 1.1], [0.6, 0.4], [-1.2, 0.7], [0.3, -1.0],
    [1.1, 0.9], [-0.5, -0.6], [0.8, 0.2], [-0.7, 1.3], [0.4, -0.5],
])
DEMO_SKY = DEMO_CANVAS @ _DEMO_R * 1.06 + np.array([12.0, -7.0]) + _DEMO_NOISE


# ---------------------------------------------------------------------- main

def main():
    # Filter Jupyter/Colab kernel-specifieke argumenten uit sys.argv
    args = [arg for arg in sys.argv if not arg.startswith('-f') and not arg.endswith('.json')]
    
    if len(args) > 1:
        labels, C, S = load_csv(args[1])
        print(f"Data geladen: {len(labels)} punten uit {args[1]}")
    else:
        labels, C, S = DEMO_LABELS, DEMO_CANVAS, DEMO_SKY
        print("Geen CSV opgegeven -- VOORBEELDDATA wordt gebruikt.")
        print("Deze waarden zijn verzonnen illustratie en GEEN metingen.\n")

    fit = similarity_procrustes(C, S)

    print("=== Procrustes fit ===")
    print(f"  schaal s       : {fit['scale']:.6f}")
    print(f"  rotatie theta  : {fit['theta_deg']:.4f} deg")
    print(f"  translatie t   : ({fit['translation'][0]:.3f}, "
          f"{fit['translation'][1]:.3f})")
    print(f"  sing. waarden  : {np.round(fit['sigma'], 6)}")
    print(f"  RMSE           : {fit['rmse']:.6f}")

    print("\n=== Residu per punt (grootste eerst) ===")
    for i in np.argsort(-fit["distances"]):
        print(f"  {labels[i]:>5s}   afwijking = {fit['distances'][i]:.4f}")

    lo, hi, _ = bootstrap_rmse(C, S)
    print(f"\nBootstrap 95%-CI voor RMSE: [{lo:.6f}, {hi:.6f}]")

    obs, p, _ = permutation_test(C, S)
    print(f"Permutatietest: waargenomen RMSE = {obs:.6f}, p = {p:.5f}")
    print("  (kleine p => de koppeling canvas<->hemel is beter dan toeval)")

    # ------------------------------------------------------------ residu-plot
    fig, axes = plt.subplots(1, 2, figsize=(12, 5))

    ax = axes[0]
    ax.scatter(C[:, 0], C[:, 1], c="tab:blue", label="canvas", zorder=3)
    ax.scatter(fit["fitted"][:, 0], fit["fitted"][:, 1], c="tab:orange",
               marker="x", label="canvas na fit", zorder=3)
    ax.scatter(S[:, 0], S[:, 1], facecolors="none", edgecolors="black",
               label="hemel", zorder=2)
    for i, lab in enumerate(labels):
        ax.annotate(lab, C[i], fontsize=7, xytext=(3, 3),
                    textcoords="offset points")
    ax.set_title("Punten en fit")
    ax.set_aspect("equal")
    ax.legend(fontsize=8)

    ax = axes[1]
    ax.quiver(fit["fitted"][:, 0], fit["fitted"][:, 1],
              fit["residuals"][:, 0], fit["residuals"][:, 1],
              angles="xy", scale_units="xy", scale=1, color="crimson")
    ax.scatter(fit["fitted"][:, 0], fit["fitted"][:, 1], s=12, c="black")
    ax.set_title(f"Residuvectoren (RMSE = {fit['rmse']:.4f})")
    ax.set_aspect("equal")

    fig.tight_layout()
    fig.savefig("procrustes_residuals.png", dpi=150)
    print("\nPlot opgeslagen als procrustes_residuals.png")
    plt.show()


if __name__ == "__main__":
    main()
