x <- c(1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0)

# --------------------------------------------------

make.ema0 <- function(r) {
    s <- 0
    list(
        update = function(x) {
            s <<- r * s + (1 - r) * x
        }
    )
}

m0 <- make.ema0(0.7)

y0 <- numeric(length(x))
for (i in 1:length(x)) {
    y0[i] <- m0$update(x[i])
}

# --------------------------------------------------

make.ema1 <- function(r) {
    started <- FALSE
    s <- NULL
    list(
        update = function(x) {
            if (!started) {
                started <<- TRUE
                s <<- x
            } else {
                s <<- r * s + (1 - r) * x
            }
        }
    )
}

m1 <- make.ema1(0.7)

y1 <- numeric(length(x))
for (i in 1:length(x)) {
    y1[i] <- m1$update(x[i])
}

# --------------------------------------------------

make.ema2 <- function(r) {
    s <- 0
    extra <- 1
    list(
        update = function(x) {
            s <<- r * s + (1 - r) * x
            extra <<- r * extra
            s / (1 - extra)
        }
    )
}

m2 <- make.ema2(0.7)

y2 <- numeric(length(x))
for (i in 1:length(x)) {
    y2[i] <- m2$update(x[i])
}

# --------------------------------------------------

# plot
plot(y0, type = "l", col = "red", lwd = 2, ylim = c(0, 1))
lines(y1, col = "blue", lwd = 2)
lines(y2, col = "green", lwd = 2)

paste(x, collapse = ", ")
paste(y2, collapse = ", ")
