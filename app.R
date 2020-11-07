library(plumber)

port <- Sys.getenv('PORT')

server <- plumb("app/plumber.R")

server$run(
	host = '0.0.0.0',
	port = strtoi(port)(port)
)
