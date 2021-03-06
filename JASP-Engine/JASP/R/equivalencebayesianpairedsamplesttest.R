#
# Copyright (C) 2013-2018 University of Amsterdam
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

EquivalenceBayesianPairedSamplesTTest <- function(jaspResults, dataset, options) {
  
  #browser()
  ready <- (length(options$pairs) > 0)
  
  # does this work? 
  for (pair in options$pairs) {
    if (pair[[1L]] == "" || pair[[2L]] == "")
      ready <- FALSE
  }
  
  # Read dataset and error checking
  if (ready) {
    dataset <- .ttestBayesianReadData(dataset, options)
    errors  <- .ttestBayesianGetErrorsPerVariable(dataset, options, "paired")
  }
  
  # Compute the results
  equivalenceBayesianPairedTTestResults <- .equivalenceBayesianPairedTTestComputeResults(jaspResults, dataset, options, ready, errors)
  
  # Output tables and plots
  .equivalenceBayesianPairedTTestTableMain(jaspResults, dataset, options, equivalenceBayesianPairedTTestResults, ready)
  
  if(options$descriptives)
    .equivalenceBayesianPairedTTestTableDescriptives(jaspResults, dataset, options, equivalenceBayesianPairedTTestResults, ready)
  
  if (options$priorandposterior)
    .equivalencePriorandPosterior(jaspResults, dataset, options, equivalenceBayesianPairedTTestResults, ready, paired = TRUE)
  
  if (options$plotSequentialAnalysis)
     .equivalencePlotSequentialAnalysis(jaspResults, dataset, options, equivalenceBayesianPairedTTestResults, ready, paired = TRUE)
  
  return()
}

.equivalenceBayesianPairedTTestComputeResults <- function(jaspResults, dataset, options, ready, errors) {
  
  if (!ready)
    return(list())
  
  if (!is.null(jaspResults[["stateEquivalenceBayesianPairedTTestResults"]]))
    return(jaspResults[["stateEquivalenceBayesianPairedTTestResults"]]$object)
  
  results <- list()

  for (pair in options$pairs) {
    
    namePair <- paste(pair[[1L]], " - ",  pair[[2L]], sep = "")
    
    results[[namePair]] <- list()
    
    if (!isFALSE(errors[[namePair]])) {
      errorMessage <- errors[[namePair]]$message
      results[[namePair]][["status"]] <- "error"
      results[[namePair]][["errorFootnotes"]] <- errorMessage
    } else {
      subDataSet <- dataset[, .v(c(pair[[1L]], pair[[2L]]))]
      subDataSet <- subDataSet[complete.cases(subDataSet), ]
      
      x <- subDataSet[[1L]]
      y <- subDataSet[[2L]]
      
      r <- try(.generalEquivalenceTtestBF(x       = x, 
                                          y       = y, 
                                          paired  = TRUE, 
                                          options = options))
      
      if (isTryError(r)) {
        
        errorMessage <- .extractErrorMessage(r)
        results[[namePair]][["status"]]         <- "error"
        results[[namePair]][["errorFootnotes"]] <- errorMessage
        
      } else if (r[["bfEquivalence"]] < 0 || r[["bfNonequivalence"]] < 0) {
        
        results[[variable]][["status"]] <- "error"
        results[[variable]][["errorFootnotes"]] <- "Not able to calculate Bayes factor while the integration was too unstable"
        
      } else {
        
        results[[namePair]][["bfEquivalence"]]    <- r[["bfEquivalence"]]
        results[[namePair]][["bfNonequivalence"]] <- r[["bfNonequivalence"]]
        results[[namePair]][["errorPrior"]]       <- r[["errorPrior"]]
        results[[namePair]][["errorPosterior"]]   <- r[["errorPosterior"]]
        results[[namePair]][["tValue"]]           <- r[["tValue"]]
        results[[namePair]][["n1"]]               <- r[["n1"]]
        results[[namePair]][["n2"]]               <- r[["n2"]]
      }
    }
  }
  
  # Save results to state
  jaspResults[["stateEquivalenceBayesianPairedTTestResults"]] <- createJaspState(results)
  jaspResults[["stateEquivalenceBayesianPairedTTestResults"]]$dependOn(c("pairs", "lowerbound", "upperbound", "missingValues",
                                                                         "priorWidth", "effectSizeStandardized","informative", "informativeCauchyLocation", "informativeCauchyScale",
                                                                         "informativeNormalMean", "informativeNormalStd", "informativeTLocation",
                                                                         "informativeTScale", "informativeTDf")) 
  return(results)
}

