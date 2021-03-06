
Descriptives <- function(dataset=NULL, options, perform="run", callback=function(...) 0, ...) {

	variables <- unlist(options$variables)
	
	if (is.null(dataset)) {
	
		if (perform == "run") {
		
			dataset <- .readDataSetToEnd(columns=variables)
			
		} else {
		
			dataset <- .readDataSetHeader(columns=variables)
		}
	}
	
	state <- .retrieveState()
	

	run <- perform == "run"

	results <- list()
	
	#### META
	
	meta <- list()
	
	meta[[1]] <- list(name="title", type="title")
	meta[[2]] <- list(name="stats", type="table")
	meta[[3]] <- list(name="frequenciesHeading", type="h1")
	meta[[4]] <- list(name="tables", type="tables")
	meta[[5]] <- list(name="plots", type="images")
	meta[[6]] <- list(name="matrixPlot", type="image")
	
	results[[".meta"]] <- meta
	results[["title"]] <- "Descriptives"


	#### STATS TABLE
	
	last.stats.table <- NULL
	if (is.list(state))
		last.stats.table <- state[["results"]][["stats"]]

	results[["stats"]] <- .descriptivesDescriptivesTable(dataset, options, run, last.stats.table)
	

	#### FREQUENCIES TABLES
	
	last.frequency.tables <- NULL
	if (is.list(state))
		last.frequency.tables <- state[["results"]][["tables"]]

	if (options$frequencyTables) {
	
		frequency.tables <- .descriptivesFrequencyTables(dataset, options, run, last.frequency.tables)
		
		if (length(frequency.tables) > 0)
			results[["frequenciesHeading"]] <- "Frequencies"
		
		results[["tables"]] <- frequency.tables
	}
	

    ####  FREQUENCY PLOTS

	last.plots <- NULL
	if (is.list(state))
		last.plots <- state$results$plots

	results[["plots"]] <- .descriptivesFrequencyPlots(dataset, options, run, last.plots)
		
	keep <- NULL

	for (plot in results$plots)
		keep <- c(keep, plot$data)
	
	
	####  MATRIX PLOT
	
	results[["matrixPlot"]] <- .descriptivesMatrixPlot(dataset, options, run)
	
	
	
	if (perform == "init") {
	
		if (length(variables) == 0) {
		
			return(list(results=results, status="complete"))
			
		} else {
		
			return(list(results=results, status="inited", keep=keep))
		}
		
	} else {
	
		return(list(results=results, status="complete", state=list(options=options, results=results), keep=keep))
	}
}

