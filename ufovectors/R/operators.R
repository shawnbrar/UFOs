#-----------------------------------------------------------------------------
# Custom operators implementation: perform operations by chunks
#-----------------------------------------------------------------------------

ufo_add           <- function(x, y) 
                       if(missing(y)) .ufo_unary (.base_add,           "ufo_neg_result", x) else
                                      .ufo_binary(.base_add,           "ufo_fit_result", x, y)
ufo_subtract      <- function(x, y)   
                       if(missing(y)) .ufo_unary (.base_subtract,      "ufo_neg_result", x) else
                                      .ufo_binary(.base_subtract,      "ufo_fit_result", x, y) 
ufo_multiply      <- function(x, y)   .ufo_binary(.base_multiply,      "ufo_fit_result", x, y)
ufo_divide        <- function(x, y)   .ufo_binary(.base_divide,        "ufo_div_result", x, y)
ufo_int_divide    <- function(x, y)   .ufo_binary(.base_int_divide,    "ufo_mod_result", x, y)
ufo_power         <- function(x, y)   .ufo_binary(.base_power,         "ufo_div_result", x, y)
ufo_modulo        <- function(x, y)   .ufo_binary(.base_modulo,        "ufo_mod_result", x, y)
ufo_less          <- function(x, y)   .ufo_binary(.base_less,          "ufo_rel_result", x, y)
ufo_less_equal    <- function(x, y)   .ufo_binary(.base_less_equal,    "ufo_rel_result", x, y)
ufo_greater       <- function(x, y)   .ufo_binary(.base_greater,       "ufo_rel_result", x, y)
ufo_greater_equal <- function(x, y)   .ufo_binary(.base_greater_equal, "ufo_rel_result", x, y)
ufo_equal         <- function(x, y)   .ufo_binary(.base_equal,         "ufo_log_result", x, y)
ufo_unequal       <- function(x, y)   .ufo_binary(.base_unequal,       "ufo_log_result", x, y)
ufo_or            <- function(x, y)   .ufo_binary(.base_or,            "ufo_log_result", x, y)
ufo_and           <- function(x, y)   .ufo_binary(.base_and,           "ufo_log_result", x, y)
ufo_not           <- function(x)      .ufo_unary (.base_not,           "ufo_neg_result", x)
#ufo_subset        <- function(x, i) 
#ufo_subset_assign <- function(x, i, v)

#-----------------------------------------------------------------------------
# Helper functions that do the actual chunking
#-----------------------------------------------------------------------------

.ufo_binary <- function(operation, result_inference, x, y, min_load_count=0, chunk_size=100000) {
  #cat("...\n")
  if (!is_ufo(x) && !is_ufo(y)) return(operation(x, y))

  result <- .Call(result_inference, x, y, as.integer(min_load_count))
  result_size <- length(result);    
  number_of_chunks <- ceiling(result_size / chunk_size)
            
  for (chunk in 0:(.base_subtract(number_of_chunks, 1))) {
    x_chunk <- .Call("ufo_get_chunk", x, chunk, chunk_size, result_size)
    y_chunk <- .Call("ufo_get_chunk", y, chunk, chunk_size, result_size)
    result[attr(x_chunk, 'start_index'):attr(x_chunk, 'end_index')] <- operation(x_chunk, y_chunk)
  }
  
  return(.add_class(result, "ufo", .check_add_class()))
}

.ufo_unary <- function(operation, result_inference, x, min_load_count=0, chunk_size=100000) {
  #cat("...\n")
  if (!is_ufo(x)) return(operation(x))
  
  result <- .Call(result_inference, x, as.integer(min_load_count))
  result_size <- length(result);    
  number_of_chunks <- ceiling(result_size / chunk_size)
  
  for (chunk in 0:(.base_subtract(number_of_chunks, 1))) {
    x_chunk <- .Call("ufo_get_chunk", x, chunk, chunk_size, result_size)
    result[attr(x_chunk, 'start_index'):attr(x_chunk, 'end_index')] <- operation(x_chunk)
  }
  
  return(.add_class(result, "ufo", .check_add_class()))
}

#-----------------------------------------------------------------------------
# Save base operators to disambiguate in case of overloading
#-----------------------------------------------------------------------------

