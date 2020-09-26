#include <stdio.h>
#include <signal.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/wait.h>

static void term(int sig)
{
    printf("Received signal %d\n", sig);
}

int main()
{
    pid_t   pid;
    int     status;

    puts("Waiting for container stop...");
    fflush(stdout);
    signal(SIGTERM, term);
    siginterrupt(SIGTERM, 1);
    while ((pid = waitpid(-1, &status, 0)) > 0)
    {
	printf("Process with PID=%d ", pid);
	if (WIFEXITED(status))
	    printf("exited with status=%d\n", WEXITSTATUS(status));
	else if (WIFSIGNALED(status))
	    printf("killed by signal %d\n", WTERMSIG(status));
	else if (WIFSTOPPED(status))
	    printf("stopped by signal %d\n", WSTOPSIG(status));
	else if (WIFCONTINUED(status))
	    printf("continued\n");
	else
	    printf("ended with status=0x%X\n", status);
    }
    if (errno == ECHILD)
	puts("No more process to wait for");
    else if (errno == EINTR)
	puts("Interrupted by a signal");
    else
	printf("Got errno=%d\n", errno);

    return 0;
}