.descriptivesDescriptivesTable <- function(dataset, options, run, last.table=NULL) {

	variables <- unlist(options$variables)
	equalGroupsNo <- options$percentileValuesEqualGroupsNo 
	percentilesPercentiles  <- options$percentileValuesPercentilesPercentiles

	stats.results <- list()
	
	stats.results[["title"]] <- "Descriptive Statistics"
	stats.results[["casesAcrossColumns"]] <- TRUE

	fields <- list()

	fields[[length(fields) + 1]] <- list(name="Variable", title="", type="string")
	fields[[length(fields) + 1]] <- list(name="Valid", type="integer")
	fields[[length(fields) + 1]] <- list(name="Missing", type="integer")


	if (options$mean)
		fields[[length(fields) + 1]] <- list(name="Mean", type="number", format="sf:4")
	if (options$standardErrorMean)
		fields[[length(fields) + 1]] <- list(name="Std. Error of Mean", type="number", format="sf:4")
	if (options$median)
		fields[[length(fields) + 1]] <- list(name="Median", type="number", format="sf:4")
	if (options$mode)
		fields[[length(fields) + 1]] <- list(name="Mode", type="number", format="sf:4")
	if (options$standardDeviation)
		fields[[length(fields) + 1]] <- list(name="Std. Deviation", type="number", format="sf:4")
	if (options$variance)
		fields[[length(fields) + 1]] <- list(name="Variance", type="number", format="sf:4")
		
	if (options$skewness) {
	
		fields[[length(fields) + 1]] <- list(name="Skewness", type="number", format="sf:4")
		fields[[length(fields) + 1]] <- list(name="Std. Error of Skewness", type="number", format="sf:4")
	}
	
	if (options$kurtosis) {
	
		fields[[length(fields) + 1]] <- list(name="Kurtosis", type="number", format="sf:4")
		fields[[length(fields) + 1]] <- list(name="Std. Error of Kurtosis", type="text", format="sf:4")
	}
	
	if (options$range)
		fields[[length(fields) + 1]] <- list(name="Range", type="number", format="sf:4")
	if (options$minimum)
		fields[[length(fields) + 1]] <- list(name="Minimum", type="number", format="sf:4")
	if (options$maximum)
		fields[[length(fields) + 1]] <- list(name="Maximum", type="number", format="sf:4")
	if (options$sum)
		fields[[length(fields) + 1]] <- list(name="Sum", type="number", format="sf:4")
	
	if (options$percentileValuesQuartiles) {
	
		fields[[length(fields) + 1]] <- list(name="q1", title="25th percentile", type="number", format="sf:4")
		fields[[length(fields) + 1]] <- list(name="q2", title="50th percentile", type="number", format="sf:4")
		fields[[length(fields) + 1]] <- list(name="q3", title="75th percentile", type="number", format="sf:4")
	}
	
	if (options$percentileValuesEqualGroups) {  # I've read that there are several ways how to estimate percentiles so it should be checked if it match the SPSS way
	
		for (i in seq(equalGroupsNo - 1))
			fields[[length(fields) + 1]] <- list(name=paste("eg", i, sep=""), title=paste(as.integer(100 * i / equalGroupsNo), "th percentile", sep=""), type="number", format="sf:4")
	}
	
	if (options$percentileValuesPercentiles) { 
	
		for (i in percentilesPercentiles) 
			fields[[length(fields) + 1]] <- list(name=paste("pc", i, sep=""), title=paste(i, "th percentile", sep=""), type="number", format="sf:4")
	} 
  
	stats.results[["schema"]] <- list(fields=fields)

	footnotes <- .newFootnotes()
	
	note.symbol <- "<i>Note.</i>"
	na.for.categorical <- "Not all values are available for nominal and ordinal variables"
	
	
	stats.values <- list()

	for (variable in variables) {
		
		variable.results <- list(Variable=variable)

		for (col in last.table$data) {
		
			if (col$Variable == variable) {
			
				variable.results <- col
				break
			}
		}

		column <- dataset[[ .v(variable) ]]

		if (perform == "run") {

			rows <- nrow(dataset)
			na.omitted <- na.omit(column)
			
			variable.results[["Valid"]] = length(na.omitted)
			variable.results[["Missing"]] = rows - length(na.omitted)
		}
		else {

			na.omitted <- column
		}



		if (options$mean) {
		
			if (base::is.factor(na.omitted) == FALSE) {
			
				if (perform == "run")
					variable.results[["Mean"]] <- .clean(mean(na.omitted))
				
			} else {
			
				variable.results[["Mean"]] <- ""
				.addFootnote(footnotes, na.for.categorical, note.symbol)
			}
			
		} else {
		
			variable.results[["Mean"]] <- NULL
		}
		
		if (options$median) {
		
			if (base::is.factor(na.omitted) == FALSE) {

				if (perform == "run")
					variable.results[["Median"]] <- .clean(median(na.omitted))
				
			} else {
			
				variable.results[["Median"]] <- ""
				.addFootnote(footnotes, na.for.categorical, note.symbol)
			}
		} else {

			variable.results[["Median"]] <- NULL
		}
		
		if (options$mode) {
	
			if (base::is.factor(na.omitted) == FALSE) {
		
				if (perform == "run") {

					mode <- as.numeric(names(table(na.omitted)[table(na.omitted)==max(table(na.omitted))]))

					if (length(mode) > 1) {

						index <- .addFootnote(footnotes, "More than one mode exists, only the first is reported")
						variable.results[[".footnotes"]] <- list(Mode=list(index))
					}
		
					variable.results[["Mode"]] <- .clean(mode[1])
					
				}
			
			} else {
		
				variable.results[["Mode"]] <- ""
				.addFootnote(footnotes, na.for.categorical, note.symbol)
			}
		} else {
		
			variable.results[["Mode"]] <- NULL
		}
		
		if (options$sum) {
		
			if (base::is.factor(na.omitted) == FALSE) {

				if (perform == "run")
					variable.results[["Sum"]] <- .clean(sum(na.omitted))
				
			} else {
			
				variable.results[["Sum"]] <- ""
				.addFootnote(footnotes, na.for.categorical, note.symbol)
			}
			
		} else {
		
			variable.results[["Sum"]] <- NULL
		}
		
		if (options$maximum) {
		
			if (base::is.factor(na.omitted) == FALSE) {

				if (perform == "run")
					variable.results[["Maximum"]] <- .clean(max(na.omitted))
				
			} else {
			
				variable.results[["Maximum"]] <- ""
				.addFootnote(footnotes, na.for.categorical, note.symbol)
			}
			
		} else {
		
			variable.results[["Maximum"]] <- NULL
		}
		
		if (options$minimum) {
		
			if (base::is.factor(na.omitted) == FALSE) {
			
				if (perform == "run")
					variable.results[["Minimum"]] <- .clean(min(na.omitted))
				
			} else {
			
				variable.results[["Minimum"]] <- ""
				.addFootnote(footnotes, na.for.categorical, note.symbol)
			}
		} else {
		
			variable.results[["Minimum"]] <- NULL
		}
		
		if (options$range) {
		
			if (base::is.factor(na.omitted) == FALSE) {

				if (perform == "run")
					variable.results[["Range"]] <- .clean(range(na.omitted)[2]-range(na.omitted)[1])
				
			} else {
			
				variable.results[["Range"]] <- ""
				.addFootnote(footnotes, na.for.categorical, note.symbol)
			}
			
		} else {
		
			variable.results[["Range"]] <- NULL
		}
		
		if (options$standardDeviation) {
		
			if (base::is.factor(na.omitted) == FALSE){
			
				if (perform == "run")
					variable.results[["Std. Deviation"]] <- .clean(sd(na.omitted))
				
			} else {
			
				variable.results[["Std. Deviation"]] <- ""
				.addFootnote(footnotes, na.for.categorical, note.symbol)
			}
			
		} else {
		
			variable.results[["Std. Deviation"]] <- NULL
		}
		
		if (options$standardErrorMean) {
		
			if (base::is.factor(na.omitted) == FALSE) {

				if (perform == "run")
					variable.results[["Std. Error of Mean"]] <- .clean(sd(na.omitted)/sqrt(length(na.omitted)))
				
			} else {
			
				variable.results[["Std. Error of Mean"]] <- ""
				.addFootnote(footnotes, na.for.categorical, note.symbol)
			}
			
		} else {
		
			variable.results[["Std. Error of Mean"]] <- NULL
		}
		
		if (options$variance) {
		
			if (base::is.factor(na.omitted) == FALSE) {

				if (perform == "run")
					variable.results[["Variance"]] <- .clean(var(na.omitted))
				
			} else {
			
				variable.results[["Variance"]] <- ""
				.addFootnote(footnotes, na.for.categorical, note.symbol)
			}
			
		} else {

			variable.results[["Variance"]] <- NULL
		}
		
		if (options$kurtosis) {
		
			if (base::is.factor(na.omitted) == FALSE) {

				if (perform == "run") {
				
					variable.results[["Kurtosis"]] <- .clean(.descriptivesKurtosis(na.omitted))
					variable.results[["Std. Error of Kurtosis"]] <- .clean(.descriptivesSEK(na.omitted))
				}
				
			} else {
			
				variable.results[["Kurtosis"]] <- ""
				variable.results[["Std. Error of Kurtosis"]] <- ""
				.addFootnote(footnotes, na.for.categorical, note.symbol)
			}
			
		} else {
		
			variable.results[["Kurtosis"]] <- NULL
			variable.results[["Std. Error of Kurtosis"]] <- NULL
		}
		
		if (options$skewness) {
		
			if (base::is.factor(na.omitted) == FALSE) {
			
				if (perform == "run") {
				
					variable.results[["Skewness"]] <- .clean(.descriptivesSkewness(na.omitted))
					variable.results[["Std. Error of Skewness"]] <- .clean(.descriptivesSES(na.omitted))
					
				}
				
			} else {
			
				variable.results[["Skewness"]] <- ""
				variable.results[["Std. Error of Skewness"]] <- ""
				.addFootnote(footnotes, na.for.categorical, note.symbol)
			}
		} else {
		
			variable.results[["Skewness"]] <- NULL
			variable.results[["Std. Error of Skewness"]] <- NULL
		}
		
		if (options$percentileValuesQuartiles) {
		
			if (base::is.factor(na.omitted) == FALSE) {
			
				if (perform == "run") {
				
					variable.results[["q1"]] <- .clean(quantile(na.omitted, c(.25), type=6, names=F))
					variable.results[["q2"]] <- .clean(quantile(na.omitted, c(.5), type=6, names=F))
					variable.results[["q3"]] <- .clean(quantile(na.omitted, c(.75), type=6, names=F))
					
				}
				
			} else {
			
				variable.results[["q1"]] <- ""
				variable.results[["q2"]] <- ""
				variable.results[["q3"]] <- ""
				.addFootnote(footnotes, na.for.categorical, note.symbol)
			}
		} else {
		
			variable.results[["q1"]] <- NULL
			variable.results[["q2"]] <- NULL
			variable.results[["q3"]] <- NULL
		}
		
		
		equalGroupNames <- NULL
		if (options$percentileValuesEqualGroups)
			equalGroupNames <- paste("eg", seq(equalGroupsNo - 1), sep="")

		for (row in names(variable.results)) {
		
			if (substr(row, 1, 2) == "eg" && ((row %in% equalGroupNames) == FALSE))
				variable.results[[row]] <- NULL
		}

		if (options$percentileValuesEqualGroups) {
		
			if (base::is.factor(na.omitted) == FALSE) {
			
				if (perform == "run") {
			
					for (i in seq(equalGroupsNo - 1))
						variable.results[[paste("eg", i, sep="")]] <- .clean(quantile(na.omitted, c(i / equalGroupsNo), type=6, names=F))
					
				}
				
			} else {
			
				for (i in seq(equalGroupsNo - 1))
					variable.results[[paste("eg", i, sep="")]] <- ""
				.addFootnote(footnotes, na.for.categorical, note.symbol)
			}
		}
		
		
		percentileNames <- NULL
		if (options$percentileValuesPercentiles)
			percentileNames <- paste("pc", percentilesPercentiles, sep="")
		
		for (row in names(variable.results)) {
		
			if (substr(row, 1, 2) == "pc" && ((row %in% percentileNames) == FALSE))
				variable.results[[row]] <- NULL
		}
		
		if (options$percentileValuesPercentiles) {
		
			if (base::is.factor(na.omitted) == FALSE) {
			
				if (perform == "run") {
			
					for (i in percentilesPercentiles)
						variable.results[[paste("pc", i, sep="")]] <- .clean(quantile(na.omitted, c(i / 100), type=6, names=F))
					
				}
				
			} else {
			
				for (i in percentilesPercentiles)
					variable.results[[paste("pc", i, sep="")]] <- ""
				.addFootnote(footnotes, na.for.categorical, note.symbol)
			}
		}
		
		stats.values[[length(stats.values) + 1]] <- variable.results
			
	
		stats.results[["data"]] <- stats.values
		stats.results[["footnotes"]] <- as.list(footnotes)
	}

	stats.results
}

