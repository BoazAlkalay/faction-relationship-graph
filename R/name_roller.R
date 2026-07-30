# name_roller.R
#
# Two ways to get names, both explained here so you can pick per-field:
#
# 1. roll_name() / roll_name_options() - procedural, offline, no dependency.
#    Builds names by combining syllable fragments (onset/nucleus/coda), the
#    same technique classic tools like the old rinkworks/Perlin "fantasy
#    name generator" use. Not a word list from anywhere, not a call to a
#    generative model - so there's no copyright/attribution question the
#    way there would be with a curated name list. Good for house names,
#    which can afford to sound invented.
#
# 2. roll_name_realistic() - calls the free randomuser.me API (an existing,
#    keyless, non-AI name generator people use for realistic test data) to
#    get a real first+last name pulled from a chosen country's naming
#    pool. Good for NPCs where you want something that reads as a plausible
#    human name rather than an obviously fantasy one. Needs internet and
#    the httr package (install.packages("httr")).
#
# Want to use a real curated fantasy name list instead (e.g. the CC0 "Name
# Generator with lists" pack on OpenGameArt)? Load it the same way as
# trait_roller.R's load_custom_traits() and credit it in the README - don't
# paste the list itself into this repo unless its license clearly allows it.

# --- Procedural generator ---------------------------------------------

# Given names: kept deliberately simple (plain consonant-vowel-consonant
# syllables, no exotic clusters) so they read more like plausible human
# names and less like a string of Scrabble tiles.
.given_onsets <- c("b","c","d","f","g","h","j","k","l","m","n","p","r","s","t","v","w",
                    "br","cr","dr","fr","gr","tr","st","sh","ch","th")
.given_nuclei <- c("a","e","i","o","u","ia","ie","ei","ee","oa")
.given_codas  <- c("", "", "", "n","r","l","s","t","d","m","th")

# House names: allowed to be a bit more elaborate/invented-sounding.
.house_onsets <- c("br","cr","dr","fr","gr","kr","pr","tr","bl","cl","fl","gl",
                    "pl","sl","sc","sk","sp","st","sw","th","sh","ch","wh","qu",
                    "b","c","d","f","g","h","j","k","l","m","n","p","r","s","t",
                    "v","w","y","z")
.house_nuclei <- c("a","e","i","o","u","ae","ai","ea","ee","ei","ia","io","oa",
                    "oo","ou","y")
.house_codas  <- c("", "", "b","d","f","g","k","l","m","n","p","r","s","t","v","x","z",
                    "nd","rn","rd","st","sk","th","sh","ch","ll","ss","nn","mm")
.house_suffixes <- c("holt","mere","vane","thorne","crest","wick","hall",
                      "wood","dale","haven","moor","reach","fen","spire")

.roll_syllable <- function(onsets, nuclei, codas) {
  paste0(sample(onsets, 1), sample(nuclei, 1), sample(codas, 1))
}

#' Roll a procedurally-generated name.
#' @param kind "given" (a personal/first name for an NPC) or "house"
#'   (a noble house name, occasionally with a place-name-style suffix)
#' @param syllables how many syllables to combine (default 2)
roll_name <- function(kind = c("given", "house"), syllables = 2) {
  kind <- match.arg(kind)

  if (kind == "given") {
    onsets <- .given_onsets; nuclei <- .given_nuclei; codas <- .given_codas
  } else {
    onsets <- .house_onsets; nuclei <- .house_nuclei; codas <- .house_codas
  }

  core <- paste(replicate(syllables, .roll_syllable(onsets, nuclei, codas)), collapse = "")
  core <- paste0(toupper(substr(core, 1, 1)), substr(core, 2, nchar(core)))

  if (kind == "house" && runif(1) < 0.5) {
    core <- paste0(core, sample(.house_suffixes, 1))
  }
  core
}

#' Roll several distinct name candidates at once, e.g. to show 3 options
#' in the UI and let the user pick one.
roll_name_options <- function(kind = c("given", "house"), n = 3, syllables = 2) {
  kind <- match.arg(kind)
  candidates <- unique(replicate(n * 3, roll_name(kind, syllables)))
  head(candidates, n)
}

# --- Realistic (external) generator -----------------------------------

# Country codes randomuser.me supports, kept short and grouped loosely by
# region so the dropdown reads as "flavor/inspiration" without pretending
# to be a serious ethnicity model.
realistic_name_nationalities <- c(
  "US" = "US", "GB" = "GB", "IE" = "IE", "FR" = "FR", "DE" = "DE",
  "ES" = "ES", "NO" = "NO", "DK" = "DK", "TR" = "TR", "IN" = "IN",
  "BR" = "BR", "MX" = "MX", "NL" = "NL", "UA" = "UA", "RS" = "RS"
)

#' Fetch one realistic human first+last name from randomuser.me.
#' @param nationality one of realistic_name_nationalities
roll_name_realistic <- function(nationality = "US") {
  if (!requireNamespace("httr", quietly = TRUE)) {
    stop("Realistic names need the httr package: install.packages('httr')")
  }
  url <- paste0("https://randomuser.me/api/?nat=", tolower(nationality), "&inc=name")
  resp <- httr::GET(url, httr::timeout(5))
  if (httr::status_code(resp) != 200) {
    stop("Name service unavailable right now — try the procedural generator instead.")
  }
  parsed <- httr::content(resp, as = "parsed", simplifyVector = TRUE)
  first <- tools::toTitleCase(parsed$results$name$first)
  last  <- tools::toTitleCase(parsed$results$name$last)
  paste(first, last)
}
