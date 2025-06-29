#' Initialize ScienceBase login and cache token in .Renviron
#'
#' @param sb_username chr; ScienceBase username. The default prompts the user to
#'   enter the username in the console.
#' @param renviron_file chr; path to .Renviron file
#' @param override_login lgl; should ScienceBase be re-initialized if already
#'   logged in?
#'
#' @return lgl; result of `sbtools::is_logged_in()`
#'
initialize_and_cache_sb <- function(sb_username = NULL,
                                    renviron_file = ".Renviron",
                                    override_login = FALSE) {
  # Give error if already logged in and `override_login = FALSE`
  tryCatch(
    sbtools:::token_refresh(),
    warning = function(x) {},
    error = function(x) FALSE
  )

  if (sbtools::is_logged_in()) {
    if (override_login) {
      # If logged in and overriding login: warn and re-initialize SB
      cli::cli_warn(c(
        "!" = "You are already logged into ScienceBase and re-initialization
        anyways.",
        "i" = "If you would not like to re-initialize, abort and re-run with
        {.arg override_login = FALSE}"
      ))
      sbtools::initialize_sciencebase_session(username = sb_username)
    }
  } else {
    # If not logged into SB, initialize SB
    sbtools::initialize_sciencebase_session(username = sb_username)
  }

  # Grab token and update it in .Renviron
  update_renviron(
    sb_username = sb_username,
    sb_token = jsonlite::toJSON(
      sbtools::current_session()[c("access_token", "refresh_token")]
    ),
    renviron_file
  )

  # Output if currently logged into SB
  if (sbtools::is_logged_in()) {
    return(TRUE)
  } else {
    cli::cli_abort(c(
      "!" = "You are not logged into ScienceBase after attempting it.",
      "i" = "Try running {.fun initialize_and_cache_sb} again."
    ))
  }
}

#' Create/update .Renviron with ScienceBase token
#'
#' @param sb_token chr; token used to initialize a ScienceBase session
#' @param renviron_file chr; path to .Renviron file
#'
#' @return chr; path to .Renviron file
#'
update_renviron <- function(sb_username, sb_token, renviron_file) {
  if (file.exists(renviron_file)) {
    # If there is an existing .Renviron file...
    # Read in existing .Renviron file and check if there is an "sb_token" value
    existing <- readLines(renviron_file)
    sb_token_idx <- which(startsWith(existing, "sb_token="))
    sb_username_idx <- which(startsWith(existing, "sb_username="))

    # If there is already a value for sb_token update it; if not, create one.
    if (length(sb_token_idx) > 0) {
      existing[sb_token_idx] <- paste0("sb_token=", sb_token)
      writeLines(existing, con = renviron_file)
    } else {
      write(paste0("sb_token=", sb_token), file = renviron_file, append = TRUE)
    }

    # If there is already a value for sb_username update it; if not, create one
    if (length(sb_username_idx) > 0) {
      existing[sb_username_idx] <- paste0("sb_username=", sb_username)
      writeLines(existing, con = renviron_file)
    } else {
      write(
        paste0("sb_username=", sb_username),
        file = renviron_file,
        append = TRUE
      )
    }
  } else {
    # If there isn't an .Renviron file, create one with an "sb_token" value
    write(
      paste0("sb_token=", sb_token, "\n", "sb_username=", sb_username),
      file = renviron_file
    )
  }

  return(renviron_file)
}