.descriptivesFrequencyTables <- function(dataset, options, run, last.tables) {

	frequency.tables <- list()
		
	for (variable in options$variables) {

		column <- dataset[[ .v(variable) ]]
	
		if (base::is.factor(column) == FALSE)
			next
		
		frequency.table <- list()

		for (last in last.tables) {
		
			if (last$name == variable) {
			
				frequency.table <- last
				break
			}
		}
	
		fields <- list(
						list(name="Level", type="string", title=""),
						list(name="Frequency", type="integer"),
						list(name="Percent", type="number", format="dp:1"),
						list(name="Valid Percent", type="number", format="dp:1"),
						list(name="Cumulative Percent", type="number", format="dp:1"))

		frequency.table[["title"]] <- paste("Frequencies for", variable)
		frequency.table[["name"]]  <- variable
		frequency.table[["schema"]] <- list(fields=fields)
	
		lvls <- levels(dataset[[ .v(variable) ]])

		if (run) {

			t <- table(column)
			total <- sum(t)

			ns <- list()
			freqs <- list()
			percent <- list()
			validPercent <- list()
			cumPercent <- list()

			cumFreq <- 0

			for (n in names(t)) {

				ns[[length(ns)+1]] <- n
				freq <- as.vector(t[n])
				
				cumFreq <- cumFreq + freq

				freqs[[length(freqs) + 1]] <- freq
				percent[[length(percent) + 1]] <- freq / total * 100
				validPercent[[length(validPercent) + 1]] <- freq / total * 100
				cumPercent[[length(cumPercent)+1]] <- cumFreq / total * 100
			}

			ns[[length(ns)+1]] <- "Total"
			freqs[[length(freqs)+1]] <- total
			percent[[length(percent)+1]] <- 100
			validPercent[[length(validPercent)+1]] <- 100
			cumPercent[[length(cumPercent)+1]] <- ""

			data <- list()

			for (i in seq(freqs))
				data[[length(data)+1]] <- list(Level=ns[[i]], "Frequency"=freqs[[i]], "Percent"=percent[[i]], "Valid Percent"=validPercent[[i]], "Cumulative Percent"=cumPercent[[i]])

			frequency.table[["data"]] <- data

		} else {

			if (("data" %in% names(frequency.table)) == FALSE) {
			
				data <- list()
			
				for (level in lvls)
					data[[length(data)+1]] <- list(level=level)
				
				data[[length(data)+1]] <- list(level="Total", "Cumulative Percent"="")
				
				frequency.table[["data"]] <- data
				
			} else {
			
				frequency.table[["status"]] <- "complete"
			}
		}
	
		frequency.tables[[length(frequency.tables)+1]] <- frequency.table
	}
	
	frequency.tables
}

