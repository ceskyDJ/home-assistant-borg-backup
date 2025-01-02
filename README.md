# Borg-based Backup for Home Assistant

## About

Home assistant is a very nice system, but every system can crash or disks it resides on can stop spinning eventually.
So we need to keep configuration and data safe with some kind of backup, this add-on provides exactly that.
You can find more about BorgBackup at [BorgBackup's website](https://www.borgbackup.org/).

This add-on provides a few things:
- automation of backups,
- compression of backups,
- deduplication of backups.

The first part is done by home assistant itself, but the last two are benefits that
[BorgBackup](https://www.borgbackup.org/) provides.

This add-on is a fork of [bmanojlovic/home-assistant-borg-backup](https://github.com/bmanojlovic/home-assistant-borg-backup).
So, big thanks go to [bmanojlovic](https://github.com/bmanojlovic)!



## Installation

Installation consists of these steps:

1) Add repository https://github.com/ceskyDJ/home-assistant-addons into supervisor's add-ons store.
    See [official guide](https://www.home-assistant.io/common-tasks/os#installing-a-third-party-add-on-repository) for help.
2) Install Borg-Backup add-on.
3) Configure add-on (see [Add-on Configuration](#add-on-configuration)).
4) Add a generated public SSH key to target Borg repository's server (see [SSH Key Authentication](#ssh-key-authentication)).
5) Set up automatic backing up via Home Assistant's automation (see [Setup Automation](#setup-automation)).


### Add-on Configuration

This section describes how to properly configure this add-on.

#### Path to Borg Repository

You need to specify a path to Borg repository you want to use.
This is just SSH credentials and path to the folder, where borg repository should be stored at the server.
It could look to something like (for Hetzner's StorageBox):
```yaml
borg_hostname: u100000-sub1.your-storagebox.de
borg_user: u100000-sub1
borg_repo_name: /./home-assistant
```

If you have some special requirements for SSH connection (e.g., different port), you can set a list of SSH arguments.
It could look like this for Hetzner's StorageBox:
```yaml
borg_ssh_params: -p 23
```
This is optional, so configure it ONLY in case you need to, and you know what you are doing!
If you configure add-on from GUI, you need to toggle on the "Show unused optional configuration options" option.

#### Passphrase

Now, insert some (prefer randomly generated) string that will be used as passphrase for encryption:
```yaml
borg_passphrase: some-random-string---CHANGE-IT!
```

#### Configuration Done

When you have filled all the required fields, you're done here!
Feel free to run the add-on and go to Logs, as there you will find generated public key you will need in the next step.

### SSH Key Authentication

This add-on uses SSH key authentication, when logs in to Borg repository.
It automatically generates its keypair, so all you need to do is add generated public key to Borg repository's server.

When first run, add-on will provide a generated SSH key in its logs. It looks like this:
```
[00:01:07] INFO: Your ssh key to use for borg backup host
[00:01:07] INFO: ************ SNIP **********************
ssh-rsa AAAAB3N... root@local-borg-backup
[00:01:07] INFO: ************ SNIP **********************
```

Alternatively you could find the key under `/addon-config/XXXXXXXX_borg_backup/keys/borg_backup.pub`.
You need to have SSH access to Home Assistant instance or some other way, how to access add-on config directory.

#### Adding Key to the Server

You need to add the copied key to the server somehow.
There is no definitive guide for this.
You need to google a bit or see documentation of your Borg repository's provider.

For Hetzner's StorageBox you can use this list of SSH commands that should be run from some Unix-like terminal
(of course you need to replace `u100000-sub1` with your StorageBox's account name):

- `cd /tmp`
- `nano id_borg_backup.pub`
- Paste the copied public key here and save editor (CTRL + X, Y, ENTER)
- `cat ./id_borg_backup.pub | ssh -p 23 u100000-sub1@u100000-sub1.your-storagebox.de install-ssh-key`
- `rm id_borg_backup.pub`

You can find Hetzner's official guide here: https://docs.hetzner.com/storage/storage-box/backup-space-ssh-keys/.

#### Public SSH Key Added to the Server

If you are done with adding the public key to the server, where you host your Borg repository, you are definitely done
with configuration at the add-on side.
Now turn on the add-on one more time and go to Logs again.
If it succeeded (no error message will be there, and you will see "End borg create --stats..."), you can continue
to next step.

### Setup Automation

You need to create new automation to run backups regularly in an automated manner.

Go to [Automations & scenes](https://my.home-assistant.io/redirect/automations) in your Home Assistant instance.
You can click on the link or go to Settings --> Automations & scenes.

Create new automation by following this guide:

1) Click the "CREATE AUTOMATION" button to open the Create automation dialog.
2) Click the "Create new automation" button to create automation from scratch.
3) Click the "ADD TRIGGER" button.
4) Search for "Time" (start typing until you see "Time" in the list) and select it from the list (click on it).
5) Set the time you want to automatically create Borg backups (e.g. `02:02:02`).
6) Scroll down a bit and click on "ADD ACTION" button.
7) Search for "Start add-on" and select "Home Assistant Supervisor: Start add-on" from the list (click on it).
8) Click into the "Add-on" field and select "Borg-based Backup for Home Assistant" from the list.
9) Click the "SAVE" button.
10) Give automation a name, e.g., `Automatic Borg backup` and optionally a description.
11) Click the "SAVE" button.

Now, you should have everything set up!



## Issues and Troubleshooting

If you encounter any problems during the guided installation setup, feel free to create
[issue on GitHub](https://github.com/ceskyDJ/home-assistant-borg-backup/issues).
Of course, you can use GitHub issues for feature requests or general bug reporting, too.
