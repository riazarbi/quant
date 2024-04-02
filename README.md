# quant
Programmatic trading and equity research base image.

Based on riazarbi/ib-headless, with added R packages and rstudio server. 

# Usage

```
docker build . --tag quant
docker run -it --rm --name quant -e USERNAME=REDACTED -e PASSWORD=REDACTED -e TRADINGMODE=paper -e EXEC_MODE=rstudio -p 8888:8888 quant
```