.descriptivesFrequencyPlots <- function(dataset, options, run, last.plots) {

	frequency.plots <- NULL

	if (options$plotVariables) {
	
		for (variable in options$variables) {

			plot <- list()
			plotted <- FALSE

			for (last.plot in last.plots) {
			
				if (variable == last.plot$name) {
				
					plot <- last.plot
					plotted <- TRUE
					break
				}
			}
			
			if (plotted && (plot$width != options$plotWidth || plot$height != options$plotHeight))
				plotted <- FALSE
	
			plot[["title"]] <- variable
			plot[["name"]]  <- variable
			plot[["width"]]  <- options$plotWidth
			plot[["height"]] <- options$plotHeight
			plot[["custom"]] <- list(width="plotWidth", height="plotHeight")
				
			column <- na.omit(dataset[[ .v(variable) ]])

			if (plotted) {
			
				# already plotted, no nothing
				
			} else if (run == FALSE) {
			
				image <- .beginSaveImage(options$plotWidth, options$plotHeight)
				
				.barplotJASP(variable=variable, dontPlotData=TRUE)
				
				plot[["data"]] <- .endSaveImage(image)
			
			} else if (any(is.infinite(column))) {
				
				image <- .beginSaveImage(options$plotWidth, options$plotHeight)
			
				.barplotJASP(variable=variable, dontPlotData=TRUE)
			
				plot[["data"]] <- .endSaveImage(image)
				plot[["error"]] <- list(error="badData", errorMessage="Plotting is not possible: Variable contains infinity")
				plot[["status"]] <- "complete"
					
			} else if (length(column) > 0 && is.factor(column) || length(column) > 0  && all(column %% 1 == 0) && length(unique(column)) <= 24) {
			
				if ( ! is.factor(column)) {
				
					column <- as.factor(column)
				}
				
				image <- .beginSaveImage(options$plotWidth, options$plotHeight)
				
				.barplotJASP(column, variable)
				
				plot[["data"]] <- .endSaveImage(image)
				plot[["status"]] <- "complete"
				
			} else if (length(column) > 0 && !is.factor(column)) {
				
				if (any(is.infinite(column))) {
				
					image <- .beginSaveImage(options$plotWidth, options$plotHeight)
			
					.barplotJASP(variable=variable, dontPlotData=TRUE)
			
					plot[["data"]] <- .endSaveImage(image)
					plot[["error"]] <- list(error="badData", errorMessage="Plotting is not possible: Variable contains infinity")
					plot[["status"]] <- "complete"
					
				} else {
				
					image <- .beginSaveImage(options$plotWidth, options$plotHeight)
				
					.plotMarginal(column, variableName=variable)
				
					plot[["data"]] <- .endSaveImage(image)
					plot[["status"]] <- "complete"
				}
				
			}
			
			frequency.plots[[length(frequency.plots)+1]] <- plot
		}
	}
	
	frequency.plots
}

