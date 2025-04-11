# Wspom
Let's take a walk down the memory lane!

This application is a viewer for categorized entries from my diary.

It also allows me to track some other data that I am interested in, e.g. my weight or the books I'm reading.

Icons taken from flaticon.com.

# Backup

```
scp michal@rpi:/home/michal/wspom/tags.dat .
scp michal@rpi:/home/michal/wspom/wspom.dat .
scp michal@rpi:/home/michal/wspom/weight.dat .
```

# Restore from backup

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

First, kill the running process:

```
screen -r
screen -ls
screen -X -S 2967.pts-1.malina quit 
```

Then, rebuild:

xyz

Finally, run the process:

```
cd wspom
authbind --deep _build/prod/rel/wspom/bin/wspom start
```

Finally, press `CTRL+A D` to detach the screen session.