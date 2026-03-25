---
title: Installation
---
# Installation

Since Cafaye is something you need to install and host yourself, you’ll need a few things before you begin:

1. Your own domain name.
2. A web server connected to the internet.
3. Some basic technical know-how.

While Cafaye isn’t difficult to set up, if you’re not a technical person you might want to get a techy friend to help.

Ok, let’s get into it.

Here’s how to get it running on your end:

1. **FIRST, pick a machine to host Cafaye.** If you need one in the cloud, we recommend checking out <a href="https://www.digitalocean.com" target="_blank">Digital Ocean</a> ([instructions](/2/the-cafaye-manual/180/installing-on-digital-ocean)) or <a href="https://www.hetzner.com" target="_blank">Hetzner</a> ([instructions](/2/the-cafaye-manual/181/installing-on-hetzner)).
2. **THEN, point DNS to the IP address of the machine that’ll be hosting Cafaye**. You need to point a domain (example.com) or subdomain (books.example.com) to the IP address of the machine hosting Cafaye. Make sure it’s a straight DNS pointer, no proxying! (Don’t worry about SSL, Cafaye will automatically set that up for you).
3. **NEXT, connect a terminal to the machine**. To run the install command, you must connect to the machine you’re using with either `SSH` or a web-based cloud console.
4. **LAST, install Cafaye with one simple command**. Paste the command you received via email into the terminal on your server and wait while everything is installed (this may take up to 5 minutes).

You personal install command will look something like this:
```
/bin/bash -c "$(curl -fsSL http://cafaye.local/install/5555-5555-5555-5555)"
```

**IMPORTANT NOTE: Do not give this install command out to anyone, or share it on the public internet. It is personalized to you, and the license is tied back to you. Your personalized purchase token can be found in the email you received after you downloaded Cafaye**

Running this command will automatically install Docker on your server if you’re using Linux (which is what everything in the cloud usually runs), then download the latest Cafaye application as a container that can run on top of Docker. In the process, it’ll ask for the domain name you’re using to host Cafaye, so that we can configure an SSL certificate for you.

 ![Screenshot 2024-06-19 at 8.02.28 PM.png](/u/screenshot-2024-06-19-at-8-02-28-pm-PFWfLF.png)

That’s it! Now you’re ready to setup the first user on the new installation. Go to the `https://YOUR-DOMAIN` and the process will begin. Then you’ll be ready to invite the rest of your team to the system.

Your Cafaye installation will automatically update to the latest version every night at 2am (local time of your server). You can turn this off via the cafaye command-line tool. You can also use this command to take a backup of your data, reset a password, and several other administrative functions. Just connect a terminal to the machine again and run the cafaye command-line tool to see all the options.

Enjoy publishing with Cafaye!

**P.S.** If you’d like to run multiple installations of Cafaye, you’ll need to get one license per installation/domain.
