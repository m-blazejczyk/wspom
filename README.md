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
```

# Restore from backup (Local ==> Server)

```
scp tags.dat weight.dat wspom.dat michal@rpi:/home/michal/wspom
```

or:

```
scp wspom.dat michal@rpi:/home/michal/wspom
scp tags.dat michal@rpi:/home/michal/wspom
scp weight.dat michal@rpi:/home/michal/wspom
```

# Deploy or re-deploy

Go to the `wspom` folder:
```
cd wspom
```

First, kill the running process and exit the screen. After the first command, do `CTRL+C A` to stop the Elixir process, and then continue with `-ls` and `-X -S`.

```
screen -r
screen -ls
screen -X -S 2967.pts-1.malina quit 
```

Get latest:

```
git pull
```

Change the version on the top of this file:

```
vi mix.exs
```

Then, rebuild:

```
MIX_ENV=prod mix release
mix assets.deploy 
```

If everything was fine, commit the changes made to `mix.exs`.

Then, open `screen` and run the process:

```
screen
authbind --deep _build/prod/rel/wspom/bin/wspom start
```

Finally, press `CTRL+A D` to detach the screen session.