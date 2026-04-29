# Usage
This app requires a bit of setup before it will work on your machine. 

- First, dump a copy of the database into the `data/` directory.
- Second, create `temp/secrets.R` and paste into there any secrets required for the app to run. 
- Finally, prior to running the app, restore the R environment to sync your package libraries to the ones used by the app by running `renv::restore()` in the console.
