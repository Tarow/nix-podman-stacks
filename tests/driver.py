machine.wait_for_unit("multi-user.target")
machine.wait_for_unit("home-manager-ci.service")
machine.succeed("loginctl enable-linger ci")
machine.wait_until_succeeds("test -S /run/user/1000/systemd/private")
(status, output) = machine.execute(
    "su ci -c 'XDG_RUNTIME_DIR=/run/user/1000 /etc/nps-test/check.sh'",
    timeout=900,
)
print(output)
if status != 0:
    raise Exception(f"integration check failed with exit code {status}")