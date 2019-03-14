kill -SIGUSR1 "$(pidof enlightenment_start)"
sudo gdb enlightenment "$(pidof enlightenment)"
