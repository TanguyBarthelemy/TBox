
#' @title The path to the font Fira Code
#'
#' @description
#' This function returns the path to the font Fira Code installed with
#' the package TBox.
#'
#' @returns a character vector of length 1 representing the path
#'
#' @details
#' This function helps the other functions to find the path to the font Fira
#' Code to render documents and use this font by default for code chunks.
#'
#' @export
#'
#' @examples
#' get_fira_path()
#'
get_fira_path <- function() {
    fira_path <- system.file("extdata", "FiraCode", "FiraCode-Regular.ttf",
                             package = "TBox")
    fira_path <- normalizePath(fira_path, winslash = "/", mustWork = FALSE)
    return(fira_path)
}

#' @title The path to the word template
#'
#' @description
#' This function returns the path to the word template installed with
#' the package TBox.
#'
#' @returns a character vector of length 1 representing the path
#'
#' @details
#' This function helps the other functions to find the template of the word
#' document used to render in \code{.docx} output.
#'
#' @export
#'
#' @examples
#' get_word_template_path()
#'
get_word_template_path <- function() {
    word_template_path <- system.file("extdata", "template.docx",
                                      package = "TBox")
    word_template_path <- normalizePath(word_template_path,
                                        winslash = "/",
                                        mustWork = FALSE)
    return(word_template_path)
}

#' @title Generate R chunk header
#' @description
#' Function to generate R chunk header for rmarkdown rendering in different
#' output
#'
#' @param ... The different options for R code chunks.
#'
#' @returns a string of length 1
#'
#' @details
#' To get the list of all accepted options, you can call
#' \code{names(knitr::opts_chunk$get())} and to get the default values you can
#' call \code{knitr::opts_chunk$get()}.
#'
#' More information in the function #' \code{\link[knitr]{opts_chunk}} or
#' directly \url{https://yihui.org/knitr/options/#chunk-options} to see all
#' available options and their descriptions.
#'
#' @export
#'
#' @examples
#'
#' generate_chunk_header()
#' generate_chunk_header(eval = TRUE, echo = TRUE)
#' generate_chunk_header(results = "asis")
#' generate_chunk_header(fig.width = "4px", fig.height = "3px")
#'
generate_chunk_header <- function(...) {
    yaml_begining <- "```{r"
    yaml_ending <- "}"

    additional_args <- vapply(
        X = list(...),
        FUN = deparse,
        FUN.VALUE = character(1L)
    )

    # Check additionnal argument as knitr options
    checkmate::assert_character(
        x = names(additional_args),
        unique = TRUE, null.ok = TRUE
    )
    vapply(
        X = names(additional_args),
        FUN =  checkmate::assert_choice,
        choices = names(knitr::opts_chunk[["get"]]()),
        FUN.VALUE = character(1L)
    )

    yaml_inter <- ifelse(
        test = length(additional_args) > 0L,
        yes = paste(",", names(additional_args),
                    "=", additional_args, collapse = ""),
        no = ""
    )

    return(paste0(
        yaml_begining,
        yaml_inter,
        yaml_ending
    ))
}