.equivalenceBayesianPairedTTestTableMain <- function(jaspResults, dataset, options, equivalenceBayesianPairedTTestResults, ready) {
  
  if(!is.null(jaspResults[["equivalenceBayesianPairedTTestTable"]])) return()
  
  # Create table
  equivalenceBayesianPairedTTestTable <- createJaspTable(title = gettext("Equivalence Bayesian Paired Samples T-Test"))
  equivalenceBayesianPairedTTestTable$dependOn(c("pairs", "lowerbound", "upperbound", "priorWidth", "effectSizeStandardized","informative", "informativeCauchyLocation", "informativeCauchyScale",
                                                 "informativeNormalMean", "informativeNormalStd", "informativeTLocation",
                                                 "informativeTScale", "informativeTDf"))
  equivalenceBayesianPairedTTestTable$showSpecifiedColumnsOnly <- TRUE
  
  # Add Columns to table
  equivalenceBayesianPairedTTestTable$addColumnInfo(name = "variable1",   title = " ",                         type = "string")
  equivalenceBayesianPairedTTestTable$addColumnInfo(name = "separator",   title = " ",                         type = "separator")
  equivalenceBayesianPairedTTestTable$addColumnInfo(name = "variable2",   title = " ",                         type = "string")
  equivalenceBayesianPairedTTestTable$addColumnInfo(name = "statistic",   title = gettext("Model Comparison"), type = "string")
  equivalenceBayesianPairedTTestTable$addColumnInfo(name = "bf",          title = gettext("BF"),               type = "number")
  equivalenceBayesianPairedTTestTable$addColumnInfo(name = "error",       title = gettext("error %"),            type = "number")
  
  if (ready)
    equivalenceBayesianPairedTTestTable$setExpectedSize(length(options$pairs))

  message <- gettextf("I ranges from %1$s to %2$s", options$lowerbound, options$upperbound)
  equivalenceBayesianPairedTTestTable$addFootnote(message)
  
  jaspResults[["equivalenceBayesianPairedTTestTable"]] <- equivalenceBayesianPairedTTestTable
  
  if (!ready)
    return()
  
  .equivelanceBayesianPairedTTestFillTableMain(equivalenceBayesianPairedTTestTable, dataset, options, equivalenceBayesianPairedTTestResults)
  
  return()
  
}