.descriptivesMatrixPlot <- function(dataset, options, run) {

	matrix.plot <- NULL

	if (options$plotCorrelationMatrix) {
		
		if (run) {
			matrix.plot <- .matrixPlot(dataset, perform="run", options) 
		} else {
			matrix.plot <- .matrixPlot(dataset, perform="init", options)
		}
	}
	
	matrix.plot
}

.descriptivesKurtosis <- function(x) {

	# Kurtosis function as in SPSS: 
	# http://www.ats.ucla.edu/stat/mult_pkg/faq/general/kurtosis.htm
	# http://en.wikipedia.org/wiki/Kurtosis#Estimators_of_population_kurtosis
	
	n <- length(x)
	s4 <- sum((x - mean(x))^4)
	s2 <- sum((x - mean(x))^2)
	v <- s2 / (n-1)
	a <- (n * (n + 1)) / ((n - 1) * (n - 2) * (n - 3))
	b <- s4 / (v^2)
	c <- (-3 * (n - 1)^2) / ((n - 2) * (n - 3))
	kurtosis <- a * b + c
	return(kurtosis)
}

.descriptivesSkewness <- function(x) {

	# Skewness function as in SPSS (for samlpes spaces): 
	# http://suite101.com/article/skew-and-how-skewness-is-calculated-in-statistical-software-a231005
	
	n <- length(x)
	m <- mean(x)
	s <- sd(x) 
	z <- (x - m) / s  # z scores
	a <- n / ((n - 1) * (n - 2))
	skewness <- sum(z^3) * a
	return(skewness)
}