#' @title Generate Rmd file
#' @description
#' This function creates the Rmd file which will be rendered in a specific
#' format.
#'
#' @param content a string. The body of the Rmd file (for example code or text)
#' @param output_format a string representing the output format. The values
#' \code{"pdf"}, \code{"html"} or \code{"word"} and their knitr equivalent
#' \code{"pdf_document"}, \code{"html_document"} or \code{"word_document"} are
#' accepted.
#' @param font_size a numeric. The font size, only available in pdf format.
#' @param code a boolean. Should the \code{content} string have to be inserted
#' in R chunk or is it just text? Default is TRUE (so the \code{content} will be
#' inserted in R chunk).
#' @param font_path a string. The path to the font used to render code chunks.
#' It should link to a \code{.ttf} file. Only available in pdf format.
#' @param word_template_path a string. The path to the word template file used
#' when rendering with word. By default, the template used is the one included
#' in the package. Only used with word output.
#' @param \dots other arguments passed to R chunk (for example
#' \code{eval = TRUE}, \code{echo = FALSE}...)
#' @returns a string of length 1.
#'
#' @details
#' More information about the argument \dots in the  documentation of the
#' function \code{\link[TBox]{render_code}}.
#'
#' @export
#'
#' @examples
#'
#' generate_rmd_file(content = "Bonjour tout le monde",
#'                   code = FALSE,
#'                   output_format = "word")
#' generate_rmd_file(content = "print(AirPassengers)",
#'                   code = TRUE,
#'                   output_format = "pdf",
#'                   eval = TRUE,
#'                   echo = FALSE)
#' generate_rmd_file(content = "plot(AirPassengers)",
#'                   code = TRUE,
#'                   output_format = "html_document",
#'                   eval = FALSE,
#'                   echo = TRUE)
#'
generate_rmd_file <- function(
        content,
        output_format = c("word", "pdf", "html",
                          "word_document", "pdf_document", "html_document"),
        font_size = 12.,
        code = TRUE,
        font_path = get_fira_path(),
        word_template_path = get_word_template_path(),
        ...) {

    output_format <- match.arg(output_format)
    output_format <- gsub(x = output_format,
                          pattern = "_document$",
                          replacement = "",
                          perl = TRUE, fixed = FALSE)

    # Check content
    checkmate::assert_character(content)
    # Check font_size
    checkmate::assert_count(font_size)
    # Check code
    checkmate::assert_logical(code)

    has_xelatex <- nchar(Sys.which("xelatex")) > 0L

    rmd_header <- paste0(
        "---\ntitle: \"Format code\"\noutput:\n  ",
        output_format,
        "_document:\n    highlight: arrow\n",
        switch(
            output_format,
            word = paste0("    reference_docx: \"", word_template_path, "\"\n"),
            html = "monofont: \"Fira Code\"\n",
            pdf = paste0("    fig_crop: true\n",
                         if (has_xelatex) "    latex_engine: xelatex\n")
        ),
        "code-block-bg: true\n",
        "code-block-border-left: \"#31BAE9\"\n",
        "---\n"
    )
    rmd_font_size <- ifelse(
        test = (output_format == "pdf"),
        yes = paste0("\n\\fontsize{", font_size, "}{", font_size, "}\n"),
        no = ""
    )

    font_dir <- dirname(font_path)
    font_file <- basename(font_path)

    rmd_monofont <- ifelse(
        test = (output_format == "pdf" && has_xelatex),
        yes = paste0(
            "\\setmonofont[ExternalLocation=",
            font_dir, "/]{", font_file, "}\n"
        ),
        no = ""
    )

    rmd_body <- paste0(
        c(
            "\n## Running Code\n",
            ifelse(
                test = code,
                yes = generate_chunk_header(...),
                no = ""
            ),
            content,
            ifelse(
                test = code,
                yes = "```",
                no = ""
            )
        ),
        collapse = "\n"
    )

    return(paste0(rmd_header, rmd_font_size, rmd_monofont, rmd_body, "\n"))
}

