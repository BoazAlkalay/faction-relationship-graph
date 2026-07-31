# seed_data.R
#
# Demo world for the public app: the real Padgett/Ansell Florentine families
# network (16 leading families of Renaissance Florence, 20 documented
# marriage alliances among them), the same dataset used to teach social
# network analysis in countless courses - including the one this whole
# project was originally inspired by.
#
#   Padgett, J.F. & Ansell, C.K. (1993). "Robust Action and the Rise of the
#   Medici, 1400-1434." American Journal of Sociology, 98(6), 1259-1319.
#
# Layered on top: a handful of real, named historical individuals from five
# of these houses, with FACTUAL descriptions only (titles, dates, documented
# actions) - deliberately not run through the personality/bond/flaw/ideal
# roller, since inventing fictional character traits for real named people,
# however long dead, is a different thing than stating history. That roller
# is for NPCs you invent yourself.
#
# Real people included, and why: Cosimo, Lorenzo, and Giuliano de' Medici;
# Jacopo, Francesco, and Renato de' Pazzi; Rinaldo degli Albizzi; Palla
# Strozzi; Francesco Salviati. Together they cover two of Florence's most
# documented political conflicts - Cosimo de' Medici's rise over Rinaldo
# degli Albizzi and Palla Strozzi in the 1430s, and the 1478 Pazzi
# conspiracy, an assassination attempt on Lorenzo and Giuliano de' Medici
# during Easter Mass at the Florence Duomo (Giuliano was killed; Lorenzo
# survived and the conspirators were executed).

