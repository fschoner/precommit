#' Locate the pre-commit executable
#'
#' [path_precommit_exec()] simply reads the R option `precommit.executable`, ]
#' [path_derive_precommit_exec()] uses a heuristic to derive it from scratch.
#'
#' @param check_if_exists Whether or not to make sure the returned path also
#'  exists.
#'  @return
#'  A character vector of length one with the path to the pre-commit executable.
#' @export
path_precommit_exec <- function(check_if_exists = TRUE) {
  final <- getOption("precommit.executable") %>%
    as.character()
  if (!check_if_exists) {
    return(final)
  }
  if (!fs::file_exists(final)) {
    rlang::abort(paste0(
      "pre-commit executable does not exist at ",
      final,
      ". Please locate your pre-commit ",
      "executable and set the R option `precommit.executable` to this ",
      "path so it can be used to perform various pre-commit commands from R."
    ))
  }
  final
}

#' @rdname path_precommit_exec
#' @export
path_pre_commit_exec <- function(check_if_exists = TRUE) {
  .Deprecated("path_precommit_exec", old = "path_pre_commit_exec")
  path_precommit_exec(check_if_exists = check_if_exists)
}

#' Derive the path to the pre-commit executable
#'
#' All these functions return "" if search was not successful.
#' @section Heuristic:
#' - First check if there is an executable on the `$PATH` using
#'   [path_derive_precommit_exec_path()]
#' - If not, check if we can find one in a conda environment with
#'   [path_derive_precommit_exec_conda()].
#' - Search os dependent for other possible locations for common installation
#'   methods.
#' @keywords internal
path_derive_precommit_exec <- function() {
  path <- path_derive_precommit_exec_path()
  if (path == "") {
    path <- path_derive_precommit_exec_conda()
  }
  if (path == "") {
    os <- tolower(Sys.info()[["sysname"]])
    if (os == "darwin") {
      path <- path_derive_precommit_exec_macOS()
    } else if (os == "windows") {
      path <- path_derive_precommit_exec_win()
    } else if (os == "linux") {
      path <- path_derive_precommit_exec_linux()
    }
  }
  path
}

#' Find an executable
#'
#' Evaluates if the pre-commit executable exists in one or more candidate
#' locations. If so, return one, else return the empty string
#' @param candidate A directory to check for the pre-commit executable. The
#'   directory may also not exist.
#' @keywords internal
path_derive_precommit_exec_impl <- function(candidate) {
  assumed <- fs::path(candidate, precommit_executable_file())
  existant <- assumed[fs::file_exists(assumed)]
  if (length(existant) > 0) {
    existant[1]
  } else {
    ""
  }
}

path_derive_precommit_exec_linux <- function() {
  path_derive_precommit_exec_impl(
    "~/.local/bin" # pip: https://unix.stackexchange.com/questions/240037/why-did-pip-install-a-package-into-local-bin
  )
}

path_derive_precommit_exec_win <- function() {
  path_derive_precommit_exec_impl(fs::path_home("AppData/Roaming/Python/Scripts"))
}

path_derive_precommit_exec_macOS <- function() {
  c(
    fs::path(fs::dir_ls(path_if_exist("~/Library/Python/")), "bin"), # pip
    "/usr/local/bin" # homebrew
  ) %>%
    path_derive_precommit_exec_impl()
}


#' Derive the pre-commit executable from the path
#'
#' Tries to derive the `pre-commit` executable from the `$PATH`.
#' Returns `""` if no executable is found.
#' @keywords internal
path_derive_precommit_exec_path <- function() {
  unname(Sys.which(precommit_executable_file())[1])
}

#' Derive the path to the conda pre-commit executable
#'
#' Only checks the conda env `r-precommit`.
#' If we can't find the executable, the empty string is returned.
#' @keywords internal
path_derive_precommit_exec_conda <- function() {
  path <- path_derive_precommit_exec_conda_impl("r-precommit")
  if (path == "") {
    path <- path_derive_precommit_exec_conda_impl("r-reticulate")
    if (path != "") {
      rlang::warn(paste0(
        "The R packae {precommit} now requires the executable to live ",
        "in the conda environment r-precommit, not r-reticulate anymore ",
        "where it is currently installed. ",
        "Please run `precommit::install_precommit(force = TRUE)` to re-install with conda ",
        "or choose another installation method as described in the README. To save ",
        "space on disk, you probably want to delete the pre-commit executable at ",
        path, " and the package sources in the ",
        "conda environment r-reticulate with ",
        "`reticulate::conda_remove('r-reticulate', 'precommit')`."
      ))
    }
  }
  path
}

path_derive_precommit_exec_conda_impl <- function(conda_env) {
  tryCatch(
    {
      ls <- reticulate::conda_list()

      path_reticulate <- fs::path_dir(ls[ls$name == conda_env, "python"][1])
      derived <- fs::path(
        path_reticulate,
        ifelse(is_windows(), "Scripts", ""),
        precommit_executable_file()
      )
      unname(ifelse(fs::file_exists(derived), derived, ""))
    },
    error = function(e) ""
  )
}

#' The name of the executable file
#'
#' This is platform dependent.
#' @keywords internal
precommit_executable_file <- function() {
  ifelse(is_windows(), "pre-commit.exe", "pre-commit")
}
