# Wspom
Let's take a walk down the memory lane!

This application is a viewer for categorized entries from my diary.

It also allows me to track some other data that I am interested in, e.g. my weight or the books I'm reading.

Icons taken from flaticon.com.

More icons: https://tailwindcss-generator.com/icon

# Backup (Server ==> Local)

```
scp michal@rpi:/home/michal/wspom/tags.dat .
scp michal@rpi:/home/michal/wspom/wspom.dat .
scp michal@rpi:/home/michal/wspom/weight.dat .
scp michal@rpi:/home/michal/wspom/books.dat .
```

or all the files at once, including backups:

```
scp -r michal@rpi:'"/home/michal/wspom"/*.dat' .
```

# Restore from backup (Local ==> Server)

```
scp tags.dat weight.dat wspom.dat books.dat michal@rpi:/home/michal/wspom
```

or:

```
scp wspom.dat michal@rpi:/home/michal/wspom
scp tags.dat michal@rpi:/home/michal/wspom
scp weight.dat michal@rpi:/home/michal/wspom
scp books.dat michal@rpi:/home/michal/wspom
scp weather.dat michal@rpi:/home/michal/wspom
```

# Deploy or re-deploy

SSH into the server:
```
ssh rpi
```

Go to the `wspom` folder:
```
cd wspom
```

First, enter the screen:

```
screen -r
```

You should see the Phoenix log. Kill the running process with `CTRL+C A`, as usual. You will now be in the screen session which is still active. Kill it with the following (the session / socket id will be different every time):

```
screen -ls
screen -X -S 2967.pts-1.malina quit 
```

Get latest:

```
git pull
```

Rebuild:

```
MIX_ENV=prod mix compile
MIX_ENV=prod mix assets.deploy
mix phx.gen.release
MIX_ENV=prod mix release 
```

# Run the application

Go into the `wspom` directory and run `screen`:

```
cd wspom
screen
authbind --deep _build/prod/rel/wspom/bin/wspom start
```

Finally, press `CTRL+A D` to detach the screen session.