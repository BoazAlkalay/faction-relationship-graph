# name_roller.R
#
# A small procedural name generator — NOT a word list scraped from anywhere,
# NOT a call to a generative model. It builds names by combining syllable
# fragments (onset/nucleus/coda), the same technique classic tools like the
# old rinkworks/Perlin "fantasy name generator" use. Because it's just
# recombining short phonetic fragments algorithmically, there's no
# copyright/attribution question the way there would be with a curated
# name list.
#
# If you'd rather roll on a real curated list instead (e.g. the CC0 "Name
# Generator with lists" pack on OpenGameArt), load it the same way as
# trait_roller.R's load_custom_traits() and credit it in the README - don't
# paste the list itself into this repo unless its license clearly allows it.

.onsets <- c("br","cr","dr","fr","gr","kr","pr","tr","bl","cl","fl","gl",
             "pl","sl","sc","sk","sp","st","sw","th","sh","ch","wh","qu",
             "b","c","d","f","g","h","j","k","l","m","n","p","r","s","t",
             "v","w","y","z")

.nuclei <- c("a","e","i","o","u","ae","ai","ea","ee","ei","ia","io","oa",
             "oo","ou","y")

.codas <- c("", "", "b","d","f","g","k","l","m","n","p","r","s","t","v","x","z",
            "nd","rn","rd","st","sk","th","sh","ch","ll","ss","nn","mm")

.house_suffixes <- c("holt","mere","vane","thorne","crest","wick","hall",
                      "wood","dale","haven","moor","reach","fen","spire")

.roll_syllable <- function() {
  paste0(sample(.onsets, 1), sample(.nuclei, 1), sample(.codas, 1))
}

#' Roll a procedurally-generated name.
#' @param kind "given" (a personal/first name for an NPC) or "house"
#'   (a noble house name, occasionally with a place-name-style suffix)
#' @param syllables how many syllables to combine (default 2)
roll_name <- function(kind = c("given", "house"), syllables = 2) {
  kind <- match.arg(kind)
  core <- paste(replicate(syllables, .roll_syllable()), collapse = "")
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
