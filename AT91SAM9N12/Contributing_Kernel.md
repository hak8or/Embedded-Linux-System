# Contributing to the Linux Kernel

The process involved to contribute to the Linux kernel is not trivial, with you having to go through their mailing lists and being unable to use GMail. This should give a rough overview of how to go through the process so I don't forget myself, using my USB patch as an example. This is based on a few guides, some of which are [this](https://kernelnewbies.org/FirstKernelPatch), [this](http://nickdesaulniers.github.io/blog/2017/05/16/submitting-your-first-patch-to-the-linux-kernel-and-responding-to-feedback/), and [this](https://burzalodowa.wordpress.com/2013/10/05/how-to-send-patches-with-git-send-email/), and some very helpful people on the IRC (especially gregkh).

## Getting the Kernel

First things first, grab an up to date kernel. The kernel has a [website](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git) showing the state of it's git based development. On there you can find what URL to use for doing a git clone.

But before you do that, keep in mind the kernel is huge, with many thousands of commits. Doing a simple ```git clone``` takes a very long time on my machine, so you can instead do a "shallow" clone, which only takes the most recent commit for each file. This drastically speeds things up.

```bash
git clone --depth 1 git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
cd linux
```

## Creating the patch

We have to modify the ```recalc_rate()``` function to use the cached DIV and MUL values. So in ```drivers/clk/at91/clk-pll.c``` change the ```clk_pll_recalc_rate()``` function as shown below. The "-" signs mean to remove the line, and the "+" signs mean to add the line. In our case we are removing most of the function body and replacing how the return value is calculated. Conceptually, this is all the information the kernel people need, but we still have to add some things.

```c
static unsigned long clk_pll_recalc_rate(struct clk_hw *hw,
                                         unsigned long parent_rate)
 {
        struct clk_pll *pll = to_clk_pll(hw);
-       unsigned int pllr;
-       u16 mul;
-       u8 div;
-
-       regmap_read(pll->regmap, PLL_REG(pll->id), &pllr);
-
-       div = PLL_DIV(pllr);
-       mul = PLL_MUL(pllr, pll->layout);
-
-       if (!div || !mul)
-               return 0;

-       return (parent_rate / div) * (mul + 1);
+       return (parent_rate / pll->div) * (pll->mul + 1);
 }
```

Create a git commit with this change with a ```git add drivers/clk/at91/clk-pll.c``` and then ```git commit --signoff```. The ```--signoff``` flag adds a line to the end of the commit which includes your name and email for copyright purposes.

The title must specify what subsystem(s) this is for (in our case CLK and AT91), a **short**  title. In our case, it will be "clk: at91: PLL recalc_rate() now using cached MUL+DIV values". Then write a proper git commit message detailing what the issue is and how it was fixed. Be specific and clear, this goes to developers who have tons of things to do and little time, so try to make this as painless as possible for them.

Then do a ```git format-patch HEAD~``` to create a patch file (```0001-clk-at91-PLL-recalc_rate-now-using-cached-MUL-and-DI.patch``` in our case). The contents of which is as follows:

```git
[hak8or@hak8or linux_commit]$ cat 0001-clk-at91-PLL-recalc_rate-now-using-cached-MUL-and-DI.patch
From 47ded631f3c787f00272d140dbb5ff1842e2716d Mon Sep 17 00:00:00 2001
From: Marcin Ziemianowicz <marcin@ziemianowicz.com>
Date: Sun, 29 Apr 2018 14:04:37 -0400
Subject: [PATCH V4] clk: at91: PLL recalc_rate() now using cached MUL and DIV values

When a USB device is connected to the USB host port on the SAM9N12 then
you get "-62" error which seems to indicate USB replies from the device
are timing out. Based on a logic sniffer, I saw the USB bus was running
at half speed.

The PLL code uses cached MUL and DIV values which get set in set_rate()
and applied in prepare(), but the recalc_rate() function instead
queries the hardware instead of using these cached values. Therefore,
if recalc_rate() is called between a set_rate() and prepare(), the
wrong frequency is calculated and later the USB clock divider for the
SAM9N12 SOC will be configured for an incorrect clock.

In my case, the PLL hardware was set to 96 Mhz before the OHCI
driver loads, and therefore the usb clock divider was being set
to /2 even though the OHCI driver set the PLL to 48 Mhz.

As an alternative explanation, I noticed this was fixed in the past by
87e2ed338f1b ("clk: at91: fix recalc_rate implementation of PLL
driver") but the bug was later re-introduced by 1bdf02326b71 ("clk:
at91: make use of syscon/regmap internally").

Fixes: 1bdf02326b71 ("clk: at91: make use of syscon/regmap internally)
Cc: <stable@vger.kernel.org>
Signed-off-by: Marcin Ziemianowicz <marcin@ziemianowicz.com>
---
Thank you for bearing with me about this Boris.

Changes since V3:
  Fix for double returns found by kbluild test robot
  > Comments by Boris Brezillon about email formatting issues
Changes since V2:
  Removed all logging/debug messages I added
  > Comment by Boris Brezillon about my fix being wrong addressed
Changes since V1:
  Added patch set cover letter
  Shortened lines which were over >80 characters long
  > Comment by Greg Kroah-Hartman about "from" field in email addressed
  > Comment by Alan Stern about redundant debug lines addressed

 drivers/clk/at91/clk-pll.c | 13 +------------
 1 file changed, 1 insertion(+), 12 deletions(-)

diff --git a/drivers/clk/at91/clk-pll.c b/drivers/clk/at91/clk-pll.c
index 7d3223fc..72b6091e 100644
--- a/drivers/clk/at91/clk-pll.c
+++ b/drivers/clk/at91/clk-pll.c
@@ -132,19 +132,8 @@ static unsigned long clk_pll_recalc_rate(struct clk_hw *hw,
                                         unsigned long parent_rate)
 {
        struct clk_pll *pll = to_clk_pll(hw);
-       unsigned int pllr;
-       u16 mul;
-       u8 div;
-
-       regmap_read(pll->regmap, PLL_REG(pll->id), &pllr);
-
-       div = PLL_DIV(pllr);
-       mul = PLL_MUL(pllr, pll->layout);
-
-       if (!div || !mul)
-               return 0;
 
-       return (parent_rate / div) * (mul + 1);
+       return (parent_rate / pll->div) * (pll->mul + 1);
 }
 
 static long clk_pll_get_best_div_mul(struct clk_pll *pll, unsigned long rate,
-- 
2.17.0
```

There are a few things to note here.

- The commit title starts with ```[PATCH V4]```. When running ```git format-patch HEAD~```, ```[PATCH]``` gets put into the subject line of the patch file. Since in my case this was the 4th attempt for the patch, each attempt includes a version that you must put in manually into the patch file.

- Notes get put between two ```---``` lines. These notes are meant for the mailing list and do not get put into the commit message. In my case it shows changes between each patch version and a short note thanking Boris for putting up with me and my issues with getting this right. :P

- The ```From:``` field is the same as the ```Signed-off-by``` field. Ensure this is the same!

- Since this was traced back to a bug in a commit done a long time ago, the commit and commit title is added in a ```Fixes``` field. Furthermore, a ```CC``` field was added so when we do ```git send-email``` later, it will get automatically added to the list of people to CC the email too. The CC entry is also to (from what I understand) let kernel maintainers know that it can be back ported to past kernels.

- Past commits are referenced by their commit hash, not a link to LKML or github or anything else, just a commit hash and the title of the commit.

## Verfying

There are multiple tools to ensure the changes are following kernel guidelines. One way is to use the ```checkpatch.pl``` script which in our case gives an error but it's probably fine since it's a URL.

```none
[hak8or@hak8or linux]$ ./scripts/checkpatch.pl --strict --codespell ../0001-clk-at91-PLL-recalc_rate-now-using-cached-MUL-and-DI.patch 
No codespell typos will be found - file '/usr/share/codespell/dictionary.txt': No such file or directory
total: 0 errors, 0 warnings, 0 checks, 20 lines checked

../0001-clk-at91-PLL-recalc_rate-now-using-cached-MUL-and-DI.patch has no obvious style problems and is ready for submission.
```