.descriptivesSES <- function(x) {

	# Standard Error of Skewness
	# Formula found http://web.ipac.caltech.edu/staff/fmasci/home/statistics_refs/SkewStatSignif.pdf
	
	n <- length(x)
	SES <- sqrt((6 * n * (n - 1) / ((n - 2) * (n + 1) * (n + 3))))
	return(SES)
}

.descriptivesSEK <- function(x) {

	# Standard Error of Kurtosis
	# Formula found http://web.ipac.caltech.edu/staff/fmasci/home/statistics_refs/SkewStatSignif.pdf
	
	n <- length(x)
	SEK <- 2 * .descriptivesSES(x) * sqrt((n^2 - 1) / ((n - 3) * (n + 5)))
	return(SEK)
} 

.barplotJASP <- function(column, variable, dontPlotData= FALSE){

	if (dontPlotData) {
	
		plot(1, type='n', xlim=0:1, ylim=0:1, bty='n', axes=FALSE, xlab="", ylab="")
		
		axis(1, at=0:1, labels=FALSE, cex.axis= 1.4, xlab="")
		axis(2, at=0:1, labels=FALSE, cex.axis= 1.4, ylab="")
		
		mtext(text = variable, side = 1, cex=1.5, line = 3)
		
		return()
	}

	maxFrequency <- max(summary(column))
	
	i <- 1
	step <- 1
	
	while (maxFrequency / step > 9) {
		
		if (i == 2) {
			
			step <- 2 * step
			i <- i + 1
			
		} else if (i %% 3 == 0) {
			
			step <- 2.5 * step
			i <- i + 1
			
		} else {
			
			step <- 2 * step
			i <- i + 1
		}
		
	}
	
	yticks <- 0
	
	while (yticks[length(yticks)] < maxFrequency) {
		
		yticks <- c(yticks, yticks[length(yticks)] + step)
	}
	
	
	yLabs <- vector("character", length(yticks))
	
	for(i in seq_along(yticks)){
		
		if(yticks[i] < 10^6){
			
			yLabs[i] <- format(yticks[i], digits= 3, scientific = FALSE)
			
		} else{
			
			yLabs[i] <- format(yticks[i], digits= 3, scientific = TRUE)
		}
	}
	
	distLab <- max(nchar(yLabs))/1.8
	
	par(mar= c(5, 7.2, 4, 2) + 0.1)
	barplot(summary(column), cex.names= 1.3, axes= FALSE, ylim= range(yticks))
	axis(2, las=1, at= yticks, labels= yLabs, cex.axis= 1.4)
	mtext(text = variable, side = 1, cex=1.5, line = 3)
	mtext(text = "Frequency", side = 2, cex=1.5, line = distLab+2, las=0)
}