build_seed_graph <- function() {
  g <- new_empty_graph()

  # --- The 16 houses (Padgett & Ansell's dataset) -----------------------
  florentine_houses <- c(
    "Acciaiuoli", "Albizzi", "Barbadori", "Bischeri", "Castellani", "Ginori",
    "Guadagni", "Lamberteschi", "Medici", "Pazzi", "Peruzzi", "Pucci",
    "Ridolfi", "Salviati", "Strozzi", "Tornabuoni"
  )
  for (h in florentine_houses) {
    g <- g |> add_house(
      h, city = "Florence",
      desc = "One of the 16 leading families in Padgett & Ansell's historical network of Renaissance Florence.",
      visible_fields = "desc,city"
    )
  }

  # --- The 20 documented marriage alliances -------------------------------
  # (Pucci has no ties in the historical data - not a bug, that's accurate;
  # Pucci really was on the margins of this particular elite network.)
  marriage_ties <- list(
    c("Acciaiuoli", "Medici"), c("Castellani", "Peruzzi"), c("Castellani", "Strozzi"),
    c("Castellani", "Barbadori"), c("Medici", "Barbadori"), c("Medici", "Ridolfi"),
    c("Medici", "Tornabuoni"), c("Medici", "Albizzi"), c("Medici", "Salviati"),
    c("Salviati", "Pazzi"), c("Peruzzi", "Strozzi"), c("Peruzzi", "Bischeri"),
    c("Strozzi", "Ridolfi"), c("Strozzi", "Bischeri"), c("Ridolfi", "Tornabuoni"),
    c("Tornabuoni", "Guadagni"), c("Albizzi", "Ginori"), c("Albizzi", "Guadagni"),
    c("Bischeri", "Guadagni"), c("Guadagni", "Lamberteschi")
  )
  for (pair in marriage_ties) {
    g <- g |> add_house_relations(pair[1], pair[2], standing = "Marriage alliance", mutual = TRUE)
  }

  # --- Real historical individuals (facts only, no invented traits) ------
  g <- g |>
    add_NPC("Cosimo de' Medici", birth_year = "1389", death_year = "1464",
            desc = "\"il Vecchio.\" Unofficial ruler of Florence from 1434; financed Brunelleschi's dome for the Duomo.",
            visible_fields = "birth_year,death_year,desc") |>
    add_NPC("Lorenzo de' Medici", birth_year = "1449", death_year = "1492",
            desc = "\"il Magnifico.\" Grandson of Cosimo. Survived an assassination attempt during the 1478 Pazzi conspiracy.",
            visible_fields = "birth_year,death_year,desc") |>
    add_NPC("Giuliano de' Medici", birth_year = "1453", death_year = "1478",
            desc = "Lorenzo's brother and co-ruler. Killed during the Pazzi conspiracy's attack at Easter Mass in the Duomo.",
            visible_fields = "birth_year,death_year,desc") |>
    add_NPC("Jacopo de' Pazzi",
            desc = "Head of the Pazzi family at the time of the 1478 conspiracy against the Medici. Executed after it failed.",
            visible_fields = "desc") |>
    add_NPC("Francesco de' Pazzi",
            desc = "Nephew of Jacopo. One of the conspiracy's organizers and among those who attacked Giuliano de' Medici. Executed.",
            visible_fields = "desc") |>
    add_NPC("Renato de' Pazzi", birth_year = "1442", death_year = "1478",
            desc = "Nephew of Jacopo. Took no part in the conspiracy, but was seized and killed in the reprisals afterward regardless.",
            visible_fields = "birth_year,death_year,desc") |>
    add_NPC("Rinaldo degli Albizzi", birth_year = "1370", death_year = "1442",
            desc = "Primary political opponent of Cosimo de' Medici's rise; exiled after Cosimo returned to power in 1434, died in exile in Ancona.",
            visible_fields = "birth_year,death_year,desc") |>
    add_NPC("Palla Strozzi",
            desc = "One of Florence's wealthiest men and, alongside Rinaldo degli Albizzi, a primary opponent of Cosimo de' Medici's rise; exiled in 1434.",
            visible_fields = "desc") |>
    add_NPC("Francesco Salviati",
            desc = "Archbishop of Pisa. One of the organizers of the 1478 Pazzi conspiracy; executed by hanging from the Palazzo della Signoria afterward.",
            visible_fields = "desc")

  # --- Memberships ---------------------------------------------------------
  g <- g |>
    NPC_assign_house("Cosimo de' Medici", "Medici", position = "Patriarch") |>
    NPC_assign_house("Lorenzo de' Medici", "Medici", position = "Head of Household (from 1469)") |>
    NPC_assign_house("Giuliano de' Medici", "Medici", position = "Co-ruler with Lorenzo") |>
    NPC_assign_house("Jacopo de' Pazzi", "Pazzi", position = "Head of Household") |>
    NPC_assign_house("Francesco de' Pazzi", "Pazzi", position = "Nephew of Jacopo") |>
    NPC_assign_house("Renato de' Pazzi", "Pazzi", position = "Nephew of Jacopo") |>
    NPC_assign_house("Rinaldo degli Albizzi", "Albizzi", position = "Head of Household") |>
    NPC_assign_house("Palla Strozzi", "Strozzi", position = "Prominent member") |>
    NPC_assign_house("Francesco Salviati", "Salviati", position = "Archbishop of Pisa")

  # --- Family ties -----------------------------------------------------
  g <- g |>
    add_NPC_relationship("Cosimo de' Medici", "Lorenzo de' Medici", "grandfather/grandson", mutual = TRUE) |>
    add_NPC_relationship("Lorenzo de' Medici", "Giuliano de' Medici", "brothers", mutual = TRUE) |>
    add_NPC_relationship("Jacopo de' Pazzi", "Francesco de' Pazzi", "uncle/nephew", mutual = TRUE) |>
    add_NPC_relationship("Jacopo de' Pazzi", "Renato de' Pazzi", "uncle/nephew", mutual = TRUE) |>
    add_NPC_relationship("Francesco de' Pazzi", "Renato de' Pazzi", "cousins", mutual = TRUE)

  # --- Documented political conflict --------------------------------------
  g <- g |>
    add_NPC_relationship(
      "Cosimo de' Medici", "Rinaldo degli Albizzi", "political rivals", mutual = TRUE,
      additional_desc = "Primary opponents of each other's rise to power; Rinaldo was exiled after Cosimo returned to power in 1434."
    ) |>
    add_NPC_relationship(
      "Cosimo de' Medici", "Palla Strozzi", "political rivals", mutual = TRUE,
      additional_desc = "Palla Strozzi was exiled in 1434 alongside Rinaldo degli Albizzi as Cosimo consolidated power."
    ) |>
    add_NPC_relationship(
      "Lorenzo de' Medici", "Jacopo de' Pazzi", "target of the 1478 conspiracy", mutual = FALSE,
      additional_desc = "Lorenzo was wounded but survived the attack at the Duomo."
    ) |>
    add_NPC_relationship(
      "Giuliano de' Medici", "Francesco de' Pazzi", "killed by", mutual = FALSE,
      additional_desc = "Francesco de' Pazzi was among those who attacked and killed Giuliano during the 1478 conspiracy."
    ) |>
    add_NPC_relationship(
      "Giuliano de' Medici", "Francesco Salviati", "targeted by", mutual = FALSE,
      additional_desc = "Salviati helped organize the conspiracy that killed Giuliano, though the historical record has him among the plotters rather than the attackers who struck the blow."
    )

  g
}
