# About setting up SSH for raw files transfer

The spectrometer acquisition computer should have an SSHD service running. The best way to do that is by installing Microsoft official `OpenSSH Server` system extension.

You should also replace the ssh default shell with a GNU-like one (Git Bash is quite easy to install).

When it is done, you'll want to setup key-based authentification. Generate pair of SSH keys for the workflow shell user to access spectrometer without password
```bash
# On the workflow server and user
ssh-keygen
ssh-copy-id spectrometer-user@spectrometer.server
```
You have to make sure that the spectrometer sshd accepts key-based authentification.
On Windows, if the OpenSSH Server extension is installed, you should edit the config located at `C:\ProgramData\ssh\sshd_config` and set
```
PubkeyAuthentication yes
StrictModes no
```
If **spectrometer-user** is admin (probably shouldn't) you'll have to copy the public key from `C:\Users\spectrometer-user\.ssh\authorized_keys` to  `C:\Users\spectrometer-user\.ssh\authorized_keys`

On workflow server/user,
```
Host *
    ServerAliveInterval 20
    ServerAliveCountMax 3
    ControlMaster auto
    ControlPath ~/.ssh/controlmasters/%r@%h:%p
    ControlPersist 30m

Host spectrometer.server
    User spectrometer-user
```