.plotMarginal <- function(variable, variableName, cexYlab= 1.3, lwd= 2, rugs= FALSE){

	par(mar= c(5, 4.5, 4, 2) + 0.1)
	
	density <- density(variable)
	
	h <- hist(variable, plot = FALSE)
	jitVar <- jitter(variable)
	yhigh <- max(max(h$density), max(density$y))
	ylow <- 0
	xticks <- pretty(c(variable, h$breaks), min.n= 3)
	
	plot(1, xlim= range(xticks), ylim= c(ylow, yhigh), type="n", axes=FALSE, ylab="", xlab="")
	h <- hist(variable, freq=F, main = "", ylim= c(ylow, yhigh), xlab = "", ylab = " ", axes = F, col = "grey", add= TRUE, nbreaks= round(length(variable)/5))
	ax1 <- axis(1, line = 0.3, at= xticks, lab= xticks, cex.axis = 1.2)
	mtext(text = variableName, side = 1, cex=1.5, line = 3)
	par(las=0)
	ax2 <- axis(2, at = c(0, max(max(h$density), max(density$y))/2, max(max(h$density), max(density$y))) , labels = c("", "Density", ""), lwd.ticks=0, pos= range(ax1)- 0.05*diff(range(ax1)), cex.axis= 1.5, mgp= c(3, 0.7, 0))
	
	if(rugs){
		rug(jitVar)
	}
	
	lines(density$x[density$x>= min(ax1) & density$x <= max(ax1)], density$y[density$x>= min(ax1) & density$x <= max(ax1)], lwd= lwd)
}

.plotScatterDescriptives <- function(xVar, yVar, cexPoints= 1.3, cexXAxis= 1.3, cexYAxis= 1.3, lwd= 2){
	
	d <- data.frame(xx= xVar, yy= yVar)
	d <- na.omit(d)
	xVar <- d$xx
	yVar <- d$yy
	
	# fit different types of regression
	fit <- vector("list", 1)# vector("list", 4)
	
	fit[[1]] <- lm(yy ~ poly(xx, 1, raw= TRUE), d)
	fit[[2]] <- lm(yy ~ poly(xx, 2, raw= TRUE), d)
	fit[[3]] <- lm(yy ~ poly(xx, 3, raw= TRUE), d)
	fit[[4]] <- lm(yy ~ poly(xx, 4, raw= TRUE), d)
	
	# find parsimonious, best fitting regression model
	Bic <- vector("numeric", 4)
	
	for (i in 1:4) {
		
		Bic[i] <- BIC(fit[[i]])	
		
	}
	
	bestModel <- which.min(Bic)
	
	xlow <- min((min(xVar) - 0.1* min(xVar)), min(pretty(xVar)))
	xhigh <- max((max(xVar) + 0.1* max(xVar)), max(pretty(xVar)))
	xticks <- pretty(c(xlow, xhigh))
	
	ylow <- min((min(yVar) - 0.1* min(yVar)), min(pretty(yVar)), min(.poly.pred(fit[[bestModel]], line= FALSE, xMin= xticks[1], xMax= xticks[length(xticks)], lwd=lwd)))
	yhigh <- max((max(yVar) + 0.1* max(yVar)), max(pretty(yVar)), max(.poly.pred(fit[[bestModel]], line= FALSE, xMin= xticks[1], xMax= xticks[length(xticks)], lwd=lwd)))
	yticks <- pretty(c(ylow, yhigh))
	
	plot(xVar, yVar, col="black", pch=21, bg = "grey", ylab="", xlab="", axes=F, ylim= range(yticks), xlim= range(xticks), cex= cexPoints)
	
	.poly.pred(fit[[bestModel]], line= TRUE, xMin= xticks[1], xMax= xticks[length(xticks)], lwd=lwd)
	
	par(las=1)
	
	axis(1, line= 0.4, labels= xticks, at= xticks, cex.axis= cexXAxis)
	axis(2, line= 0.2, labels= yticks, at= yticks, cex.axis= cexYAxis)
}