.equivelanceBayesianPairedTTestFillTableMain <- function(equivalenceBayesianPairedTTestTable, dataset, options, equivalenceBayesianPairedTTestResults) {
  
  for (pair in options$pairs) {
    
    namePair <- paste(pair[[1L]], " - ",  pair[[2L]], sep = "")
    results <- equivalenceBayesianPairedTTestResults[[namePair]]
    
    if (!is.null(results$status)) {
      equivalenceBayesianPairedTTestTable$addFootnote(message = results$errorFootnotes, rowNames = namePair, colNames = "statistic")
      equivalenceBayesianPairedTTestTable$addRows(list(variable1 = pair[[1L]], separator = "-", variable2 = pair[[2L]], statistic = NaN), rowNames = namePair)
    } else {
      equivalenceBayesianPairedTTestTable$addRows(list(variable1     = pair[[1L]], 
                                                       separator     = "-",
                                                       variable2     = pair[[2L]],
                                                       statistic     = "\U003B4 \U02208 I vs. H1",
                                                       bf            = results$bfEquivalence,
                                                       error         = (results$errorPrior + results$errorPosterior) / results$bfEquivalence))
      
      equivalenceBayesianPairedTTestTable$addRows(list(variable1     = " ", 
                                                       separator     = " ",
                                                       variable2     = " ",
                                                       statistic     = "\U003B4 \U02209 I vs. H1",
                                                       bf            = results$bfNonequivalence,
                                                       error         = (results$errorPrior + results$errorPosterior) / results$bfNonequivalence))
      
      equivalenceBayesianPairedTTestTable$addRows(list(variable1     = " ", 
                                                       separator     = " ",
                                                       variable2     = " ",
                                                       statistic     = "\U003B4 \U02208 I vs. \U003B4 \U02209 I",
                                                       bf            = results$bfEquivalence / results$bfNonequivalence,
                                                       error         = (2*(results$errorPrior + results$errorPosterior)) / (results$bfEquivalence / results$bfNonequivalence)))
      
      equivalenceBayesianPairedTTestTable$addRows(list(variable1     = " ", 
                                                       separator     = " ",
                                                       variable2     = " ",
                                                       statistic     = "\U003B4 \U02209 I vs. \U003B4 \U02208 I",
                                                       bf            = 1 / (results$bfEquivalence / results$bfNonequivalence),
                                                       error         = (2*(results$errorPrior + results$errorPosterior)) / (1/(results$bfEquivalence / results$bfNonequivalence))))
    }
  }
  
  return()
}

.equivalenceBayesianPairedTTestTableDescriptives <- function(jaspResults, dataset, options, equivalenceBayesianPairedTTestResults, ready) {
  
  if(!is.null(jaspResults[["equivalenceBayesianDescriptivesTable"]])) return()
  
  # Create table
  equivalenceBayesianDescriptivesTable <- createJaspTable(title = gettext("Descriptives"))
  equivalenceBayesianDescriptivesTable$dependOn(c("pairs", "descriptives", "missingValues"))
  equivalenceBayesianDescriptivesTable$showSpecifiedColumnsOnly <- TRUE
  
  # Add Columns to table
  equivalenceBayesianDescriptivesTable$addColumnInfo(name = "variable",   title = " ",                  type = "string")
  equivalenceBayesianDescriptivesTable$addColumnInfo(name = "N",          title = gettext("N"),         type = "integer")
  equivalenceBayesianDescriptivesTable$addColumnInfo(name = "mean",       title = gettext("Mean"),      type = "number")
  equivalenceBayesianDescriptivesTable$addColumnInfo(name = "sd",         title = gettext("SD"),        type = "number")
  equivalenceBayesianDescriptivesTable$addColumnInfo(name = "se",         title = gettext("SE"),        type = "number")

  title    <- gettextf("95%% Credible Interval")
  equivalenceBayesianDescriptivesTable$addColumnInfo(name = "lowerCI", type = "number", format = "sf:4;dp:3", title = gettext("Lower"), overtitle = title)
  equivalenceBayesianDescriptivesTable$addColumnInfo(name = "upperCI", type = "number", format = "sf:4;dp:3", title = gettext("Upper"), overtitle = title)
  
  jaspResults[["equivalenceBayesianDescriptivesTable"]] <- equivalenceBayesianDescriptivesTable
  
  vars <- unique(unlist(options$pairs))
  
  for (var in vars) {
    
    data <- na.omit(dataset[[ .v(var) ]])
    n    <- length(data)
    mean <- mean(data)
    med  <- median(data)
    sd   <- sd(data)
    se   <- sd/sqrt(n) 
    
    posteriorSummary <- .posteriorSummaryGroupMean(variable = data, descriptivesPlotsCredibleInterval = 0.95)
    ciLower <- .clean(posteriorSummary[["ciLower"]])
    ciUpper <- .clean(posteriorSummary[["ciUpper"]])
    
    equivalenceBayesianDescriptivesTable$addRows(list(variable      = var,
                                                      N             = n,
                                                      mean          = mean,
                                                      sd            = sd,
                                                      se            = se,
                                                      lowerCI       = ciLower,
                                                      upperCI       = ciUpper))
  }
  
  return()
}