.base_add           <- `+`
.base_subtract      <- `-`
.base_multiply      <- `*`
.base_divide        <- `/`
.base_power         <- `^`
.base_modulo        <- `%%`
.base_int_divide    <- `%/%`
.base_less          <- `<`
.base_less_equal    <- `<=`
.base_greater       <- `>`
.base_greater_equal <- `>=`
.base_equal         <- `==`
.base_unequal       <- `!=`
.base_not           <- `!`
.base_or            <- `|`
.base_and           <- `&`
.base_subset        <- `[`
.base_subset_assign <- `[<-`

#-----------------------------------------------------------------------------
# Set up S3 opertors or overload operators on load
#-----------------------------------------------------------------------------

# Poor workaround of the commented out code below
overload_operators <- function() {
  operator_overload_statements <- c(
    "`+`  <- ufovectors:::ufo_add",
    "`-`  <- ufovectors:::ufo_subtract",
    "`*`  <- ufovectors:::ufo_multiply",
    "`/`  <- ufovectors:::ufo_divide",
    "`^`  <- ufovectors:::ufo_power",
    "`%%` <- ufovectors:::ufo_modulo",
    "`%/%`<- ufovectors:::ufo_int_divide",
    "`<`  <- ufovectors:::ufo_less",
    "`<=` <- ufovectors:::ufo_less_equal",
    "`>`  <- ufovectors:::ufo_greater",
    "`>=` <- ufovectors:::ufo_greater_equal",
    "`==` <- ufovectors:::ufo_equal",
    "`!=` <- ufovectors:::ufo_unequal",
    "`!`  <- ufovectors:::ufo_not",
    "`|`  <- ufovectors:::ufo_or",
    "`&`  <- ufovectors:::ufo_and"
    #"`[` <- ufovectors:::ufo_subset",
    #"`[<-` <- ufovectors:::ufo_subset_assign"
  )
  
  eval(parse(text=operator_overload_statements), envir=globalenv())
}

unload_operators <- function() {
  operator_overload_statements <- c(
    "`+`   <- ufovectors:::.base_add",
    "`-`   <- ufovectors:::.base_subtract",
    "`*`   <- ufovectors:::.base_multiply",
    "`/`   <- ufovectors:::.base_divide",
    "`^`   <- ufovectors:::.base_power",
    "`%%`  <- ufovectors:::.base_modulo",
    "`%/%` <- ufovectors:::.base_int_divide",
    "`<`   <- ufovectors:::.base_less",
    "`<=`  <- ufovectors:::.base_less_equal",
    "`>`   <- ufovectors:::.base_greater",
    "`>=`  <- ufovectors:::.base_greater_equal",
    "`==`  <- ufovectors:::.base_equal",
    "`!=`  <- ufovectors:::.base_unequal",
    "`!`   <- ufovectors:::.base_not",
    "`|`   <- ufovectors:::.base_or",
    "`&`   <- ufovectors:::.base_and"
    #"`[` <- ufovectors:::.base_subset",
    #"`[<-`	<- ufovectors:::.base_subset_assign"
  )
  
  eval(parse(text=operator_overload_statements), envir=globalenv())
}

# options(ufovectors.add_class = TRUE)
# options(ufovectors.overload_operators = TRUE)
.onLoad <- function(...) {
  if (isTRUE(getOption("ufovectors.add_class"))) {
    registerS3method("+",   "ufo", ufo_add)
    registerS3method("-",   "ufo", ufo_subtract)
    registerS3method("*",   "ufo", ufo_multiply)
    registerS3method("/",   "ufo", ufo_divide)
    registerS3method("^",   "ufo", ufo_power)
    registerS3method("%%",  "ufo", ufo_modulo)
    registerS3method("%/%", "ufo", ufo_int_divide)
    registerS3method("<",   "ufo", ufo_less)
    registerS3method("<=",  "ufo", ufo_less_equal)
    registerS3method(">",   "ufo", ufo_greater)
    registerS3method(">=",  "ufo", ufo_greater_equal)
    registerS3method("==",  "ufo", ufo_equal)
    registerS3method("!=",  "ufo", ufo_unequal)
    registerS3method("!",   "ufo", ufo_not)
    registerS3method("|",   "ufo", ufo_or)
    registerS3method("&",   "ufo", ufo_and)
    #registerS3method("[",   "ufo", ufo_subset)
    #registerS3method("[<-", "ufo", ufo_subset_assign)	
  }
  
  if (isTRUE(getOption("ufovectors.overload_operators"))) {
    ufovectors:::overload_operators()
  }
}


