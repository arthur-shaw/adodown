#' Check whether a file has YAML frontmatter
#' 
#' @description 
#' Tries to find a pair of `---` in the file
#' First one must be on the first line
#' 
#' @param file Character. Path to the markdown file
check_has_yaml <- function(file) {

    file_raw <- readLines(
        file, 
        warn = FALSE # suppress warnings to avoid user confusion
    )
    yaml_boundaries <- which(file_raw == "---")
    has_yaml <- (
        # at least 2 boundary markers found
        length(yaml_boundaries) >= 2 & 
        # first marker is on the first line
        yaml_boundaries[1] == 1
    )

    # alternatively, consider yaml::yaml.load_file()
    # if no YAML found, issues error
    # if YAML found, returns it as a list

    return(has_yaml)

}

#' Add YAML to file
#' 
#' Pre-pend YAML to file contents.
#' YAML contains file name as title.
#' 
#' @inheritParams check_has_yaml
#' 
#' @importFrom fs path_file
add_yaml <- function(file) {

    file_raw <- readLines(
        file,
        warn = FALSE # suppress warning to avoid confusion
    )

    # construct YAML with file name as title
    file_name <- fs::path_file(file)
    yaml <- c(
        "---",
        paste0("title: ", file_name),
        "---"
    )

    # combine YAML and file lines
    file_w_yaml <- c(yaml, file_raw)

    return(file_w_yaml)

}

#' Check whether title is part of YAML
#' 
#' @inheritParams check_has_yaml
#' 
#' @importFrom yaml yaml.load_file
check_title_in_yaml <- function(file) {

    # read YAML as list
    yaml <- yaml::yaml.load_file(
        input = file, 
        readLines.warn = FALSE # suppress warnings to avoid confusion
    )

    # check whether title is top-level element of list
    has_title <- "title" %in% names(yaml)

    return(has_title)

}

#' Add title to YAML
#' 
#' @description 
#' In the absence of a title, the file name is taken.
#' 
#' @inheritParams check_has_yaml
add_title_to_yaml <- function(file) {

    # read in file as vector of lines
    file_raw <- readLines(file)

    # construct title key and value
    file_name <- fs::path_file(file)
    title <- paste0("title: ", file_name)

    # insert title as first entry in YAML
    yaml_boundaries <- which(file_raw == "---")
    yaml_start <- yaml_boundaries[1]
    file_raw <- base::append(x = file_raw, values = title, after = 1)

    return(file_raw)

}


#' Convert Markdown files to Quarto
#' 
#' @param path_in Character. Path to Markdown file
#' @param dir_out Character. Directory to save Quarto file
#' 
#' @importFrom fs path_file path_ext_remove path file_create
#' 
#' @export 
convert_md_to_qmd <- function(
    path_in,
    dir_out
) {

    # TODO:

    # Confirm that paths exists
    # - path_in
    # - dir_out

    # Check that YAML exists
    has_yaml <- check_has_yaml(path_in)
    if (!has_yaml) {
        file_raw <- add_yaml(path_in)
    }

    # Check that title attribute is present in YAML
    if (has_yaml) {
        has_title <- check_title_in_yaml(path_in)
        if (!has_title) {
            file_raw <- add_title_to_yaml(path_in)
        } else {
            file_raw <- readLines(path_in)
        }
    }

    # construct path for file to create
    file_name <- path_in |>
        fs::path_file() |>
        fs::path_ext_remove()
    path_out <- fs::path(dir_out, paste0(file_name, ".qmd"))

    # save with qmd file extension
    fs::file_create(path = path_out)
    writeLines(
        text = file_raw,
        con = path_out
    )

}

#' Convert package README to site index.qmd
#' 
#' @description 
#' Simply copy the README file in the package directory to 
#' the index file in the site directory.
#' 
#' @param pkg_dir Charcter. Directory of the source package.
#' @param site_dir Charcter. Directory of the target site.
#' 
#' @importFrom fs file_copy path
#' 
#' @export 
convert_readme_to_index <- function(pkg_dir, site_dir) {

    fs::file_copy(
        path = fs::path(pkg_dir, "README.md"),
        new_path = fs::path(site_dir, "index.qmd")
    )

}