#' @title Generate a file with formatted code
#' @description
#' Format a piece of code to copy it into an email, a pdf, a document, etc.
#'
#' @param output_format a string representing the output format. The values
#' "pdf", "html" or "word" and their knitr equivalent "pdf_document",
#' "html_document" or "word_document" are accepted.
#' @param browser a string. The path to the browser which will open the
#' generated file format
#' @param font_size a numeric. The font size in pdf format.
#' @param code a boolean. Should the copied content have to be inserted in R
#' chunk or is it just text? Default is TRUE (so the copied content will be
#' inserted in R chunk).
#' @param open a boolean. Default is TRUE meaning that the document will open
#' automatically after being generated.
#' @param font_path a string. The path to the font used to render code chunks.
#' It should link to a \code{.ttf} file. Only available in pdf format.
#' @param word_template_path a string. The path to the word template file used
#' when rendering with word. By default, the template used is the one included
#' in the package. Only used with word output.
#' @param ... other arguments passed to R chunk (for example eval = TRUE,
#' echo = FALSE...)
#'
#' @details
#' This function allows the user to generate formatted code (for email,
#' document, copy, message, etc.) on the fly.
#'
#' It accepts mainly word, pdf and html formats, but any format accepted by
#' rmarkdown on the computer.
#'
#' To use this function, simply copy a piece of code and run
#' \code{render_code()} with the arguments that interest us.
#' If you want content that is not R code, use the \code{code} argument to
#' \code{FALSE}.
#' In pdf format, you can change the font size using the \code{font_size}
#' argument.
#' Also, you can change the browser that opens the file by default with the
#' \code{browser} argument.
#'
#' With the argument \dots, you can specify knitr arguments to be included in
#' the chunk. For example, you can add \code{eval = TRUE} (if you want the R
#' code to be evaluated (and the result displayed)), \code{echo = FALSE} (if
#' you don't want to display the code)...
#'
#' More information in the function \code{\link[knitr]{opts_chunk}} or directly
#' \url{https://yihui.org/knitr/options/#chunk-options} to see all available
#' options and their descriptions.
#'
#' If the \code{open} argument is set to \code{FALSE} then the \code{browser}
#' argument will be ignored.
#'
#' @returns This function returns invisibly (with \code{invisible()}) a vector
#' of length two with two element:
#' - the path of the created rmarkdown (template) document (\code{.Rmd})
#' - the path of the created output (in the format \code{.pdf}, \code{.docx} or
#' \code{.html}).
#'
#' @export
#' @examples
#' # Copy a snippet of code
#' if (clipr::clipr_available()) {
#'     clipr::write_clip("plot(AirPassengers)", allow_non_interactive = TRUE)
#' }
#'
#' render_code(
#'     output_format = "word",
#'     echo = TRUE
#' )
#'
#' render_code(
#'     output_format = "html",
#'     eval = FALSE
#' )
#'
#' \donttest{
#' render_code(
#'     output = "pdf",
#'     eval = TRUE,
#'     font_size = 16
#' )
#' }
render_code <- function(
        output_format = c("word", "pdf", "html",
                          "word_document", "pdf_document", "html_document"),
        browser = getOption("browser"),
        font_size = 12.,
        code = TRUE,
        open = TRUE,
        font_path = get_fira_path(),
        word_template_path = get_word_template_path(),
        ...) {

    if (!clipr::clipr_available()) {
        return(clipr::dr_clipr())
    }

    font_path <- normalizePath(font_path, winslash = "/", mustWork = TRUE)
    word_template_path <- normalizePath(word_template_path, winslash = "/",
                                        mustWork = TRUE)

    content <- paste(clipr::read_clip(allow_non_interactive = TRUE),
                     collapse = "\n")

    output_format <- match.arg(output_format)
    output_format <- gsub(x = output_format,
                          pattern = "_document$",
                          replacement = "",
                          perl = TRUE, fixed = FALSE)

    rmd_content <- generate_rmd_file(
        content = content,
        output_format = output_format,
        font_size = font_size,
        code = code,
        font_path = font_path,
        word_template_path,
        ...
    )

    ext <- switch(
        output_format,
        word = ".docx",
        html = ".html",
        pdf = ".pdf"
    )

    out_dir <- tempfile(pattern = "render_code", fileext = "")
    dir.create(out_dir, showWarnings = TRUE, recursive = TRUE)

    rmd_file <- file.path(out_dir, "template.Rmd")
    out_file <- file.path(out_dir, paste0("output", ext))

    write(rmd_content, file = rmd_file)
    rmarkdown::render(
        input = rmd_file,
        output_file = paste0("output", ext),
        output_dir = out_dir
    )

    if (interactive() && open) {
        utils::browseURL(
            url = normalizePath(out_file, mustWork = TRUE),
            browser = browser # nolint undesirable_function_linter
        )
    }

    return(invisible(normalizePath(out_dir, mustWork = TRUE)))
}