You can also run the script on the file itself, which shows issues but unrelated to our change. If you want to fix these errors, ensure that they are properly split into multiple different commits.

```none
[hak8or@hak8or linux]$ ./scripts/checkpatch.pl -f drivers/clk/at91/clk-pll.c 
WARNING: Missing or malformed SPDX-License-Identifier tag in line 1
#1: FILE: drivers/clk/at91/clk-pll.c:1:
+/*

WARNING: line over 80 characters
#103: FILE: drivers/clk/at91/clk-pll.c:103:
+                       characteristics->icpll[pll->range] << PLL_ICPR_SHIFT(id));

ERROR: open brace '{' following function definitions go on the next line
#139: FILE: drivers/clk/at91/clk-pll.c:139:
+static long clk_pll_get_best_div_mul(struct clk_pll *pll, unsigned long rate,
+                                    unsigned long parent_rate,
+                                    u32 *div, u32 *mul,
+                                    u32 *index) {

total: 1 errors, 2 warnings, 519 lines checked

NOTE: For some of the reported defects, checkpatch may be able to
      mechanically convert to the typical style using --fix or --fix-inplace.

drivers/clk/at91/clk-pll.c has style problems, please review.

NOTE: If any of the errors are false positives, please report
      them to the maintainer, see CHECKPATCH in MAINTAINERS.
```

## Who to send to

The Linux kernel development ecosystem relies heavily on mailing lists. No, this isn't like Github where you get fancy shmancy commenting, emoji's, or even doing pull requests. This is the old fashioned way which seems to work best for them, over email.

