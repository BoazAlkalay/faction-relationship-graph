# trait_roller.R
#
# Rolls a random personality trait / bond / flaw / ideal for an NPC.
#
# NOTE ON TABLES: the tables below are original, written for this project —
# not transcribed from any published sourcebook. If you'd rather use tables
# from a book you own (e.g. a published background's trait tables), don't
# paste their text in here; instead drop your own CSV at data/custom_traits/
# with columns `category,text` and pass its path to load_custom_traits(),
# and credit the source in your README. That keeps this repo redistributable
# without carrying anyone else's copyrighted text.

default_traits <- list(
  personality_trait = c(
    "Speaks in half-finished sentences, as if everyone already agrees with them.",
    "Collects small, useless souvenirs from every room they enter.",
    "Never sits with their back to a door.",
    "Compliments people right before asking them for something.",
    "Repeats the last thing said to them, as a stalling tactic.",
    "Names their weapons, horses, and houseplants.",
    "Can't resist correcting minor inaccuracies, even at bad moments.",
    "Laughs at funerals and goes quiet at parties."
  ),
  bond = c(
    "Owes a debt to someone they haven't seen in years and dread repaying.",
    "Is raising a sibling's child as their own.",
    "Still writes letters to a mentor who died a decade ago.",
    "Would burn down half the district to protect one particular building.",
    "Is secretly funding a rival house's ruin, one bad harvest at a time.",
    "Keeps a promise made to a dying stranger above every other obligation.",
    "Believes their family's name will only mean something once they've fixed one old mistake.",
    "Is bound by an oath they no longer believe in, but can't bring themselves to break."
  ),
  flaw = c(
    "Cannot stand being laughed at, even in jest.",
    "Trusts the wrong people specifically because they remind them of family.",
    "Will lie about small things for no reason, even when the truth would serve them better.",
    "Is convinced they're the smartest person in every room.",
    "Spends money they don't have to look like they do.",
    "Holds grudges for decades over slights most people forgot within the week.",
    "Can't say no to a dare.",
    "Genuinely believes the rules don't apply to people of their standing."
  ),
  ideal = c(
    "Legacy. What I build should outlast the people who doubted me.",
    "Loyalty. My house comes before my own comfort, always.",
    "Ambition. Power unclaimed is power wasted.",
    "Order. A city runs on rules, even ones I privately resent.",
    "Freedom. No contract, oath, or bloodline gets to own me.",
    "Redemption. My family's name can still be worth something.",
    "Knowledge. Every secret uncovered is a debt someone else now owes me.",
    "Community. The lowest district's problems are the whole city's problems."
  )
)

#' Roll one random trait from a category ("personality_trait","bond","flaw","ideal").
#' Pass a custom table (character vector) to override the built-in defaults.
roll_trait <- function(category, tables = default_traits) {
  if (!category %in% names(tables)) {
    stop(paste("Unknown trait category:", category,
               "- expected one of:", paste(names(tables), collapse = ", ")))
  }
  sample(tables[[category]], size = 1)
}

#' Roll all four traits at once and return them as a named list, ready to
#' spread into add_NPC(...) / update_node(...) via do.call.
roll_all_traits <- function(tables = default_traits) {
  list(
    personality_trait = roll_trait("personality_trait", tables),
    bond = roll_trait("bond", tables),
    flaw = roll_trait("flaw", tables),
    ideal = roll_trait("ideal", tables)
  )
}

#' Load a custom trait table from a CSV with columns: category,text
#' Returns a list shaped like default_traits, suitable for roll_trait()/roll_all_traits().
#' Use this to swap in tables from a source you own; credit it in your README.
load_custom_traits <- function(csv_path) {
  df <- readr::read_csv(csv_path, show_col_types = FALSE)
  split(df$text, df$category)
}
