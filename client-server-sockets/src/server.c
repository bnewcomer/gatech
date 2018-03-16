#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <string.h>
#include <time.h>

#define BUFFER_BYTES 100
#define SERVER_LOG "./server.log"
#define MAX_CONNECTIONS 5
#define LOG_SERVER_OPEN "--------------------\n"

char* timestamp();
void current_time(char *buffer, int buffer_size);
void current_weather(char *buffer, int buffer_size);
void close_conn(int sockfd, FILE *logfd);
int close_server(int sockfd, FILE *logfd);
int handle_conn(struct sockaddr *addr, int sockfd, FILE *logfd);
int runserver(int port_num);

/**
 * timestamp() returns the current time.
 *
 * taken from http://stackoverflow.com/
 * questions/9596945/how-to-get-
 * appropriate-timestamp-in-c-for-logs
 */
char *timestamp() {
    
    // get current system time
    time_t ltime = time(NULL);
    char *cur_time = asctime(localtime(&ltime));

    // remove trailing newline
    int len = strlen(cur_time);
    cur_time[len - 1] = 0;

    return cur_time;
}

/**
 * current_time places the current time into
 * the buffer given by char *buffer.
 */
void current_time(char *buffer, int buffer_size) {
    char *cur_time = timestamp();
    strncpy(buffer, cur_time, buffer_size);
}

/**
 * current_weather places the current weather into
 * the buffer given by char *buffer.
 */
void current_weather(char *buffer, int buffer_size) {

    char *weather[5];
    weather[0] = "cloudy :(";
    weather[1] = "sunny :D";
    weather[2] = "thunderstorm!";
    weather[3] = "TORNADO";
    weather[4] = "global warming...";

    int option = ((int) time(NULL)) % 5;
    char *cur_weather = weather[option];

    strncpy(buffer, cur_weather, buffer_size);
}

/**
 * close_conn takes in a socket descriptor and log
 * file descriptor and closes the socket using the close()
 * system call.
 */
void close_conn(int sockfd, FILE *logfd) {
	close(sockfd);
}

/**
 * close_server shuts down the server
 * instance by logging the action and
 * then calling close_conn on the 
 * server socket
 */
int close_server(int sockfd, FILE *logfd) {

    // log server closing
    fprintf(
        logfd, 
        "server instance closed %s\n", 
        timestamp()
    );

    close(sockfd);
    return 0;
}

/**
 * handle_conn() takes in a socket descriptor
 * and log file descriptor. It receives one message
 * using the socket, parses the message, and sends
 * a response on the same socket. Returns 0 after
 * socket is closed. Returns 1 if an error is
 * encountered.
 */
int handle_conn(struct sockaddr *addr, int sockfd, FILE *logfd) {

    // log new connection
    struct sockaddr_in *addr_in = (struct sockaddr_in *) addr;
    int client_port = addr_in->sin_port;
    char *client_ip = inet_ntoa(addr_in->sin_addr);
    fprintf(logfd, 
        "new connection opened: %s:%d\n",
        client_ip,
        client_port
    );

	char send_buffer[BUFFER_BYTES];
    char recv_buffer[BUFFER_BYTES];
	int msg_size, send_result;

	// initialize buffer
	memset(recv_buffer, 0, BUFFER_BYTES);

	// receive request
    while ((msg_size = read(
    	sockfd, 
    	recv_buffer, 
    	BUFFER_BYTES
    ))) {

        if (msg_size < 0) {
            perror("error receiving request");
            return 1;
        }

        // log request
        fprintf(logfd, "request received: %s\n", recv_buffer);

        // parse and respond to request
        if (strncmp(
                recv_buffer, 
                "GET time", 
                strlen("GET time")
            ) == 0) {
            current_time(send_buffer, BUFFER_BYTES);
        } else if (strncmp(
                recv_buffer, 
                "GET weather", 
                strlen("GET weather")
            ) == 0) {
            current_weather(send_buffer, BUFFER_BYTES);
        }

        // send response
        send_result = write(
            sockfd, 
            send_buffer, 
            strlen(send_buffer)
        );
        if (send_result < 0) {
            perror("error sending");
            return 1;
        }

        // log response
        fprintf(logfd, "response sent: %s\n", send_buffer);

        // erase recv_buffer
        memset(recv_buffer, 0, BUFFER_BYTES);
    }

    // close client connection
    fprintf(logfd, "connection terminated by client\n");
    close_conn(sockfd, logfd);
    return 0;
}

/**
 * runserver() initailizes a server using the
 * sockets interface.
 */
int runserver(int port_num) {

	int server_sock, client_sock, pid;
	int bind_result, listen_result, close_result;
	struct sockaddr_in server_addr;
	struct sockaddr client_addr;
	socklen_t client_len;
	FILE *logfd;

	// open log file, append only
	logfd = fopen(SERVER_LOG, "a");
    if (logfd < 0) {
		perror("error opening log file");
		return 1;
	}

    // log new server instance
    fprintf(
        logfd, 
        "%s"
        "server instance started %s\n"
        "listening on port %u...\n", 
        LOG_SERVER_OPEN, 
        timestamp(), 
        port_num
    );

	// create server socket
	server_sock = socket(AF_INET, SOCK_STREAM, 0);
	if (server_sock < 0) {
		perror("error opening socket");
		return 1;
	}

	// create server address struct
	memset(&server_addr, 0, sizeof(server_addr));
	server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = INADDR_ANY;
    server_addr.sin_port = htons(port_num);

    // bind server socket
    bind_result = bind(
    	server_sock, 
    	(struct sockaddr *) &server_addr, 
    	sizeof(server_addr)
    );
    if (bind_result < 0) {
    	perror("error binding host");
    	return 1;
    }

    // listen on socket
    listen_result = listen(server_sock , MAX_CONNECTIONS);
    if (bind_result < 0) {
    	perror("error listening");
    	return 1;
    }

    // set client addr length
    client_len = (socklen_t) sizeof(client_addr);

    while((client_sock = accept(
        server_sock, 
        &client_addr, 
        &client_len
    ))) {

	    if (client_sock < 0) {
	    	perror("error connecting to client");
	    	return 1;
	    }

	    // fork new process
	    pid = fork();

	    if (pid == 0) {
	    	// child process (handle client)
	    	close_conn(server_sock, logfd);
	    	return handle_conn(
                &client_addr, 
                client_sock, 
                logfd
            );
	    } else if (pid < 0) {
	    	// fork error
	    	perror("fork error");
	    	return 1;
	    } else {
	    	// mother process (close client)
	    	close_conn(client_sock, logfd);
	    }
    }

    // control never reaches this point
    // need signal trap to reach here
    close_result = close_server(server_sock, logfd);
    fclose(logfd);
    return close_result;  
}

int main(int argc, char *argv[]) {

    // get port and max connections from
    // cmd line
    if (argc < 2) {
        perror("missing argument");
        return 1;
    }
    int port_num = atoi(argv[1]);

	return runserver(port_num);
}