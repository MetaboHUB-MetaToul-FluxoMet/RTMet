# /etc/cylc/uiserver/jupyter_config.py

c.JupyterHub.internal_ssl = False
c.JupyterHub.internal_certs_location = "/etc/cylc/uiserver/internal-ssl"
c.Authenticator.allow_all = True
c.Authenticator.allow_existing_users = True

# 1. Jupyter Hub
#    Allow all authenticated users to access, start and stop
#    each other's servers
c.JupyterHub.load_roles = [
    {
        "name": "user",
        "scopes": ["self", "access:servers", "servers"],
    }
]

# 3. Cylc
#    Delegate permissions to users
c.CylcUIServer.user_authorization = {
    # provide all authenticated users with read-only access to each other's
    # servers
    "*": ["READ"],
}