The kernel has many developers, all of whom reside in their respective mailing list. The mailing lists are split up in various catagories you can find [here](https://patchwork.kernel.org/), such as ```linux-pm``` for Linux Power Management or ```linux-clk``` for Linux Clocking.

Thankfully there is a script to help you find out who to email your changes to. In our case, since this is a single file change, simply running the ```get_maintainer.pl``` script on our changed file suffices.

```none
[hak8or@hak8or linux]$ ./scripts/get_maintainer.pl ../0001-clk-at91-PLL-recalc_rate-now-using-cached-MUL-and-DI.patch
Boris Brezillon <boris.brezillon@bootlin.com> (maintainer:ARM/ATMEL AT91 Clock Support)
Michael Turquette <mturquette@baylibre.com> (maintainer:COMMON CLK FRAMEWORK)
Stephen Boyd <sboyd@kernel.org> (maintainer:COMMON CLK FRAMEWORK)
Nicolas Ferre <nicolas.ferre@microchip.com> (supporter:ARM/Microchip (AT91) SoC support)
Alexandre Belloni <alexandre.belloni@bootlin.com> (supporter:ARM/Microchip (AT91) SoC support)
linux-clk@vger.kernel.org (open list:COMMON CLK FRAMEWORK)
linux-arm-kernel@lists.infradead.org (moderated list:ARM/Microchip (AT91) SoC support)
linux-kernel@vger.kernel.org (open list)
```

The kernel also makes use of the ```TO``` and ```CC``` fields in emails, with the first being for people most directly associated and BCC for everyone else. In our case, the divide will be like this:

```none
to:
Boris Brezillon <boris.brezillon@free-electrons.com>, Nicolas Ferre <nicolas.ferre@microchip.com>, Alexandre Belloni <alexandre.belloni@bootlin.com>

CC:
Michael Turquette <mturquette@baylibre.com>, Stephen Boyd <sboyd@kernel.org>, linux-clk@vger.kernel.org, linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
```

## Sending

Great, so we know who to send it to. What about actually sending it? We can't really use GMail since it seems to break our formatting. Instead, ```git send-email``` will be used. Sure, you can use Mutt, but it was very error prone in my experience. Configuring it is pretty straight forward, with this being my ```~/.gitconfig```.

```none
[hak8or@hak8or linux]$ cat ~/.gitconfig
[user]
        email = marcin@ziemianowicz.com
        name = Marcin Ziemianowicz
[core]
        editor = code --wait --new-window
[sendemail]
        smtpuser = marcin@ziemianowicz.com
        smtpPass = Put_your_smtp_pass_here
        smtpserver = smtp.zoho.com
        smtpencryption = tls
        smtpserverport = 587
```

First send an email just to yourself (just ```git send-email``` with the patch file and no email), with an empty TO field (CC gets populated with your email). Do this to ensure the format is correct, there are no typo's, and a last check to ensure you didn't miss something in your bugfix.

Lastly, send out the actual patch!

```none
git send-email \
      ../0001-clk-at91-PLL-recalc_rate-now-using-cached-MUL-and-DI.patch \
      --cc='Michael Turquette <mturquette@baylibre.com>' \
      --cc='Stephen Boyd <sboyd@kernel.org>' \
      --cc='linux-clk@vger.kernel.org' \
      --cc='linux-arm-kernel@lists.infradead.org' \
      --cc='linux-kernel@vger.kernel.org' \
      --to='Boris Brezillon <boris.brezillon@free-electrons.com>' \
      --to='Nicolas Ferre <nicolas.ferre@microchip.com>' \
      --to='Alexandre Belloni <alexandre.belloni@bootlin.com>' \
      --to='Greg Kroah-Hartman <gregkh@linuxfoundation.org>'
```

[Here](https://lkml.org/lkml/2018/4/29/105) is this commit in the wild on the LKML website which is great for tracking your messages. You can also use [PatchWork](https://patchwork.kernel.org/patch/10370651/) which isn't bad either.

## Replying to Mailing List

You sent it out to the kernel mailing list, and you will definitely get feedback. We can't really use GMail for this, so might as well use [Mutt](http://www.mutt.org/). Thankfully it's settings are fairly similar to the ones used for ```git send-email```. I won't go over how to configure it (which was a pain), but here is what to put in your ```~/.muttrc``` to have it work with Zoho Mail.

```none
[hak8or@hak8or linux]$ cat ~/.muttrc
set envelope_from=yes
set realname = 'Marcin Ziemianowicz'
set from="Marcin Ziemianowicz <marcin@ziemianowicz.com>"
set use_from=yes
set edit_headers=yes

set smtp_url = "smtps://marcin@ziemianowicz.com@smtp.zoho.com"
set smtp_pass = "Put your smtp_pass here!"
set ssl_force_tls = yes

set folder      = imaps://imappro.zoho.com:993
set imap_user   = marcin@ziemianowicz.com
set imap_pass   = Put_your_smtp_pass_here
set spoolfile   = +INBOX
mailboxes       = +INBOX

# Store message headers locally to speed things up.
# If hcache is a folder, Mutt will create sub cache folders for each account which may speeds things up even more.
set header_cache = ~/.cache/mutt

# Store messages locally to speed things up, like searching message bodies.
# Can be the same folder as header_cache.
# This will cost important disk usage according to your e-mail amount.
set message_cachedir = "~/.cache/mutt"

# Specify where to save and/or look for postponed messages.
set postponed = +[stuff]/Drafts

# Allow Mutt to open a new IMAP connection automatically.
unset imap_passive

# Keep the IMAP connection alive by polling intermittently (time in seconds).
set imap_keepalive = 300

# How often to check for new mail (time in seconds).
set mail_check = 120
```

Reply to everyone who messages you via the ```g``` key when having an email open, and reply to people **inside** the quotes. For example,

```none
> Some long message from a great
> kernel maintainer goes here.
>
> > Looks like they quoted yet someone else!
> > These are baiscally nested quotes.
>
> But here they ask a question?

So you reply here! See the lack of > characters?
The > character is considered to be a quote from someone else.

> And some other text from the maintainer
> goes here.
```

This is suprisingly readable actually, much better than expected.

## Summary

Yes, this is a jarring experience if you are used to the pull request systems implimented in Github or GitLab, but it actually works. Linux has been using this method for many many years and it's still going, so clearly it's doing something right. Not to mention, it seems to scale well too based on how many commits there are per day. But it still has a decent learning curve and tons of little nit-picks which don't seem to fully documented in one place.

Lastly, [here](https://lkml.org/lkml/fancy/2018/4/29/105) is my patch on the LKML website, and [here](https://patchwork.kernel.org/patch/10370647/) is the patchwork version.
