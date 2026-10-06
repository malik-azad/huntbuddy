# Anthem — TryHackMe Walkthrough

> **Room:** [Anthem](https://tryhackme.com/room/anthem) · **Difficulty:** Easy · **Type:** Windows / Web
> **Skills:** Reconnaissance · OSINT · Reading Source Code · Windows File Permissions
> **Author's note:** Written for beginners. Every concept is explained before it's used, and almost everything is done through a graphical interface so you can follow along on a laptop with no scripting background.

---

## TL;DR (spoilers)

<details>
<summary>Click to reveal the answers — check off as you go</summary>

**Task 1 — Website Analysis**

| Question | Answer |
|---|---|
| Open ports | `80, 3389` |
| What port is for the web server? | `80` |
| What port is for remote desktop service? | `3389` |
| Possible password in a crawler's page? | `UmbracoIsTheBest!` |
| What CMS is the website using? | `Umbraco` |
| What is the domain of the website? | `anthem.com` |
| Administrator's name | `Solomon Grundy` |
| Administrator's email | `SG@anthem.com` |

**Task 2 — Spot the Flags**

| # | Flag | Where it lives |
|---|---|---|
| 1 | `THM{L0L_WH0_US3S_M3T4}` | Page source → *We are hiring* post (`og:description` meta tag) |
| 2 | `THM{G!T_G00D}` | Page source → search box `placeholder` text (on every page) |
| 3 | `THM{L0L_WH0_D15}` | Author page → Jane Doe |
| 4 | `THM{AN0TH3R_M3TA}` | Page source → *A cheers to our IT department* post (`og:description` meta tag) |

> The questions aren't in flag-number order. If one is rejected, try it in another answer box — only TryHackMe knows the numbering.

**Task 3 — Into the box**

| Question | Answer |
|---|---|
| Username & password | `sg` / `UmbracoIsTheBest!` |
| `user.txt` | `THM{N00T_NO0T}` — on the Desktop after logging in |
| Admin password | `ChangeMeBaby1MoreTime` — inside `C:\backup\restore.txt` |
| `root.txt` | `THM{Y0U_4R3_1337}` — on the Administrator's Desktop after the second login |

</details>

---

## Before You Start

### What kind of room is this?

Anthem is a **Windows** machine that exposes exactly two things to the network: a website and a remote desktop. There is **no exploit to find and no vulnerability to weaponise**. You will not run a single exploit tool in this room.

Instead, the entire room is solved by **looking carefully at what the machine freely gives you** and connecting the pieces. That is a deliberate design choice, and it's the most valuable thing about this lab: it teaches *methodology* rather than tooling.

If you can finish Anthem by reasoning rather than by reaching for tools, you understand how real enumeration works.

### What you'll need

- **Kali Linux** (or any Linux with a terminal) — or a Windows machine with WSL
- **An active TryHackMe VPN connection** — without this, none of your traffic reaches the target
- **A web browser** — you will do most of the work here
- **An RDP client** — Remmina (Linux) or the built-in Remote Desktop app (Windows)

### Start here: give the domain a friendly name

Once your VPN is connected and the machine is started, open a terminal and run:

```bash
echo "10.49.172.250 anthem.thm" | sudo tee -a /etc/hosts
```

*(Replace `10.49.172.250` with whatever IP TryHackMe shows you. The room displays it at the top of the machine page.)*

**Why do this?** The website's internal links point back to its own domain name. If you browse using only the raw IP address, some pages will fail to load or redirect strangely. Adding a hostname mapping means every link on the site just works, and you can browse it like a normal website.

**What does this command do?**
- `echo "..."` — produce the line of text
- `sudo tee -a` — append it to a file (as root, since `/etc/hosts` is protected)
- `| sudo tee -a /etc/hosts` — pipe the text into that file

You can also open `/etc/hosts` in a text editor and add the line by hand. Either is fine.

---

## Concepts You Will Need

Nothing here is advanced. These are the only ideas the room depends on, and each one is worth knowing for every lab that follows.

| Concept | What it means, in one line |
|---|---|
| **Reconnaissance** | Gathering information about a target *before* you try to attack it. |
| **Enumeration** | The systematic listing of what a machine actually has — ports, services, files, users. |
| **Port** | A numbered doorway on a machine. Each one belongs to a different service. |
| **Service** | The software listening on a port (for example, a web server or a remote desktop server). |
| **Web server** | Software that serves web pages over HTTP, normally on port `80`. |
| **CMS (Content Management System)** | Ready-made website software such as WordPress, Joomla or Umbraco. A CMS is worth identifying early, because it tells you what the site is built from and where its admin panel lives. |
| **`robots.txt`** | A text file a website owner writes to tell search-engine crawlers which folders not to index. Humans are not supposed to read it — which is exactly why it is so useful. |
| **View Page Source** | The raw HTML your browser received from the server, before it draws anything. Anything hidden on a page still exists here. |
| **OSINT (Open-Source Intelligence)** | Information about a target gathered from public sources — search engines, public records, social media. Here, a poem is all it takes. |
| **RDP (Remote Desktop Protocol)** | Windows' protocol for connecting to a full graphical desktop, normally on port `3389`. |
| **NLA (Network Level Authentication)** | The requirement to supply valid credentials *before* an RDP session starts. |
| **Privilege escalation** | Gaining *higher* rights on a system you can already access. You log in as a normal user, then find a way to become an administrator. |
| **ACL / DACL (Access Control List)** | The list attached to a file that records who is allowed to read, write or change it. |
| **File owner** | The account that owns a file. The owner always holds an implicit right to *change the permissions*, even when the permission list grants them nothing. |
| **Hidden attribute** | A flag that stops Explorer from *displaying* a file. It does **not** prevent you from opening it. |
| **Port scanning** | Probing every port to see which ones answer. `nmap` is the tool that does it. |
| **Brute forcing** | Trying many passwords against a login until one works. Powerful, slow, and completely unnecessary in this room. |

---

## Step 1 — Reconnaissance: What Is Actually Running Here?

> **Concept — reconnaissance:** you never attack a machine you haven't properly looked at. First you build a picture of it, and then you let that picture decide what to do.

Open a terminal. Your first act is to ask the machine: *which doors are open, and who is answering?*

```bash
sudo nmap -sC -sV -A -Pn 10.49.172.250
```

### What each flag means

| Flag | Meaning |
|---|---|
| `-sC` | Run Nmap's default scripts — small automated checks. One of them automatically fetches `robots.txt` for you. |
| `-sV` | Detect software **versions**, not just "this port is open". |
| `-A` | *Aggressive* mode — a convenient bundle of version detection, OS guessing, traceroute and the default scripts. |
| `-Pn` | **Do not ping the host first. Go straight to probing ports.** |

### Why `-Pn` is not optional on this machine

This is worth understanding properly, because it's the most common beginner mistake in pentesting.

Run that exact command **without** `-Pn` and you get this:

```
Note: Host seems down. If it is really up, but blocking our ping probes, try -Pn
Nmap done: 1 IP address (0 hosts up) scanned in 2.60 seconds
```

The machine is perfectly healthy. It simply **ignores ICMP ping**, which Windows does by default as a firewall behaviour. Without `-Pn`, Nmap trusts the failed ping and reports "zero hosts up" — and you would wrongly conclude the target is unreachable and give up.

**The lesson:** *a failed ping does not mean a dead host.* Only a failed port probe does. On Windows targets, always use `-Pn`.

You can prove this to yourself right now. In the same terminal, run:

```bash
ping -c 3 10.49.172.250
```

It will report 100% packet loss. Then run the `-Pn` scan and watch it find two open ports on the "dead" machine.

### Reading the results

```
PORT     STATE SERVICE       VERSION
80/tcp    open  http          Microsoft HTTPAPI httpd 2.0
| http-robots.txt: 4 disallowed entries
|_/bin/ /config/ /umbraco/ /umbraco_client/
3389/tcp  open  ms-wbt-server Microsoft Terminal Services
| ssl-cert: Subject: commonName=WIN-LU09299160F
| rdp-ntlm-info:
|   NetBIOS_Domain_Name: WIN-LU09299160F
|   NetBIOS_Computer_Name: WIN-LU09299160F
|   Product_Version: 10.0.17763
Service Info: OS: Windows
```

Five things to take from this output:

**1. Only two services exist.** A web server on `80` and Remote Desktop on `3389`.

**2. Read what is *missing*, not just what is there.** No `445` (no SMB file sharing), no `5985` (no remote PowerShell), no `22` (no SSH). Each absent service removes an entire category of attack from your plan. Knowing the shape of what's missing saves you from wasting time on techniques that cannot possibly work.

**3. `ms-wbt-server` is Remote Desktop.** You don't need to memorise port numbers — the `SERVICE` column tells you in plain words. Nmap has a lookup table for this.

**4. `NetBIOS_Domain_Name` equals the computer name.** This is a strong signal that the machine is **not joined to a domain** — it's a standalone computer. Make a note of this, because it changes how you type the username in Step 5. Getting it wrong looks *exactly* like a wrong password.

**5. `10.0.17763` is Windows Server 2019**, and the hostname leaked in the TLS certificate is `WIN-LU09299160F`. Certificates routinely hand out more information than their owners intended.

> **Note:** Nmap's script already printed the `robots.txt` contents for you under the port 80 entry. We'll read it properly in the next step anyway, because knowing how to find it yourself matters more than having it handed to you.

---

## Step 2 — Read `robots.txt`

> **Concept:** most people only visit a website's visible pages. `robots.txt` is a file the *owner* wrote specifically for automated software — and they never expected a human to read it.

Open your web browser and go to:

```
http://10.49.172.250/robots.txt
```

You should see:

```
UmbracoIsTheBest!

# Use for all search robots
User-agent: *

# Define the directories not to crawl
Disallow: /bin/
Disallow: /config/
Disallow: /umbraco/
Disallow: /umbraco_client/
```

**Three free wins from six lines:**

1. **`UmbracoIsTheBest!`** — a plaintext password sitting in the open, on a page the website owner thought was invisible to people.
2. **`/umbraco/`** — the path to the site's admin panel.
3. **The CMS name** — you did not need a fingerprinting tool or a database of software signatures. The website told you exactly what it runs, in a file most people never open.

> **The lesson:** *always read `robots.txt` before you consider brute-forcing anything.* It is the highest-value single URL on almost every web application, and reaching for a directory-busting tool against a site that has just handed you its own structure is wasted minutes. Tools are for filling gaps — not for replacing careful reading.

To confirm the admin panel really exists, visit:

```
http://10.49.172.250/umbraco/
```

You'll be met with an **Umbraco** login page that helpfully states: *"Your username is usually your email."* Keep that in mind — it confirms what we work out in Step 3.

---

## Step 3 — Work Out Who the Administrator Is

> **Concept — OSINT:** some answers are not inside the target at all. Public information — search results, public records — is a legitimate and often decisive source of intelligence.

The Umbraco login page wants an email address. We have a password, but no username. The website never states one. Time to actually read the site.

Open `http://10.49.172.250/` in your browser. It's a small blog with two posts.

### Post one — "We are hiring"

Read it and you'll find the author's contact address in the post body:

```
jd@anthem.com
```

The author is **Jane Doe**. Look at how that address is built: the **first initial** and the **last initial** of her name, then the domain — `J`ane `D`oe → `JD` → `jd@anthem.com`.

Hold onto that. It's the key to the next step.

### Post two — "A cheers to our IT department"

This post is a tribute to the website administrator, written as a poem. It reads:

> *Born on a Monday, Christened on Tuesday,*
> *Married on Wednesday, Took ill on Thursday,*
> *Grew worse on Friday, Died on Saturday,*
> *Buried on Sunday.*
> *That was the end…*

**Do not try to guess a name from that.** The correct move is to **search the poem.** Copy the distinctive line — *"Born on a Monday, Christened on Tuesday"* — into a search engine.

You'll find it's the old nursery rhyme **"Solomon Grundy"**, a short cautionary rhyme about a man who had a wonderful life and then, abruptly, was finished. The author of the blog post is not the administrator; the poem is written *about* them.

**The administrator is Solomon Grundy.**

### Deriving the email address

Now apply the pattern you learned from Jane Doe. You are not guessing — you are *deriving from a real sample the target gave you*:

| Person | Pattern | Email |
|---|---|---|
| Jane **D**oe | first initial + last initial + `@anthem.com` | `jd@anthem.com` |
| **S**olomon **G**rundy | first initial + last initial + `@anthem.com` | **`SG@anthem.com`** |

**Verify it yourself:** the Umbraco login page said *"your username is usually your email"*, so go to `http://10.49.172.250/umbraco/` and sign in with:

- **Email:** `SG@anthem.com`
- **Password:** `UmbracoIsTheBest!`

You should land in the CMS admin dashboard. Most of the flags in Task 2 are also visible from inside here, if you'd like to poke around.

> **The lesson:** *never invent a username format when the target has already demonstrated one.* Find a real example, work out the rule, apply it. This is faster, and it is dramatically more reliable than guessing — and the Umbraco login working is your proof.

---

## Step 4 — The Four Flags

> **Concept — "hidden" vs "view source":** a web page you see in a browser is a *rendering* of the HTML that the server actually sent. Anything on the page — including text scrolled out of sight, colour-matched text, or data tucked into attributes — is still sitting in that HTML. `Ctrl+U` shows you the real thing.

### The graphical way

For each page, open it in your browser and press:

- **`Ctrl` + `U`** — view the page source (on a Mac, `Cmd` + `Option` + `U`)
- Then **`Ctrl` + `F`** and search for `THM{`

The flag format is always `THM{...}`, so this finds them instantly. Walk through the site's pages like this:

**1. The homepage** — `http://anthem.thm/`

Search for `THM{`. You'll find it inside the search box's HTML:

```html
<input type="text" name="term" placeholder="Search...          THM{G!T_G00D}" />
```

That text is in the `placeholder` attribute — the grey prompt text inside the search box. It's padded with spaces so that it sits **far off the visible edge of the box**, which is why you've never seen it on screen. It's rendered, just not *visible*.

**2. "We are hiring" post** — `http://anthem.thm/archive/we-are-hiring/`

Search for `THM{` and you'll find it in a metadata tag near the top of the document:

```html
<meta content="THM{...}" property="og:description" />
```

**3. "A cheers to our IT department" post** — `http://anthem.thm/archive/a-cheers-to-our-it-department/`

Same trick — a `og:description` meta tag contains the flag.

**4. The author page** — click through to **Jane Doe** (or go to `http://anthem.thm/authors/jane-doe/`)

This one isn't even hidden. It's printed as plain visible text on the page, right under her name, next to the word "Website:". It's the easiest of the four, and it's the one that teaches you the flag format (`THM{...}`) that the other three searches depend on.

**So find Jane Doe's flag first.** It shows you what a flag looks like, and then `Ctrl+F` for `THM{` works everywhere else.

### The terminal shortcut (optional)

If you'd rather not read through raw HTML by eye, this finds the flags for you:

```bash
curl -s http://10.49.172.250/ | grep -o "THM{[^}]*}"
```

| Part | Meaning |
|---|---|
| `curl -s` | Fetch the page quietly, without a progress bar. |
| `grep -o` | Print **only** the matched text, not the whole line. |
| `THM{` | A literal `{` — the backslash stops it being read as a regex operator. |
| `[^}]*` | "Any character that isn't `}`" — this is what makes the match stop cleanly at the end of the flag. |

To sweep every page at once, a small loop does the work:

```bash
for page in "/" "/archive/we-are-hiring/" "/archive/a-cheers-to-our-it-department/" "/authors/jane-doe/"; do
  printf "%-42s " "$page"
  curl -s "http://10.49.172.250$page" | grep -o "THM{[^}]*}" | tr '\n' ' '
  echo
done
```

**What this loop is doing, in plain English:** for each web page, print the page name, fetch it, keep only the flag-shaped text, put the results on one line, then move to the next page.

The output looks like this:

```
/                                          THM{G!T_G00D}
/archive/we-are-hiring/                    THM{L0L_WH0_US3S_M3T4} THM{G!T_G00D}
/archive/a-cheers-to-our-it-department/    THM{AN0TH3R_M3TA} THM{G!T_G00D}
/authors/jane-doe/                         THM{G!T_G00D} THM{L0L_WH0_D15}
```

**Read that output carefully — it earns its keep.** Three of the flags appear on only one page each, so they're clearly stored in that specific page. But one flag — `THM{G!T_G00D}` — appears on **every single page**. That's the useful deduction: a value present *everywhere* isn't stored in any page. It lives in the site's **template**, which is why it's the search box placeholder. You worked that out from evidence rather than assumption.

> **TryHackMe tip:** the questions in Task 2 aren't in flag-number order, and the site won't tell you which flag belongs to which question. If one is rejected, simply try it in another answer box. Only TryHackMe can confirm the numbering.

---

## Step 5 — Getting In: Remote Desktop

> **Concepts:** *RDP* (Remote Desktop Protocol) is how you get a full graphical Windows desktop on another machine, normally on port `3389`. *NLA* (Network Level Authentication) means RDP asks for and validates your credentials **before** it shows you the desktop — so a wrong username format fails here exactly like a wrong password would.

We have everything we need:

| Field | Value | Where it came from |
|---|---|---|
| IP | `10.49.172.250` | TryHackMe |
| Username | `sg` | Derived in Step 3 |
| Password | `UmbracoIsTheBest!` | `robots.txt`, Step 2 |

### The one detail that trips everyone up

Use **`sg`**.

Not `sg@anthem.com`. Not `anthem\sg`. Just **`sg`**.

The room tells you *"the box is not on a domain"*, and Nmap independently confirmed it in Step 1 — the `NetBIOS_Domain_Name` matched the computer name, which only happens on a standalone machine.

| Situation | Correct username format |
|---|---|
| **Standalone / workgroup — this box** | **`sg`** |
| Joined to a Windows domain | `DOMAIN\user` or `user@domain.local` |
| Logging into the Umbraco web app | `SG@anthem.com` |

This matters more than it looks. If you get the format wrong, the error message is identical to a wrong password — and a great many people abandon this room believing the password is wrong when it was the username all along.

### Connecting — graphically, with Remmina

Remmina is the RDP client that comes pre-installed on Kali. It's a windowed app, so there is nothing to memorise:

1. Open the **Remmina** application (search for it in your applications menu)
2. Click the **"+"** button at the top right to create a new connection profile
3. Fill in the **Name** field with something like `Anthem`
4. **Server**: `10.49.172.250`
5. **Username**: `sg`
6. **Password**: `UmbracoIsTheBest!`
7. Leave **Domain** **empty** — this is a standalone machine, so there is no domain to join
8. Set **Security** to `Negotiate` (the default) — this is what makes NLA work
9. Click **Connect**
10. When it asks whether you trust the certificate, choose **Yes** — the machine uses a self-signed certificate, which is normal for a lab

Within a second or two you'll be looking at the Windows desktop.

### Connecting from the command line

If you prefer the terminal, the same connection is one line:

```bash
xfreerdp /v:10.49.172.250 /u:sg /p:'UmbracoIsTheBest!' /cert:ignore
```

| Part | Meaning |
|---|---|
| `/v:` | The server (target) IP address |
| `/u:` | Username |
| `/p:` | Password |
| `/cert:ignore` | Skip the certificate warning (fine in a lab) |
| `+clipboard` | Add this to share your clipboard both ways — genuinely useful |

`rdesktop -u sg 10.49.172.250` is another common client that works equally well.

### The user flag

You're in as `sg`, and **`user.txt` is sitting on the Desktop**. Double-click it to read the flag and submit it.

---

## Step 6 — Privilege Escalation

> **Concept — privilege escalation:** you are now logged in, but as an ordinary user. Privilege escalation is the process of gaining *higher* rights on a machine you already have access to — usually from a normal user up to an administrator. There are two broad ways: find a flaw in the software, or find a mistake in how the system is **configured**. This room is the second kind, and the mistake is a beautiful one.

To read `root.txt` you need to become **Administrator**. The room asks *"Can we spot the admin password?"* with the hint *"It is hidden."*

So: go and look for something hidden.

### Step 6a — Find the hidden folder

Open **File Explorer** and navigate to `C:\`.

Nothing looks unusual. But remember the hint: *"It is hidden."*

**Show the hidden files:**

1. In File Explorer, click the **View** tab at the top
2. On the far right, click **Options** (or **Show** → **Hidden items** → tick it)
3. In the dialog that appears, select **"Hidden files, folders, and drives"** and click **OK**

Now go back to `C:\`. A folder named **`backup`** has appeared.

**What just happened?** Every file and folder in Windows has an attribute — a small flag stored with the file. One of them is the *hidden* attribute. It does nothing to protect the file. It only tells File Explorer to leave it out of the listing, so that ordinary users don't stumble across it.

> **Worth internalising:** *hidden does not mean protected.* It hides from the eye, not from the filesystem. If you know the path, you can open it directly without changing any settings at all.

Open **`C:\backup\`** and you'll find **`restore.txt`**.

### Step 6b — Try to open it, and understand the failure

Double-click `restore.txt`. You get **access denied**.

Before reaching for tools, work out *why*. This is the most valuable five minutes in the room.

Right-click `restore.txt` → **Properties** → the **Security** tab.

You'll see something strange: the list of users and groups who can access this file is **completely empty**. Nobody has any permission. Not the Administrators group, not SYSTEM, not you.

**And yet the file has an owner.** (Still on the Security tab, near the top, it says something like *"Owner: SG"*.)

**Here's the flaw in Windows' permission model.** File access is controlled by two separate things:

- The **DACL** (Discretionary Access Control List) — the list of who gets which permissions. On this file, that list is empty.
- The **owner** — and Windows always gives the owner an *implicit* right to **change the permissions**, no matter what the DACL says.

Think about what the administrator actually did here. They locked this file down so thoroughly that **no account at all** could read it — and in the process, they **made your user account the owner.** So the "security measure" handed you the exact key needed to undo it.

This is a misconfiguration, not a software vulnerability. Nothing is exploitable and no patch fixes it. It is simply a mistake — and this exact mistake, a sensitive file locked down but owned by the wrong account, appears constantly in real Windows penetration tests.

> **The transferable habit:** *always check **why** you have access, not just whether you do.* Ownership is frequently the whole attack.

### Step 6c — Fix it: the graphical method

You're going to use the owner privilege you just discovered. Still on the **Security** tab:

1. Click **Edit…** (this button is available to you precisely *because* you own the file)
2. In the permissions window, click **Add…**
3. Type `SG` in the box and click **Check Names** — this confirms the account exists
4. Tick the **Full control** checkbox under basic permissions
5. Click **OK**
6. Click **Apply**, then **OK** a couple more times to close everything

Now **double-click `restore.txt`** and it opens.

**Read it carefully:**

```
ChangeMeBaby1MoreTime
```

That's the Administrator password.

### Step 6d — Fix it: the command-line method (a useful alternative)

There's a command-line equivalent of that Security tab. Open PowerShell — press **`Windows key` + `R`**, type `powershell`, and press Enter. (The Run dialog exists on every Windows machine, so this works even on a bare desktop with no shortcuts on it.)

```powershell
icacls "C:\backup\restore.txt" /grant SG:F
```

| Part | Meaning |
|---|---|
| `icacls` | Windows' built-in permission editor — the terminal version of the Security tab |
| `/grant` | Add a permission entry |
| `SG:F` | Grant the user **SG** the permission **F** = **Full control** |

Then read the file:

```powershell
Get-Content C:\backup\restore.txt
```

> **Two practical notes.** First, you can skip the "show hidden files" step completely if you want — just type `C:\backup\restore.txt` into Explorer's address bar and press Enter. To *find* hidden items from a terminal instead, use `Get-ChildItem C:\ -Hidden`. Second, if you try PowerShell's `Set-Acl` on this file it will **fail**, because that cmdlet looks for an explicit *Change permissions* entry in the DACL — and the DACL is empty. `icacls` uses the owner's implicit right and succeeds. Knowing that difference between the two tools will save you a very confusing twenty minutes on a harder machine.

---

## Step 7 — Root

Now log out of the remote session and reconnect using the Administrator account.

**With Remmina:** open the connection, change the **Username** to `administrator` and the **Password** to `ChangeMeBaby1MoreTime`, then connect.

**From the terminal:**

```bash
xfreerdp /v:10.49.172.250 /u:administrator /p:'ChangeMeBaby1MoreTime' /cert:ignore
```

| Part | Meaning |
|---|---|
| `/u:` | Username |
| `/p:` | Password |

The window will be a **different desktop** — you'll notice Administrator's wallpaper and a different set of icons, because you are now logged in as a different user with different rights.

**`root.txt` is on the Desktop.** Open it, read the flag, and submit it.

**Room complete.**

---

## What This Room Actually Teaches

**1. A failed ping does not mean a dead host.** Windows ignores ICMP by default. Always use `-Pn` on Windows targets, and trust port results over ping results. This one habit can be the difference between solving a box and abandoning it.

**2. Read `robots.txt` first, always.** It is authored *for* you. On this machine it delivered a password, a CMS name and the admin panel path in six lines. Tools should fill gaps you can't close by reading — they shouldn't replace reading.

**3. Derive, don't guess.** `JD@anthem.com` for Jane Doe gave you the format; applying it produced `SG@anthem.com`. A real example from the target is always better evidence than any guess you could invent.

**4. OSINT is real enumeration.** A children's nursery rhyme, found with a search engine, identified the administrator. Not every answer lives inside the target.

**5. Credential format depends on domain membership.** `sg` versus `DOMAIN\sg`. This produces an error message indistinguishable from a wrong password, and it stalls people regularly.

**6. Ownership is a security boundary that frequently isn't one.** The owner holds an implicit *Change permissions* right even when the ACL grants nothing at all. Here, the over-restrictive lock-down **created** the weakness. `icacls` and `Get-Acl` are worth learning properly — they appear in a large share of real Windows engagements.

**7. Hidden is a display setting, not a security control.** Every file in that hidden folder was reachable the entire time. Turning on "show hidden files" is a convenience for *browsing*; it has no effect on *access*.

**8. This room contained no exploit — and that was the point.** Six flags, zero vulnerabilities, no payloads, no shell. The whole box fell to observation and reasoning. Real penetration testing is overwhelmingly this, and the tools are secondary.

---

## Methodology Notes

The order of operations used here wasn't arbitrary. Each step was chosen because the previous one made it the *cheapest useful next move*:

```
Scan ports
   └─ told me: only a web server and RDP exist
        └─ so no SMB, no WinRM, no SSH — those attack paths are dead, skip them
             └─ so the website is the only place to gather information
                  └─ robots.txt gave a password + CMS + admin path for free
                       └─ so no directory brute-forcing was needed
                            └─ so read the blog posts for the admin's identity
                                 └─ search engine gave the name, a real email gave the pattern
                                      └─ so RDP credentials were complete
                                           └─ so log in and look for the admin password
                                                └─ the owner could change the file's permissions
```

Two principles did most of the work:

- **Cheapest move that could be wrong, first.** Six lines of `robots.txt` beat minutes of directory brute-forcing. A top-1000-port scan beats a full 65,535-port scan — and you escalate only when the story doesn't add up.
- **Read every output for decisions, not just for data.** The `NetBIOS_Domain_Name` line in the very first scan told you to use `sg` rather than `sg@anthem.com` — roughly forty minutes before that detail became necessary. The flag appearing on every single page told you it lived in the template rather than in a page.

---

## Tools Used

| Tool | Purpose |
|---|---|
| **Nmap** | Port scanning, service and version detection, light OS fingerprinting |
| **Web browser** | All of the web reconnaissance, OSINT, and reading page source |
| **Ctrl+U / View Page Source** | Reading the HTML the server actually sent |
| **Remmina** (or `xfreerdp`, `rdesktop`) | Remote Desktop client |
| **File Explorer** | Enabling hidden files, and the Properties → Security permissions dialog |
| **PowerShell / `icacls`** | Command-line alternative for the permissions change |
| **`curl` + `grep`** *(optional)* | Terminal shortcut for pulling flags out of page source |

Nothing exotic. That's the point.

---

## Screenshots to Include

If you're publishing this as a blog post, these are the images that make it a story rather than a wall of text. Capture them as you go.

| # | What to capture | Why it earns its place |
|---|---|---|
| 1 | The **failed** scan without `-Pn`, showing *"Host seems down"* | The single most useful moment in the room — makes the `-Pn` lesson land |
| 2 | The **successful** scan with `-Pn` | The payoff; shows only 80 and 3389 open |
| 3 | `robots.txt` open in the browser, password circled | Three answers in one image |
| 4 | The "We are hiring" post showing `jd@anthem.com` | Evidence for the email-pattern deduction |
| 5 | The poem post | The OSINT breadcrumb |
| 6 | A search engine result for "Solomon Grundy" | Proves the name came from research, not guessing |
| 7 | `Ctrl+U` view with a flag highlighted inside a `og:description` meta tag | Demonstrates the page-source technique |
| 8 | The search box, zoomed, showing the off-screen placeholder flag | The cleverest find in the room |
| 9 | The terminal loop output table | All four flags and their pages, at a glance |
| 10 | The RDP desktop with `user.txt` open | Proof of initial access |
| 11 | `restore.txt` showing "access denied", then the **Security** tab with the empty permission list | The reasoning that makes the privesc understandable |
| 12 | The permissions dialog with `SG` added and Full control ticked | The fix, in progress |
| 13 | `restore.txt` open showing the Administrator password | The turning point of the room |
| 14 | The final Administrator desktop with `root.txt` | The finish |

**Presentation notes:** crop tightly to the part that matters — a red box around one line beats a full-screen dump. Use a readable font size. Add captions that explain *why* an image exists, not merely what it shows. And if you republish screenshots elsewhere, check that nothing identifying needs redacting.

---

*Anthem is an educational TryHackMe room. The techniques covered here — service enumeration, reading `robots.txt`, OSINT, and Windows file-permission analysis — are standard offensive-security fundamentals, and are equally applicable to systems you are legally authorised to test. Always practise only on systems you own or have explicit written permission to assess.*