#### Matrix Plot function #####
.matrixPlot <- function(dataset, perform, options) {

	if (!options$plotCorrelationMatrix)
		return()
	
	matrix.plot <- list()

	if (perform == "init") {
	
		variables <- unlist(options$variables)
		variables <- .v(variables)
		l <- length(variables)
		
		if (l > 0) {

			if (l <= 2) {
			
				width <- 580
				height <- 580
				
			} else {
				
				width <- 250 * l
				height <- 250 * l
				
			}
			
			
			plot <- list()
			
			plot[["title"]] <- ""
			plot[["width"]]  <- width
			plot[["height"]] <- height
			
			matrix.plot <- plot
		
		} else {
		
			matrix.plot <- NULL
		}
	}
	
	
	if (perform == "run" && length(unlist(options$variables)) > 0) {

		variables <- unlist(options$variables)
		
		l <- length(variables)
		
		# check variables
		d <- vector("character", length(.v(variables)))
		sdCheck <- vector("numeric", length(.v(variables)))
		infCheck <- vector("logical", length(.v(variables)))
		
		for (i in seq_along(.v(variables))) {
		
			d[i] <- class(dataset[[.v(variables)[i]]])
			sdCheck[i] <- sd(dataset[[.v(variables)[i]]], na.rm=TRUE) > 0
			infCheck[i] <- all(is.finite(dataset[[.v(variables)[i]]]))
		}
		
		numericCheck <- d == "numeric" | d == "integer"
		variables <- .v(variables)
		variable.statuses <- vector("list", length(variables))
		
		for (i in seq_along(variables)) {
		
			variable.statuses[[i]]$unplotable <- FALSE
			variable.statuses[[i]]$plottingError <- NULL
			
			if ( ! (numericCheck[i] && sdCheck[i] && infCheck[i])) {
				
				variable.statuses[[i]]$unplotable <- TRUE
				
				if ( ! numericCheck[i]) {
					variable.statuses[[i]]$plottingError <- "Variable is not continuous"
				} else if ( ! infCheck[i]) {
					variable.statuses[[i]]$plottingError <- "Variable contains infinity"
				} else if ( ! sdCheck[i]) {
					variable.statuses[[i]]$plottingError <- "Variable has zero variance"
				}
				
			}
		}
		
		if (l > 0) {
			
			if (l <= 2) {
			
				width <- 580
				height <- 580
				
			} else {
				
				width <- 250 * l
				height <- 250 * l
				
			}
			
			matrix.plot <- list()
			
			plot <- list()
			
			plot[["title"]] <- ""
			plot[["width"]]  <- width
			plot[["height"]] <- height
			
			matrix.plot <- plot
			
		} else {
		
			matrix.plot <- NULL
		}
		
		if (length(variables) > 0) {
		
			image <- .beginSaveImage(width, height)
			
				if (l == 1) {
				
					par(mfrow= c(1,1), cex.axis= 1.3, mar= c(3, 4, 2, 1.5) + 0.1, oma= c(2, 0, 0, 0))
					
					if ( ! variable.statuses[[1]]$unplotable) {
						.plotMarginalCor(dataset[[variables[1]]]) 
						mtext(text = .unv(variables)[1], side = 1, cex=1.9, line = 3)
					} else {
						.displayError(variable.statuses[[1]]$plottingError)
					}
					
				} else if (l > 1) {
				
					par(mfrow= c(l,l), cex.axis= 1.3, mar= c(3, 4, 2, 1.5) + 0.1, oma= c(0.2, 2.2, 2, 0))
				
					for (row in seq_len(l)) {
					
						for (col in seq_len(l)) {
						
							if (row == col) {
								
								if ( ! variable.statuses[[row]]$unplotable) {
										.plotMarginalCor(dataset[[variables[row]]]) # plot marginal (histogram with density estimator)
								} else {
									.displayError(variable.statuses[[row]]$plottingError)
								}
							
							}
							
							if (col > row) {
							
								if ( ! variable.statuses[[col]]$unplotable && ! variable.statuses[[row]]$unplotable) {
									.plotScatterDescriptives(dataset[[variables[col]]], dataset[[variables[row]]]) # plot scatterplot
								} else {
									errorMessages <- c(variable.statuses[[row]]$plottingError, variable.statuses[[col]]$plottingError)
									.displayError(errorMessages[1])
								}
								
							}
							
							if (col < row) {
							
								plot(1, type= "n", axes= FALSE, ylab="", xlab="")
								
							}
						}
					}
				}
				
				if (l > 1) {
				
					textpos <- seq(1/(l*2), (l*2-1)/(l*2), 2/(l*2))
					
					for (t in seq_along(textpos)) {
							
						mtext(text = .unv(variables)[t], side = 3, outer = TRUE, at= textpos[t], cex=1.5, line= -0.8)
						mtext(text = .unv(variables)[t], side = 2, outer = TRUE, at= rev(textpos)[t], cex=1.5, line= -0.1, las= 0)
					}
				}
				
			content <- .endSaveImage(image)
			
			plot <- matrix.plot
			plot[["data"]]  <- content
			matrix.plot <- plot
			
		}
	}
	
	matrix.plot
}



